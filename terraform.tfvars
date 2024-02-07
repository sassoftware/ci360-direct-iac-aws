# !NOTE! - These are only a subset of the variables in CONFIG-VARS.md provided
# as examples. Customize this file to add any variables from CONFIG-VARS.md whose
# default values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User

# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
prefix   = "ci360-direct-fullcloud"
# location = "<aws-location-value>" # e.g., "us-east-1"
default_public_access_cidrs = ["149.173.0.0/16","192.31.0.0/16"] # e.g., ["123.45.6.89/32"]
# ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

winclient_create = true
winclient_vm_ami_id = "ami-0424f07a6e09392a3"
linserver_vm_ami_id = "ami-0fb571dc3ba314efd"
linserver_vm_type = "m5n.xlarge"
winclient_vm_type = "m5n.xlarge"