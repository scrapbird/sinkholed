module "network" {
  source = "./modules/network"
  project = "sinkholed"
  environment = var.environment
  tags = {
    managedBy = "terraform"
    environment = var.environment
    project = "sinkholed"
  }
}

