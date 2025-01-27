package staga

import "core:fmt"
import "core:os"

print_help :: proc(msg: string = "") {
  fmt.eprintln(msg)
  fmt.println("usage", os.args[0], ":")
  fmt.println(" * run file.stg                  ----- runs the file")
  fmt.println(" * comp file.stg [out.odin]      ----- transpiles to odin file")
  fmt.println(" * help                          ----- prints this message")
}

print_tokens :: proc(tokens: []Token) {
  for t in tokens {
    if t.content == "\n" || t.content == " " || t.skip == true do continue
    fmt.printfln("{}:{}:{} {}", t.file, t.row, t.col, t.content)
  }
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

    token_list := [dynamic]Token{}
    defer delete(token_list)
    get_tokens(os.args[2], &token_list)
    // print_tokens(token_list[:])
    // fmt.println(token_list)

    // return

    index := 0
    parse := [dynamic]instr{}
    defer delete(parse)

    parse_instrs(&index, token_list[:], &parse)
    // fmt.println(parse)

    interpret_instrs(parse[:])
  } else {
    print_help("invalid command")
    os.exit(1)
  }
}

