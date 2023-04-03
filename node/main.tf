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
  
  network {
    network_id = var.network
  }

  # Image is ignored, as we boot into rescue mode, but is a required field
  image = "fedora-37"
  rescue = "linux64"
  ssh_keys = [var.ssh_hcloud_key]
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
      "cat << \"EOF\" > /network/ens10.nmconnection",
      "[connection]",
      "id=ens10",
      "type=ethernet",
      "autoconnect=true",
      "interface-name=ens10",
      "[ipv4]",
      "dns=${var.dns_server_ip};",
      "method=auto",
      "[ipv6]",
      "method=auto",
      "EOF",
      "chmod 600 /network/ens10.nmconnection",
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

resource "hcloud_rdns" "dns-ptr-ipv4" {
  count      = var.replicas
  server_id  = element(hcloud_server.server.*.id, count.index)
  ip_address = element(hcloud_server.server.*.ipv4_address, count.index)
  dns_ptr    = element(hcloud_server.server.*.name, count.index)
}

# resource "hcloud_rdns" "dns-ptr-ipv6" {
  # count      = var.replicas
  # server_id  = element(hcloud_server.server.*.id, count.index)
  # ip_address = "${element(hcloud_server.server.*.ipv6_address, count.index)}1"
  # dns_ptr    = element(hcloud_server.server.*.name, count.index)
# }

