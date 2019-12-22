module "network" {
  source = "./modules/network"
  project = var.project
  environment = var.environment
  tags = {
    managedBy = "terraform"
    environment = var.environment
    project = var.project
  }
}

