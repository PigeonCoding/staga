
package staga

import "core:fmt"
import "core:slice"
import "core:strconv"

macro_def :: struct {
  name:    string,
  content: []instr,
}
parse_instrs :: proc(
  index: ^int,
  token_list: []Token,
  tmp_instrs: ^[dynamic]instr,
  delimiter: string = " ",
  is_macro: bool = false,
) {
  stack_len := 0
  base := len(tmp_instrs)

  tmp_macro := [dynamic]instr{}
  defer delete(tmp_macro)

  if_stack := [dynamic]int{}
  defer delete(if_stack)
  while_stack := [dynamic]int{}
  defer delete(while_stack)

  macro_list := [dynamic]macro_def{}
  defer delete(macro_list)
  current_instr := 0

  for index^ < len(token_list) {

    num := false
    #partial switch _ in token_list[index^].content {
    case int:
      num = true
    }
    if !num && delimiter != " " && token_list[index^].content.(string) == delimiter do break


    st: instr = {
      data = "",
    }

    if !num &&
       (token_list[index^].content.(string) == "\n" ||
           token_list[index^].content.(string) == " " ||
           token_list[index^].content.(string) == "\r" ||
           token_list[index^].content.(string) == "\t" ||
           token_list[index^].content.(string) == "") {
      index^ += 1
      continue
    }

    skip := false

    if !num && token_list[index^].content.(string) == "if" {
      st = {
        instr_id  = n_instr.nif,
        data_type = n_type.cjmp,
      }
      stack_len -= 1
      append(&if_stack, current_instr - base)
    } else if !num && token_list[index^].content.(string) == "else" {
      st = {
        instr_id  = n_instr.nelse,
        data_type = n_type.cjmp,
      }
      tmp_instrs[pop(&if_stack)].data = current_instr - base
      append(&if_stack, current_instr - base)
    } else if !num && token_list[index^].content.(string) == "done" {
      st = {
        instr_id  = n_instr.ndone,
        data_type = n_type.cjmp,
      }
      tmp_instrs[pop(&if_stack)].data = current_instr
    } else if !num && token_list[index^].content.(string) == "dup" {
      st = {
        instr_id  = n_instr.dup,
        data_type = n_type.ops,
      }
      stack_len += 1
    } else if !num && token_list[index^].content.(string) == "while" {
      st = {
        instr_id  = n_instr.nwhile,
        data_type = n_type.cjmp,
      }
      append(&while_stack, stack_len)
      append(&while_stack, current_instr - base)
    } else if !num && token_list[index^].content.(string) == "do" {
      st = {
        instr_id  = n_instr.ndo,
        data_type = n_type.cjmp,
      }
      append(&while_stack, current_instr - base)
      stack_len -= 1

    } else if !num && token_list[index^].content.(string) == "end" {
      st = {
        instr_id  = n_instr.nend,
        data_type = n_type.cjmp,
      }
      do_i := pop(&while_stack)
      while_i := pop(&while_stack)
      tmp_instrs[do_i].data = current_instr - base
      old_stack := pop(&while_stack)

      // TODO: check for stack size before and after loop but with macros
      // cause for now they are broken
      st.data = while_i
      tmp_instrs[do_i].data = current_instr - base
    } else if !num && token_list[index^].content.(string) == "mems" {
      st = {
        instr_id  = n_instr.nmems,
        data_type = n_type.mem,
      }
      stack_len -= 2
    } else if !num && token_list[index^].content.(string) == "meml" {
      st = {
        instr_id  = n_instr.nmeml,
        data_type = n_type.mem,
      }
    } else if !num && token_list[index^].content.(string) == "swap" {
      st = {
        instr_id  = n_instr.swap,
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if num {
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index^].content.(int),
        data_type = n_type.nint,
      }
      stack_len += 1
    } else if !num && token_list[index^].content.(string) == "macro" {
      // TODO: nested macros are not supported yet
      index^ += 1
      clear(&tmp_macro)

      mac := macro_def {
        name = token_list[index^].content.(string),
      }
      index^ += 1

      parse_instrs(index, token_list, &tmp_macro, "mend", true)
      mac.content = slice.clone(tmp_macro[:])

      index^ += 1
      append(&macro_list, mac)
      continue

    } else if !num && token_list[index^].content.(string) == "pop" {
      st = {
        instr_id  = n_instr.pop,
        data      = "",
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if !num && token_list[index^].content.(string) == "stack" {
      st = {
        instr_id  = n_instr.stack,
        data      = "",
        data_type = n_type.mem,
      }

    } else if !num && token_list[index^].content.(string) == "int3" {
      st = {
        instr_id  = n_instr.int3,
        data      = "",
        data_type = n_type.ops,
      }
    } else if !num && token_list[index^].content.(string) == "." {
      st = {
        instr_id  = n_instr.dot,
        data      = "",
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if !num && token_list[index^].content.(string) == "print" {
      st = {
        instr_id  = n_instr.print,
        data      = "",
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else {
      switch token_list[index^].content.(string)[0] {
      case '"':
        st = {
          instr_id  = n_instr.push,
          data      = token_list[index^].content,
          data_type = n_type.nstring,
        }
        stack_len += 1
      case '+':
        st = {
          instr_id  = n_instr.add,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case '-':
        st = {
          instr_id  = n_instr.minus,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case '*':
        st = {
          instr_id  = n_instr.mult,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case '/':
        st = {
          instr_id  = n_instr.div,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case '=':
        st = {
          instr_id  = n_instr.eq,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case '>':
        st = {
          instr_id  = n_instr.gr,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case '<':
        st = {
          instr_id  = n_instr.less,
          data_type = n_type.ops,
        }
        stack_len -= 1
      case:
        if st.instr_id == n_instr.none {
          f := false
          for macro in macro_list {
            if macro.name == token_list[index^].content {
              // fmt.println(macro.name)
              nn := current_instr
              for ins in macro.content {
                k := ins
                if k.instr_id == n_instr.nif ||
                   k.instr_id == n_instr.nelse ||
                   k.instr_id == n_instr.ndo ||
                   k.instr_id == n_instr.nend {

                  k.data = k.data.(int) + nn
                }
                append(tmp_instrs, k)
                current_instr += 1
              }
              index^ += 1
              f = true
              break
            }
          }
          if f do continue
        }

      }
    }
    fmt.assertf(
      st.instr_id != n_instr.none,
      "unknown symbol {}:{}:{} '{}'",
      token_list[index^].file,
      token_list[index^].row,
      token_list[index^].col,
      token_list[index^].content,
    )


    // TODO: Make it work some day but with macros it's kinda tricky
    // a_assert(
    //   true,
    //   stack_len >= 0 || is_macro,
    //   "not enough element in the stack for this op '",
    //   st.data,
    //   "'",
    // )

    // fmt.println(macro_list)
    // for n in macro_list {
    //   fmt.println(n.name)
    //   for m in n.content {
    //     fmt.println(m)
    //   }
    // }

    append(tmp_instrs, st)

    current_instr += 1
    index^ += 1
  }

  a_assert(true, len(if_stack) == 0, "an if-else block was not closed")
}

