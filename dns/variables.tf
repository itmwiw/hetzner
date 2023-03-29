
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