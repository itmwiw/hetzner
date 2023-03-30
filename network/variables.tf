
variable "network_zone" {
  type        = string
  description = "hcloud zone for the network"
}

variable "network_cidr" {
  type        = string
  description = "CIDR for the network"
}

variable "cluster_name" {
  type        = string
  description = "OKD's cluster name"
}

variable "base_domain" {
  type        = string
  description = "Name of the dns domain"
}

variable "ssh_private_key" {
  sensitive = true
  description = "SSH key"
  type = string
}

variable "ssh_hcloud_key" {
  description = "hcloud ssh key"
  type = string
}

variable "location" {
  type        = string
  description = "Region"
}


