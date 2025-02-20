package staga

import "core:fmt"
import "core:os"

print_help :: proc(msg: string = "") {
  fmt.eprintln(msg)
  fmt.println("usage", os.args[0], ":")
  fmt.println(" * <file.stg>        ----- runs the file")
  fmt.println(" * help              ----- prints this message")
}

main :: proc() {
  if len(os.args) < 2 {
    print_help("ERROR: no command provided")
    os.exit(1)
  }
  if os.args[1] == "help" {
    print_help()
    os.exit(0)
  } else {
    if len(os.args) < 2 {
      print_help("ERROR: no file provided")
      os.exit(1)
    }

    token_list := [dynamic]Token{}
    defer delete(token_list)
    get_tokens(os.args[1], &token_list)
    // print_tokens(token_list[:])
    // fmt.println(token_list)

    index := 0
    parse := [dynamic]instr{}
    defer delete(parse)

    ins := 0
    mac := [dynamic]fn_def{}
    parse_instrs(&index, token_list[:], &parse, &ins, &mac)
    // TODO: macros are jmped to so inlining after everything is
    // parsed was a lil faster but for now it's fine

    // fmt.println(parse)

    interpret_instrs(parse[:], mac[:])
  }
}

