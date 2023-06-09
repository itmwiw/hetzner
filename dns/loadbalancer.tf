resource "hcloud_load_balancer" "api" {
  name               = "api-int.${var.cluster_name}.${var.base_domain}"
  load_balancer_type = "lb11"
  location           = var.location
}
  
resource "hcloud_load_balancer_network" "api" {
  load_balancer_id        = hcloud_load_balancer.api.id
  subnet_id               = var.subnet
  enable_public_interface = false
  ip                      = var.api_lb_ip
}

resource "hcloud_load_balancer_target" "api_target" {
  count = length(var.api_server_ids)
  
  type             = "server"
  load_balancer_id = hcloud_load_balancer.api.id
  server_id        = var.api_server_ids[count.index]
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.api]
}


resource "hcloud_load_balancer_service" "api" {
  load_balancer_id = hcloud_load_balancer.api.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 1
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "mcs" {
  load_balancer_id = hcloud_load_balancer.api.id
  protocol         = "tcp"
  listen_port      = 22623
  destination_port = 22623

  health_check {
    protocol = "tcp"
    port     = 22623
    interval = 10
    timeout  = 1
    retries  = 3
  }
}

resource "hcloud_load_balancer" "ingress" {
  name               = "apps.${var.cluster_name}.${var.base_domain}"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_network" "ingress" {
  load_balancer_id        = hcloud_load_balancer.ingress.id
  subnet_id               = var.subnet
  enable_public_interface = false
  ip                      = var.ingress_lb_ip
}

resource "hcloud_load_balancer_target" "ingress_target" {
  count = length(var.ingress_server_ids)
  
  type             = "server"
  load_balancer_id = hcloud_load_balancer.ingress.id
  server_id        = var.ingress_server_ids[count.index]
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.ingress]
}

resource "hcloud_load_balancer_service" "ingress_http" {
  load_balancer_id = hcloud_load_balancer.ingress.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80

  health_check {
    protocol = "tcp"
    port     = 80
    interval = 10
    timeout  = 1
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "ingress_https" {
  load_balancer_id = hcloud_load_balancer.ingress.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443

  health_check {
    protocol = "tcp"
    port     = 443
    interval = 10
    timeout  = 1
    retries  = 3
  }
}
