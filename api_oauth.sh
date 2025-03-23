#!/bin/bash

# Define a hash map-like structure using associative arrays
declare -A CONFIGS

# Function to add configurations
add_config() {
    local system=$1 env=$2 endpoint=$3 token_url=$4 client_id=$5 api_key=$6 token_file=$7
    CONFIGS[$system,$env]="$endpoint, $token_url, $client_id, $api_key, $token_file"
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [system] [environment] [-o | -b] [--grant grant_type]"
    echo "  system       - The target system (e.g., system1, system2)"
    echo "  environment  - The environment (e.g., prod, non-prod)"
    echo "  -o           - Use OAuth authentication"
    echo "  -b           - Use Basic authentication"
    echo "  --grant      - (Optional) OAuth2 grant type: client_credentials (default), password"
    echo "  -h           - Show this help message"
    echo "  -l           - List all available configurations"
    exit 0
}

# Function to list all configurations with details, sorted by system and env
list_configs() {
    echo "Available Configurations:"
    for key in "${!CONFIGS[@]}"; do
        echo "$key|${CONFIGS[$key]}"
    done | sort | awk -F '|' '{printf "%s\n\t%s\n", $1, $2}'
    exit 0
}

# Initialize configurations
add_config "system1" "prod" "https://api.prod.system1.com/resource" "https://login.prod.system1.com/oauth/token" "your_prod_system1_client_id" "your_prod_system1_api_key" "token_system1_prod.txt"
add_config "system1" "non-prod" "https://api.nonprod.system1.com/resource" "https://login.nonprod.system1.com/oauth/token" "your_nonprod_system1_client_id" "your_nonprod_system1_api_key" "token_system1_nonprod.txt"
add_config "system2" "prod" "https://api.prod.system2.com/resource" "https://login.prod.system2.com/oauth/token" "your_prod_system2_client_id" "your_prod_system2_api_key" "token_system2_prod.txt"
add_config "system2" "non-prod" "https://api.nonprod.system2.com/resource" "https://login.nonprod.system2.com/oauth/token" "your_nonprod_system2_client_id" "your_nonprod_system2_api_key" "token_system2_nonprod.txt"

# Check for help or list flag
if [[ "$1" == "-h" ]]; then show_usage; fi
if [[ "$1" == "-l" ]]; then list_configs; fi

# Parse positional arguments
system=$1
env=$2
shift 2

# Defaults
auth_method="-o"
grant_type="client_credentials"

# Parse optional flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|-b)
            auth_method=$1
            shift
            ;;
        --grant)
            grant_type=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate system and environment
if [ -z "$system" ] || [ -z "$env" ]; then
    echo "Error: Both system and environment are required."
    show_usage
fi

if [ -z "${CONFIGS[$system,$env]}" ]; then
    echo "Invalid system or environment: $system, $env"
    exit 1
fi

# Load the selected configuration
#IFS=',' read -r APIGEE_ENDPOINT TOKEN_URL CLIENT_ID API_KEY TOKEN_FILE <<< "${CONFIGS[$system,$env]}"
IFS=',' read -r APIGEE_ENDPOINT TOKEN_URL CLIENT_ID API_KEY TOKEN_FILE <<< "$(echo "${CONFIGS[$system,$env]}" | sed 's/, */,/g')"

# OAuth Auth
if [[ "$auth_method" == "-o" ]]; then
    echo "Enter client secret:"
    stty -echo
    read CLIENT_SECRET
    stty echo
    echo ""

    if [[ "$grant_type" == "password" ]]; then
        echo "Enter username:"
        read USERNAME
        echo "Enter password:"
        stty -echo
        read PASSWORD
        stty echo
        echo ""
    fi

    get_new_token() {
        echo "Requesting token using $grant_type grant..."
        
        if [[ "$grant_type" == "client_credentials" ]]; then
            DATA="grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET"
        elif [[ "$grant_type" == "password" ]]; then
            DATA="grant_type=password&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&username=$USERNAME&password=$PASSWORD"
        else
            echo "Unsupported grant type: $grant_type"
            exit 1
        fi

        response=$(curl -s -X POST "$TOKEN_URL" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "$DATA")

        ACCESS_TOKEN=$(echo "$response" | jq -r .access_token)
        EXPIRES_IN=$(echo "$response" | jq -r .expires_in)

        if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
            echo "Failed to get token. Response: $response"
            exit 1
        fi

        EXPIRY_TIME=$(( $(date +%s) + $EXPIRES_IN ))
        echo "$ACCESS_TOKEN $EXPIRY_TIME" > "$TOKEN_FILE"
        echo "New token acquired for $system in $env."
    }

    get_stored_token() {
        if [ -f "$TOKEN_FILE" ]; then
            read ACCESS_TOKEN EXPIRY_TIME < "$TOKEN_FILE"
            CURRENT_TIME=$(date +%s)
            if [ "$CURRENT_TIME" -ge "$EXPIRY_TIME" ]; then
                get_new_token
            fi
        else
            get_new_token
        fi
    }

    get_stored_token
    AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"

# Basic Auth
elif [[ "$auth_method" == "-b" ]]; then
    echo "Enter username:"
    read USERNAME
    echo "Enter password:"
    stty -echo
    read PASSWORD
    stty echo
    echo ""
    AUTH_HEADER="Authorization: Basic $(echo -n "$USERNAME:$PASSWORD" | base64)"
else
    echo "Unsupported authentication method: $auth_method"
    exit 1
fi

# Make API call
response=$(curl -s -X GET "$APIGEE_ENDPOINT" \
    -H "$AUTH_HEADER" \
    -H "x-api-key: $API_KEY")

echo "Response: $response"

# Optional: Display token info
if [[ -n "$ACCESS_TOKEN" ]]; then
    if echo "$ACCESS_TOKEN" | grep -q '\.'; then
        HEADER=$(echo "$ACCESS_TOKEN" | cut -d '.' -f1 | base64 --decode 2>/dev/null)
        if echo "$HEADER" | grep -q 'alg'; then
            echo "Detected JWT (OAuth2 v2) $HEADER"
        else
            echo "Unknown token format"
        fi
    else
        echo "Opaque token (OAuth2 v1)"
    fi
fi
