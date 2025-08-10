#!/bin/bash

if ! oc whoami 1>/dev/null 2>&1; then
  echo "[error] Doesn't look like you are logged in. Login first."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "[error] Please provide the name of the CronJob"
  exit 1
fi

CRONJOB_NAME=$1
manual_job_name="${CRONJOB_NAME}-manual"

# check to make sure the cronjob exists
if ! oc get cronjob ${CRONJOB_NAME} 1>/dev/null 2>&1; then
  echo "[error] CronJob ${CRONJOB_NAME} does not exist"
  exit 1
fi

# check to make sure there isn't already a job with the same name
if oc get job ${manual_job_name} 1>/dev/null 2>&1; then
  echo "[info] Job ${manual_job_name} already exists. Removing..."
  oc delete job ${manual_job_name}
fi

oc create job --from=cronjob/${CRONJOB_NAME} ${manual_job_name}
