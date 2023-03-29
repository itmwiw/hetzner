output "virtual_network_id" {
  value = hcloud_network.network.id
}

output "private_subnet_id" {
  value = hcloud_network_subnet.private_subnet.id
}

output "public_subnet_id" {
  value = hcloud_network_subnet.public_subnet.id
}

