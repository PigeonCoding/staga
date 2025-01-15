build-debug: *.odin
	odin build . -debug -error-pos-style:unix -out:build/staga_debug -thread-count:4

build-release: *.odin
	odin build . -o:speed -error-pos-style:unix -out:build/staga -thread-count:4
