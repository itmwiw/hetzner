
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

variable "subnet" {
  type        = string
  description = "Loadbalancer's subnet"
}

variable "api_server_ids" {
  description = "API loadbalancer's target"
}

variable "ingress_server_ids" {
  description = "Ingress loadbalancer's target"
}

variable "dns_server_ip" {
  type        = string
  description = "The dns server's private ip"
}

variable "api_lb_ip" {
  type        = string
  description = "The api loadbalancer's private ip"
}

variable "ingress_lb_ip" {
  type        = string
  description = "The ingress loadbalancer's private ip"
}

variable "masters_ip_addresses" {
  description = "Masters' ip adresses"
}

variable "workers_ip_addresses" {
  description = "Workers' ip adresses"
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