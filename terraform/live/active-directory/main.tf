// "Live" Terraform infra config for provisioning Active Directory Domain
// Controllers, running on Proxmox VMs. Post-provisioning config handed off to Ansible.

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
  desc = "AD Domain Controller VM, created with Terraform on ${timestamp()}"
  full_clone = true
  default_image_username = "administrator"
  default_image_password = "packer"
  clone_wait = 5
  vm_sockets = 2
  vm_cores = 2  
  onboot = true
  nameserver = "192.168.2.1"
  searchdomain = "int.layer8sys.com"
  // Dynamic block for network adapters to add to VM
  vm_network = [
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
  ]

  // Dynamic block for disk devices to add to VM. 1st is OS, size should match or exceed template.
  vm_disk = [
    {
      type = "scsi"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 0
    },         
  ]  
  boot = "order=scsi0;ide2;net0"
  agent = 1
  ssh_public_keys = tls_private_key.bootstrap_private_key.public_key_openssh
  terraform_provisioner_type = "winrm"
  provisioner_target_platform = "windows"
  ansible_inventory_filename = "active_directory"

  # -- Primary Domain Controller Variables -- #
  pdc_target_node = "pve1"
  pdc_clone = "template-win-2019-DC-pve1" 
  pdc_vm_name = "dc01"
  pdc_vm_memory = "2048"
  pdc_ip_address = "192.168.2.41"
  pdc_ip_cidr = "/24"
  pdc_gw = "192.168.2.1"
  pdc_ansible_inventory_group = "primary_dc"
  
  # -- Secondary Domain Controller Variables -- #
  sdc_target_node = "pve2"
  sdc_clone = "template-win-2019-DC-pve2" 
  sdc_vm_name_prefix = "dc"
  sdc_vm_memory = "2048"
  // IP assignment count in this block will control count of secondary DC VMs provisioned
  sdc_ip_addresses = {
      "1" = "192.168.2.42"
  }
  sdc_ip_cidr = "/24"
  sdc_gw = "192.168.2.1"
  sdc_ansible_inventory_group = "secondary_dc"
}

// Create Primary Domain Controller VM 
module "pdc_vm" {
  source = "../../modules/pve-vm" 

  target_node = local.pdc_target_node
  clone = local.pdc_clone
  vm_name = local.pdc_vm_name
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores   
  memory = local.pdc_vm_memory
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  vm_network = local.vm_network
  vm_disk = local.vm_disk  
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${local.pdc_ip_address}${local.pdc_ip_cidr},gw=${local.pdc_gw}"
  ip_address = local.pdc_ip_address
  ssh_public_keys = local.ssh_public_keys
  default_image_username = local.default_image_username
  default_image_password = local.default_image_password
  provisioner_type = local.terraform_provisioner_type
  target_platform = local.provisioner_target_platform
  private_key = tls_private_key.bootstrap_private_key.private_key_pem
}

// Create Secondary Domain Controller VMs
module "sdc_vms" {
  source = "../../modules/pve-vm"
    
  count = length(local.sdc_ip_addresses)

  target_node = local.sdc_target_node
  clone = local.sdc_clone
  vm_name = "${local.sdc_vm_name_prefix}${format("%02d", count.index+2)}"
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores   
  memory = local.sdc_vm_memory
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  vm_network = local.vm_network
  vm_disk = local.vm_disk  
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${lookup(local.sdc_ip_addresses, count.index+1)}${local.sdc_ip_cidr},gw=${local.sdc_gw}"
  ip_address = lookup(local.sdc_ip_addresses, count.index+1)
  ssh_public_keys = local.ssh_public_keys
  default_image_username = local.default_image_username
  default_image_password = local.default_image_password
  provisioner_type = local.terraform_provisioner_type
  target_platform = local.provisioner_target_platform  
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
    (local.pdc_ansible_inventory_group) = [local.pdc_ip_address]
    (local.sdc_ansible_inventory_group) = [
      for k,v in local.sdc_ip_addresses: v
      ]
  }
  ansible_inventory_filename = local.ansible_inventory_filename
}

// Ansible post-provisioning configuration
resource "null_resource" "configuration" {
  depends_on = [
    module.pdc_vm,
    module.sdc_vms,
    module.ansible_inventory
  ]

  // Ansible playbook run
  provisioner "local-exec" {
    command = "ansible-playbook -i ../ansible/inventory --vault-password-file ../ansible/.vault_pass ../ansible/${local.ansible_inventory_filename}.yml"
  }
}