
package staga

import "core:fmt"

builtin_funcs_name := []fn_skeleton {
  fn_skeleton{name = "println", arg_type = []n_type{.nint, .nstring}},
  fn_skeleton{name = ".", arg_type = []n_type{.nint, .nstring}},
  fn_skeleton{name = "print", arg_type = []n_type{.nint, .nstring}},
}

fn_skeleton :: struct {
  name:     string,
  arg_type: []n_type,
}

parse_instrs :: proc(index: ^int, layer: int = 0) {
  tmp_instrs := [dynamic]instr{}
  defer delete(tmp_instrs)
  if_stack := [dynamic]int{}
  defer delete(if_stack)

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
    }

    switch token_list[index^][0] {
    case '0' ..= '9':
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index^],
        data_type = n_type.nint,
      }
    case '"':
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index^],
        data_type = n_type.nstring,
      }
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
          }
        }
      }
    }

    a_assert(
      true,
      st.instr_id != n_instr.none,
      "something fishy with ",
      token_list[index^],
      " : ",
      itos(index^),
    )

    append(&tmp_instrs, st)

    current_instr += 1
    index^ += 1
  }

  a_assert(true, len(if_stack) == 0, "an if-else block was not closed")

  for n in tmp_instrs {
    append(&instr_list, n)
  }
}

