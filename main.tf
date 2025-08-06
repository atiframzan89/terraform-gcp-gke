module "vpc" {
        source          = "./modules/vpc"
        customer        = var.customer
        region          = var.region
        vpc             = var.vpc
}

module "gke" {
        source                  = "./modules/gke"
        customer                = var.customer
        region                  = var.region
        vpc                     = var.vpc
        environment             = var.environment
        zonal-location          = data.google_compute_zones.available.names
        vpc-id                  = module.vpc.vpc-id
        private-subnet-1        = module.vpc.private-subnet-1
        project-id              = var.project-name
}
