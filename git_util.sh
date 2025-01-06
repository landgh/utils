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
    echo "refreshing git repos with $@"
    for p in ${!projs[@]}; do
        dir=${projs[$p]}
        branch=${branches[$p]=master}
        ok=0
        if [ "$param" -a "$param" = "$p" ]; then
            ok=1
        elif [ "$param" ]; then
            continue
        fi

        if [ $action = "pull" ]; then
            pull $dir $p $branch $param
        elif [ $action = "log" ]; then
            #echo "getting log $dir $p $branch $param ........"
            log $dir $p $branch $param
        elif [ $action = "status" ]; then
            #echo "getting status $dir $p $branch $param ........"
            status $dir $p $branch $param
        fi
        
        if [ $ok -eq 1 ]; then
            break
        fi
    done
}

pull() {
    path=$1
    p=$2
    branch=$3
    echo -e "\n$BGreen================== git pull $path/$p $branch==================$Color_Off"
    git checkout $branch
    
    cd $path/$p
    git fetch -p origin

    if git show-ref --quite refs/heads/$branch-new; then
        git branch -D $branch-new
    fi

    git checkout -b $branch-new origin
    git branch -D $branch
    git branch -m $branch
    git gc
}

log () {
    path=$1
    p=$2
    branch=$3
    echo -e "\n$BGreen================== git log $path/$p $branch|head -20==================$Color_Off"
    cd $path/$p
    echo "`pwd` git log $p $branch|head -20"
    git log --oneline --graph --decorate --all
}

status() {
    path=$1
    p=$2
    branch=$3

    cd $path/$p
    git fetch origin
    status_msg=$(git status)
    discarded=$(echo $status_msg | grep "nothing to commit, working tree clean")
    no_commit=$?
    
    discarded=$(echo $status_msg | grep "Your branch is up to date with 'origin/$3'")
    upto_dt=$?
    
    if [ $no_commit -eq 0 -a $upto_dt -eq 0 ]; then
        echo -e "\n$BGreen================== git status $path/$p $branch==================$Color_Off"
        echo "Working tree clean"
    else
        echo -e "\n$Red================== git status $path/$p $branch==================$Color_Off"
    fi
    git status
    #echo -e "\n$$Color_Off"
}

# source git_projs.sh
source /d/data/bin/git_projs.sh
curr=`pwd`
param=''

if [ $# -lt 1 ]; then
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