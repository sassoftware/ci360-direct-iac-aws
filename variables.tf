# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

## Global
variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with a lowercase letter and contain only alphanumeric characters and hyphens or dashes (-), but cannot start or end with '-'."
  type        = string
  default     = "ci-engage"

  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix))
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter\n * can only contain lowercase letters, numbers, hyphens, or dashes (-), but cannot start or end with '-'."
  }
}

## Provider
variable "location" {
  description = "AWS Region to provision all resources in this script."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Name of Profile in the credentials file."
  type        = string
  default     = ""
}

variable "aws_session_token" {
  description = "Session token for temporary credentials."
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "Static credential key."
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "Static credential secret."
  type        = string
  default     = ""
}

## Public Access
variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources."
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access winclient VM or linserver VM."
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server."
  type        = list(string)
  default     = null
}

## Provider Specific
variable "ssh_public_key" {
  description = "SSH public key used to access VMs."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "tags" {
  description = "Map of common tags to be placed on the resources."
  type        = map(any)
  default     = { project_name = "ci-engage" }
}

# Networking
variable "vpc_id" {
  description = "Pre-exising VPC id. Leave blank to have one created."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Map subnet usage roles to list of existing subnet ids."
  type        = map(list(string))
  default     = {}
  # Example:
  # subnet_ids = {  # only needed if using pre-existing subnets
  #   "public" : ["existing-public-subnet-id1", "existing-public-subnet-id2"],
  #   "private" : ["existing-private-subnet-id1", "existing-private-subnet-id2"],
  #   "database" : ["existing-database-subnet-id1", "existing-database-subnet-id2"] # only when 'create_postgres=true'
  # }
}

variable "vpc_cidr" {
  description = "VPC CIDR - NOTE: Subnets below must fall into this range."
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnets" {
  description = "Subnets to be created and their settings - This variable is ignored when `subnet_ids` is set (AKA bring your own subnets)."
  type        = map(list(string))
  default = {
    "private" : ["192.168.0.0/18", "192.168.64.0/18"],
    "public" : ["192.168.129.0/25", "192.168.129.128/25"],
    "database" : ["192.168.128.0/25", "192.168.128.128/25"]
  }
}

variable "security_group_id" {
  description = "Pre-existing Security Group id. Leave blank to have one created."
  type        = string
  default     = null
}

variable "nat_id" {
  description = "Pre-existing NAT Gateway id."
  type        = string
  default     = null
}

variable "winclient_create" {
  description = "Whether to create the winclient."
  type        = string
  default     = false
}

variable "winclient_vm_ami_id" {
  description = "winclient AMI id."
  type        = string
  default     = "ami-0455ec496e6cbefc4"
}

variable "winclient_vm_admin" {
  description = "OS Admin User for winclient VM."
  type        = string
  default     = "winclientuser"
}

variable "winclient_vm_type" {
  description = "winclient VM type."
  type        = string
  default     = "t2.micro"
}

variable "linserver_vm_ami_id" {
  description = "linserver AMI id."
  type        = string
  default     = "ami-0608d9a790dde7c84"
}

variable "linserver_raid_disk_size" {
  description = "Size in GB for each disk of the RAID0 cluster, when storage_type=standard."
  type        = number
  default     = 128
}

variable "linserver_raid_disk_type" {
  description = "Disk type for the linserver server EBS volumes."
  type        = string
  default     = "gp2"
}

variable "linserver_raid_disk_iops" {
  description = "IOPS for the the linserver server EBS volumes."
  type        = number
  default     = 0
}

variable "linserver_vm_admin" {
  description = "OS Admin User for linserver VM, when storage_type=standard."
  type        = string
  default     = "linserveruser"
}

variable "linserver_vm_type" {
  description = "linserver VM type."
  type        = string
  default     = "t2.micro"
}

variable "os_disk_size" {
  description = "Disk size for default VMs in GB."
  type        = number
  default     = 500
}

variable "os_disk_type" {
  description = "Disk type for default node pool VMs."
  type        = string
  default     = "standard"
}

variable "os_disk_delete_on_termination" {
  description = "Delete Disk on termination."
  type        = bool
  default     = true
}

variable "os_disk_iops" {
  description = "Disk IOPS for default node pool VMs."
  type        = number
  default     = 0
}

## PostgresSQL

# User inputs
variable "postgres_server" {
  description             = "PostgreSQL server"
  type                    = any
  default                 = {
    instance_type           : "db.t3.micro",
    storage_size            : 20,
    storage_encrypted       : false,
    backup_retention_days   : 7,
    multi_az                : false,
    deletion_protection     : false,
    administrator_login     : "pgadmin",
    administrator_password  : "passwordtest",
    db_name                 : "postgres",
    server_version          : "15.3",
    server_port             : "5432",
    ssl_enforcement_enabled : true,
    parameters              : [],
    options                 : []
  }
}

variable "vpc_private_endpoints" { # tflint-ignore: terraform_unused_declarations
  description = "Endpoints needed for private cluster."
  type        = list(string)
  default     = ["ec2", "s3", "logs", "sts"]
}

# variable "enable_ebs_encryption" {
#   description = "Enable encryption on EBS volumes."
#   type        = bool
#   default     = false
# }
