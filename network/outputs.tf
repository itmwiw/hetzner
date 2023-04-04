output "virtual_network_id" {
  value = hcloud_network.network.id
}

output "subnet_id" {
  value = hcloud_network_subnet.subnet.id
}

output "internet_gateway_ip" {
  value = hcloud_server.internet.network.*.ip[0]
}

output "internet_gateway_public_ip" {
  value = hcloud_server.internet.ipv4_address
}

output "dns_server_ip" {
  value = local.dns_server_ip
}

output "api_lb_ip" {
  value = local.api_lb_ip
}

output "ingress_lb_ip" {
  value = local.ingress_lb_ip
}

output "masters_subnet_cidr" {
  value = local.masters_subnet_cidr
}

output "workers_subnet_cidr" {
  value = local.workers_subnet_cidr
}