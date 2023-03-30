resource "hcloud_server" "server" {
  name = "cloudhelper.${var.cluster_name}.${var.base_domain}"
  labels = { "os" = "coreos" }

  server_type = "cx21"
  image = "ubuntu-22.04"
  location    = var.location
  
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  
  network {
    network_id = hcloud_network.network.id
	#ip         = "10.0.0.2"
  }

  ssh_keys = [var.ssh_hcloud_key]
  
  connection {
    host = hcloud_server.server.ipv4_address
    timeout = "10m"
    agent = false
	private_key = var.ssh_private_key
    # Root is the available user in rescue mode
    user = "root"
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      "sudo echo 1 > /proc/sys/net/ipv4/ip_forward",
      "ip_forward='net.ipv4.ip_forward=1'",
      "sed -i \"/^#$ip_forward/ c$ip_forward\" /etc/sysctl.conf",
	  "sudo apt update -q",
      "sudo DEBIAN_FRONTEND=noninteractive apt -yq install iptables-persistent",
      "sudo iptables -t nat -A POSTROUTING -s '${var.network_cidr}' -o eth0 -j MASQUERADE",
      "sudo iptables-save > /etc/iptables/rules.v4"
    ]
  }
}


