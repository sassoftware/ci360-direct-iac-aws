# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

output "winclient_private_dns" {
  value = var.winclient_create ? module.winclient[0].private_dns : null
}

output "winclient_public_dns" {
  value = var.winclient_create ? module.winclient[0].public_dns : null
}

output "winclient_public_ip" {
  value = var.winclient_create ? module.winclient[0].public_ip_address : null
}

output "linserver_instance_id" {
  value = module.linserver.id
}

output "linserver_public_ip" {
  value = module.linserver.public_ip_address
}

output "linserver_private_dns" {
  value = module.linserver.private_dns
}

output "linserver_public_dns" {
  value = module.linserver.public_dns
}

output "postgres_server_fqdn" {
  value  = module.postgresql.db_instance_address
}

output "postgres_server_user" {
  value  = var.postgres_server.administrator_login
}

output "postgres_server_password" {
  value  = var.postgres_server.administrator_password
  sensitive = true
}

output "location" {
  value = var.location
}
