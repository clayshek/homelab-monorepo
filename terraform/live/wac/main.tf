// "Live" Terraform infra config for provisioning a Windows Admin Center VM, 
// running on Proxmox. Post-provisioning config handed off to Ansible.

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
  desc = "Windows Admin Center VM, created with Terraform on ${timestamp()}"
  full_clone = true
  default_image_username = "administrator"
  default_image_password = "packer"
  clone_wait = 5
  onboot = true
  nameserver = "192.168.2.41"
  searchdomain = "ad.layer8sys.com"
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
  target_node = "pve2"
  clone = "template-win-2019-DC-pve2" 
  vm_name = "wac01"
  vm_sockets = 2
  vm_cores = 2
  vm_memory = "6144"
  vm_ip_address = "192.168.2.56"
  vm_ip_cidr = "/24"
  vm_ip_gw = "192.168.2.1"
  ansible_inventory_group = "wac"
}

// Create WAC VM 
module "wac_vm" {
  source = "../../modules/pve-vm"

  target_node = local.target_node
  clone = local.clone
  vm_name = local.vm_name
  desc = local.desc
  sockets = local.vm_sockets
  cores = local.vm_cores
  memory = local.vm_memory
  onboot = local.onboot
  full_clone = local.full_clone
  clone_wait = local.clone_wait
  vm_network = local.vm_network
  vm_disk = local.vm_disk   
  nameserver = local.nameserver
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${local.vm_ip_address}${local.vm_ip_cidr},gw=${local.vm_ip_gw}"
  ip_address = local.vm_ip_address
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
    (local.ansible_inventory_group) = [local.vm_ip_address]
  }
  ansible_inventory_filename = local.ansible_inventory_group
}

// Ansible post-provisioning configuration
resource "null_resource" "configuration" {
  depends_on = [
    module.wac_vm,
    module.ansible_inventory
  ]

  // Clear existing records (if exists) from known_hosts to prevent possible ssh connection issues
  provisioner "local-exec" {
    command = "ssh-keygen -f ~/.ssh/known_hosts -R ${local.vm_ip_address}"
  }

  // Ansible playbook run
  provisioner "local-exec" {
    command = "ansible-playbook -i ../ansible/inventory --vault-password-file ../ansible/.vault_pass ../ansible/${local.ansible_inventory_group}.yml"
  }
}