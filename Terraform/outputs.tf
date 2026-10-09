############################################
# OUTPUTS.TF — Useful Info After Deployment
############################################

# ALB Public DNS (URL to access your app)
output "alb_dns_name" {
  description = "Application Load Balancer DNS URL"
  value       = aws_lb.app_alb.dns_name
}

# App Server Private IPs (for reference)
output "app_server_a_private_ip" {
  description = "Private IP of App Server A"
  value       = aws_instance.app_server_a.private_ip
}

output "app_server_b_private_ip" {
  description = "Private IP of App Server B"
  value       = aws_instance.app_server_b.private_ip
}

# RDS Endpoint
output "rds_endpoint" {
  description = "RDS MySQL endpoint for database connections"
  value       = aws_db_instance.mysql.address
}

# VPC ID
output "vpc_id" {
  description = "VPC ID for reference"
  value       = aws_vpc.main.id
}
