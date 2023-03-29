locals {
  subnet_cidr = cidrsubnet(var.network_cidr, 3, 0)
}