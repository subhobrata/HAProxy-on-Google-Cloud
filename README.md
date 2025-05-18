# Cloud SQL Blue‑Green Demo with HAProxy

This sample repository shows **blue‑green Postgres Cloud SQL** instances on Google Cloud behind an **HAProxy** load‑balancer, so you can switch database traffic in seconds with zero‑downtime.

```
┌───────────────┐                 ┌────────────┐
│ client / app ─┼─▶ HAProxy (CE) ─┼─▶ blue DB  │
└───────────────┘   tcp:5432      └────────────┘
                          │
                          └─▶ green DB
```

* **Blue / Green** instances are created as *regional‑HA* Cloud SQL (PostgreSQL 15).
* **HAProxy** runs on a small Compute Engine VM (or container) deployed via Terraform.
* Switch traffic with `haproxy/switch_backend.sh` in \<1 s using the Runtime API.

## Prerequisites

* gcloud ≥ 471, Terraform ≥ 1.7
* A GCP project & service account with IAM: `roles/cloudsql.admin` `roles/compute.admin`
* `psql` / your Postgres client

## Quick Start

```bash
cd terraform
terraform init
terraform apply -var='project_id=YOUR_GCP_PROJECT'                  -var='region=asia-south1'                  -var='db_password=Str0ngPass!'
```

When the apply finishes you’ll get:

* private IPs of **blue** and **green** DBs
* external IP of **haproxy-vm**

```bash
ssh $(terraform output -raw haproxy_ssh)   # connect, test
psql -h <haproxy_ip> -U postgres -d appdb  # connect via HAProxy
```

### Switching traffic

```bash
# run from your workstation
./haproxy/switch_backend.sh blue   # send all sessions to blue
./haproxy/switch_backend.sh green  # go green
```

## Directory Layout

```
terraform/          # IaC for Cloud SQL, VPC & HAProxy VM
haproxy/
   └─ haproxy.cfg   # base config, 2 back‑ends
   └─ Dockerfile    # optional container build
   └─ switch_backend.sh
app/
   └─ main.py       # tiny test client (psycopg2)
```

## Caveats

* **Not production‑ready**: no SSL, minimal firewall, single HAProxy VM.
* Use the Cloud SQL Auth Proxy or private service networking for production.

---  
© 2025 Your Name. MIT License.
