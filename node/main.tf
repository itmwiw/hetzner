locals {
  # The interface for the first attached network will be named ens10 (for CX, CCX*1) or enp7s0 (for CPX, CCX*2)
  nic = startswith(var.server_type, "cpx") ? "enp7s0" : "ens10"
}

resource "hcloud_placement_group" "server" {
  count = var.role == "bootstrap" ? 0 : 1
  name = "${var.role}.${var.cluster_name}.${var.base_domain}"
  type = "spread"
  labels = {
    role = "${var.role}"
  }
}

resource "hcloud_server" "server" {
  count = var.replicas
  name = "${var.role}${count.index}.${var.cluster_name}.${var.base_domain}"
  labels = { "os" = "coreos" }

  server_type = var.server_type
  location    = var.location
  placement_group_id = var.role == "bootstrap" ? null : hcloud_placement_group.server.0.id

  # Rescue mode only works with public ip  
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  # Image is ignored, as we boot into rescue mode, but is a required field
  image = "fedora-37"
  rescue = "linux64"
  ssh_keys = [var.ssh_hcloud_key]
}

resource "hcloud_server_network" "server" {
  count      = var.replicas
  server_id  = hcloud_server.server[count.index].id
  network_id = var.network
  ip         = var.role == "bootstrap" ? cidrhost(var.subnet_cidr, count.index + 100) : cidrhost(var.subnet_cidr, count.index + 1)
}

resource "null_resource" "node_config" {
  count = var.replicas
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    node_instance_ids = join(",", hcloud_server.server.*.id)
  }

  connection {
    host = hcloud_server.server[count.index].ipv4_address
    timeout = "15m"
    agent = false
	private_key = var.ssh_private_key
    # Root is the available user in rescue mode
    user = "root"
  }

  # Private key is needed to get ignition file from provisioner server
  provisioner "file" {
    content = var.ssh_private_key
    destination = "/root/hetzner.pem"
  }
  
  # Install Fedora CoreOS in rescue mode
  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -x",
	  
	  ## configure dns ##
      "mkdir /network",
      "cat << \"EOF\" > /network/${local.nic}.nmconnection",
      "[connection]",
      "id=${local.nic}",
      "type=ethernet",
      "autoconnect=true",
      "interface-name=${local.nic}",
      "[ipv4]",
      "dns=${var.dns_server_ip};",
      "method=auto",
      "[ipv6]",
      "method=auto",
      "EOF",
      "chmod 600 /network/${local.nic}.nmconnection",
	  
	  ## Build coreos-installer binary ##
      "apt-get -y install libzstd-dev libssl-dev pkg-config",
      "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > cargo.sh",
      "chmod +x cargo.sh",
      "./cargo.sh -y",
      "source \"$HOME/.cargo/env\"",
      "cargo install --target-dir . coreos-installer",

      ## Get ignition file ##
      "chmod 400 hetzner.pem",
      "scp -o StrictHostKeyChecking=no -i hetzner.pem root@${var.provisioner_ip}:/root/${var.cluster_name}/${var.role}.ign .",
	  
	  ## Install coreos
      "coreos-installer install /dev/sda -i ./${var.role}.ign --copy-network --network-dir /network",
	  
      ## Exit rescue mode and shutdown ##
      "shutdown"
    ]
  }
}

