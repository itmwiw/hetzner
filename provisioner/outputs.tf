output "public_ip_address" {
  value = hcloud_server.provisioner.ipv4_address
}
