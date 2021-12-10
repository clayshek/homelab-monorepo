# This module currently not in use, found a better approach. 

resource "local_file" "netplan" {
  content  = templatefile("${path.module}/99_config.yaml.tpl", { netplan_static_ip_and_mask = var.netplan_static_ip_and_mask, netplan_default_gateway = var.netplan_default_gateway, netplan_dns_server = var.netplan_dns_server, netplan_dns_search_suffix = var.netplan_dns_search_suffix })
  filename = "${path.module}/.temp/${var.netplan_hostname}-99_config.yaml"
}