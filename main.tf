# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

## AWS-EKS
#
# Terraform Registry : https://registry.terraform.io/namespaces/terraform-aws-modules
# GitHub Repository  : https://github.com/terraform-aws-modules
#

provider "aws" {
  region                  = var.location
  profile                 = var.aws_profile
  access_key              = var.aws_access_key_id
  secret_key              = var.aws_secret_access_key
  token                   = var.aws_session_token
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "terraform" {}

module "vpc" {
  source = "./modules/aws_vpc"

  name                = var.prefix
  vpc_id              = var.vpc_id
  region              = var.location
  security_group_id   = local.security_group_id
  cidr                = var.vpc_cidr
  azs                 = data.aws_availability_zones.available.names
  existing_subnet_ids = var.subnet_ids
  subnets             = var.subnets
  existing_nat_id     = var.nat_id

  tags                = local.tags
  public_subnet_tags  = merge(local.tags)
  private_subnet_tags = merge(local.tags)
}


# Database Setup - https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/3.3.0
module "postgresql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.2.0"

  identifier = lower("${var.prefix}-pgsql")

  engine            = "postgres"
  engine_version    = var.postgres_server.server_version
  instance_class    = var.postgres_server.instance_type
  allocated_storage = var.postgres_server.storage_size
  storage_encrypted = var.postgres_server.storage_encrypted

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  manage_master_user_password = false
  username                    = var.postgres_server.administrator_login
  password                    = var.postgres_server.administrator_password
  db_name                     = var.postgres_server.db_name
  port                        = var.postgres_server.server_port

  vpc_security_group_ids = [local.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = var.postgres_server.backup_retention_days

  tags = local.tags

  # DB subnet group - use public subnet if public access is requested
  # publicly_accessible = length(local.postgres_public_access_cidrs) > 0 ? true : false
  subnet_ids          = length(local.postgres_public_access_cidrs) > 0 ? module.vpc.public_subnets : module.vpc.database_subnets

  # DB parameter group
  family = "postgres${replace(var.postgres_server.server_version, "/\\.\\d+/", "")}"

  # DB option group
  major_engine_version = var.postgres_server.server_version

  # Database Deletion Protection
  deletion_protection = var.postgres_server.deletion_protection

  multi_az = var.postgres_server.multi_az

  parameters = var.postgres_server.ssl_enforcement_enabled ? concat(var.postgres_server.parameters, [{ "apply_method" : "immediate", "name" : "rds.force_ssl", "value" : "1" }]) : concat(var.postgres_server.parameters, [{ "apply_method" : "immediate", "name" : "rds.force_ssl", "value" : "0" }])
  options    = var.postgres_server.options

  # Flags for module to flag if postgres should be created or not.
  create_db_instance        = true
  create_db_subnet_group    = true
  create_db_parameter_group = true
  create_db_option_group    = true

}
# Resource Groups - https://www.terraform.io/docs/providers/aws/r/resourcegroups_group.html
resource "aws_resourcegroups_group" "aws_rg" {
  name = "${var.prefix}-rg"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": ${jsonencode([
    for key, values in local.tags : {
      "Key" : key,
      "Values" : [values]
    }
])}
}
JSON
}
}
