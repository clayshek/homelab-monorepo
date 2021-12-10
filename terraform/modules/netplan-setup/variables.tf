variable "netplan_static_ip_and_mask" {
    description = "IP address and CIDR mask of the VM"
    type = string
}

variable "netplan_default_gateway" {
    description = "IP address and CIDR mask of the VM"
    type = string
}

variable "netplan_dns_server" {
    description = "The DNS server IP address used by the container"
    type = string
    default = "8.8.8.8"
}

variable "netplan_dns_search_suffix" {
    description = "Sets the DNS search domains for the container"
    type = string
    default = ".local"
}

variable "netplan_hostname" {
    description = "VM hostname, used for part of netplan filename"
    type = string
}