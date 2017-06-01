#!/usr/bin/env bash

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_REST_URL" ]; then
  error 'Please specify  Oracle Application Container Cloud REST url. (e.g.: https://apaas.europe.oraclecloud.com/paas/service/apaas/api/v1.1/apps)'
  error '(Locate Oracle Application Container Cloud in the My Services console, click Details, and look at the REST Endpoint value.)'
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
  error 'Please specify file (zip artifact)'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME" ]; then
  error 'Please specify application name (application container cloud service instance name)'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_TYPE" ]; then
  error 'Please specify application type (java|node|php)'
  exit 1
fi

if [ ! -n "$WERCKER_ORACLE_ACCS_DEPLOY_SUBSCRIPTION_TYPE" ]; then
  error 'Please specify your subscription type (Hourly|Monthly)'
  exit 1
fi


export ARCHIVE_LOCAL=target/$WERCKER_ORACLE_ACCS_DEPLOY_FILE

if [ ! -e "$ARCHIVE_LOCAL" ]; then
  echo "Error: file not found '${ARCHIVE_LOCAL}'"
  exit -1
fi

echo "File found '${ARCHIVE_LOCAL}'"

# Functions
getStorageTokenAndURLSet() {
  echo '[info] Fetching Storage Auth Token and URL.'

  shopt -s extglob
  while IFS=':' read key value; do
          value=${value##+([[:space:]])}; value=${value%%+([[:space:]])}
          case "$key" in
            X-Auth-Token) export STORAGE_AUTH_TOKEN="$value"
                  ;;
            X-Storage-Url) export STORAGE_URL="$value"
                  ;;
          esac
  done< <(curl -sI -X GET -H "X-Storage-User: Storage-${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}" -H "X-Storage-Pass: ${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD}" "https://${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}.storage.oraclecloud.com/auth/v1.0")

  if [ ! -n "$STORAGE_AUTH_TOKEN" ]; then
    error 'Unable to reterive Storage Auth Token, please check your OPC Username and Password.'
    exit 1
  fi

  if [ ! -n "$STORAGE_URL" ]; then
    error 'Unable to reterive Storage URL, please check your OPC Username and Password.'
    exit 1
  fi

}

createStorageContainer() {

  getStorageTokenAndURLSet

  echo '[info] Creating Storage Container.'
  curl -i -X PUT \
    -H "X-Auth-Token: $STORAGE_AUTH_TOKEN" \
    "$STORAGE_URL/$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME"
}

uploadACCSArchive() {
  # We get the token and URL set again in the event that the previously fetch set has expired, this may be overkill?
  getStorageTokenAndURLSet

  echo '[info] Uploading application to storage'
  curl -i -X PUT \
    -H "X-Auth-Token: $STORAGE_AUTH_TOKEN" \
    -T "$ARCHIVE_LOCAL" \
    "$STORAGE_URL/$WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME/$WERCKER_ORACLE_ACCS_DEPLOY_FILE"
}

# CREATE CONTAINER
createStorageContainer

# PUT ARCHIVE IN STORAGE CONTAINER
uploadACCSArchive

# See if application exists
export httpCode=$(curl -i -X GET  \
  -u "${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD}" \
  -H "X-ID-TENANT-NAME:${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}" \
  -H "Content-Type: multipart/form-data" \
  -sL -w "%{http_code}" \
  "${WERCKER_ORACLE_ACCS_DEPLOY_REST_URL}/${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}/${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}" \
  -o /dev/null)

# If application exists...
if [ "$httpCode" == 200 ]
then
  # Update application
  echo '[info] Updating application...'
  curl -i -X PUT  \
    -u "${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD}" \
    -H "X-ID-TENANT-NAME:${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}" \
    -H "Content-Type: multipart/form-data" \
    -F "archiveURL=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}/${WERCKER_ORACLE_ACCS_DEPLOY_FILE}" \
    "${WERCKER_ORACLE_ACCS_DEPLOY_REST_URL}/${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}//${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}"
else
  # Create application and deploy
  echo '[info] Creating application...'
  curl -i -X POST  \
    -u "${WERCKER_ORACLE_ACCS_DEPLOY_OPC_USER}:${WERCKER_ORACLE_ACCS_DEPLOY_OPC_PASSWORD}" \
    -H "X-ID-TENANT-NAME:${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}" \
    -H "Content-Type: multipart/form-data" \
    -F "name=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}" \
    -F "runtime=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_TYPE}" \
    -F "subscription=$WRECKER_ORACLE_ACCS_DEPLOY_SUBSCRIPTION_TYPE" \
    -F "archiveURL=${WERCKER_ORACLE_ACCS_DEPLOY_APPLICATION_NAME}/${WERCKER_ORACLE_ACCS_DEPLOY_FILE}" \
    "${WERCKER_ORACLE_ACCS_DEPLOY_REST_URL}/${WERCKER_ORACLE_ACCS_DEPLOY_DOMAIN}"
fi

echo '[info] Deployment complete'
