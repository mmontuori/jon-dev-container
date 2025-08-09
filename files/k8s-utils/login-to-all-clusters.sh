#!/bin/bash
#
# Uses the .context file to authenticate to all clusters

current_dir=$(dirname $(readlink -f $0))

if ! test -f $current_dir/.contexts; then
    echo "No context file found at $current_dir/.contexts"
    exit 1
fi

# Exclude all lines that start with a # (regardless of how many spaces are in front of it)
clusters=$(cat $current_dir/.contexts | grep -v '^\s*#')

read -p "user: " user_input
read -p "pass: " -s pass_input

echo

for cluster in ${clusters[*]}; do
    echo "Logging into $cluster..."
    if oc login --username="$user_input" --password="$pass_input" --context="$cluster"; then
        echo "Successfully logged into $cluster"
    else
        echo "Failed to log into $cluster"
    fi
done