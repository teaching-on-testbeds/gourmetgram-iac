# GPU node configuration
# This file adds a GPU worker node to the existing cluster

variable "gpu_reservation" {
  description = "UUID of the reserved GPU flavor"
  type        = string
}

variable "gpu_node_name" {
  description = "Name of the GPU node"
  type        = string
  default     = "gpu-node1"
}

variable "gpu_node_ip" {
  description = "Private IP for GPU node"
  type        = string
  default     = "192.168.1.14"
}

# Private network port for GPU node
resource "openstack_networking_port_v2" "gpu_private_port" {
  name                  = "port-${var.gpu_node_name}-mlops-${var.suffix}"
  network_id            = openstack_networking_network_v2.private_net.id
  port_security_enabled = false

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private_subnet.id
    ip_address = var.gpu_node_ip
  }
}

# Shared network port for GPU node
resource "openstack_networking_port_v2" "gpu_sharednet_port" {
  name       = "sharednet1-${var.gpu_node_name}-mlops-${var.suffix}"
  network_id = data.openstack_networking_network_v2.sharednet1.id
  security_group_ids = [
    data.openstack_networking_secgroup_v2.allow_ssh.id,
    data.openstack_networking_secgroup_v2.allow_9001.id,
    data.openstack_networking_secgroup_v2.allow_8000.id,
    data.openstack_networking_secgroup_v2.allow_8080.id,
    data.openstack_networking_secgroup_v2.allow_8081.id,
    data.openstack_networking_secgroup_v2.allow_8082.id,
    data.openstack_networking_secgroup_v2.allow_http_80.id,
    data.openstack_networking_secgroup_v2.allow_9090.id
  ]
}

# GPU compute instance
resource "openstack_compute_instance_v2" "gpu_node" {
  name        = "${var.gpu_node_name}-mlops-${var.suffix}"
  image_name  = "CC-Ubuntu24.04"
  flavor_id   = var.gpu_reservation
  key_pair    = var.key

  network {
    port = openstack_networking_port_v2.gpu_sharednet_port.id
  }

  network {
    port = openstack_networking_port_v2.gpu_private_port.id
  }

  user_data = <<-EOF
    #! /bin/bash
    sudo echo "127.0.1.1 ${var.gpu_node_name}-mlops-${var.suffix}" >> /etc/hosts
    su cc -c /usr/local/bin/cc-load-public-keys
  EOF
}
