// "Live" Terraform infra config for provisioning Windows Hyper-V Hypervisors,
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
  desc = "Hyper-V VM, created with Terraform on ${timestamp()}"
  full_clone = true
  default_image_username = "administrator"
  default_image_password = "packer"
  clone_wait = 5
  onboot = false
  vm_sockets = 2
  vm_cores = 4
  nameserver = "192.168.2.41"
  searchdomain = "int.layer8sys.com"
  // Dynamic block for network adapters to add to VM
  vm_network = [
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
    {
      model = "virtio"
      bridge = "vmbr0"
      tag = null
    },
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
    {
      type = "sata"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 1
    },    
    {
      type = "sata"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 1
    },  
    {
      type = "sata"
      storage = "vm-store"
      size = "50G"
      format = "qcow2"
      ssd = 1
    },          
  ]
  
  boot = "order=scsi0;ide2;net0"
  agent = 1
  ssh_public_keys = tls_private_key.bootstrap_private_key.public_key_openssh
  terraform_provisioner_type = "winrm"
  provisioner_target_platform = "windows"
  ansible_inventory_filename = "hyperv"


  # -- First Hyper-V Node Variables -- #
  hvh1_target_node = "pve1"
  hvh1_clone = "template-win-2019-DC-pve1" 
  hvh1_vm_name = "hvh01"
  hvh1_vm_memory = "4096"
  hvh1_ip_address = "192.168.2.51"
  hvh1_ip_cidr = "/24"
  hvh1_gw = "192.168.2.1"
  hvh1_ansible_inventory_group = "hyperv_first_node"
  
  # -- Subsequent Hyper-V Node Variables -- #
  hvhn_target_node = "pve2"
  hvhn_clone = "template-win-2019-DC-pve2" 
  hvhn_vm_name_prefix = "hvh"
  hvhn_vm_memory = "4096"
  // IP assignment count in this block will control count of secondary DC VMs provisioned
  hvhn_ip_addresses = {
      "1" = "192.168.2.52"
      "2" = "192.168.2.53"
      "3" = "192.168.2.54"
  }
  hvhn_ip_cidr = "/24"
  hvhn_gw = "192.168.2.1"
  hvhn_ansible_inventory_group = "hyperv_additional_nodes"
}

// Create First Hypervisor VM 
module "hvh1_vm" {
  source = "../../modules/pve-vm"

  target_node = local.hvh1_target_node
  clone = local.hvh1_clone
  vm_name = local.hvh1_vm_name
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores  
  memory = local.hvh1_vm_memory
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  vm_network = local.vm_network
  vm_disk = local.vm_disk
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${local.hvh1_ip_address}${local.hvh1_ip_cidr},gw=${local.hvh1_gw}"
  ip_address = local.hvh1_ip_address
  ssh_public_keys = local.ssh_public_keys
  default_image_username = local.default_image_username
  default_image_password = local.default_image_password
  provisioner_type = local.terraform_provisioner_type
  target_platform = local.provisioner_target_platform
  private_key = tls_private_key.bootstrap_private_key.private_key_pem
}

// Create Additional Hypervisor VMs
module "hvhn_vms" {
  source = "../../modules/pve-vm"

  count = length(local.hvhn_ip_addresses)

  target_node = local.hvhn_target_node
  clone = local.hvhn_clone
  vm_name = "${local.hvhn_vm_name_prefix}${format("%02d", count.index+2)}"
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores  
  memory = local.hvhn_vm_memory
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  nameserver = local.nameserver
  vm_network = local.vm_network
  vm_disk = local.vm_disk
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${lookup(local.hvhn_ip_addresses, count.index+1)}${local.hvhn_ip_cidr},gw=${local.hvhn_gw}"
  ip_address = lookup(local.hvhn_ip_addresses, count.index+1)
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
    (local.hvh1_ansible_inventory_group) = [local.hvh1_ip_address]
    (local.hvhn_ansible_inventory_group) = [
      for k,v in local.hvhn_ip_addresses: v
      ]
  }
  ansible_inventory_filename = local.ansible_inventory_filename
}

// Ansible post-provisioning configuration
resource "null_resource" "configuration" {
  depends_on = [
    module.hvh1_vm,
    module.hvhn_vms,
    module.ansible_inventory
  ]

  // Ansible playbook run
  provisioner "local-exec" {
    command = "ansible-playbook -i ../ansible/inventory --vault-password-file ../ansible/.vault_pass ../ansible/${local.ansible_inventory_filename}.yml"
  }
}