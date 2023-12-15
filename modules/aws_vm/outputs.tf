# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

output "private_ip_address" {
  value = aws_instance.vm.private_ip
}

output "public_ip_address" {
  value = var.create_public_ip ? coalesce(aws_eip.eip[0].public_ip, aws_instance.vm.public_ip) : null
}

output "private_dns" {
  value = aws_instance.vm.private_dns
}

output "public_dns" {
  value = var.create_public_ip ? coalesce(aws_eip.eip[0].public_dns, aws_instance.vm.public_dns) : null
}

output "id" {
  value = aws_instance.vm.id
}
