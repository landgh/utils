#!/bin/sh

# set up proj related dir and branch
java_projs=/d/myjava
python_projs=/d/mypython

#repos root on local
declare -A projs=( 
  ["demo_copilot"]=$java_projs
  ["python_best"]=$python_projs
)

# support multiple branches for each project
declare -A branches=( 
  ["demo_copilot"]="master feature1 feature2"
  ["python_best"]="master feature"
)
