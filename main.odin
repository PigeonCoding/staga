package staga

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"

stack_struct :: struct {
  data: string,
  type: n_type,
}

stack := [dynamic]stack_struct{}

token_list := [dynamic]string{}
instr_list := [dynamic]instr{}

n_instr_names := []string {
  "none",
  "consume",
  "push",
  "pop",
  "add",
  "minus",
  "mult",
  "div",
  "tmp",
  "eq",
}
n_instr :: enum {
  none,
  consume,
  push,
  pop,
  add,
  minus,
  mult,
  div,
  tmp,
  eq,
}

n_type_names := []string{"none", "string", "int", "ops", "fn"}
n_type :: enum {
  none,
  nstring,
  nint,
  ops,
  fn,
}

instr :: struct {
  instr_id:  n_instr,
  data:      string,
  data_type: n_type,
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
        data      = "",
        data_type = n_type.ops,
      }
    case:
      if st.instr_id == n_instr.none {
        for fn in builtin_funcs {
          for name in fn.name {
            if token_list[index^] == name {
              st = {
                instr_id  = n_instr.consume,
                data      = token_list[index^],
                data_type = n_type.fn,
              }
            }
          }
        }
      }
    }

    better_assert(
      false,
      st.instr_id != n_instr.none,
      "something fishy with ",
      token_list[index^],
      ":",
      itos(index^),
    )

    append(&tmp_instrs, st)

    index^ += 1
  }

  for n in tmp_instrs {
    append(&instr_list, n)
  }

}

exec_relevant_fn :: proc(st: instr, i: int) {
  better_assert(true, len(stack) > 0, "the stack is empty")
  for fn in builtin_funcs {
    for f in fn.name {
      if st.data == f && slice.contains(fn.args_type, stack[len(stack) - 1].type) {
        fn.fn(i)
        return
      }
    }
  }

  fmt.println(stack)
  better_assert(
    true,
    false,
    "no fn ",
    st.data,
    " for arg_type ",
    n_type_names[stack[len(stack) - 1].type],
  )
}

interpret_instrs :: proc() {
  for ins, i in instr_list {
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, stack_struct{data = ins.data, type = ins.data_type})
    case n_instr.consume:
      exec_relevant_fn(ins, i)
    case n_instr.add:
      val := strconv.atoi(stack[len(stack) - 1].data)
      val += strconv.atoi(instr_list[i].data)
      stack[len(stack) - 1].data = itos(val)
    case n_instr.eq:
      val1 := pop(&stack)
      val2 := pop(&stack)
      append(&stack, stack_struct{data = itos(val1 == val2), type = n_type.nint})
    case:
      better_assert(true, false, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
    }
  }
}

main :: proc() {
  if len(os.args) < 2 {
    fmt.eprintln("ERROR: no command provided")
    fmt.println("usage:")
    fmt.println(" *", os.args[0], "run <file> ----- runs the file")
    fmt.println(" * help ----- prints this message")
    os.exit(1)
  }
  if os.args[1] == "help" {
    fmt.println("usage:")
    fmt.println(" *", os.args[0], "run <file> ----- runs the file")
    fmt.println(" * help ----- prints this message")
    os.exit(0)
  }
  if os.args[1] == "run" {
    if len(os.args) < 3 {
      fmt.eprintln("ERROR: no file provided")
      fmt.println("usage:")
      fmt.println(" *", os.args[0], "run <file> ----- runs the file")
      fmt.println(" * help ----- prints this message")
      os.exit(1)
    }
    get_tokens(os.args[2], &token_list)
    index := 0
    parse_instrs(&index)

    interpret_instrs()
  }


}

