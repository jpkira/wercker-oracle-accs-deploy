#!/usr/bin/env bash


if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_REGION" ]; then
  error 'Please specify OPC region'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_OPC_DOMAIN" ]; then
  error 'Please specify OPC domain'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER" ]; then
  error 'Please specify OPC user'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD" ]; then
  error 'Please specify OPC password'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_FILE" ]; then
  error 'Please specify file (artifact)'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME" ]; then
  error 'Please specify application name'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_TYPE" ]; then
  error 'Please specify application type'
  exit 1
fi

echo 'PWWD:'
pwd

echo 'LLSS:'
ls -la


ARCHIVE_LOCAL=target/$WERCKER_ORACLE_ACCS_DEPLOY_FILE
APAAS_HOST=apaas.${WERCKER_ORACLE_ACCS_DEPLOY_REGION}.oraclecloud.com

if [ ! -e "$ARCHIVE_LOCAL" ]; then
  echo "Error: file not found '${ARCHIVE_LOCAL}'"
  exit -1
fi

# CREATE CONTAINER
echo '\n[info] Creating container\n'
curl -i -X PUT \
    -u ${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD} \
    https://${WERCKER_ORACLE_ACCS_DEPLOY_OPC_DOMAIN}.storage.oraclecloud.com/v1/Storage-$WERCKER_ORACLE_ACCS_DEPLOY_OPC_DOMAIN/$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME

# PUT ARCHIVE IN STORAGE CONTAINER
echo '\n[info] Uploading application to storage\n'
curl -i -X PUT \
  -u ${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD} \
  https://${WERCKER_ORACLE_ACCS_DEPLOY_OPC_DOMAIN}.storage.oraclecloud.com/v1/Storage-$WERCKER_ORACLE_ACCS_DEPLOY_OPC_DOMAIN/$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME/$WERCKER_ORACLE_ACCS_DEPLOY_FILE \
      -T $ARCHIVE_LOCAL

