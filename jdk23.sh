#!/bin/sh

export JAVA_HOME=/c/app/jdk-23.0.1
export GRADLE_HOME=/c/app/gradle-8.1.1
CLEANED_PATH=$(echo $PATH|tr ':' '\n'|grep -v 'jdk'|grep -v 'gradle'|tr '\n' ':')
export PATH=$JAVA_HOME/bin:$GRADLE_HOME/bin:$CLEANED_PATH