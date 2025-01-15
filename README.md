# Staga
a stack-based programming language i am working on

## File Structure:
- tokenizer.odin: is a basic tokenizer
- n_utils.odin: a bunch of utils functions
- parser.odin: generates an instruction list to execute the program
- interpreter.odin: as the name suggests it interprets the instructions and executes them
- common.odin: a file containing common structs and global vars

## Plans:
- [ ] turing complete
- [ ] compilable (bytecode || assembly) or transpilable to another language
- [ ] odin fn calls or C fn calls (Interoperability)
- [ ] functions (or something resembling them)

## "Features":
### printing
```
 "Hello, World" . // string printing
 69 . # int printing (only unsigned)
```

### arithmetics
```
 5 + 5 "5 + 5: " print .
 6 - 1 "6 - 1: " print .
 2 * 10 "2 * 10: " print .
 10 / 5 "10 / 5: " print .
```

### Conditions
```
 5 < 10 "5 < 10: " print .
 5 > 10 "5 > 10: " print .
 5 = 5 "5 = 5: " print .
```

## How To Use:
build:
```console
 make build-debug
 make build-release
```

run:
```console
 ./build/staga run showcase.stg
 ./build/staga_debug run showcase.stg
```
