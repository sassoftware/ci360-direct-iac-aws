#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

# export AWS_ACCESS_KEY_ID=
# export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_PROFILE=sandbox-617292774228
export AWS_DEFAULT_REGION=us-east-1

${BASH_SOURCE%/*}/prepare_aws_env.sh

export LIN_IP="$(terraform output -raw linserver_public_ip)"
export PG_ADDRESS="$(terraform output -raw postgres_server_fqdn)"
export PG_PASS="$(terraform output -raw postgres_server_password)"

${BASH_SOURCE%/*}/prepare_ci_content.sh