
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


// package staga

// import "core:fmt"

// builtin_funcs := []builtin_fn {
//   builtin_fn{name = []string{"println", "."}, fn = nprintln_str, args_type = []n_type{.nstring}},
//   builtin_fn{name = []string{"println", "."}, fn = nprintln_int, args_type = []n_type{.nint}},
//   builtin_fn{name = []string{"print"}, fn = nprint_str, args_type = []n_type{.nstring}},
//   builtin_fn{name = []string{"print"}, fn = nprint_int, args_type = []n_type{.nint}},
// }

// // builtin_fn :: struct {
// //   name:      []string,
// //   fn:        proc(i: int) -> bool,
// //   args_type: []n_type,
// // }


// // instr :: struct {
// //   instr_id:  n_instr,
// //   data:      string,
// //   data_type: n_type,
// // }

// // parse_instrs :: proc(token_list: ^[]string, index: ^int, layer: int = 0) {
// //   tmp_instrs := [dynamic]instr{}
// //   defer (delete(tmp_instrs))

// //   for index^ < len(token_list) {
// //     st: instr = {
// //       instr_id = n_instr.none,
// //       data     = "",
// //     }

// //     switch token_list[index^] {
// //     case "\n":
// //       index^ += 1
// //       continue
// //     case ")":
// //       if layer > 0 {
// //         if index^ < len(token_list) - 1 do index^ += 1
// //         break
// //       }
// //     case "(":
// //       index^ += 1
// //       parse_instrs(token_list, index, layer + 1)
// //     }

// //     if index^ >= len(token_list) - 1 do break


// //     switch token_list[index^][0] {
// //     case '0' ..= '9':
// //       st = {
// //         instr_id  = n_instr.push,
// //         data      = token_list[index^],
// //         data_type = n_type.nint,
// //       }
// //     case '"':
// //       st = {
// //         instr_id  = n_instr.push,
// //         data      = token_list[index^],
// //         data_type = n_type.nstring,
// //       }
// //     case '+':
// //       st = {
// //         instr_id  = n_instr.add,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case '-':
// //       st = {
// //         instr_id  = n_instr.minus,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case '*':
// //       st = {
// //         instr_id  = n_instr.mult,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case '/':
// //       st = {
// //         instr_id  = n_instr.div,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case '=':
// //       st = {
// //         instr_id  = n_instr.eq,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case '>':
// //       st = {
// //         instr_id  = n_instr.gr,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case '<':
// //       st = {
// //         instr_id  = n_instr.less,
// //         data      = token_list[index^ + 1],
// //         data_type = n_type.ops,
// //       }
// //       index^ += 1
// //     case:
// //       if st.instr_id == n_instr.none {
// //         for fn in builtin_funcs {
// //           for name in fn.name {
// //             if token_list[index^] == name {
// //               st = {
// //                 instr_id  = n_instr.consume,
// //                 data      = token_list[index^],
// //                 data_type = n_type.fn,
// //               }
// //             }
// //           }
// //         }
// //       }
// //     }

// //     better_assert(
// //       true,
// //       st.instr_id != n_instr.none,
// //       "something fishy with ",
// //       token_list[index^],
// //       " : ",
// //       itos(index^),
// //     )

// //     append(&tmp_instrs, st)

// //     index^ += 1
// //   }

// //   for n in tmp_instrs {
// //     append(&instr_list, n)
// //   }

// // }

// nprint_str :: proc(i: int) -> bool {
//   to_print := stack[len(stack) - 1].data[1:(len(stack[len(stack) - 1].data) - 1)]
//   print_str(to_print)
//   pop(&stack)
//   return len(stack) == 0
// }

// nprint_int :: proc(i: int) -> bool {
//   to_print := stack[len(stack) - 1].data
//   print_str(to_print)
//   pop(&stack)
//   return len(stack) == 0
// }

// nprintln_str :: proc(i: int) -> bool {
//   defer fmt.println()
//   return nprint_str(i)
// }

// nprintln_int :: proc(i: int) -> bool {
//   defer fmt.println()
//   return nprint_int(i)
// }

// print_str :: proc(str: string) {
//   i := 0
//   for i < len(str) {
//     if str[i] == '\\' && str[i + 1] == 'n' {
//       fmt.println("")
//       i += 1
//     } else if str[i] == '\\' && str[i + 1] == 't' {
//       fmt.print("\t")
//       i += 1
//     } else if str[i] == '\\' && str[i + 1] == 'r' {
//       fmt.print("\r")
//       i += 1
//     } else {
//       fmt.printf("%c", str[i])
//     }

//     i += 1
//   }
// }

