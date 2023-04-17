# versions.tf

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.38.1"
    }
  }
  required_version = ">= 0.15"
}