output "infrastructure_status" {
  description = "Infrastructure provisioning status"
  value       = "provisioned"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "app_name" {
  description = "Application name"
  value       = var.app_name
}