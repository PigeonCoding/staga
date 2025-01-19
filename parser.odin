
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

parse_instrs :: proc(index: ^int, layer: int = 0) {
  stack_len := 0

  tmp_instrs := [dynamic]instr{}
  defer delete(tmp_instrs)
  if_stack := [dynamic]int{}
  defer delete(if_stack)
  while_stack := [dynamic]int{}
  defer delete(while_stack)

  current_instr := 0

  for index^ < len(token_list) {
    st: instr = {
      data = "",
    }

    // if index^ >= len(token_list) - 1 do break
    if token_list[index^] == "\n" || token_list[index^] == " " {
      index^ += 1
      continue
    }


    if token_list[index^] == "if" {
      // fmt.println("if")
      st = {
        instr_id  = n_instr.nif,
        data      = "",
        data_type = n_type.cjmp,
      }
      stack_len -= 1
      append(&if_stack, current_instr)
    } else if token_list[index^] == "else" {
      // fmt.println("else")
      st = {
        instr_id  = n_instr.nelse,
        data      = "",
        data_type = n_type.cjmp,
      }
      tmp_instrs[pop(&if_stack)].data = itos(current_instr)
      append(&if_stack, current_instr)
    } else if token_list[index^] == "done" {
      // fmt.println("done")
      st = {
        instr_id  = n_instr.ndone,
        data      = "",
        data_type = n_type.cjmp,
      }
      tmp_instrs[pop(&if_stack)].data = itos(current_instr)
    } else if token_list[index^] == "dup" {
      st = {
        instr_id  = n_instr.dup,
        data      = "",
        data_type = n_type.ops,
      }
      stack_len += 1
    } else if token_list[index^] == "while" {
      st = {
        instr_id  = n_instr.nwhile,
        data      = "",
        data_type = n_type.cjmp,
      }
      append(&while_stack, stack_len)
      append(&while_stack, current_instr)
    } else if token_list[index^] == "do" {
      st = {
        instr_id  = n_instr.ndo,
        data      = "",
        data_type = n_type.cjmp,
      }
      append(&while_stack, current_instr)
      stack_len -= 1

    } else if token_list[index^] == "end" {
      st = {
        instr_id  = n_instr.nend,
        data      = "",
        data_type = n_type.cjmp,
      }
      do_i := pop(&while_stack)
      while_i := pop(&while_stack)
      tmp_instrs[do_i].data = itos(current_instr)
      a_assert(true, stack_len == pop(&while_stack), "while block was not cleaned up")
      st.data = itos(while_i)
      tmp_instrs[do_i].data = itos(current_instr)
    }

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
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
    case '-':
      st = {
        instr_id  = n_instr.minus,
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
    case '*':
      st = {
        instr_id  = n_instr.mult,
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
    case '/':
      st = {
        instr_id  = n_instr.div,
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
    case '=':
      st = {
        instr_id  = n_instr.eq,
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
    case '>':
      st = {
        instr_id  = n_instr.gr,
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
    case '<':
      st = {
        instr_id  = n_instr.less,
        data      = token_list[index^ + 1],
        data_type = n_type.ops,
      }
      index^ += 1
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
    }

    a_assert(true, st.instr_id != n_instr.none, "something fishy with '", token_list[index^], "'")

    a_assert(true, stack_len >= 0, "not enough element in the stack for this op '", st.data, "'")

    append(&tmp_instrs, st)

    current_instr += 1
    index^ += 1
  }

  a_assert(true, len(if_stack) == 0, "an if-else block was not closed")

  for n in tmp_instrs {
    append(&instr_list, n)
  }
}

