# Staga
a stack-based programming language i am working on

## Plans:
- [x] turing complete [implemented rule110](https://github.com/PigeonCoding/staga/commit/6f295e31349de59f7852529347ede943333f564a)
- [ ] Interoperability with other languages
- [x] functions (or something resembling them) ~~[macros were implement](https://github.com/PigeonCoding/staga/commit/a637a6eb6fad3ad26093e13330ddb26119b2a2ee)~~ [functions have been implemented](https://github.com/PigeonCoding/staga/commit/a082cea6b1c9175e1813560378e2b7acffb6e5f9)

## "Features":
### printing
```
 "Hello, World" .       // string printing
 "nope"         print   // prints but no newline
 -69            .       // int printing
 stack                  // prints the stack
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
 fn test1_ // start of a macro names test1_
  69 dup . 
  351 + .
 fend // end of the macro
 jmp test1_ // calling the macro
```

### file loading
```
foo.stg
 fn something
  "foo" .
 fend

main.stg
 load "foo"
 jmp something
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
### Note:
run:
```console
 // linux
 ./build/staga_debug examples/showcase.stg
 ./build/staga examples/showcase.stg

 // windows
 .\build\staga_debug examples/showcase.stg
 .\build\staga examples/showcase.stg
```
