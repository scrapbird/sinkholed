output "sinkholed_endpoint" {
  description = "The endpoint of the load balancer that can be used to connect to sinkholed"
  value       = module.service.lb_endpoint
}
