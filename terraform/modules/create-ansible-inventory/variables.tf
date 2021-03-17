variable "servers" {
  type = map
  default = {}
  description = "A map of inventory group names to IP addresses."
}

//variable "ansible_inventory_group" {
    //type = string
    //description = "Ansible group name for inventory file."
//}

variable "ansible_inventory_filename" {
    type = string
    description = "Filename for Ansible inventory file."
}