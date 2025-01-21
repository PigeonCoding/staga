
package staga

import "core:fmt"

builtin_funcs_name := []fn_skeleton {
  fn_skeleton{name = "println", arg_type = []n_type{.nint, .nstring}, consum_num = 1},
  fn_skeleton{name = ".", arg_type = []n_type{.nint, .nstring}, consum_num = 1},
  fn_skeleton{name = "print", arg_type = []n_type{.nint, .nstring}, consum_num = 1},
}

fn_skeleton :: struct {
  name:       string,
  arg_type:   []n_type,
  consum_num: int,
}


macro_def :: struct {
  name:    string,
  content: []instr,
}
parse_instrs :: proc(
  index: ^int,
  token_list: ^[dynamic]string,
  tmp_instrs: ^[dynamic]instr,
  delimiter: string = " ",
) {
  stack_len := 0

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

    if delimiter != " " && token_list[index^] == delimiter do break

    st: instr = {
      data = "",
    }

    if token_list[index^] == "\n" ||
       token_list[index^] == " " ||
       token_list[index^] == "\r" ||
       token_list[index^] == "" {
      index^ += 1
      continue
    }

    skip := false

    if token_list[index^] == "if" {
      st = {
        instr_id  = n_instr.nif,
        data_type = n_type.cjmp,
      }
      stack_len -= 1
      append(&if_stack, current_instr)
    } else if token_list[index^] == "else" {
      st = {
        instr_id  = n_instr.nelse,
        data_type = n_type.cjmp,
      }
      tmp_instrs[pop(&if_stack)].data = itos(current_instr)
      append(&if_stack, current_instr)
    } else if token_list[index^] == "done" {
      st = {
        instr_id  = n_instr.ndone,
        data_type = n_type.cjmp,
      }
      tmp_instrs[pop(&if_stack)].data = itos(current_instr)
    } else if token_list[index^] == "dup" {
      st = {
        instr_id  = n_instr.dup,
        data_type = n_type.ops,
      }
      stack_len += 1
    } else if token_list[index^] == "while" {
      st = {
        instr_id  = n_instr.nwhile,
        data_type = n_type.cjmp,
      }
      append(&while_stack, stack_len)
      append(&while_stack, current_instr)
    } else if token_list[index^] == "do" {
      st = {
        instr_id  = n_instr.ndo,
        data_type = n_type.cjmp,
      }
      append(&while_stack, current_instr)
      stack_len -= 1

    } else if token_list[index^] == "end" {
      st = {
        instr_id  = n_instr.nend,
        data_type = n_type.cjmp,
      }
      do_i := pop(&while_stack)
      while_i := pop(&while_stack)
      tmp_instrs[do_i].data = itos(current_instr)
      a_assert(true, stack_len == pop(&while_stack), "while block was not cleaned up")
      st.data = itos(while_i)
      tmp_instrs[do_i].data = itos(current_instr)
    } else if token_list[index^] == "mems" {
      st = {
        instr_id  = n_instr.nmems,
        data_type = n_type.mem,
      }
      stack_len -= 2
    } else if token_list[index^] == "meml" {
      st = {
        instr_id  = n_instr.nmeml,
        data_type = n_type.mem,
      }
    } else if token_list[index^] == "swap" {
      st = {
        instr_id  = n_instr.swap,
        data_type = n_type.ops,
      }
    } else if token_list[index^][0] == '-' && len(token_list[index^]) > 1 {
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index^],
        data_type = n_type.nint,
      }
      stack_len += 1
    } else if token_list[index^] == "macro" {
      index^ += 2
      shrink(&tmp_macro, 0)

      mac := macro_def {
        name = token_list[index^ - 1],
      }

      parse_instrs(index, token_list, &tmp_macro, "mend")
      mac.content = tmp_macro[:]

      index^ += 1
      append(&macro_list, mac)
      continue

    } else {
      switch token_list[index^][0] {
      case '0' ..= '9':
        st = {
          instr_id  = n_instr.push,
          data      = token_list[index^],
          data_type = n_type.nint,
        }
        stack_len += 1
      case '"':
        st = {
          instr_id  = n_instr.push,
          data      = token_list[index^],
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
          for fn in builtin_funcs_name {
            if token_list[index^] == fn.name {
              st = {
                instr_id  = n_instr.consume,
                data      = token_list[index^],
                data_type = n_type.fn,
              }
              stack_len -= fn.consum_num
            }
          }
        }
        if st.instr_id == n_instr.none {
          f := false
          for macro in macro_list {
            if macro.name == token_list[index^] {
              for ins in macro.content {
                append(tmp_instrs, ins)
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
    a_assert(true, st.instr_id != n_instr.none, "unknown symbol '", token_list[index^])

    a_assert(true, stack_len >= 0, "not enough element in the stack for this op '", st.data, "'")

    append(tmp_instrs, st)

    current_instr += 1
    index^ += 1
  }

  a_assert(true, len(if_stack) == 0, "an if-else block was not closed")
}
