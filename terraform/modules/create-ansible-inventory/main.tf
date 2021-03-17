resource "local_file" "inventory" {
  content  = templatefile("${path.module}/inventory.tpl", { servers = var.servers })
  filename = "${path.module}/../../../ansible/inventory/${var.ansible_inventory_filename}.yml"
}