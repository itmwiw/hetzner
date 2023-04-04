output "server_ids" {
  value = hcloud_server.server.*.id
}

output "server_names" {
  value = hcloud_server.server.*.name
}

output "ip_addresses" {
  value = hcloud_server.server.*.network.*.ip[0]
}
