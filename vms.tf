# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

# winclient BOX
module "winclient" {
  count              = var.winclient_create ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-winclient"
  tags               = local.tags
  subnet_id          = local.winclient_vm_subnet
  security_group_ids = [local.security_group_id]
  create_public_ip   = true

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  vm_type               = var.winclient_vm_type
  vm_ami_id             = var.winclient_vm_ami_id
  # vm_admin              = var.winclient_vm_admin
  ssh_public_key        = local.ssh_public_key
  # enable_ebs_encryption = var.enable_ebs_encryption

  # depends_on = [module.linserver]

}

# Defining the cloud-config to use
data "cloudinit_config" "linserver" {

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "packages: ['postgresql','git','python3-pip','libcurl-devel','python3-devel','java-17-openjdk','unzip']"
  }
}

# linserver Server VM
module "linserver" {
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-linserver"
  tags               = local.tags
  subnet_id          = local.linserver_vm_subnet
  security_group_ids = [local.security_group_id]
  create_public_ip   = true

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  # data_disk_count             = 4
  data_disk_type              = var.linserver_raid_disk_type
  data_disk_size              = var.linserver_raid_disk_size
  data_disk_iops              = var.linserver_raid_disk_iops
  data_disk_availability_zone = local.linserver_vm_subnet_az

  vm_type               = var.linserver_vm_type
  vm_ami_id             = var.linserver_vm_ami_id
  # vm_admin              = var.linserver_vm_admin
  ssh_public_key        = local.ssh_public_key
  # enable_ebs_encryption = var.enable_ebs_encryption

  cloud_init = data.cloudinit_config.linserver.rendered
}
