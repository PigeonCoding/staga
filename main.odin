package lisp_esk

import "core:fmt"
import "core:os"
import "core:strings"

func_names := []string{"print", "println"}

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

  for tok.cursor < tok.len - 1 {append(&token_list, get_next_token(&tok))}

}

parse_instrs :: proc() {

  index := 0
  for index < len(token_list) {
    // if index >= tok.len - 1 do break
    //fmt.printfln("{}", index)
    st: instr = {
      instr_id = n_instr.none,
      data     = "",
    }

    if token_list[index] == "(" || token_list[index] == ")" {
      index += 1
      continue
    }


    if is_numerical(token_list[index][0]) {
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index],
        data_type = n_type.nint,
      }
    } else if token_list[index][0] == '"' {
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index],
        data_type = n_type.nstring,
      }
    } else if token_list[index] == "+" {
      st = {
        instr_id  = n_instr.add,
        data      = token_list[index + 1],
        data_type = n_type.ops,
      }
      index += 1
    } else if token_list[index] == "-" {
      st = {
        instr_id  = n_instr.minus,
        data      = token_list[index + 1],
        data_type = n_type.ops,
      }
      index += 1

    } else if token_list[index] == "*" {

      st = {
        instr_id  = n_instr.mult,
        data      = token_list[index + 1],
        data_type = n_type.ops,
      }
      index += 1
    } else if token_list[index] == "/" {

      st = {
        instr_id  = n_instr.div,
        data      = token_list[index + 1],
        data_type = n_type.ops,
      }
      index += 1
    }

    if st.instr_id == n_instr.none {
      for fn in func_names {
        if token_list[index] == fn {
          st = {
            instr_id  = n_instr.consume,
            data      = token_list[index],
            data_type = n_type.fn,
          }
        }
      }
    }

    better_assert(true, st.instr_id != n_instr.none, "something fishy with ", token_list[index])

    append(&instr_list, st)

    index += 1
  }

}

print_str :: proc(str: string) {
  i := 0
  // fmt.print("{}", str[0])
  for i < len(str) {
    if str[i] == '\\' && str[i + 1] == 'n' {
      fmt.println("")
      i += 1
    } else if str[i] == '\\' && str[i + 1] == 't' {
      fmt.print("\t")
      i += 1
    } else {
      fmt.printf("%c", str[i])
    }

    i += 1
  }
}

main :: proc() {

  get_tokens("test.lsek")
  parse_instrs()

  fmt.println(instr_list)

  stack := [dynamic]string{}

  for ins, i in instr_list {
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, ins.data)
    case n_instr.consume:
      switch ins.data {
      case "print":
        to_print: string
        t := stack[i - 1]
        #partial switch instr_list[i - 1].data_type {
        case n_type.nstring:
          to_print = t[1:(len(stack[i - 1]) - 1)]
        case n_type.nint:
          for n in instr_list[i - 1].data {
            to_print = t
          }

        }
        print_str(to_print)
        pop(&stack)
        if len(stack) == 0 do break
      case "println":
        to_print: string
        t := stack[i - 1]
        #partial switch instr_list[i - 1].data_type {
        case n_type.nstring:
          to_print = t[1:(len(stack[i - 1]) - 1)]
        case n_type.nint:
          for n in instr_list[i - 1].data {
            to_print = t
          }

        }
        print_str(to_print)
        fmt.println("")
        pop(&stack)
        if len(stack) == 0 do break
      case:
        better_assert(true, false, "fn not implemented", ins.data)
      }
    case:
      better_assert(true, false, "instr not implemented ", itos(auto_cast ins.instr_id))
    }
  }
}

