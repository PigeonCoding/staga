build: *.odin
	odin build . -debug -error-pos-style:unix -out:build/staga_debug -thread-count:4

run: build
	./build/staga_debug

build-release: *.odin
	odin build . -debug -o:speed -error-pos-style:unix -out:build/staga -thread-count:4
