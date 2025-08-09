#!/usr/bin/env bash
#
# This script checks the connectivity of various endpoints defined in a JSON file.
# Usage: ./connectivity-tester.sh --filename <filename> --environment <environment> [--dependencies]
#
# Options:
#   --filename <filename>      Path to the JSON file containing endpoints
#   --environment <environment> Name of the environment (e.g., dev, prod)
#   --dependencies              Check and install required dependencies
#
# Alternatively, you can use environment variables to set the filename and environment:
#   CONNECTIVITY_TESTER_NAMESPACE_CONFIG_URL   URL of the JSON file containing the endpoints.
#   CONNECTIVITY_TESTER_ENVIRONMENT            Name of the environment (e.g., dev, prod)
#
# The connectivity results will be logged to the console in JSON format.

check_dependencies() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 could not be found, installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y "$1"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y "$1"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "$1"
        else
            echo "Neither apt-get nor dnf found. Please install $1 manually."
            exit 1
        fi
    fi
}

dependencies=("jq" "curl" "getent" "nc" "openssl")

if [ -n "$CONNECTIVITY_TESTER_NAMESPACE_CONFIG_URL" ]; then
    filename="$CONNECTIVITY_TESTER_NAMESPACE_CONFIG_URL"
fi

if [ -n "$CONNECTIVITY_TESTER_ENVIRONMENT" ]; then
    environment="$CONNECTIVITY_TESTER_ENVIRONMENT"
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --filename)
            filename="$2"
            shift 2
            ;;
        --environment)
            environment="$2"
            shift 2
            ;;
        --dependencies)
            check_dependencies "${dependencies[@]}"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$filename" ] || [ -z "$environment" ]; then
    echo "Usage: $0 --filename <filename> --environment <environment> [--dependencies]"
    echo "Or set the environment variables CONNECTIVITY_TESTER_NAMESPACE_CONFIG_URL and CONNECTIVITY_TESTER_ENVIRONMENT"
    exit 1
fi

if [[ "${filename}" == http* ]]; then
    temp_file="$(mktemp)"
    curl -sSL "$filename" -o "$temp_file"
    if [ -s "$temp_file" ]; then
        filename="$temp_file"
    else
        echo "Failed to download or empty file: $filename"
        exit 1
    fi
fi

TEST_NAME=$(jq -r '.name // empty' "$filename")
if [ -z "$TEST_NAME" ]; then
    echo "The file does not contain the element 'name'. Exiting..."
    exit 1
fi

check_tcp_connectivity() {
    local name=$1
    local host=$2
    local port=$3
    local cert_check=$4
    local result
    local ip
    local status
    local valid_certificate
    local error
    local timestamp=$(date +%Y-%m-%dT%H:%M:%SZ)

    ip=$(getent ahosts "$host" | grep -m 1 -oP '^\S+')
    if [ -z "$ip" ]; then
        error="Failed to resolve hostname: $host"
        result=$(jq -c -n --arg timestamp "${timestamp}" --arg host "${host}" --arg error "${error}" '{con_test_timestamp: $timestamp, con_test_host: $host, con_test_error: $error}')
        echo "$result"
        return
    fi

    nc -z -w 5 "$ip" "$port"
    if [ $? -eq 0 ]; then
        status="successful"
        if [ "$cert_check" = true ]; then
            valid_certificate=$(echo | openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null | openssl x509 -noout -checkend 0)
            if [ $? -eq 0 ]; then
                valid_certificate=true
            else
                valid_certificate=false
            fi
        else
            valid_certificate=null
        fi
        result=$(jq -c -n --arg timestamp "${timestamp}" --arg host "${host}" --arg ip "${ip}" --arg port "${port}" --arg status "${status}" --arg valid_certificate "${valid_certificate}" '{con_test_timestamp: $timestamp, con_test_host: $host, con_test_ip: $ip, con_test_port: ($port|tonumber), con_test_status: $status, con_test_valid_certificate: $valid_certificate}')
    else
        status="failed"
        error="Connection to ${host}:${port} failed"
        result=$(jq -c -n --arg timestamp "${timestamp}" --arg host "${host}" --arg ip "${ip}" --arg port "${port}" --arg status "${status}" --arg error "${error}" '{con_test_timestamp: $timestamp, con_test_host: $host, con_test_ip: $ip, con_test_port: ($port|tonumber), con_test_status: $status, con_test_error: $error}')
    fi

    echo "$result"
}

check_udp_connectivity() {
    local name=$1
    local host=$2
    local port=$3
    local result
    local ip
    local status
    local error
    local timestamp=$(date +%Y-%m-%dT%H:%M:%SZ)

    ip=$(getent ahosts "$host" | grep -m 1 -oP '^\S+')
    if [ -z "$ip" ]; then
        error="Failed to resolve hostname: $host"
        result=$(jq -c -n --arg timestamp "${timestamp}" --arg host "${host}" --arg error "${error}" '{con_test_timestamp: $timestamp, con_test_host: $host, con_test_error: $error}')
        echo "$result"
        return
    fi

    nc -z -u -w 5 "$ip" "$port"
    if [ $? -eq 0 ]; then
        status="successful"
    else
        status="failed"
    fi

    result=$(jq -c -n --arg timestamp "${timestamp}" --arg host "${host}" --arg ip "${ip}" --arg port "${port}" --arg status "${status}" '{con_test_timestamp: $timestamp, con_test_host: $host, con_test_ip: $ip, con_test_port: ($port|tonumber), con_test_status: $status}')

    echo "$result"
}

if jq -e '.endpoints | arrays' "$filename" > /dev/null; then
    ENDPOINTS_ARRAY=$(jq -r '.endpoints[]' "$filename")
    for endpoint in ${ENDPOINTS_ARRAY}; do
        SCRIPT_DIR=$(dirname "$(realpath "$0")")
        "${SCRIPT_DIR}/connectivity-tester.sh" --filename "${endpoint}" --environment "${environment}"
    done
fi

CHECK_NAME=$(jq -r '.name // "NOT_PROVIDED"' "$filename")

if jq -e --arg env "${environment}" '.[$env] | arrays' "$filename" > /dev/null; then
    FULL_FEATURED_ENDPOINTS_ARRAY=$(jq -c --arg env "${environment}" '.[$env]' "$filename")
    if [ $? -ne 0 ]; then
        echo "Error parsing JSON file or environment '${environment}' not found."
        exit 1
    fi

    echo "${FULL_FEATURED_ENDPOINTS_ARRAY}" | jq -c '.[]' | while read -r endpoint; do
        host=$(echo "$endpoint" | jq -r '.host')
        port=$(echo "$endpoint" | jq -r '.port')
        protocol=$(echo "$endpoint" | jq -r '.protocol // "TCP"')
        description=$(echo "$endpoint" | jq -r '.description')
        verify_cert=$(echo "$endpoint" | jq -r '.verify_cert // empty')

        if [ "${protocol}" == "TCP" ]; then
            check_tcp_connectivity "${CHECK_NAME}" "${host}" "${port}" "${verify_cert}"
        elif [ "${protocol}" == "UDP" ]; then
            check_udp_connectivity "${CHECK_NAME}" "${host}" "${port}"
        else
            echo "Unsupported protocol: ${protocol}"
        fi
    done
fi