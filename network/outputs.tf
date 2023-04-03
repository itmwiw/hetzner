output "virtual_network_id" {
  value = hcloud_network.network.id
}

output "subnet_id" {
  value = hcloud_network_subnet.subnet.id
}

output "internet_gateway_ip" {
  value = hcloud_server.internet.network.*.ip[0]
}

output "cloudhelper_public_ip" {
  value = hcloud_server.internet.ipv4_address
}

