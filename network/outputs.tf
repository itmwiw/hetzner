output "virtual_network_id" {
  value = hcloud_network.network.id
}

output "subnet_id" {
  value = hcloud_network_subnet.subnet.id
}

output "cloudhelper_public_ip" {
  value = hcloud_server.server.ipv4_address
}

