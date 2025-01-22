package staga

import "core:fmt"
import "core:os"

print_help :: proc(msg: string = "") {
  fmt.eprintln(msg)
  fmt.println("usage:")
  fmt.println(" *", os.args[0], "run <file> ----- runs the file")
  fmt.println(" * help ----- prints this message")
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
    // fmt.println(token_list)

    index := 0
    parse := [dynamic]instr{}
    defer delete(parse)

    parse_instrs(&index, &token_list, &parse)
    // fmt.println("parsed:" parse)

    // for n, i in parse {
    //   fmt.println(i, n)
    // }

    interpret_instrs(&parse)
  } else {
    print_help("invalid command")
    os.exit(1)
  }
}

