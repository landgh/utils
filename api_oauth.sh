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
    echo "Usage: $0 [system] [environment]"
    echo "  system       - The target system (e.g., system1, system2)"
    echo "  environment  - The environment (e.g., prod, non-prod)"
    echo "  -h           - Show this help message"
    echo "  -l           - List all available configurations with details"
    exit 0
}

# Function to list all configurations with details
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
if [[ "$1" == "-h" ]]; then
    show_usage
elif [[ "$1" == "-l" ]]; then
    list_configs
fi

# Accept system and environment as arguments
system=${1:-"system1"}  # Default to system1 if not provided
env=${2:-"non-prod"}  # Default to non-prod if not provided

# Validate system and environment
if [ -z "${CONFIGS[$system,$env]}" ]; then
    echo "Invalid system or environment: $system, $env"
    exit 1
fi

# Prompt user for client secret (hidden input)
echo -n "Enter client secret: "
stty -echo
read CLIENT_SECRET
stty echo
echo ""

# Load the selected configuration
IFS=',' read -r APIGEE_ENDPOINT TOKEN_URL CLIENT_ID API_KEY TOKEN_FILE <<< "${CONFIGS[$system,$env]}"

GRANT_TYPE="client_credentials"

# Function to fetch a new token
get_new_token() {
    echo "Fetching new token for $system in $env environment..."
    response=$(curl -s -X POST "$TOKEN_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=$GRANT_TYPE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET")
    
    ACCESS_TOKEN=$(echo "$response" | jq -r .access_token)
    EXPIRES_IN=$(echo "$response" | jq -r .expires_in)
    
    if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
        echo "Failed to get access token. Response: $response"
        exit 1
    fi
    
    EXPIRY_TIME=$(( $(date +%s) + $EXPIRES_IN ))
    echo "$ACCESS_TOKEN $EXPIRY_TIME" > "$TOKEN_FILE"
    echo "New token acquired for $system in $env."
}

# Function to read the existing token
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

# Get a valid token
get_stored_token

# Make API request
response=$(curl -s -X GET "$APIGEE_ENDPOINT" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "x-api-key: $API_KEY")

# Output response
echo "Response: $response"
