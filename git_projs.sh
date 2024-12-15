#!/bin/sh

# set up proj related dir and branch
java_projs=/d/myjava
python_projs=/d/mypython

#repos root on local
declare -A projs=( 
  ["demo_copilot"]=$java_projs
)

# assume upstream branch associated is "origin/master". Otherwise specify it in the following array
#declare -A branches=( 
#  ["demo_copilot"]="master"
#)
