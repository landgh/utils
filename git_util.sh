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