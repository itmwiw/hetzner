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
}

module "dns" {
  source             = "./dns"
  location           = var.location
  base_domain        = var.base_domain
  cluster_name       = var.cluster_name
  subnet             = module.network.subnet_id
  api_server_ids     = concat(module.master.server_ids, module.worker.server_ids)
  ingress_server_ids = concat(module.master.server_ids, module.worker.server_ids)
}