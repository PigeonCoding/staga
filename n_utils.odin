package staga

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// int to string
itos :: proc(i: int) -> string {
  conv_buf := make([]byte, 8)
  defer delete_slice(conv_buf)
  return strings.clone(strconv.itoa(conv_buf, i))
}

// TODO: user fmt.assertf instead maybe?
a_assert :: proc(with_assert: bool, cond: bool, rest: ..string) {
  if !cond {
    fmt.print("ERROR: ")
    for m in rest {
      fmt.printf("{}", m)
    }
    fmt.printfln("")
    if with_assert do os.exit(1)
  }
}

check_type :: proc(l: ^lexer, expected: token_id) -> bool {
  if l.token.type != expected {
    fmt.eprintfln("%s:%d:%d expected {} but got {}", l.file, l.row + 1, l.col + 1, expected, l.token.type)
    // os.exit(1)
  }

  return l.token.type == expected
}


is_operand :: proc(c: byte) -> bool {
  return(
    c == '+' ||
    c == '-' ||
    c == '=' ||
    c == '/' ||
    c == '*' ||
    c == ':' ||
    c == '<' ||
    c == '>' \
  )
}
