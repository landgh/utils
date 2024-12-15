#!/bin/sh

Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red
BGreen='\033[1;32m'       # Green

display() {
    echo "Usage: . git_refresh.sh -h|-l [proj]|r [proj]|-s [proj]"
    for p in ${!projs[@]}; do
        echo -e "  $BGreen${projs[$p]}/$p:$Red ${branches[$p]=master}$Color_Off"
    done | sort

    exit 0
}

refresh() {
    for p in ${!projs[@]}; do
        if [ "$1" == "$p" ]; then
            dir=${projs[$p]}
            branch=${branches[$p]=master}
            break
        fi

        if [ $action == "pull" ]; then
            pull $dir $p $branch $param
        elif [ $action == "log" ]; then
            log $dir $p $branch $param
        elif [ $action == "status" ]; then
            status $dir $p $branch $param
        fi    
    done
}

pull() {
    cd $1/$2
    echo -e "\n$BGreen================== git pull $2 $3==================$Color_Off"
    git checkout $3
    
    cd $1/$2
    git fetch -p origin

    if git show-ref --quite refs/heads/$3-new; then
        git branch -D $3-new
    fi

    git checkout -b $3-new origin
    git branch -D $3
    git branch -m $3
}

log () {
    echo -e "\n$BGreen================== git log $2 $3|head -20==================$Color_Off"
    cd $1/$2
    git log --oneline --graph --decorate --all
}

status() {
    cd $1/$2
    git fetch origin
    status_msg=$(git status)
    discarded=$(echo $status_msg | grep "nothing to commit, working tree clean")
    no_commit=$?
    
    discarded=$(echo $status_msg | grep "Your branch is up to date with 'origin/$3'")
    upto_dt=$?
    
    if [ $no_commit -eq 0 -a $upto_dt -eq 0]; then
        echo -e "\n$BGreen================== git status $2 $3==================$Color_Off"
        echo "Working tree clean"
    else
        echo -e "\n$Red================== git status $2 $3==================$Color_Off"
    fi
    git status
 
    echo -e "\n$BGreen================== git status $2 $3==================$Color_Off"
    git status

    echo -e "\n$$Color_Off"
}

# source git_projs.sh
source /d/data/bin/git_projs.sh
curr=`pwd`
param=''

if [ $# -lt 1]; then
    display
fi

while getopts ":hlsr" opt; do
    case $opt in
        h)
            display
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
            display
            ;;
    esac
done

shift $((OPTIND - 1))
refresh
cd $curr

echo -e "\n$BGreen================== git_util.sh done ==================$Color_Off"