@echo off
if not exist ".\build" (
    echo "mkdir build"
    mkdir build
)

IF "%~1" == "debug" (
    echo "odin build . -debug -error-pos-style:unix -out:build\staga_debug.exe -thread-count:4"
    odin build . -debug -error-pos-style:unix -out:build\staga_debug.exe -thread-count:4
)
IF "%~1" == "release" (
    echo "odin build . -o:speed -error-pos-style:unix -out:build\staga.exe -thread-count:4"
    odin build . -o:speed -error-pos-style:unix -out:build\staga.exe -thread-count:4
)