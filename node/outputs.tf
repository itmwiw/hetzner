output "server_ids" {
  value = hcloud_server.server.*.id
}

output "server_names" {
  value = hcloud_server.server.*.name
}

output "ip_addresses" {
  value = hcloud_server_network.server.*.ip
}

output "public_ip_addresses" {
  value = hcloud_server.server.*.ipv4_address
}