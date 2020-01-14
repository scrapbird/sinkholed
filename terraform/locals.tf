locals {
  tags = merge(var.tags, {
    environment = var.environment
    project     = "sinkholed"
  })
}
