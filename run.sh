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

export ARCHIVE_LOCAL=target/$WERCKER_ORACLE_ACCS_DEPLOY_FILE
export APAAS_HOST=apaas.${WERCKER_ORACLE_ACCS_DEPLOY_REGION}.oraclecloud.com

if [ ! -e "$ARCHIVE_LOCAL" ]; then
  echo "Error: file not found '${ARCHIVE_LOCAL}'"
  exit -1
fi

echo "File found '${ARCHIVE_LOCAL}'"

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

# See if application exists
let httpCode=`curl -i -X GET  \
  -u ${USER_ID}:${USER_PASSWORD} \
  -H "X-ID-TENANT-NAME:${ID_DOMAIN}" \
  -H "Content-Type: multipart/form-data" \
  -sL -w "%{http_code}" \
  https://${APAAS_HOST}/paas/service/apaas/api/v1.1/apps/${ID_DOMAIN}/${APP_NAME} \
  -o /dev/null`

# If application exists...
if [ $httpCode == 200 ]
then
  # Update application
  echo '\n[info] Updating application...\n'
  curl -i -X PUT  \
    -u ${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD} \
    -H "X-ID-TENANT-NAME:${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}" \
    -H "Content-Type: multipart/form-data" \
    -F archiveURL=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}/${WERCKER_ORACLE_ACCS_DEPLOY_FILE} \
    https://${APAAS_HOST}/paas/service/apaas/api/v1.1/apps/${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}/${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}
else
  # Create application and deploy
  echo '\n[info] Creating application...\n'
  curl -i -X POST  \
    -u ${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD} \
    -H "X-ID-TENANT-NAME:${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}" \
    -H "Content-Type: multipart/form-data" \
    -F "name=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}" \
    -F "runtime=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_TYPE}" \
    -F "subscription=Hourly" \
    -F archiveURL=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}/${WERCKER_ORACLE_ACCS_DEPLOY_FILE} \
    https://${APAAS_HOST}/paas/service/apaas/api/v1.1/apps/${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}
fi
echo '\n[info] Deployment complete\n'