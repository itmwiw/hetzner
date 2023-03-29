resource "hcloud_network" "network" {
  name     = "vnet-${var.cluster_name}"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "private_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = var.network_zone
  ip_range     = local.private_subnet_cidr
}

resource "hcloud_network_subnet" "public_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = var.network_zone
  ip_range     = local.public_subnet_cidr
}
