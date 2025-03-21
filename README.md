- git remote add origin https://github.com/landgh/utils.git
- git branch -M main
- git push -u origin main

----- api_oauth.sh
```
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
    echo "Usage: $0 [-h | -l ] [system] [environment] -o | -b"
    echo "  system       - The target system (e.g., system1, system2)"
    echo "  environment  - The environment (e.g., prod, non-prod)"
    echo "  -o           - Use OAuth authentication"
    echo "  -b           - Use Basic authentication"
    echo "  -h           - Show this help message"
    echo "  -l           - List all available configurations with details"
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
if [[ "$1" == "-h" ]]; then
    show_usage
elif [[ "$1" == "-l" ]]; then
    list_configs
fi

# Accept system, environment, and authentication method as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both system and environment parameters are required."
    show_usage
    exit 1
fi
system=$1
env=$2  # Default to non-prod if not provided
auth_method=${3:-"-o"}  # Default to OAuth if not specified

# Validate system and environment
if [ -z "${CONFIGS[$system,$env]}" ]; then
    echo "Invalid system or environment: $system, $env"
    exit 1
fi

# Load the selected configuration
#IFS=',' read -r APIGEE_ENDPOINT TOKEN_URL CLIENT_ID API_KEY TOKEN_FILE <<< "${CONFIGS[$system,$env]}"
IFS=',' read -r APIGEE_ENDPOINT TOKEN_URL CLIENT_ID API_KEY TOKEN_FILE <<< "$(echo "${CONFIGS[$system,$env]}" | sed 's/, */,/g')"


# Handle authentication method
if [[ "$auth_method" == "-o" ]]; then
    echo -e "Connecting to $system in $env environment using OAuth...\n"
    echo -n "Enter $CLIENT_ID client secret: "
    stty -echo
    read CLIENT_SECRET
    stty echo
    echo ""
    
    get_new_token() {
        echo "Fetching new token for $system in $env environment..."
        response=$(curl -s -X POST "$TOKEN_URL" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET")
        
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

elif [[ "$auth_method" == "-b" ]]; then
    echo -e "Connecting to $system in $env environment using basic auth...\n"
    echo -n "Enter $CLIENT_ID password: "
    stty -echo
    read PASSWORD
    stty echo
    echo ""
    AUTH_HEADER="Authorization: Basic $(echo -n "$CLIENT_ID:$PASSWORD" | base64)"
else
    echo "Invalid authentication method. Use -o for OAuth or -b for Basic Auth."
    exit 1
fi

# Make API request
response=$(curl -s -X GET "$APIGEE_ENDPOINT" \
    -H "$AUTH_HEADER" \
    -H "x-api-key: $API_KEY")

# Output response
echo "Response: $response"

# Detect and display token version if applicable
# Extract and show token claims if it's a JWT token
if [[ -n "$ACCESS_TOKEN" ]]; then
    if echo "$ACCESS_TOKEN" | grep -q '\.'; then
        # JWT token - likely v2
        HEADER=$(echo "$ACCESS_TOKEN" | cut -d '.' -f1 | base64 --decode 2>/dev/null)
        if echo "$HEADER" | grep -q 'alg'; then
            echo "Detected OAuth2 v2 token (JWT format)"
        else
            echo "Token format could not be identified"
        fi
    else
        echo "Detected OAuth2 v1 token (opaque format)"
    fi
fi

```
--- git_projs.sh
```
#!/bin/sh

# set up proj related dir and branch
java_projs=/d/myjava
python_projs=/d/mypython

#repos root on local
declare -A projs=( 
  ["demo_copilot"]=$java_projs
  ["python_best"]=$python_projs
)

# assume upstream branch associated is "origin/master". Otherwise specify it in the following array
#declare -A branches=( 
#  ["demo_copilot"]="master"
#)

```
--- git_utils.sh
```
#!/bin/sh

# Color codes for output
Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red
BGreen='\033[1;32m'       # Green

# Display usage information
display_usage() {
    echo "Usage: . git_refresh.sh -h|-l [proj]|r [proj]|-s [proj]"
    for p in "${!projs[@]}"; do
        echo -e "  $BGreen${projs[$p]}/$p:$Red ${branches[$p]:-master}$Color_Off"
    done | sort
    exit 0
}

# Refresh git repositories
refresh_repos() {
    echo "Refreshing git repos with $@"
    for p in "${!projs[@]}"; do
        dir=${projs[$p]}
        branch=${branches[$p]:-$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')}
        ok=0

        if [ "$param" ] && [ "$param" = "$p" ]; then
            ok=1
        elif [ "$param" ]; then
            continue
        fi

        case $action in
            pull)
                pull_repo "$dir" "$p" "$branch" "$param"
                ;;
            log)
                log_repo "$dir" "$p" "$branch" "$param"
                ;;
            status)
                status_repo "$dir" "$p" "$branch" "$param"
                ;;
            *)
                echo "Unknown action: $action"
                ;;
        esac
    done
}

# Pull repository
pull_repo() {
    local dir=$1
    local proj=$2
    local branch=$3
    local param=$4
    echo -e "\n$BGreen================== git pull $dir/$proj $branch ===================$Color_Off"
    cd $dir/$proj
    
    git fetch -p origin

    if git show-ref --quiet refs/heads/$branch-new; then
        # echo "Deleting existing branch $branch-new"
        git checkout --detach
        git branch -D $branch-new
    fi

    echo "Creating new branch $branch-new"
    git checkout -b $branch-new

    git branch -D $branch
    git branch -m $branch
    git gc
}

# Log repository
log_repo() {
    local dir=$1
    local proj=$2
    local branch=$3
    local param=$4
    echo -e "\n$BGreen================== git log $dir/$proj $branch|head -20==================$Color_Off"
    cd $dir/$proj
    echo "`pwd` git log $proj $branch|head -20"
    git log --oneline --graph --decorate --all
}

# Status repository
status_repo() {
    local dir=$1
    local proj=$2
    local branch=$3
    local param=$4

    cd $dir/$proj
    git fetch origin
    status_msg=$(git status)
    discarded=$(echo $status_msg | grep "nothing to commit, working tree clean")
    no_commit=$?
    
    discarded=$(echo $status_msg | grep "Your branch is up to date with 'origin/$branch'")
    upto_dt=$?
    
    if [ $no_commit -eq 0 -a $upto_dt -eq 0 ]; then
        echo -e "\n$BGreen================== git status $dir/$proj $branch==================$Color_Off"
        echo "Working tree clean"
    else
        echo -e "\n$Red================== git status $dir/$proj $branch==================$Color_Off"
    fi
    git status
}

# source git_projs.sh
source /d/data/bin/git_projs.sh
curr=`pwd`
param=''

if [ $# -lt 1 ]; then
    display_usage
fi

while getopts ":hlsr" opt; do
    case $opt in
        h)
            display_usage
            ;;
        l)
            shift && action="log" && param=$1
            ;;
        s)
            shift && action="status" && param=$1
            ;;
        r)
            shift && action="pull" && param=$1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            display_usage
            ;;
    esac
done

shift $((OPTIND - 1))
refresh_repos
cd $curr

echo -e "\n$BGreen================== git_util.sh done ==================$Color_Off"
```
