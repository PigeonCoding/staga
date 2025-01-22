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
- [ ] compilable (bytecode) or transpilable
- [ ] Interoperability with other languages
- [x] functions (or something resembling them) [macros where implement](https://github.com/PigeonCoding/staga/commit/a637a6eb6fad3ad26093e13330ddb26119b2a2ee)

## "Features":
### printing
```
 "Hello, World" .       // string printing
 "nope"         print   // prints but no newline
 420            println # the same as .
 -69            .       # int printing
 stack "" .             // prints the stack (no new line at the end)
```

### arithmetics
```
 -5 5 + .
 6 1  - .
 2 10 * .
 10 5 / .
```

### Conditions
```
 5 10 < .
 5 10 > .
 5 5 =  .
```

### Control Flow
```
 1 0 > if "yes"   else "no"         done . // if 1 > 0
 69 if "non zero" else "it is zero" done . // if 69 != 0

 0 while dup < 100 do dup . 1 + end

 int3 "waited for you" .                   // halt program execution until user presseed enter
```

### stack manipulation
```
69 dup . .
1 2 3 2 swap . . // this swaps the top element with the 2th one aka 3 and 2 respectively in this case
1 pop            // deleted the top of the stack aka the 1 in this example
```

### memory
```
 10 2 mems // stores 10 in memory no 2
 2 meml .  // loads the value in memory no 2 and prints it
```

### macros
```
 macro test1_ // start of a macro names test1_
  69 dup . 
  351 + .
 mend // end of the macro
 test1_ // calling the macro
```

## How To Build:
first install [odin](https://odin-lang.org/)

then
```console
 ./build.sh debug
 ./build.sh release

 build.bat debug
 build.bat release

```
## How to Use
run:
```console
 // linux
 ./build/staga_debug run showcase.stg
 ./build/staga run showcase.stg

 // windows
 .\build\staga_debug run showcase.stg
 .\build\staga run showcase.stg
```
