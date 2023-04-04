locals {
  subnet_cidr = cidrsubnet(var.network_cidr, 3, 0)
  internet_gateway_ip = cidrhost(local.subnet_cidr, 254)
  dns_server_ip = cidrhost(local.subnet_cidr, 253)
  api_lb_ip = cidrhost(local.subnet_cidr, 2)
  ingress_lb_ip = cidrhost(local.subnet_cidr, 3)
  masters_subnet_cidr = cidrsubnet(var.network_cidr, 3, 1)
  workers_subnet_cidr = cidrsubnet(var.network_cidr, 3, 2)
}