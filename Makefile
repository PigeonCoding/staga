main-build: main.c
	clang ./main.c -g -Wall -Wextra -Wswitch-enum -o build/main
main-run: main-build
	./build/main