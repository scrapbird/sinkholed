output "lb_endpoint" {
  description = "The endpoint that can be used to connect to the load balancer"
  value       = aws_lb.main.dns_name
}

