build: *.odin
	odin build . -debug -error-pos-style:unix -out:build/nirop_debug -thread-count:4

run: build
	./build/nirop_debug

build-release: *.odin
	odin build . -debug -o:speed -error-pos-style:unix -out:build/nirop -thread-count:4
