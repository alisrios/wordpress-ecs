output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.this.endpoint
}

output "alb_dns_name" {
  description = "DNS name do Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "cloudfront_domain_name" {
  description = "Domain name do CloudFront"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.this.id
}
