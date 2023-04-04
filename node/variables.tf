
############
# Node variables
#########

variable "location" {
  type        = string
  description = "Region"
}

variable "server_type" {
  description = "vServer type name, lookup via `hcloud server-type list`"
  type = string
}

variable "role" {
  type        = string
  description = "Possible values: bootstrap, master, worker"
}

variable "replicas" {
  type        = number
  description = "Count of this role replicas"
}

variable "base_domain" {
  type        = string
  description = "Name of the dns domain"
}

variable "cluster_name" {
  type        = string
  description = "OKD's cluster name"
}

variable "network" {
  type        = string
  description = "The server's network"
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

variable "dns_server_ip" {
  type        = string
  description = "The dns server's private ip"
}

variable "subnet_cidr" {
  type        = string
  description = "The nodes' subnet"
}
