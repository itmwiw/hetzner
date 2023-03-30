output "cloudhelper_public_ip" {
  value = module.network.cloudhelper_public_ip
}

output "cloudhelper_ssh_private_key" {
  value = "The private ssh key is generated in the artifacts/ssh folder" 
}