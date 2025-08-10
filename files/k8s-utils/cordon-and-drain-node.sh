#!/bin/bash

oc adm cordon $1

if [ $? -ne 0 ]; then
  echo "Failed to cordon node $1"
  exit 1
fi

oc adm drain $1 --grace-period=120 --force=true --ignore-daemonsets --delete-emptydir-data=true

if [ $? -ne 0 ]; then
  echo "Failed to drain node $1"
  exit 1
else
  echo "Successfully cordoned and drained node $1"
fi