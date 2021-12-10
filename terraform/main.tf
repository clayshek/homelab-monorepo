# -------------------------------------------------------------------------------------------
# Master Terraform module for provisioning listed child module infrastructure components.
# While possible to provision all at once, strongly suggest targeting specific modules
# individually, and just using this module to allow for a single 'terraform init' run. 
# Add -compact-warnings parameter to minimize output warnings related to resource targeting.
#
# terraform [plan|apply|destroy] -target=module.hashi-vault 
# terraform [plan|apply|destroy] -target=module.github-runner 
# terraform [plan|apply|destroy] -target=module.active-directory
# terraform [plan|apply|destroy] -target=module.cloudstack
# terraform [plan|apply|destroy] -target=module.wac
# terraform [plan|apply|destroy] -target=module.hyperv
# terraform [plan|apply|destroy] -target=module.awx
# terraform [plan|apply|destroy] -target=module.k3s
# terraform [plan|apply|destroy] -target=module.rancher
# -------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "~> 2.6.7"
    }
  }
}

provider "proxmox" {
    pm_api_url = var.proxmox_api_url
    pm_user = var.proxmox_api_user
    pm_password = var.proxmox_api_pass
    pm_tls_insecure = var.proxmox_ignore_tls
    pm_parallel = 2
    // pm_parallel hardcoded to 2 as workaround to "transport is closing" issue
    // Ref: github.com/Telmate/terraform-provider-proxmox/issues/257
}

#------------------------------------------#
# --------- Hashicorp Vault --------------- #
#------------------------------------------#
module "hashi-vault" {
  source = "./live/hashi-vault"
}

#------------------------------------------#
# ------- GitHub Actions Runner ---------- #
#------------------------------------------#
module "github-runner" {
  source = "./live/github-runner"
}

#------------------------------------------#
# --------- Active Directory ------------- #
#------------------------------------------#
module "active-directory" {
  source = "./live/active-directory"
}

#------------------------------------------#
# -------- Windows Admin Center ---------- #
#------------------------------------------#
module "wac" {
  source = "./live/wac"
}

#------------------------------------------#
# --------------- Hyper-V ---------------- #
#------------------------------------------#
module "hyperv" {
  source = "./live/hyperv"
}

#------------------------------------------#
# CloudStack Management Server & KVM Hosts #
#------------------------------------------#
module "cloudstack" {
  source = "./live/cloudstack"
}

#------------------------------------------#
# ------------ Ansible AWX --------------- #
#------------------------------------------#
module "awx" {
  source = "./live/awx"
}

#------------------------------------------#
# -------------- Rancher ----------------- #
#------------------------------------------#
module "rancher" {
  source = "./live/rancher"
}

#------------------------------------------#
# ---------------- k3s ------------------- #
#------------------------------------------#
module "k3s" {
  source = "./live/k3s"
}

#------------------------------------------#
# -------------- DevBox ------------------ #
#------------------------------------------#
module "devbox" {
  source = "./live/devbox"
}