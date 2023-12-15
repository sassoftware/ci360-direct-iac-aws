#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

echo $(date '+%Y-%m-%d %H:%M:%S')

${BASH_SOURCE%/*}/copy_ami.sh
echo $(date '+%Y-%m-%d %H:%M:%S')

export TF_VAR_winclient_vm_ami_id="$(aws ec2 describe-images --filters 'Name=name,Values=sas-ci360-ed-windows-v1.0' --output text --query 'Images[0].ImageId')"

terraform init
terraform plan -out ci-engage.plan
echo $(date '+%Y-%m-%d %H:%M:%S')

terraform apply ci-engage.plan
echo $(date '+%Y-%m-%d %H:%M:%S')

LIN_SERVER_ID="$(terraform output -raw linserver_instance_id)"
REGION="$(terraform output -raw location)"
LIN_IP="$(terraform output -raw linserver_public_ip)"

echo "Waiting for instance $LIN_SERVER_ID ..."
aws ec2 wait instance-status-ok \
    --region $REGION \
    --instance-ids $LIN_SERVER_ID
echo "Instance $LIN_SERVER_ID ready"

ssh-keyscan -H ${LIN_IP} >> ~/.ssh/known_hosts
echo "Turn off selinux ..."
ssh ec2-user@${LIN_IP} 'sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config'
ssh ec2-user@${LIN_IP} 'sudo setenforce 0 && sestatus'

echo "Reboot vm ..."
aws ec2 reboot-instances --instance-ids $LIN_SERVER_ID 

sleep 300

echo "Waiting for instance $LIN_SERVER_ID ..."
aws ec2 wait instance-status-ok \
    --region $REGION \
    --instance-ids $LIN_SERVER_ID
echo "Instance $LIN_SERVER_ID ready"