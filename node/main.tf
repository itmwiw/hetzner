locals {
  # The interface for the first attached network will be named ens10 (for CX, CCX*1) or enp7s0 (for CPX, CCX*2)
  nic = startswith(var.server_type, "cpx") ? "enp7s0" : "ens10"
}

resource "hcloud_server" "server" {
  count = var.replicas
  name = "${var.role}${count.index}.${var.cluster_name}.${var.base_domain}"
  labels = { "os" = "coreos" }

  server_type = var.server_type
  location    = var.location
  
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
    timeout = "10m"
    agent = false
	private_key = var.ssh_private_key
    # Root is the available user in rescue mode
    user = "root"
  }

  # Copy config.ign
  provisioner "file" {
    source = "../${var.cluster_name}/${var.role}.ign"
    destination = "/root/config.ign"
  }

  # Copy coreos-installer binary, as initramfs has not sufficient space to compile it in rescue mode
  provisioner "file" {
    source = "../coreos-installer"
    destination = "/usr/local/bin/coreos-installer"
  }

  # Install Fedora CoreOS in rescue mode
  provisioner "remote-exec" {
    inline = [
      "set -x",
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
      # coreos-installer binary is copied, if you have sufficient RAM available, you can also uncomment the following
      # two lines and comment-out the `chmod +x` line, to build coreos-installer in rescue mode
      # "apt install cargo",
      # "cargo install coreos-installer",
      "chmod +x /usr/local/bin/coreos-installer",
      # Download and install Fedora CoreOS to /dev/sda
      "coreos-installer install /dev/sda -i /root/config.ign --copy-network --network-dir /network",
      # Exit rescue mode and boot into coreos
      "shutdown"
    ]
  }
}

