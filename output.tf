# output "webapp_subnet_cidr"{
#     value = google_compute_subnetwork.webapp_subnet.ip_cidr_range
# }

# # Printing each key
# output "vpc_names" {
#   value = each.key
# }

# output "database_password" {
#   value = random_password.db_password.result
#   sensitive = true
# }