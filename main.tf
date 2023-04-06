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

module "provisioner" {
  source          = "./provisioner"
  hcloud_token    = var.hcloud_token
  master_replicas = var.master_replicas
  worker_replicas = var.worker_replicas
  location        = var.location
  base_domain     = var.base_domain
  cluster_name    = var.cluster_name
  network         = module.network.virtual_network_id
  ssh_private_key = tls_private_key.hetzner.private_key_pem
  ssh_hcloud_key  = hcloud_ssh_key.key.id
  dns_server_ip   = module.network.dns_server_ip
  provisioner_ip  = module.network.provisioner_ip
  
  depends_on      = [module.network]
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
  provisioner_ip  = module.network.provisioner_ip
  subnet_cidr     = module.network.masters_subnet_cidr
  
  depends_on      = [module.network,module.provisioner]
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
  provisioner_ip  = module.network.provisioner_ip
  subnet_cidr     = module.network.masters_subnet_cidr
  
  depends_on      = [module.network,module.provisioner]
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
  provisioner_ip  = module.network.provisioner_ip
  subnet_cidr     = module.network.workers_subnet_cidr
  
  depends_on      = [module.network,module.provisioner]
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

locals {
  to_delete_ips = concat(module.bootstrap.public_ip_addresses,module.master.public_ip_addresses, module.worker.public_ip_addresses)
}

resource "null_resource" "delete_public_ips" {
  count = length(local.to_delete_ips)
  connection {
    host = module.provisioner.public_ip_address
    timeout = "5m"
    agent = false
	private_key = tls_private_key.hetzner.private_key_pem
    user = "root"
  }
  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -x",
	  "server_id=$(hcloud server list | grep ${local.to_delete_ips[count.index]} | awk '{print $1;}')",
      "hcloud server poweroff $server_id",
	  "hcloud primary-ip delete $(hcloud primary-ip list | grep ${local.to_delete_ips[count.index]} | awk '{print $1;}')",
      "hcloud server poweron $server_id)"
    ]
  }
  
  depends_on = [module.network,module.master,module.worker,module.dns]
}

