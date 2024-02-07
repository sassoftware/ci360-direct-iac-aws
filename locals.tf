# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

locals {

  # General
  security_group_id         = var.security_group_id == null ? aws_security_group.sg[0].id : data.aws_security_group.sg[0].id
  default_tags              = { project_name = "ci360-direct-fullcloud" }
  tags                      = var.tags == null ? local.default_tags : length(var.tags) == 0 ? local.default_tags : var.tags

  # CIDRs
  default_public_access_cidrs           = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs                = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  postgres_public_access_cidrs          = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

  # Subnets
  winclient_vm_subnet    = module.vpc.public_subnets[0]
  linserver_vm_subnet    = module.vpc.public_subnets[0]
  linserver_vm_subnet_az = module.vpc.public_subnet_azs[0]

  ssh_public_key = file(var.ssh_public_key)

}
