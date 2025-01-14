package lisp_esk

import "core:fmt"
import "core:os"
import "core:strconv"

conv_buf_cont := [dynamic]([8]byte){}

itos :: proc(i: int) -> string {
  conv_buf: [8]byte
  append(&conv_buf_cont, conv_buf)
  return strconv.itoa(conv_buf_cont[len(conv_buf_cont) - 1][:], i)
}

better_assert :: proc(with_assert: bool, cond: bool, rest: ..string) {
  if !cond {
    for m in rest {
      fmt.printf("{}", m)
    }
    fmt.printfln("")
    if with_assert do assert(false, "")
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
  return c == ' ' || c == '\t' || c == '\n'
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

