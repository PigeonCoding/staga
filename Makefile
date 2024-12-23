main-build: main.c
	clang ./main.c -g -Wall -Wextra -Wswitch-enum -o build/main
main-run: main-build
	./build/main
qbe-test: qbe-test.ssa
	qbe -o build/qbe/out.s qbe-test.ssa && cc build/qbe/out.s -o build/qb-test
	./build/qb-test