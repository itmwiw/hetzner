variable "hcloud_token" {
  sensitive = true
  description = "Hetzner Cloud API Token"
  type = string
}

variable "location" {
  type        = string
  description = "Region"
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

variable "subnet_cidr" {
  type        = string
  description = "The nodes' subnet"
}

variable "dns_server_ip" {
  type        = string
  description = "The dns server's private ip"
}

variable "provisioner_ip" {
  type        = string
  description = "The provisioner server's private ip"
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

variable "master_replicas" {
  type        = number
  description = "Count of master replicas"
}

variable "worker_replicas" {
  type        = number
  description = "Count of worker replicas"
}