# main.tf

####
# Infrastructure config
##

provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "hetzner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "key" {
  name = "hcloud_ssh_key"
  public_key = tls_private_key.hetzner.public_key_openssh
}

module "networking" {
  source              = "./network"
  network_cidr        = var.network_cidr
  network_zone        = var.network_zone
  cluster_name        = var.cluster_name
  base_domain         = var.base_domain
  location            = var.location
  ssh_private_key     = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key      = hcloud_ssh_key.key.id
}

module "bootstrap" {
  source          = "./node"
  role            = "bootstrap"
  replicas        = 1
  server_type     = var.master_server_type
  location        = var.location
  base_domain     = var.base_domain
  cluster_name    = var.cluster_name
  network         = module.networking.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.networking.dns_server_ip
  subnet_cidr     = module.networking.masters_subnet_cidr
  
  depends_on      = [module.networking]
}

module "master" {
  source          = "./node"
  role            = "master"
  replicas        = var.master_replicas
  server_type     = var.master_server_type
  location        = var.location
  base_domain     = var.base_domain
  cluster_name    = var.cluster_name
  network         = module.networking.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.networking.dns_server_ip
  subnet_cidr     = module.networking.masters_subnet_cidr
  
  depends_on      = [module.networking]
}

module "worker" {
  source          = "./node"
  role            = "worker"
  replicas        = var.worker_replicas
  server_type     = var.worker_server_type
  location        = var.location
  base_domain     = var.base_domain
  cluster_name    = var.cluster_name
  network         = module.networking.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.networking.dns_server_ip
  subnet_cidr     = module.networking.workers_subnet_cidr
  
  depends_on      = [module.networking]
}

module "dns" {
  source               = "./dns"
  location             = var.location
  base_domain          = var.base_domain
  cluster_name         = var.cluster_name
  subnet               = module.networking.subnet_id
  api_server_ids       = concat(module.master.server_ids, module.bootstrap.server_ids)
  ingress_server_ids   = concat(module.master.server_ids, module.worker.server_ids)
  dns_server_ip        = module.networking.dns_server_ip
  api_lb_ip            = module.networking.api_lb_ip
  ingress_lb_ip        = module.networking.ingress_lb_ip
  masters_ip_addresses = module.master.ip_addresses
  workers_ip_addresses = module.worker.ip_addresses
}

# Output Generated Private Key
resource "local_file" "private_key" {
  content         = tls_private_key.hetzner.private_key_pem
  filename        = "artifacts/ssh/hetzner.pem"
  file_permission = "0600"
} 