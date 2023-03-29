locals {
  private_subnet_cidr = cidrsubnet(var.network_cidr, 3, 0)
  public_subnet_cidr = cidrsubnet(var.network_cidr, 3, 1)
}