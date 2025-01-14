package lisp_esk

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

builtin_funcs := []builtin_fn {
  builtin_fn{name = []string{"println", "."}, n_consume = 1, fn = println},
  builtin_fn{name = []string{"print"}, n_consume = 1, fn = print},
}

builtin_fn :: struct {
  name:      []string,
  n_consume: int,
  fn:        proc(i: int) -> bool,
}

stack_struct :: struct {
  data: string,
  type: n_type,
}

stack := [dynamic]stack_struct{}

print :: proc(i: int) -> bool {
  to_print: string
  t := stack[len(stack) - 1].data
  z := i - 1
  #partial switch stack[len(stack) - 1].type {
  case n_type.nstring:
    to_print = t[1:(len(stack[len(stack) - 1].data) - 1)]
  case n_type.nint:
    to_print = t
  case:
    better_assert(true, false, "op not implemented ", itos(auto_cast instr_list[z].data_type))
  }
  print_str(to_print)
  pop(&stack)
  return len(stack) == 0
}

println :: proc(i: int) -> bool {
  print(i)
  fmt.println("")
  return len(stack) == 0
}

token_list := [dynamic]string{}
instr_list := [dynamic]instr{}

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
}

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

get_tokens :: proc(file: string) {
  tok: Tokenizer
  f_err: os.Error
  tok.res, f_err = read_file(file)
  if f_err != nil {
    fmt.eprintfln("could not read because {}", f_err)
    os.exit(1)
  }
  tok.len = len(tok.res)
  append(&token_list, "(")

  for tok.cursor < tok.len - 1 {append(&token_list, get_next_token(&tok))}

  append(&token_list, ")")
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

exec_relevant_fn :: proc(name: string, i: int) {
  for fn in builtin_funcs {
    for f in fn.name {
      if name == f {
        fn.fn(i)
      }
    }
  }
}

interpret_instrs :: proc() {
  for ins, i in instr_list {
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, stack_struct{data = ins.data, type = ins.data_type})
    case n_instr.consume:
      exec_relevant_fn(ins.data, i)
    case n_instr.add:
      val := strconv.atoi(stack[len(stack) - 1].data)
      val += strconv.atoi(instr_list[i].data)
      stack[len(stack) - 1].data = itos(val)
    case:
      better_assert(true, false, "instr not implemented ", itos(auto_cast ins.instr_id))
    }
  }
}

main :: proc() {

  get_tokens("test.stg")
  index := 0
  parse_instrs(&index)

  interpret_instrs()

}

