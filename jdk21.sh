#!/bin/sh

export JAVA_HOME=/c/app/jdk-21.0.5
export GRADLE_HOME=/c/app/gradle-8.1.1
CLEANED_PATH=$(echo $PATH|tr ':' '\n'|grep -v 'jdk'|grep -v 'gradle'|tr '\n' ':')
export PATH=$JAVA_HOME/bin:$GRADLE_HOME/bin:$CLEANED_PATH