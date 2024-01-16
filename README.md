# FullCloud CI360 Direct Engage IaC

## Overview

This project consists of two parts:
 - Terraform template to set up the AWS infrastructure (VPC, subnets, AMIs, Postgres, etc) 
 - Automation scripts to configure SAS (update hostnames, update licences, configure DirectAgent, other assets)

### Prerequisites

 - bash (on Windows git bash can be used https://git-scm.com/download/win)
 - Install AWS CLI https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
 - Install Terraform https://developer.hashicorp.com/terraform/downloads
 - Make sure that both aws and terraform are accessible from command line
 - AWS user with admin policies
 - Valid SAS license

### Installation

 - Clone this project to a path without spaces
 - Put your SAS license in ./files/custom-data/license.txt

#### Config for terraform
 - Put your config ovverrides in ./terraform.tfvars (Available variables are described in ./variables.tf)

#### Config for SAS
 - Copy ./files/custom-data/config.txt.example to ./files/custom-data/config.txt and set appropriate config variables

### Running

#### To run both infrasturcture and config
 - Put AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in ./files/tools/run_all.sh
 - Run:
```bash
./files/tools/run_all.sh | tee run.log
```

#### To run only config
 - set environment variables
   - LIN_IP # SAS server address
   - PG_ADDRESS # Postgres server address
   - PG_PASS # Postgres password
 - postgres user must be 'pgadmin'
 - Make sure your private ssh key is configured for the SAS server
- Run:
```bash
./files/tools/prepare_ci_content.sh | tee prepare_ci_content.log
```

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

Terraform template based on [viya4-iac-aws](https://github.com/sassoftware/viya4-iac-aws)