# ---------------------------------------------------------------------------------------------------
# Reference: github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/lxc.md
# ---------------------------------------------------------------------------------------------------

variable "target_node" {
    description = "A string containing the cluster node name"
    type = string
}

variable "ostemplate" {
    description = "The volume identifier that points to the OS template to use"
    type = string
}

variable "hostname" {
    description = "Specifies the host name of the container"
    type = string
}

variable "description" {
    description = "Sets the container description seen in the web interface"
    type = string
    default = "Terraform created LXC container"
}

variable "cores" {
    description = "The number of cores assigned to the container."
    type = number
    default = 2
}
variable "memory" {
    description = "A number containing the amount of RAM to assign to the container (in MB)."
    type = string
    default = "1024"
}

variable "onboot" {
    description = "A boolean that determines if the container will start on boot."
    type = bool
    default = false
}

variable "start" {
    description = "A boolean that determines if the container is started after creation."
    type = bool
    default = false
}

variable "network_name" {
    description = "The name of the network interface as seen from inside the container (e.g. eth0)"
    type = string
    default = "eth0"
}

variable "network_bridge" {
    description = "The bridge to attach the network interface"
    type = string
    default = "vmbr0"
}

variable "network_ip" {
    description = "The IPv4 address of the network interface. The Telmate provider allows other keywords here, but this Terraform module will be opinionated and require a static IPv4 address."
    type = string
    default = "dhcp"
}

variable "ip_address" {
    description = "IP address of the container, for post-provisioning connectivity check"
    type = string
}

variable "network_gw" {
    description = "The IPv4 address belonging to the network interface's default gateway"
    type = string
}

variable "network_firewall" {
    description = "A boolean to enable the firewall on the network interface"
    type = bool
    default = false
}

variable "nameserver" {
    description = "The DNS server IP address used by the container"
    type = string
}

variable "searchdomain" {
    description = "Sets the DNS search domains for the container"
    type = string
}

variable "password" {
    description = "Sets the root password inside the container."
    type = string
    sensitive = true
}

variable "ssh_public_keys" {
    description = "SSH public key that will be added to the container"
    type = string
}

variable "rootfs_storage" {
    description = "A string containing the volume, directory, or device to be mounted into the container (at the path specified by mp). E.g. local-lvm, local-zfs, local etc."
    type = string
}

variable "rootfs_size" {
    description = "Size of the underlying volume. Must end in G, M, or K (e.g. 5G)"
    type = string
}

variable "unprivileged" {
    description = "A boolean that makes the container run as an unprivileged user."
    type = bool
    default = false
}

variable "private_key" {
    description = "Temp SSH private key for provisioning"
    type = string
}

variable "default_image_username" {
    description = "Username baked into template image, used for initial connection for configuration"
    type = string
}