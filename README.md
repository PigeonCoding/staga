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
- [ ] compilable (bytecode)
- [ ] odin fn calls or C fn calls (Interoperability)
- [ ] functions (or something resembling them)

## "Features":
### printing
```
 "Hello, World" . // string printing
 "nope"         print // prints but no newline
 420            println # the same as .
 69             . # int printing (only unsigned)
```

### arithmetics
```
 5 + 5  .
 6 - 1  .
 2 * 10 .
 10 / 5 .
```

### Conditions
```
 5 < 10 .
 5 > 10 .
 5 = 5  .
```

### Control Flow
```
 1 if "yes" else "no" done .
 69 if "non zero" else "it is zero" done .
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
