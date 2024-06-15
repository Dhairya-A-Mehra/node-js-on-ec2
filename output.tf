output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_alb.hello_world_alb.dns_name
}
