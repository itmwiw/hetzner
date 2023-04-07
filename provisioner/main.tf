data "hcloud_ssh_key" "key" {
  id = var.ssh_hcloud_key
}

resource "hcloud_server" "provisioner" {
  name = "provisioner.${var.cluster_name}.${var.base_domain}"
  labels = { "os" = "ubuntu" }

  location    = var.location

  network {
    network_id = var.network
    ip         = var.provisioner_ip
  }	
 
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  server_type = "cx21"
  image = "ubuntu-22.04"
  ssh_keys = [var.ssh_hcloud_key]
  
  connection {
    host = hcloud_server.provisioner.ipv4_address
    timeout = "5m"
    agent = false
	private_key = var.ssh_private_key
    user = "root"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -x",
	  
	  ## Install oc and openshift-install ##
      "wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz",
      "tar xvf oc.tar.gz",
      "sudo mv oc /usr/local/bin",
      "sudo mv kubectl /usr/local/bin",
      "oc adm release extract --command=openshift-install --to ./ quay.io/openshift/okd:4.12.0-0.okd-2023-03-18-084815",
      "sudo mv openshift-install /usr/local/bin",
      "rm oc.tar.gz",
	  
	  ## Prepare install-config.yaml ##
      "cat << \"EOF\" | sudo tee install-config.yaml",
      "apiVersion: v1",
      "baseDomain: ${var.base_domain}",
      "metadata:",
      "  name: ${var.cluster_name}",
      "compute:",
      "- name: worker",
      "  replicas: ${var.worker_replicas}",
      "controlPlane:",
      "  name: master",
      "  replicas: ${var.master_replicas}",
      "networking:",
      "  clusterNetwork:",
      "  - cidr: 10.140.0.0/14",
      "    hostPrefix: 23",
	  # to do: try to fix OVN
      "  networkType: OpenShiftSDN",
      "  serviceNetwork:",
      "  - 172.40.0.0/16",
      "platform:",
      "  none: {}",
      "fips: false",
      "pullSecret: '{\"auths\":{\"fake\":{\"auth\":\"aWQ6cGFzcwo=\"}}}'",
      "sshKey: '${data.hcloud_ssh_key.key.public_key}'",
      "EOF",
	  
	  ## Generate ignition files
      "mkdir ${var.cluster_name}",
      "cp install-config.yaml ./${var.cluster_name}",
      "./openshift-install create manifests --dir=${var.cluster_name}/",
      "./openshift-install create ignition-configs --dir=${var.cluster_name}/",

      ## Install hcloud ##
      "wget https://github.com/hetznercloud/cli/releases/download/v1.32.0/hcloud-linux-amd64.tar.gz",
      "tar -xvf hcloud-linux-amd64.tar.gz",
      "mv hcloud /usr/local/bin",
      "rm hcloud-linux-amd64.tar.gz",
	  
	  ## Generate hcloud cli.toml file ##
      "mkdir -p ~/.config/hcloud/",
      "cat <<EOF > ~/.config/hcloud/cli.toml",
      "active_context = 'hetzner'",
      "[[contexts]]",
      "name = 'hetzner'",
      "token = '${var.hcloud_token}'",
      "EOF",

      ## configure DNS
      "echo DNS=${var.dns_server_ip} >> /etc/systemd/resolved.conf",
      "systemctl restart systemd-resolved"
    ]
  }
}

resource "hcloud_firewall" "provisioner" {
  name = "provisioner.${var.cluster_name}.${var.base_domain}"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "provisioner" {
    firewall_id = hcloud_firewall.provisioner.id
    server_ids  = [hcloud_server.provisioner.id]
	depends_on  = [hcloud_server.provisioner]
}