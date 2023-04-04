output "internet_gateway_public_ip" {
  value = module.network.internet_gateway_public_ip
}

output "ssh_private_key" {
  value = "The private ssh key is generated in the artifacts/ssh folder" 
}