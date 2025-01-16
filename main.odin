package staga

import "core:fmt"
import "core:os"

print_help :: proc(msg: string = "") {
  fmt.eprintln("ERROR: no command provided")
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
    get_tokens(os.args[2], &token_list)
    // fmt.println(token_list)

    index := 0
    parse_instrs(&index)
    // fmt.println(instr_list)

    interpret_instrs()
  } else {
    print_help("invalid command")
    os.exit(1)
  }
}

