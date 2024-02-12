#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0

echo $(date '+%Y-%m-%d %H:%M:%S')
source /sas/amiautomation/config.txt

echo "Creating databases..."
echo 'create database ci;' | psql -h ${PG_ADDRESS} -p 5432 "dbname=postgres user=pgadmin password=${PG_PASS} sslmode=require"
echo 'create schema cdm;create schema cmdm;' | psql -h ${PG_ADDRESS} -p 5432 "dbname=ci user=pgadmin password=${PG_PASS} sslmode=require"


echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Running SAS init..."
sed -i -e "28 i export MAS_M2PATH=${SAS_HOME_DIR}/SASFoundation/9.4/misc/tkmas/mas2py.py" \
    -e "28 i export MAS_PYPATH=/usr/bin/python" \
    ${SAS_HOME_DIR}/SASFoundation/9.4/bin/sasenv_local
${SAS_HOME_DIR}/SASPlatformObjectFramework/9.4/ImportPackage -target / -package /sas/amiautomation/packages/dbserver.spk \
    -host localhost -port 8561 -user sasadm@saspw -password ${META_PASS} -disableX11
${SAS_HOME_DIR}/SASPlatformObjectFramework/9.4/SetPassword -metaServer localhost -metaPort 8561 \
    -metaUser sasadm@saspw -metaPass ${META_PASS} -userID pgadmin -ownerType IdentityGroup \
    -ownerName RDSAccess -authDom RDSAuth -password ${PG_PASS}
${SAS_HOME_DIR}/SASFoundation/9.4/bin/sas_u8 -metaautoresources 'SASApp' -metaServer localhost -metaPort 8561 \
    -metaUser sasadm@saspw -metaPass ${META_PASS} \
    -sysin /sas/amiautomation/sas-codes/sas_init_meta.sas -log /sas/amiautomation/logs/sas_init_meta.log

echo "Sleep 600..."
sleep 600

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Start Web Apps..."
${SAS_CONFIG_DIR}/Lev1/sas.servers start

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Prepare DirectAgent..."
cd /sas/software/DirectAgent
cp ${SAS_CONFIG_DIR}/Lev1/Web/WebAppServer/SASServer1_1/conf/jaas.config . 
cp ${SAS_CONFIG_DIR}/Lev1/Web/WebAppServer/SASServer1_1/conf/server.xml . 
cp ${SAS_CONFIG_DIR}/Lev1/Web/WebAppServer/SASServer1_1/conf/catalina.properties . 
cp ${AMI_AUTOMATION_TMP_DIR}/cionprem.properties . 
cp ${AMI_AUTOMATION_TMP_DIR}/credentials.properties . 

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Upgrade DirectAgent..."
/sas/software/DirectAgent/upgrade_app.sh

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Download repos from github..."
cd /sas/software/
git clone https://github.com/sassoftware/ci360-cdm-loader-sas.git
perl -i -0777 -pe 's/libname dblib [^;]+;/libname dblib \(cdm\);/g' ci360-cdm-loader-sas/macros/cdm_launch.sas
sed -i -e 's/\/dev\/sassoftware/\/sas\/software/g' ci360-cdm-loader-sas/macros/cdm_launch.sas

git clone https://github.com/sassoftware/ci360-download-client-sas.git
sed -i -e "s/^\s*%let UtilityLocation=.*$/%let UtilityLocation=\/sas\/software\/ci360-download-client-sas;/g" \
    -e "s/^\s*%let PYTHON_PATH=.*$/%let PYTHON_PATH=%str(python);/g" \
    -e "s/^\s*%let mart_nm=.*$/%let mart_nm=${CI_360_DSC_MART_NM};/g" \
    -e "s/^\s*%let DSC_DOWNLOAD_URL=.*$/%let DSC_DOWNLOAD_URL=%nrstr(https:\/\/${CI_360_GW_HOST}\/marketingGateway\/discoverService\/dataDownload\/eventData\/);/g" \
    -e "s/^\s*%let DSC_AGENT_NAME=.*$/%let DSC_AGENT_NAME=${CI_360_AGENT_NAME};/g" \
    -e "s/^\s*%let DSC_TENANT_ID=.*$/%let DSC_TENANT_ID=%str(${CI_360_TENANT_ID});/g" \
    -e "s/^\s*%let DSC_SECRET_KEY=.*$/%let DSC_SECRET_KEY=%str(${CI_360_CLIENT_SECRET});/g" \
    -e "s/^\s*%let DSC_SCHEMA_VERSION=.*$/%let DSC_SCHEMA_VERSION=${CI_360_DSC_SCHEMA_VERSION};/g" \
    -e "s/^\s*%let CATEGORY=.*$/%let CATEGORY=${CI_360_DSC_CATEGORY};/g" \
    -e "s/^\s*%let DSC_LOAD_START_DTTM=%nrquote.*$//g" \
    -e "s/^\s*%let DSC_LOAD_END_DTTM=%nrquote.*$//g" \
    ci360-download-client-sas/macros/dsc_download.sas

git clone https://github.com/sassoftware/ci360-direct-samples.git
sed -i \
    -e "s/^\s*%let ci360_env\b.*$/%let ci360_env = `echo ${CI_360_GW_HOST} | cut -d '-' -f2`;/g" \
    -e "s/^\s*%let api_agent\b.*$/%let api_agent = '${CI_360_AGENT_NAME}';/g" \
    -e "s/^\s*%let api_tenant\b.*$/%let api_tenant = '${CI_360_TENANT_ID}';/g" \
    -e "s/^\s*%let api_secret\b.*$/%let api_secret = '${CI_360_CLIENT_SECRET}';/g" \
    ci360-direct-samples/ci360-new-identities-uploader/initialize_parameter.sas

sed -i \
    -e "s/^\s*%let CI360_server\b.*$/%let CI360_server=${CI_360_GW_HOST};/g" \
    -e "s/^\s*%let DSC_TENANT_ID\b.*$/%let DSC_TENANT_ID=%str(${CI_360_TENANT_ID});/g" \
    -e "s/^\s*%let DSC_SECRET_KEY\b.*$/%let DSC_SECRET_KEY=%str(${CI_360_CLIENT_SECRET});/g" \
    ci360-direct-samples/ci360-gdpr-delete/initialize_parameter.sas

sed -i \
    -e "s/^\s*%let CI360_server\b.*$/%let CI360_server=${CI_360_GW_HOST};/g" \
    -e "s/^\s*%let DSC_TENANT_ID\b.*$/%let DSC_TENANT_ID=%str(${CI_360_TENANT_ID});/g" \
    -e "s/^\s*%let DSC_SECRET_KEY\b.*$/%let DSC_SECRET_KEY=%str(${CI_360_CLIENT_SECRET});/g" \
    ci360-direct-samples/ci360-customer-data-uploader/initialize_parameter.sas

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Run CDM DDL..."
export CDM_TABLES_META_PATH="/Shared Data/Customer Intelligence/CDM/Tables"
${SAS_HOME_DIR}/SASPlatformObjectFramework/9.4/tools/sas-make-folder -host localhost -port 8561 \
    -user sasadm@saspw -password ${META_PASS} -makeFullPath "${CDM_TABLES_META_PATH}"
${SAS_HOME_DIR}/SASFoundation/9.4/bin/sas_u8 -metaautoresources 'SASApp' -metaServer localhost -metaPort 8561 \
    -metaUser sasadm@saspw -metaPass ${META_PASS} \
    -sysin /sas/amiautomation/sas-codes/sas_init_db.sas -log /sas/amiautomation/logs/sas_init_db.log

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Runing ci360-download-client-sas..."
${SAS_HOME_DIR}/SASFoundation/9.4/bin/sas_u8 -metaautoresources 'SASApp' -metaServer localhost -metaPort 8561 \
    -metaUser sasadm@saspw -metaPass ${META_PASS} \
    -sysin /sas/software/ci360-download-client-sas/macros/dsc_download.sas -log /sas/amiautomation/logs/dsc_download.log

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Running ci360-cdm-loader-sas..."
${SAS_HOME_DIR}/SASFoundation/9.4/bin/sas_u8 -metaautoresources 'SASApp' -metaServer localhost -metaPort 8561 \
    -metaUser sasadm@saspw -metaPass ${META_PASS} \
    -sysin /sas/software/ci360-cdm-loader-sas/macros/cdm_launch.sas -log /sas/amiautomation/logs/cdm_launch.log
echo $(date '+%Y-%m-%d %H:%M:%S')

echo $(date '+%Y-%m-%d %H:%M:%S')
echo "Build ci360-events-to-db-agent..."
sed -i -e "s/^\s*ci360.gatewayHost=.*$/ci360.gatewayHost=${CI_360_GW_HOST}/g" \
    -e "s/^\s*ci360.tenantID=.*$/ci360.tenantID=${CI_360_TENANT_ID}/g" \
    -e "s/^\s*ci360.clientSecret=.*$/ci360.clientSecret=${CI_360_CLIENT_SECRET}/g" \
    -e "s/^\s*spring.datasource.url=.*$/spring.datasource.url=jdbc:postgresql:\/\/${PG_ADDRESS}:5432\/ci/g" \
    -e "s/^\s*spring.datasource.username=.*$/spring.datasource.username=pgadmin/g" \
    -e "s/^\s*spring.datasource.password=.*$/spring.datasource.password=${PG_PASS}/g" \
    ci360-direct-samples/ci360-events-to-db-agent/src/main/resources/application.properties

curl -O https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
tar xzvf apache-maven-3.9.6-bin.tar.gz
cd /sas/software/ci360-direct-samples/ci360-events-to-db-agent
/sas/software/apache-maven-3.9.6/bin/mvn install:install-file -Dfile="sdk/mkt-agent-sdk-jar-2.2311.2309271430.jar" -DpomFile="sdk/pom.xml"
./gradlew build
echo $(date '+%Y-%m-%d %H:%M:%S')