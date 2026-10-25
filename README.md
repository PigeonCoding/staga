# Staga
a stack-based programming language I am working on

## Plans:
- [x] Turing complete [implemented rule110](https://github.com/PigeonCoding/staga/commit/6f295e31349de59f7852529347ede943333f564a)
- [ ] Interoperability with other languages
- [x] functions (or something resembling them) ~~[macros were implemented](https://github.com/PigeonCoding/staga/commit/a637a6eb6fad3ad26093e13330ddb26119b2a2ee)~~ [functions have been implemented](https://github.com/PigeonCoding/staga/commit/a082cea6b1c9175e1813560378e2b7acffb6e5f9)
- [x] real functions with call frames, arguments, return values and recursion
- [x] static stack-underflow checking
- [x] sparse memory (map instead of a fixed 4096 slots)

## "Features":
### printing
```
"Hello, World" .           // string printing
69             .           // int printing
0xFF           .           // hex printing (also supports binary and octal)
-69            .           // int printing
-0.69          .           // float printing
1 2 3 stack    pop pop pop // prints the stack
```

### arithmetic
```
 -5 5 + .
 6 1  - .
 2 10 * .
 10 5 / .
```
`+` also concatenates two strings. `+ - * /` require both operands to be the
same type; mixing an int and a float is a runtime error (with a source location).

### Conditions
```
 5 10 < .
 5 10 > .
 5 5 =  .
 5 5 <= .
 5 5 >= .
```
Comparisons work on ints, floats and strings, and push `1` or `0`.

### Control Flow
```
 1 0 > if "yes"   else "no"         done . // if 1 > 0
 69 if "non-zero" else "it is zero" done . // if 69 != 0

 0 while dup < 100 do dup . 1 + end

 int3 "waited for you" .                   // halt program execution until the user presses enter
```

### stack manipulation
```
69 dup . .
1 2 3 2 swap . . // this swaps the top element with the 2nd one, aka 3 and 2 respectively in this case
1 pop            // deletes the top of the stack, aka the 1 in this example
```

### memory
Memory is a sparse map of integer slots. There is no fixed size, negative
indices are allowed, and reading a slot that was never written is a runtime
error instead of a silent zero.
```
 10 2 mems // stores 10 in memory no. 2
 2 meml .  // loads the value in memory no. 2 and prints it
```

### macros
Macros are the original jump-based implementation. They are expanded into the
caller's stack: no frame, no arguments, no return values. They are useful for
constants and small stack shuffles.
```
 macro test1_ // start of a macro named test1_
  69 dup .
  351 + .
 fend // end of the macro
 jmp test1_ // calling the macro
```

Their stack effect is inferred, so calling a macro with too few values is a
compile error:
```
 macro add_two + 2 + fend
 1 jmp add_two   // error: macro 'add_two' needs 2 values, but only 1 would be there
```

### functions
Functions have a real call frame: arguments, return values, locals on the
stack, and recursion.

Syntax: `fn <name> <number of arguments> <number of return values>`, the body,
then `fend`. Call with `call <name>` and leave the function with `ret`.

```
 fn add 2 1
   + ret
 fend
 2 3 call add .          // 5
```

Arguments are the top values on the stack when the function is called. `ret`
keeps the top `<number of return values>` values, drops everything else the
body left on the stack, and returns. That makes early returns and recursion
work:
```
 fn fib 1 1
   dup 2 < if
     1 ret
   done
   dup 1 - call fib
   2 swap 2 - call fib
   +
   ret
 fend
 10 call fib .           // 89
```

Calling a function with the wrong number of arguments, `call`ing a macro, or
`jmp`ing a function is reported with a source location.

### file loading
`load "name"` reads `name.stg` relative to the file that contains the `load`.
Functions and macros from the loaded file are available afterwards.
```
foo.stg
 macro something
   "foo" .
 fend

main.stg
 load "foo"
 jmp something
```

## Errors and checking
Before running, the whole program is checked:

- stack underflow (`pop`, `+`, `swap`, function arguments, ...)
- an `if` and its `else` must leave the same stack depth
- a loop body must preserve the loop's stack depth
- every function must end with `ret` and leave enough return values
- `call` / `jmp` must target an existing function / macro of the right kind
- unterminated `if` / `while` / function / macro and stray `else` / `done` / `end`
- duplicate function or macro names

Every diagnostic points at the source:
```
bad.stg:3:9: error: stack underflow: '+' needs 2 value(s), but only 1 would be on the stack
```

Runtime errors use the same format and include a call stack:
```
bad.stg:7:12: runtime error: division by zero
  call stack: div() fib()
```

## Tests
The test suite is written with Odin's `@test` attribute and builds the
interpreter once, then runs real programs against it:

```console
odin test tests
```

You can also run the tests in parallel:

```console
odin test tests -define:ODIN_TEST_THREADS=4
```

## How To Build:
first install [odin](https://odin-lang.org/)

this project vendors the shared lexer from
[pigeon.odin](https://github.com/PigeonCoding/pigeon.odin) in `thirdparty/lexer`.

then
```console
 odin run builder -- debug
 odin run builder -- release
 odin run builder -- all
```
The build is configured in `builder/main.odin` using [build_odin](https://github.com/PigeonCoding/build_odin), which is vendored in `builder/build_odin`.

## How to Use
### Note:
run:
```console
 // linux
 ./build/staga_debug examples/showcase.stg
 ./build/staga examples/showcase.stg

 // windows
 .\build\staga_debug examples\showcase.stg
 .\build\staga examples\showcase.stg
```
