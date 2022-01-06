#-------------------------------------------------------------------------------------------#
# Proxmox Variables 
# Reference: https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md
#-------------------------------------------------------------------------------------------#

variable "proxmox_api_url" {
    description = "This is the target Proxmox API endpoint"
    type = string
    default = "https://192.168.2.31:8006/api2/json"
}
variable "proxmox_api_user" {
    description = "This is the Proxmox API user. Use root@pam or custom. Will need PVEDatastoreUser, PVEVMAdmin, PVETemplateUser permissions"
    type = string
    sensitive = true
    default = "packer-api@pve"
}
variable "proxmox_api_pass" {
    description = "API user password. Required, sensitive, or use environment variable TF_VAR_proxmox_api_pass"
    sensitive = true
}
variable "proxmox_ignore_tls" {
    description = "Disable TLS verification while connecting"
    type = string
    default = "true"
}
variable "proxmox_rpi_api_url" {
    description = "This is the target Proxmox API endpoint"
    type = string
    default = "https://192.168.2.25:8006/api2/json"
}
variable "proxmox_rpi_api_user" {
    description = "This is the Proxmox API user. Use root@pam or custom. Will need PVEDatastoreUser, PVEVMAdmin, PVETemplateUser permissions"
    type = string
    sensitive = true
    default = "terraform-prov@pve"
}
variable "proxmox_rpi_api_pass" {
    description = "API user password. Required, sensitive, or use environment variable TF_VAR_proxmox_api_pass"
    sensitive = true
}