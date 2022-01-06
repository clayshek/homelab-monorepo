// "Live" Terraform infra config for a Cloudstack / KVM environment 
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
  desc = "CloudStack VM, created with Terraform on ${timestamp()}"
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
  ansible_inventory_filename = "cloudstack"

  # -- Management VM Variables -- #
  mgmt_target_node = "pve1"
  mgmt_clone = "tpl-ubuntu-20-04-3-pve1" 
  mgmt_vm_memory = "4096"
  mgmt_ip_address = "192.168.2.70"
  mgmt_ip_cidr = "/24"
  mgmt_gw = "192.168.2.1"
  mgmt_ansible_inventory_group = "cloudstack_manager"
  // Dynamic block for network adapters to add to VM
  mgmt_vm_network = [
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
  ]

  // Dynamic block for disk devices to add to VM. 1st is OS, size should match or exceed template.
  mgmt_vm_disk = [
    {
      type = "scsi"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 0
    },         
  ]    
  
  # -- Hypervisor VMs Variables -- #
  hypervisor_target_node = "pve2"
  hypervisor_clone = "tpl-ubuntu-20-04-3-pve2" 
  hypervisor_vm_name_prefix = "kvm"
  hypervisor_vm_memory = "2048"
  // IP assignment count in this block will control count of hypervisor VMs provisioned
  hypervisor_ip_addresses = {
      "1" = "192.168.2.71"
      "2" = "192.168.2.72"
      "3" = "192.168.2.73"
  }
  hypervisor_ip_cidr = "/24"
  hypervisor_gw = "192.168.2.1"
  hypervisor_ansible_inventory_group = "cloudstack_kvm_hypervisor"
  // Dynamic block for network adapters to add to VM
  hypervisor_vm_network = [
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
  ]

  // Dynamic block for disk devices to add to VM. 1st is OS, size should match or exceed template.
  hypervisor_vm_disk = [
    {
      type = "scsi"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 0
    },         
  ]    
}

// Create CloudStack Management VM 
module "mgmt_vm" {
  source = "../../modules/pve-vm"

  target_node = local.mgmt_target_node
  clone = local.mgmt_clone
  vm_name = "csmgmt"
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores    
  memory = local.mgmt_vm_memory
  vm_network = local.mgmt_vm_network
  vm_disk = local.mgmt_vm_disk    
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${local.mgmt_ip_address}${local.mgmt_ip_cidr},gw=${local.mgmt_gw}"
  ip_address = local.mgmt_ip_address
  ssh_public_keys = local.ssh_public_keys
  default_image_username = local.default_image_username
  default_image_password = local.default_image_password
  private_key = tls_private_key.bootstrap_private_key.private_key_pem
}

// Create Hypervisor VMs
module "hypervisor_nodes" {
  source = "../../modules/pve-vm"

  count = length(local.hypervisor_ip_addresses)

  target_node = local.hypervisor_target_node
  clone = local.hypervisor_clone
  vm_name = "${local.hypervisor_vm_name_prefix}${format("%02d", count.index+1)}"
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores    
  memory = local.hypervisor_vm_memory
  vm_network = local.hypervisor_vm_network
  vm_disk = local.hypervisor_vm_disk    
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${lookup(local.hypervisor_ip_addresses, count.index+1)}${local.hypervisor_ip_cidr},gw=${local.hypervisor_gw}"
  ip_address = lookup(local.hypervisor_ip_addresses, count.index+1)
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
    (local.mgmt_ansible_inventory_group) = [local.mgmt_ip_address]
    (local.hypervisor_ansible_inventory_group) = [
      for k,v in local.hypervisor_ip_addresses: v
      ]
  }
  ansible_inventory_filename = local.ansible_inventory_filename
}

/*

*/

// Ansible post-provisioning configuration
resource "null_resource" "configuration" {
  depends_on = [
    module.mgmt_vm,
    module.hypervisor_nodes
  ]

  // Clear existing records (if exists) from known_hosts to prevent possible ssh connection issues
  provisioner "local-exec" {
    command = <<-EOT
      if test -f "~/.ssh/known_hosts"; then
        ssh-keygen -f ~/.ssh/known_hosts -R ${local.mgmt_ip_address}
      fi
      EOT
  }

  // Ansible playbook run
  provisioner "local-exec" {
    command = "ansible-playbook -u ${local.default_image_username} -i ../ansible/inventory --private-key ${path.module}/private_key.pem --vault-password-file ../ansible/.vault_pass ../ansible/${local.ansible_inventory_filename}.yml"
  }
}