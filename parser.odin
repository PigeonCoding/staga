
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
  defer (delete(tmp_instrs))

  for index^ < len(token_list) {
    st: instr = {
      instr_id = n_instr.none,
      data     = "",
    }

    switch token_list[index^] {
    case "\n":
      index^ += 1
      continue
    case ")":
      if layer > 0 {
        if index^ < len(token_list) - 1 do index^ += 1
        break
      }
    case "(":
      index^ += 1
      parse_instrs(index, layer + 1)
    }

    if index^ >= len(token_list) - 1 do break


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

    index^ += 1
  }

  for n in tmp_instrs {
    append(&instr_list, n)
  }
}

