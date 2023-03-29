output "virtual_network_id" {
  value = hcloud_network.network.id
}

output "subnet_id" {
  value = hcloud_network_subnet.subnet.id
}

