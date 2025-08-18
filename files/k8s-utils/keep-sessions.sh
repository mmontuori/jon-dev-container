#!/bin/bash
#
# Keeps the sessions alive for all clusters
#

current_dir=$(dirname $(readlink -f $0))

if ! test -f $current_dir/.contexts; then
    echo "No context file found at $current_dir/.contexts"
    exit 1
fi

sleep_interval=180

while true; do
    clear
    clusters=$(cat $current_dir/.contexts | grep -v '^\s*#')
    for cluster in ${clusters[*]}; do
        echo -n "Keeping session alive for $cluster... "
        oc whoami --context="$cluster" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "failed"
        else
            echo "success"
        fi
    done
    echo
    echo "last refresh: $(TZ='America/New_York' date '+%H:%M:%S')"
    sleep $sleep_interval
done
