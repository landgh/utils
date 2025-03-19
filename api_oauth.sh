#!/bin/bash

# Define a hash map-like structure using associative arrays
declare -A CONFIGS

# Function to add configurations
add_config() {
    local system=$1 env=$2 endpoint=$3 token_url=$4 client_id=$5 client_secret=$6 api_key=$7 token_file=$8
    CONFIGS[$system,$env,APIGEE_ENDPOINT]="$endpoint"
    CONFIGS[$system,$env,TOKEN_URL]="$token_url"
    CONFIGS[$system,$env,CLIENT_ID]="$client_id"
    CONFIGS[$system,$env,CLIENT_SECRET]="$client_secret"
    CONFIGS[$system,$env,API_KEY]="$api_key"
    CONFIGS[$system,$env,TOKEN_FILE]="$token_file"
}

# Initialize configurations
add_config "system1" "prod" "https://api.prod.system1.com/resource" "https://login.prod.system1.com/oauth/token" "your_prod_system1_client_id" "your_prod_system1_client_secret" "your_prod_system1_api_key" "token_system1_prod.txt"
add_config "system1" "non-prod" "https://api.nonprod.system1.com/resource" "https://login.nonprod.system1.com/oauth/token" "your_nonprod_system1_client_id" "your_nonprod_system1_client_secret" "your_nonprod_system1_api_key" "token_system1_nonprod.txt"
add_config "system2" "prod" "https://api.prod.system2.com/resource" "https://login.prod.system2.com/oauth/token" "your_prod_system2_client_id" "your_prod_system2_client_secret" "your_prod_system2_api_key" "token_system2_prod.txt"
add_config "system2" "non-prod" "https://api.nonprod.system2.com/resource" "https://login.nonprod.system2.com/oauth/token" "your_nonprod_system2_client_id" "your_nonprod_system2_client_secret" "your_nonprod_system2_api_key" "token_system2_nonprod.txt"

# Accept system and environment as arguments
system=${1:-"system1"}  # Default to system1 if not provided
env=${2:-"non-prod"}  # Default to non-prod if not provided

# Validate system and environment
if [ -z "${CONFIGS[$system,$env,APIGEE_ENDPOINT]}" ]; then
    echo "Invalid system or environment: $system, $env"
    exit 1
fi

# Load the selected configuration
APIGEE_ENDPOINT="${CONFIGS[$system,$env,APIGEE_ENDPOINT]}"
TOKEN_URL="${CONFIGS[$system,$env,TOKEN_URL]}"
CLIENT_ID="${CONFIGS[$system,$env,CLIENT_ID]}"
CLIENT_SECRET="${CONFIGS[$system,$env,CLIENT_SECRET]}"
API_KEY="${CONFIGS[$system,$env,API_KEY]}"
TOKEN_FILE="${CONFIGS[$system,$env,TOKEN_FILE]}"

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
