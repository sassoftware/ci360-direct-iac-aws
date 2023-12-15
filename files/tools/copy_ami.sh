#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

echo "Creating instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --region us-east-2 \
    --image-id ami-037a6d121ef9c1618 \
    --instance-type t2.micro \
    --output text \
    --query 'Instances[0].{InstanceId:InstanceId}')
echo "Instance $INSTANCE_ID created"
    
aws ec2 create-tags \
    --region us-east-2 \
    --resources $INSTANCE_ID \
    --tags "Key=Name,Value=Temporary for copying CI 360 AMI" 

echo "Waiting for instance $INSTANCE_ID ..."
aws ec2 wait instance-status-ok \
    --region us-east-2 \
    --instance-ids $INSTANCE_ID
echo "Instance $INSTANCE_ID ready"
    
echo "Creating image..."
AMI_ID=$(aws ec2 create-image \
    --region us-east-2 \
    --instance-id $INSTANCE_ID \
    --name "sas-ci360-ed-windows-v1.0" \
    --description "SAS Customer Intelligence 360 - Engage Direct - On-prem - Windows" \
    --output text \
    --query 'ImageId')
echo "Image $AMI_ID created"
    
aws ec2 create-tags \
    --region us-east-2 \
    --resources $AMI_ID \
    --tags "Key=Name,Value=Temporary for copying CI 360 AMI" 
  
echo "Waiting for image $AMI_ID ..."  
aws ec2 wait image-available \
    --region us-east-2 \
    --image-ids $AMI_ID
echo "Image $AMI_ID ready"
    
echo "Terminating instance $INSTANCE_ID"
aws ec2 terminate-instances \
    --region us-east-2 \
    --instance-ids $INSTANCE_ID

echo "Copying image $AMI_ID ..."
export NEW_AMI_ID=$(aws ec2 copy-image \
    --region us-east-1 \
    --source-image-id $AMI_ID \
    --source-region us-east-2 \
    --description "SAS Customer Intelligence 360 - Engage Direct - On-prem - Windows" \
    --name "sas-ci360-ed-windows-v1.0" \
    --output text \
    --query 'ImageId')
echo "Image $NEW_AMI_ID created"

aws ec2 create-tags \
    --region us-east-1 \
    --resources $NEW_AMI_ID \
    --tags "Key=Name,Value=SAS Customer Intelligence 360 - Engage Direct - On-prem - Windows"

echo "Waiting for image $NEW_AMI_ID ..."    
aws ec2 wait image-available \
    --region us-east-1 \
    --image-ids $NEW_AMI_ID
echo "Image $NEW_AMI_ID ready"

echo "Deregistering image $AMI_ID"
aws ec2 deregister-image \
    --region us-east-2 \
    --image-id $AMI_ID