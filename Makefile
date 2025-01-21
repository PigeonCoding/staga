linux-debug: *.odin
	odin build . -debug -error-pos-style:unix -out:build/staga_debug -thread-count:4

linux-release: *.odin
	odin build . -o:speed -error-pos-style:unix -out:build/staga -thread-count:4

windows-debug: *.odin
	odin build . -debug -error-pos-style:unix -out:build\staga_debug.exe -thread-count:4

windows-release: *.odin
	odin build . -o:speed -error-pos-style:unix -out:build\staga.exe -thread-count:4