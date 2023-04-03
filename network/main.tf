resource "hcloud_network" "network" {
  name     = "vnet-${var.cluster_name}"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = var.network_zone
  ip_range     = local.subnet_cidr
}

resource "hcloud_network_route" "internet" {
  network_id  = hcloud_network.network.id
  destination = "0.0.0.0/0"
  gateway     = hcloud_server.internet.network.*.ip[0]
  depends_on  = [hcloud_server.server]
}