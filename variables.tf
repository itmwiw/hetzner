
############
# Hetzner variables
#########

variable "hcloud_token" {
  sensitive = true
  description = "Hetzner Cloud API Token"
  type = string
}

variable "location" {
  type        = string
  description = "Region"
  default     = "nbg1"
}

############
# Nodes variables
#########

variable "master_server_type" {
  description = "vServer type name, lookup via `hcloud server-type list`"
  type = string
  default = "cx41"
}

variable "worker_server_type" {
  description = "vServer type name, lookup via `hcloud server-type list`"
  type = string
  default = "cx41"
}

variable "master_replicas" {
  type        = number
  default     = 3
  description = "Count of master replicas"
}

variable "worker_replicas" {
  type        = number
  default     = 1
  description = "Count of worker replicas"
}

############
# Networking variables
#########

variable "network_cidr" {
  type        = string
  description = "CIDR for the network"
  default     = "10.0.0.0/16"
}

variable "network_zone" {
  type        = string
  description = "hcloud zone for the network"
  default     = "eu-central"
}

############
# OKD variables
#########

variable "cluster_name" {
  type        = string
  description = "OKD's cluster name."
}

variable "base_domain" {
  type        = string
  description = "Name of the DNS domain"
}






