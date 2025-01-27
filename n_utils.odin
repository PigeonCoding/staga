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

read_file :: proc(file: string) -> (res: string, err: os.Error) {
  file, ferr := os.open(file)
  if ferr != nil {
    return "", ferr
  }
  defer os.close(file)

  buff_size, _ := os.file_size(file)
  buf := make([]byte, buff_size)
  for {
    n, _ := os.read(file, buf)
    if n == 0 do break
  }

  return string(buf), nil
}

is_whitespace :: proc(c: byte) -> bool {
  return c == ' ' || c == '\t' || c == '\r'
}

is_numerical :: proc(c: byte) -> bool {
  return c >= '0' && c <= '9'
}

is_alphabetical :: proc(c: byte) -> bool {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

is_alphanumerical :: proc(c: byte) -> bool {
  return is_numerical(c) || is_alphabetical(c)
}

is_operand :: proc(c: byte) -> bool {
  return c == '+' || c == '-' || c == '=' || c == '/' || c == '*' || c == ':'
}

