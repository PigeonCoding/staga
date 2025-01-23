#!/bin/bash

exec_and_log () { echo -- $1; $1; }

if [ ! -d "build" ]; then
 exec_and_log "mkdir -p build"
fi

if [ "$1" == "debug" ]; then
 exec_and_log "odin build . -debug -error-pos-style:unix -out:build/staga_debug -thread-count:4"
fi

if [ "$1" == "release" ]; then
 exec_and_log "odin build . -o:speed -error-pos-style:unix -out:build/staga -thread-count:4"
fi


if [ "$1" == "all" ]; then
 exec_and_log "odin build . -debug -error-pos-style:unix -out:build/staga_debug -thread-count:4" &
 exec_and_log "odin build . -o:speed -error-pos-style:unix -out:build/staga -thread-count:4" &&
 echo Done
fi

if [ "$1" == "" ]; then
 echo "ERROR: no command provided"
 echo "Usage:"
 echo "   $0 [debug|release]"
fi
