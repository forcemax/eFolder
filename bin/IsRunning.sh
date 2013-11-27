#!/bin/bash

#  JJHWANG:  2004.09.13
#  This Program Checks to see whether the process by name (with args) is running
#  If the program is running, program exit with 1, otherwise, 0.

ARGS=$@

if [ "x$ARGS" == "x" ] ; then
	exit 0 
fi

RUNTEST=`ps -ef --columns=256 | grep -- "$ARGS" | grep -v IsRunning.sh | grep -v grep| awk '{print $2}' | wc -l` 

if [ $RUNTEST -gt 1 ] ; then
	RETURN=1
else
	RETURN=0
fi
exit $RETURN
