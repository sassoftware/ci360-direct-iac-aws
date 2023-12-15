# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

data "aws_security_group" "sg" {
  count = var.security_group_id == null ? 0 : 1
  id    = var.security_group_id
}

# Security Groups - https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "sg" {
  count  = var.security_group_id == null ? 1 : 0
  name   = "${var.prefix}-sg"
  vpc_id = module.vpc.vpc_id

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags, { "Name" : "${var.prefix}-sg" })
}

resource "aws_security_group_rule" "vms" {
  type              = "ingress"
  description       = "Allow all from source"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.vm_public_access_cidrs
  security_group_id = local.security_group_id
}

resource "aws_security_group_rule" "all" {
  type              = "ingress"
  description       = "Allow internal security group communication."
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  security_group_id = local.security_group_id
  self              = true
}


resource "aws_security_group_rule" "postgres_internal" {
  type              = "ingress"
  description       = "Allow Postgres within network"
  from_port         = var.postgres_server.server_port
  to_port           = var.postgres_server.server_port
  protocol          = "tcp"
  self              = true
  security_group_id = local.security_group_id
}

resource "aws_security_group_rule" "postgres_external" {
  type              = "ingress"
  description       = "Allow Postgres from source"
  from_port         = var.postgres_server.server_port
  to_port           = var.postgres_server.server_port
  protocol          = "tcp"
  cidr_blocks       = local.postgres_public_access_cidrs
  security_group_id = local.security_group_id
}

