module "network" {
  source = "./modules/network"
  project = var.project
  tags = {
    managedBy = "terraform"
    environment = "test"
  }
}

