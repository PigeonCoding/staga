package staga

import "core:fmt"

builtin_funcs := []builtin_fn {
  builtin_fn{name = []string{"println", "."}, fn = nprintln_str, args_type = []n_type{.nstring}},
  builtin_fn{name = []string{"println", "."}, fn = nprintln_int, args_type = []n_type{.nint}},
  builtin_fn{name = []string{"print"}, fn = nprint_str, args_type = []n_type{.nstring}},
  builtin_fn{name = []string{"print"}, fn = nprint_int, args_type = []n_type{.nint}},
}


builtin_fn :: struct {
  name:      []string,
  // n_consume: int,
  fn:        proc(i: int) -> bool,
  args_type: []n_type,
}


nprint_str :: proc(i: int) -> bool {
  to_print := stack[len(stack) - 1].data[1:(len(stack[len(stack) - 1].data) - 1)]
  print_str(to_print)
  pop(&stack)
  return len(stack) == 0
}

nprint_int :: proc(i: int) -> bool {
  to_print := stack[len(stack) - 1].data
  print_str(to_print)
  pop(&stack)
  return len(stack) == 0
}

nprintln_str :: proc(i: int) -> bool {
  defer fmt.println()
  return nprint_str(i)
}

nprintln_int :: proc(i: int) -> bool {
  defer fmt.println()
  return nprint_int(i)
}

print_str :: proc(str: string) {
  i := 0
  for i < len(str) {
    if str[i] == '\\' && str[i + 1] == 'n' {
      fmt.println("")
      i += 1
    } else if str[i] == '\\' && str[i + 1] == 't' {
      fmt.print("\t")
      i += 1
    } else if str[i] == '\\' && str[i + 1] == 'r' {
      fmt.print("\r")
      i += 1
    } else {
      fmt.printf("%c", str[i])
    }

    i += 1
  }
}

