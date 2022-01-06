// "Live" Terraform infra config for a nest K3s (k3s.io) cluster 
// running on Proxmox VMs. Post-provisioning config handed off to Ansible.

terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "~> 2.6.7"     
    }
  }
}

// Set local variables for provisioning 
locals {
  # -- Common Variables -- #
  desc = "K3s VM, created with Terraform on ${timestamp()}"
  full_clone = true
  default_image_username = "ansible"
  default_image_password = "ansible"
  clone_wait = 5
  onboot = false
  nameserver = "192.168.2.1"
  searchdomain = "int.layer8sys.com"
  boot = "order=scsi0;ide2;net0"
  vm_sockets = 2
  vm_cores = 4  
  agent = 1
  ssh_public_keys = tls_private_key.bootstrap_private_key.public_key_openssh
  terraform_provisioner_type = "ssh"
  ansible_inventory_filename = "k3s"
  k3s_ansible_git_repo = "https://github.com/clayshek/k3s-ansible.git"

  # -- K3s Server Node VM Variables -- #
  k3sserver_target_node = "pve1"
  k3sserver_clone = "tpl-ubuntu-20-04-3-pve1" 
  k3sserver_vm_name = "k3smaster"
  k3sserver_vm_memory = "2048"
  k3sserver_ip_address = "192.168.2.60"
  k3sserver_ip_cidr = "/24"
  k3sserver_gw = "192.168.2.1"
  k3sserver_ansible_inventory_group = "k3s_server"
  // Dynamic block for network adapters to add to VM
  k3sserver_vm_network = [
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
  ]

  // Dynamic block for disk devices to add to VM. 1st is OS, size should match or exceed template.
  k3sserver_vm_disk = [
    {
      type = "scsi"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 0
    },         
  ]    
  
  # -- K3s Worker Node VM Variables -- #
  k3sworker_target_node = "pve2"
  k3sworker_clone = "tpl-ubuntu-20-04-3-pve2" 
  k3sworker_vm_name_prefix = "k3sworker"
  k3sworker_vm_memory = "2048"
  // IP assignment count in this block will control count of k3sworker VMs provisioned
  k3sworker_ip_addresses = {
      "1" = "192.168.2.61"
      "2" = "192.168.2.62"
      "3" = "192.168.2.63"
  }
  k3sworker_ip_cidr = "/24"
  k3sworker_gw = "192.168.2.1"
  k3sworker_ansible_inventory_group = "k3s_workers"
  // Dynamic block for network adapters to add to VM
  k3sworker_vm_network = [
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
  ]

  // Dynamic block for disk devices to add to VM. 1st is OS, size should match or exceed template.
  k3sworker_vm_disk = [
    {
      type = "scsi"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 0
    },         
  ]    
}

// Create k3s server node VM 
module "k3sserver_vm" {
  source = "../../modules/pve-vm"

  target_node = local.k3sserver_target_node
  clone = local.k3sserver_clone
  vm_name = local.k3sserver_vm_name
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores    
  memory = local.k3sserver_vm_memory
  vm_network = local.k3sserver_vm_network
  vm_disk = local.k3sserver_vm_disk    
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${local.k3sserver_ip_address}${local.k3sserver_ip_cidr},gw=${local.k3sserver_gw}"
  ip_address = local.k3sserver_ip_address
  ssh_public_keys = local.ssh_public_keys
  default_image_username = local.default_image_username
  default_image_password = local.default_image_password
  private_key = tls_private_key.bootstrap_private_key.private_key_pem
}

// Create k3s worker node VMs
module "k3sworker_nodes" {
  source = "../../modules/pve-vm"

  count = length(local.k3sworker_ip_addresses)

  target_node = local.k3sworker_target_node
  clone = local.k3sworker_clone
  vm_name = "${local.k3sworker_vm_name_prefix}${format("%02d", count.index+1)}"
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores    
  memory = local.k3sworker_vm_memory
  vm_network = local.k3sworker_vm_network
  vm_disk = local.k3sworker_vm_disk    
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${lookup(local.k3sworker_ip_addresses, count.index+1)}${local.k3sworker_ip_cidr},gw=${local.k3sworker_gw}"
  ip_address = lookup(local.k3sworker_ip_addresses, count.index+1)
  ssh_public_keys = local.ssh_public_keys
  default_image_username = local.default_image_username
  default_image_password = local.default_image_password
  private_key = tls_private_key.bootstrap_private_key.private_key_pem
}

// Create a temporary key pair for post-provisioning config
resource "tls_private_key" "bootstrap_private_key" {
  algorithm = "RSA"
}

// Create temp private key file from key pair above for initial Ansible use
resource "local_file" "temp-private-key" {
  sensitive_content = tls_private_key.bootstrap_private_key.private_key_pem
  filename = "${path.module}/private_key.pem"
  file_permission = "0600"
}

// Create Ansible inventory file
module "ansible_inventory" {
  source = "../../modules/create-ansible-inventory"
  servers = {
    (local.k3sserver_ansible_inventory_group) = [local.k3sserver_ip_address]
    (local.k3sworker_ansible_inventory_group) = [
      for k,v in local.k3sworker_ip_addresses: v
      ]
  }
  ansible_inventory_filename = local.ansible_inventory_filename
}

/*

*/

// Ansible post-provisioning configuration
resource "null_resource" "configuration" {
  depends_on = [
    module.k3sserver_vm,
    module.k3sworker_nodes
  ]

  // Clear existing records (if exists) from known_hosts to prevent possible ssh connection issues
  provisioner "local-exec" {
    command = <<-EOT
      if test -f "~/.ssh/known_hosts"; then
        ssh-keygen -f ~/.ssh/known_hosts -R ${local.k3sserver_ip_address}
      fi
      EOT
  }

  // Ansible playbook run - base config
  provisioner "local-exec" {
    command = "ansible-playbook -u ${local.default_image_username} -i ../ansible/inventory --private-key ${path.module}/private_key.pem --vault-password-file ../ansible/.vault_pass ../ansible/${local.ansible_inventory_filename}.yml"
  }

}