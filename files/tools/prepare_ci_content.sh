#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

echo $(date '+%Y-%m-%d %H:%M:%S')

ssh-keyscan -H ${LIN_IP} >> ~/.ssh/known_hosts
ssh ec2-user@${LIN_IP} 'sudo chmod -R 777 /sas/amiautomation'
ssh ec2-user@${LIN_IP} 'sudo chmod -R 777 /sas/software'
scp ${BASH_SOURCE%/*}/* ec2-user@${LIN_IP}:/sas/amiautomation
scp -r ${BASH_SOURCE%/*}/../custom-data/* ec2-user@${LIN_IP}:/sas/amiautomation
ssh ec2-user@${LIN_IP} "cd /sas/amiautomation && sudo ./setinitialpass.sh"
ssh ec2-user@${LIN_IP} 'sudo chmod -R 777 /sas/amiautomation'
ssh ec2-user@${LIN_IP} bash -s << EOF
    sudo -u sas bash -c 'cd /sas/amiautomation && ./amiautomation_full.sh | tee -a /sas/amiautomation/logs/amiautomation.log'
EOF

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Download repos from gitlab..."
TMPDIR=$(mktemp -d)
cd $TMPDIR
git clone https://gitlab.sas.com/retail-incubation/ci-assets-refactoring/chagentstream-queues.git
git clone https://gitlab.sas.com/retail-incubation/ci-assets-refactoring/ci360-new-identities-uploader.git
git clone https://gitlab.sas.com/retail-incubation/ci-assets-refactoring/uploading-customer-data-to-cloud-datahub.git
git clone https://gitlab.sas.com/retail-incubation/ci-assets-refactoring/ci360-gdpr-delete.git
scp -r $TMPDIR/* ec2-user@${LIN_IP}:/sas/software
cd -
rm -rf $TMPDIR
ssh ec2-user@${LIN_IP} 'sudo chmod -R 777 /sas/software'
echo $(date '+%Y-%m-%d %H:%M:%S')

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Install python modules..."
ssh ec2-user@${LIN_IP} bash -s << EOF
    sudo -i bash -c 'pip install PyJWT'
    sudo -i bash -c 'pip install http.client'
EOF
echo $(date '+%Y-%m-%d %H:%M:%S')

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Running CI config..."
ssh ec2-user@${LIN_IP} bash -s << EOF
    sudo -i -u sas bash -c "
        export PG_ADDRESS=${PG_ADDRESS};
        export PG_PASS=${PG_PASS};
        cd /sas/amiautomation && ./config_ci_content.sh | tee -a /sas/amiautomation/logs/config_ci_content.log
    "
EOF

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Start DirectAgent as service..."
ssh ec2-user@${LIN_IP} bash -s << EOF
    sudo -i bash -c 'cp /sas/software/DirectAgent/systemd/direct-agent-service.service /usr/lib/systemd/system'
    sudo -i bash -c 'systemctl daemon-reload'
    sudo -i bash -c 'systemctl start direct-agent-service'
    sudo -i bash -c 'systemctl status direct-agent-service'
EOF

