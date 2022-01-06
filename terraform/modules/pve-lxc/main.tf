terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "~> 2.6.7"
    }
  }
}

resource "proxmox_lxc" "lxc_container" { 
    target_node = var.target_node 
    ostemplate = var.ostemplate 
    hostname = var.hostname
    description = var.description
    cores = var.cores
    memory = var.memory
    onboot = var.onboot
    start = var.start
    network {
        name = var.network_name
        bridge = var.network_bridge
        ip = var.network_ip
        gw = var.network_gw
        firewall = var.network_firewall
    }
    nameserver = var.nameserver
    searchdomain = var.searchdomain
    password = var.password
    rootfs {
        storage = var.rootfs_storage
        size = var.rootfs_size
    }  
    unprivileged = var.unprivileged
    ssh_public_keys = var.ssh_public_keys
 
}
// Reference: https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/lxc.md

// Allow time for provisioning & startup to complete before continuing
resource "time_sleep" "wait_25_sec" {
  depends_on = [proxmox_lxc.lxc_container]
  create_duration = "30s"
}

// Post-provisioning pre-Ansible connectivity check
resource "null_resource" "provisioning" {
  depends_on = [time_sleep.wait_25_sec]
  // Connection check before handoff to Ansible in parent module. Default timeout of 5 minutes.
  provisioner "remote-exec" {
    inline = [
      "echo NOW CONNECTED!"
    ]

    connection {
      type        = "ssh"
      host        = var.ip_address
      user        = var.default_image_username
      private_key = var.private_key
    }
  }
}