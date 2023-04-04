resource "hcloud_server" "dns" {
  name = "dns.${var.cluster_name}.${var.base_domain}"
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
	ip         = var.dns_server_ip
  }

  ssh_keys = [var.ssh_hcloud_key]
}

resource "null_resource" "dns_config" {  
  connection {
    host = hcloud_server.dns.ipv4_address
    timeout = "10m"
    agent = false
	private_key = var.ssh_private_key
    user = "root"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt -yq install dnsmasq",
      "sudo systemctl disable systemd-resolved && systemctl stop systemd-resolved",
      "rm /etc/resolv.conf",
      "rm /etc/hosts",
      "cat << \"EOF\" | sudo tee /etc/dnsmasq.conf",
      "listen-address=::1,127.0.0.1,${hcloud_server.dns.network.*.ip[0]}",
      "server=8.8.8.8",
      "server=4.4.4.4",
      "address=/.apps.okd.internal.com/${hcloud_load_balancer_network.ingress.ip}",
      "EOF",
      "sudo echo nameserver 127.0.0.1 > /etc/resolv.conf",
	  "sudo echo ${hcloud_load_balancer_network.api.ip} api-int.okd.internal.com >> /etc/hosts",
	  "sudo echo ${hcloud_load_balancer_network.api.ip} api.okd.internal.com >> /etc/hosts",
      "sudo systemctl restart dnsmasq"
    ]
  }
}

resource "null_resource" "dns_config_masters" {
  count = length(var.masters_ip_addresses)}
  connection {
    host = hcloud_server.dns.ipv4_address
    timeout = "1m"
    agent = false
	private_key = var.ssh_private_key
    user = "root"
  }
  provisioner "remote-exec" {
    inline = [
	  "sudo echo ${element(var.var.masters_ip_addresses, count.index))} master${count.index}.${var.cluster_name}.${var.base_domain} >> /etc/hosts"
    ]
  }
}

resource "null_resource" "dns_config_workers" {
  count = length(var.workers_ip_addresses)}
  connection {
    host = hcloud_server.dns.ipv4_address
    timeout = "1m"
    agent = false
	private_key = var.ssh_private_key
    user = "root"
  }
  provisioner "remote-exec" {
    inline = [
	  "sudo echo ${element(var.var.workers_ip_addresses, count.index))} worker${count.index}.${var.cluster_name}.${var.base_domain} >> /etc/hosts"
    ]
  }
}