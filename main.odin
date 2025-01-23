package staga

import "core:fmt"
import "core:os"

print_help :: proc(msg: string = "") {
  fmt.eprintln(msg)
  fmt.println("usage", os.args[0], ":")
  fmt.println(" *", "run file.stg                  ----- runs the file")
  fmt.println(" *", "bytecode input.stg [out.bstg] ----- compiles the given file to bytecode")
  fmt.println(" *", "exec file.bstg                ----- runs the file")
  fmt.println(" * help                          ----- prints this message")
}

main :: proc() {
  if len(os.args) < 2 {
    print_help("ERROR: no command provided")
    os.exit(1)
  }
  if os.args[1] == "help" {
    print_help()
    os.exit(0)
  } else if os.args[1] == "run" {
    if len(os.args) < 3 {
      print_help("ERROR: no file provided")
      os.exit(1)
    }

    token_list := [dynamic]string{}
    get_tokens(os.args[2], &token_list)

    index := 0
    parse := [dynamic]instr{}
    defer delete(parse)

    parse_instrs(&index, &token_list, &parse)

    interpret_instrs(parse[:])
  } else if os.args[1] == "bytecode" {
    if len(os.args) < 3 {
      print_help("ERROR: no file provided")
      os.exit(1)
    }
    path := "out.bstg"
    if len(os.args) == 4 do path = os.args[3]

    token_list := [dynamic]string{}
    defer delete(token_list)
    get_tokens(os.args[2], &token_list)

    index := 0
    parse := [dynamic]instr{}
    defer delete(parse)

    parse_instrs(&index, &token_list, &parse)

    bytecode_save(&parse, path)
  } else if os.args[1] == "exec" {

    if len(os.args) < 3 {
      print_help("ERROR: no file provided")
      os.exit(1)
    }

    path := os.args[2]

    new := bytecode_read(path)
    interpret_instrs(new)
  } else {
    print_help("invalid command")
    os.exit(1)
  }
}

