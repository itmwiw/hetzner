resource "hcloud_server" "internet" {
  name = "internet.${var.cluster_name}.${var.base_domain}"
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
	ip = locals.internet_gateway_ip
  }

  ssh_keys = [var.ssh_hcloud_key]
}

resource "null_resource" "internet_config" {  
  connection {
    host = hcloud_server.internet.ipv4_address
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
      "sudo iptables-save > /etc/iptables/rules.v4",
	  
      "sudo DEBIAN_FRONTEND=noninteractive apt -yq install dnsmasq",
      "sudo systemctl disable systemd-resolved && systemctl stop systemd-resolved",
      "rm /etc/resolv.conf",
      "cat << \"EOF\" | sudo tee /etc/dnsmasq.conf",
      "listen-address=::1,127.0.0.1,${hcloud_server.internet.network.*.ip[0]}",
      "server=8.8.8.8",
      "server=4.4.4.4",
      "EOF",
      "sudo echo nameserver 127.0.0.1 > /etc/resolv.conf",
      "sudo systemctl restart dnsmasq"
    ]
  }
}

resource "hcloud_firewall" "internet_gateway" {
  name = "internet.${var.cluster_name}.${var.base_domain}"
}

resource "hcloud_firewall_attachment" "internet_gateway" {
    firewall_id = hcloud_firewall.internet_gateway.id
    server_ids  = [hcloud_server.internet.id]
	depends_on  = [null_resource.internet_config]
}


