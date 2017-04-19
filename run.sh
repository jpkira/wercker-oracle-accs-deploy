#!/usr/bin/env bash


if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_REGION" ]; then
  error 'Please specify OPC region'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN" ]; then
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

echo 'PWD:'
pwd

echo 'LS:'
ls -la

echo 'TARGET:'
ls -la target

echo 'WERCKER_OUTPUT_DIR:'
ls -la $WERCKER_OUTPUT_DIR

export ARCHIVE_LOCAL=target/$WERCKER_ORACLE_ACCS_DEPLOY_FILE
export APAAS_HOST=apaas.${WERCKER_ORACLE_ACCS_DEPLOY_REGION}.oraclecloud.com

if [ ! -e "$ARCHIVE_LOCAL" ]; then
  echo "Error: file not found '${ARCHIVE_LOCAL}'"
  exit -1
fi

# CREATE CONTAINER
echo '[info] Creating container'
curl -i -X PUT \
    -u "${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD}" \
    "https://${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}.storage.oraclecloud.com/v1/Storage-$WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN/$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME"

# PUT ARCHIVE IN STORAGE CONTAINER
echo '[info] Uploading application to storage'
curl -i -X PUT \
  -u "${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD}" \
  "https://${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}.storage.oraclecloud.com/v1/Storage-$WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN/$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME/$WERCKER_ORACLE_ACCS_DEPLOY_FILE" \
      -T "$ARCHIVE_LOCAL"

