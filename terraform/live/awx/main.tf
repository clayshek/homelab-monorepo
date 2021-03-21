// "Live" Terraform infra config for an AWS instance running on
// a Proxmox VM. Post-provisioning config handed off to Ansible.

// Set local variables for provisioning 
locals {
  # -- Common Variables -- #
  desc = "AWX VM, created with Terraform on ${timestamp()}"
  full_clone = true
  default_image_username = "ubuntu"
  default_image_password = "ubuntu"
  clone_wait = 5
  onboot = true
  nameserver = "192.168.2.1"
  searchdomain = "int.layer8sys.com"
  boot = "order=scsi0;ide2;net0"
  agent = 1
  ssh_public_keys = tls_private_key.bootstrap_private_key.public_key_openssh
  terraform_provisioner_type = "ssh"
  target_node = "pve1"
  clone = "template-ubuntu-18-04-5-pve1" 
  vm_name = "awx"
  vm_sockets = 2
  vm_cores = 2
  vm_memory = "4096"
  vm_ip_address = "192.168.2.7"
  vm_ip_cidr = "/24"
  vm_ip_gw = "192.168.2.1"
  ansible_inventory_group = "awx"
  
}

// Create AWX VM 
module "awx_vm" {
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
  nameserver = local.nameserver
  searchdomain = local.searchdomain
  boot = local.boot
  agent = local.agent
  ipconfig0 = "ip=${local.vm_ip_address}${local.vm_ip_cidr},gw=${local.vm_ip_gw}"
  ip_address = local.vm_ip_address
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
    (local.ansible_inventory_group) = [local.vm_ip_address]
  }
  ansible_inventory_filename = local.ansible_inventory_group
}

// Ansible post-provisioning configuration
resource "null_resource" "configuration" {
  depends_on = [
    module.awx_vm,
  ]

  // Clear existing records (if exists) from known_hosts to prevent possible ssh connection issues
  provisioner "local-exec" {
    command = "ssh-keygen -f ~/.ssh/known_hosts -R ${local.vm_ip_address}"
  }

  // Ansible playbook run
  provisioner "local-exec" {
    command = "ansible-playbook -u ${local.default_image_username} -i ../ansible/inventory --private-key ${path.module}/private_key.pem ../ansible/${local.ansible_inventory_group}.yml"
  }
}