#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

# Include all the configurations and stabdard functions
source ./config.txt

SERVER_KEY="$AMI_AUTOMATION_TMP_DIR/$NEW_HOST.key"
SERVER_CSR="$AMI_AUTOMATION_TMP_DIR/$NEW_HOST.csr"
SERVER_CRT="$AMI_AUTOMATION_TMP_DIR/$NEW_HOST.crt"
EXTFILE="$AMI_AUTOMATION_TMP_DIR/self.signed.certification.cnf"
AUTH_KEY="$AMI_AUTOMATION_TMP_DIR/$NEW_HOST.CA.key"
AUTH_PEM="$AMI_AUTOMATION_TMP_DIR/$NEW_HOST.CA.pem"
OPENSSL_CMD=openssl
META_PASS_ENC=$(./sas_pass_util.sh encode $META_PASS)

function processSDMTemplates()
{
    for templatefile in *.template
    do
        propfilefname=`echo $templatefile | sed 's/.template//g'| tr -d \\\n`
        cp $templatefile $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's/{NEW_HOST}/'"$NEW_HOST"'/g' -e 's/{OLD_HOSTNAME}/'"$OLD_HOST"'/g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's/{NEW_HOST_INT}/'"$NEW_HOST_INT"'/g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{LICENSE_LOCATION}~'"$LICFILE"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{SAS_CONFIG_DIR}~'"$SAS_CONFIG_DIR"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{AMI_AUTOMATION_TMP_DIR}~'"$AMI_AUTOMATION_TMP_DIR"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{AMI_ATUMATION_DIR}~'"$AMI_ATUMATION_DIR"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{CI_360_TENANT_ID}~'"$CI_360_TENANT_ID"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{CI_360_GW_HOST}~'"$CI_360_GW_HOST"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{CI_360_CLIENT_SECRET}~'"$CI_360_CLIENT_SECRET"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{META_PASS}~'"$META_PASS"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
        sed -i -e 's~{META_PASS_ENC}~'"$META_PASS_ENC"'~g' $AMI_AUTOMATION_TMP_DIR/$propfilefname
    done;
}


echo "SAS Customer Intelligence 360 - Direct - AWS AMI Configuration Utility - START"


echo "${AMILOGMESSAGE}\n************************************"
echo "${AMILOGMESSAGE}\nCurrent Host Name                                       : HOST=$NEW_HOST"

processSDMTemplates
echo "************************************"

echo "Stopping SAS Servers...."
$SAS_CONFIG_DIR/Lev1/sas.servers stop

echo "Applying Hotfixes...."
$SAS_HOME_DIR/SASDeploymentManager/9.4/sasdm.sh -nosidvalidate -responsefile $AMI_AUTOMATION_TMP_DIR/sdmresponses.applyhotfix.properties -quiet

echo "Renewing SAS License...."
$SAS_HOME_DIR/SASDeploymentManager/9.4/sasdm.sh -nosidvalidate -responsefile $AMI_AUTOMATION_TMP_DIR/sdmresponses.renew.license.properties -quiet

echo "Updating SAS License in Metadata...."
$SAS_HOME_DIR/SASDeploymentManager/9.4/sasdm.sh -nosidvalidate -responsefile $AMI_AUTOMATION_TMP_DIR/sdmresponses.renew.metadata.license.properties -quiet 

echo "Start Data Server...."
$SAS_CONFIG_DIR/Lev1/sas.servers.pre start
until [[ $($SAS_CONFIG_DIR/Lev1/sas.servers.pre status) == "SAS Web Infrastructure Data Server is UP" ]]
do
    echo "Waiting for Data Server...."
    sleep 5
done

echo "Changing Hostname in SAS Configuration...."
$SAS_HOME_DIR/SASDeploymentManager/9.4/sasdm.sh -responsefile $AMI_AUTOMATION_TMP_DIR/sdmresponses.properties -skipdatabasecheck -quiet

echo "Generate certificates...."
$OPENSSL_CMD genrsa -out $AUTH_KEY  4096 2>/dev/null
$OPENSSL_CMD req -x509 -new -nodes -key $AUTH_KEY -days 3650 -config $EXTFILE -out $AUTH_PEM  2>/dev/null
$OPENSSL_CMD genrsa -out $SERVER_KEY  4096 2>/dev/null
$OPENSSL_CMD req -new -key $SERVER_KEY -out $SERVER_CSR -config $EXTFILE 2>/dev/null
$OPENSSL_CMD x509 -req -in $SERVER_CSR -signkey $SERVER_KEY -out $SERVER_CRT -days 3650 2>/dev/null
cp $AMI_AUTOMATION_TMP_DIR/$NEW_HOST.key $SSL_CERT_LOCATION
cp $AMI_AUTOMATION_TMP_DIR/$NEW_HOST.crt $SSL_CERT_LOCATION
$OPENSSL_CMD x509 -in $AMI_AUTOMATION_TMP_DIR/$NEW_HOST.crt -out $AMI_AUTOMATION_TMP_DIR/$NEW_HOST.pem -outform PEM

echo "Updating self-signed certificates...."
$SAS_HOME_DIR/SASDeploymentManager/9.4/sasdm.sh -responsefile $AMI_AUTOMATION_TMP_DIR/sdmresponses.add.selfsigned.cert.properties -skipdatabasecheck -quiet

# echo "Changing password for SAS Internal and External Users...."
# $SAS_HOME_DIR/SASDeploymentManager/9.4/sasdm.sh -responsefile $AMI_AUTOMATION_TMP_DIR/sdmresponses.changepass.properties -skipdatabasecheck -quiet

echo "Stopping SAS Servers...."
$SAS_CONFIG_DIR/Lev1/sas.servers stop

echo "Performing cleanup...."

rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebAppServer/SASServer1_1/temp/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebAppServer/SASServer1_1/logs/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebAppServer/SASServer1_1/work/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebAppServer/SASServer2_1/temp/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebAppServer/SASServer2_1/logs/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebAppServer/SASServer2_1/work/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/Logs/SASServer1_1/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/Logs/SASServer2_1/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/WebServer/logs/*
rm -rf $SAS_CONFIG_DIR/Lev1/Web/geode/instances/ins_41415/*.log
rm -rf $SAS_CONFIG_DIR/Lev1/Web/geode/instances/ins_41415/*.dat
rm -rf $SAS_CONFIG_DIR/Lev1/Web/activemq/data/*

echo "Starting SAS Servers....."
$SAS_CONFIG_DIR/Lev1/sas.servers start

echo "SAS Customer Intelligence 360 - Direct - AWS AMI Configuration Utility - END"

