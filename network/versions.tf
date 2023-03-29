# versions.tf

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.36.2"
    }
  }
  required_version = ">= 0.13"
}