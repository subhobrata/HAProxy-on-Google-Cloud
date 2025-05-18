terraform {
  required_version = ">= 1.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name = "bg-demo-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "bg-demo-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_firewall" "haproxy" {
  name    = "haproxy-fw"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "5432"]
  }

  source_ranges = var.allowed_cidrs
  target_tags   = ["haproxy"]
}

# Blue & Green Cloud SQL (regional‑HA)
locals {
  instances = [
    { name = "blue", tier = "db-custom-2-7680" },
    { name = "green", tier = "db-custom-2-7680" },
  ]
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

resource "google_compute_global_address" "private_ip" {
  name          = "bg-demo-sql-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_sql_database_instance" "bg" {
  for_each        = { for inst in local.instances : inst.name => inst }
  name            = "bg-${each.key}"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier            = each.value.tier
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  deletion_protection = false
  root_password       = var.db_password
}

resource "google_sql_database" "appdb" {
  for_each = google_sql_database_instance.bg
  name     = "appdb"
  instance = each.value.name
}

# Simple HAProxy VM
resource "google_compute_instance" "haproxy" {
  name         = "haproxy-vm"
  machine_type = "e2-small"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOF
    apt-get update -y
    apt-get install -y haproxy socat openssl
    openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
      -subj "/CN=haproxy" \
      -keyout /etc/ssl/private/haproxy.key \
      -out /etc/ssl/certs/haproxy.crt
    cat /etc/ssl/certs/haproxy.crt /etc/ssl/private/haproxy.key > /etc/haproxy/server.pem
    chmod 600 /etc/haproxy/server.pem
    cat > /etc/haproxy/haproxy.cfg <<CFG
global
  log /dev/log local0
  stats socket /var/run/haproxy.sock mode 600 level admin
defaults
  mode tcp
  timeout connect 5s
  timeout client  1m
  timeout server  1m

frontend pg_front
  bind *:5432 ssl crt /etc/haproxy/server.pem
  default_backend pg_blue

backend pg_blue
  option  ssl-hello-chk
  server  pg1 ${google_sql_database_instance.bg["blue"].private_ip_address}:5432 check

backend pg_green
  option  ssl-hello-chk
  server  pg2 ${google_sql_database_instance.bg["green"].private_ip_address}:5432 check
CFG
    systemctl restart haproxy
  EOF

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["haproxy"]
}

output "haproxy_ip" {
  value = google_compute_instance.haproxy.network_interface[0].access_config[0].nat_ip
}

output "haproxy_ssh" {
  value = "ssh ubuntu@${google_compute_instance.haproxy.network_interface[0].access_config[0].nat_ip}"
}
