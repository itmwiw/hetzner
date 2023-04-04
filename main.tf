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

module "network" {
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
  network         = module.network.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.network.dns_server_ip
  subnet_cidr     = module.network.masters_subnet_cidr
  
  depends_on      = [module.network]
}

module "master" {
  source          = "./node"
  role            = "master"
  replicas        = var.master_replicas
  server_type     = var.master_server_type
  location        = var.location
  base_domain     = var.base_domain
  cluster_name    = var.cluster_name
  network         = module.network.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.network.dns_server_ip
  subnet_cidr     = module.network.masters_subnet_cidr
  
  depends_on      = [module.network]
}

module "worker" {
  source          = "./node"
  role            = "worker"
  replicas        = var.worker_replicas
  server_type     = var.worker_server_type
  location        = var.location
  base_domain     = var.base_domain
  cluster_name    = var.cluster_name
  network         = module.network.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.network.dns_server_ip
  subnet_cidr     = module.network.workers_subnet_cidr
  
  depends_on      = [module.network]
}

module "dns" {
  source               = "./dns"
  location             = var.location
  base_domain          = var.base_domain
  cluster_name         = var.cluster_name
  network              = module.network.virtual_network_id
  subnet               = module.network.subnet_id
  ssh_private_key      = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key       = hcloud_ssh_key.key.id
  api_server_ids       = concat(module.master.server_ids, module.bootstrap.server_ids)
  ingress_server_ids   = concat(module.master.server_ids, module.worker.server_ids)
  dns_server_ip        = module.network.dns_server_ip
  api_lb_ip            = module.network.api_lb_ip
  ingress_lb_ip        = module.network.ingress_lb_ip
  masters_ip_addresses = module.master.ip_addresses
  workers_ip_addresses = module.worker.ip_addresses
  
  depends_on      = [module.network,module.master,module.worker]
}

# Output Generated Private Key
resource "local_file" "private_key" {
  content         = tls_private_key.hetzner.private_key_pem
  filename        = "artifacts/ssh/hetzner.pem"
  file_permission = "0600"
} 