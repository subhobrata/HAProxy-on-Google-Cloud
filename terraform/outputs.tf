output "blue_private_ip" {
  value = google_sql_database_instance.bg["blue"].private_ip_address
}
output "green_private_ip" {
  value = google_sql_database_instance.bg["green"].private_ip_address
}
