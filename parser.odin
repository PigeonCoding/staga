package staga

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

fn_def :: struct {
  name:    string,
  content: []instr,
}

parse_instrs_intern :: proc(
  instrs: ^[dynamic]instr,
  fn_list: ^[dynamic]fn_def,
  current_instr: ^uint,
  file: string,
  lex: ^lexer = nil,
  delimiter: string = "",
  is_fn: bool = false,
) {
  ins_cnt: int = 0

  if_stack := [dynamic]int{}
  defer delete(if_stack)
  while_stack := [dynamic]int{}
  defer delete(while_stack)

  stack_len: int = 0
  l: lexer

  if lex == nil {
    l = init_lexer(file)
    get_token(&l)
  } else {
    get_token(lex)
    l.file = lex.file
  }


  for l.token.type != .either_end_or_failure {
    if lex != nil {
      l.row = lex.row
      l.col = lex.col
      l.file = lex.file
      l.token = lex.token
    }

    if l.token.str == delimiter && delimiter != "" do break

    st: instr
    #partial switch l.token.type {
    case .dqstring:
      st = {
        instr_id  = n_instr.push,
        data      = l.token.str,
        data_type = n_type.nstring,
      }
      stack_len += 1

    case .dot:
      st = {
        instr_id  = n_instr.dot,
        data      = "",
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .intlit:
      st = {
        instr_id  = n_instr.push,
        data      = l.token.int_lit,
        data_type = n_type.nint,
      }
      stack_len += 1

    case .minus_sign:
      // '-'
      st = {
        instr_id  = n_instr.minus,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .plus_sign:
      // '+'
      st = {
        instr_id  = n_instr.add,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .asterisk:
      // '*'
      st = {
        instr_id  = n_instr.mult,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .forward_slash:
      // '/'
      st = {
        instr_id  = n_instr.div,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .less_than_sign:
      // '<'
      st = {
        instr_id  = n_instr.less,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .greater_than_sign:
      // '>'
      st = {
        instr_id  = n_instr.gr,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .equals_sign:
      // '='
      st = {
        instr_id  = n_instr.eq,
        data_type = n_type.ops,
      }
      stack_len -= 1

    case .id:
      switch l.token.str {
      // keywords
      case "stack":
        st = {
          instr_id  = n_instr.stack,
          data      = "",
          data_type = n_type.mem,
        }

      case "pop":
        st = {
          instr_id  = n_instr.pop,
          data      = "",
          data_type = n_type.ops,
        }
        stack_len -= 1

      case "print":
        st = {
          instr_id  = n_instr.print,
          data      = "",
          data_type = n_type.ops,
        }
        stack_len -= 1

      case "if":
        st = {
          instr_id  = n_instr.nif,
          data_type = n_type.cjmp,
        }
        stack_len -= 1
        if is_fn do append(&if_stack, ins_cnt)
        else do append(&if_stack, auto_cast current_instr^)

      case "else":
        st = {
          instr_id  = n_instr.nelse,
          data_type = n_type.cjmp,
        }

        if is_fn do instrs[pop(&if_stack)].data = cast(i64)ins_cnt
        else do instrs[pop(&if_stack)].data = cast(i64)current_instr^

        if is_fn do append(&if_stack, ins_cnt)
        else do append(&if_stack, auto_cast current_instr^)

      case "done":
        st = {
          instr_id  = n_instr.ndone,
          data_type = n_type.cjmp,
        }

        if is_fn do instrs[pop(&if_stack)].data = cast(i64)ins_cnt
        else do instrs[pop(&if_stack)].data = cast(i64)current_instr^

      case "while":
        st = {
          instr_id  = n_instr.nwhile,
          data_type = n_type.cjmp,
        }

        append(&while_stack, stack_len)
        // else do append(&while_stack, auto_cast current_instr^)
        if is_fn do append(&while_stack, ins_cnt)
        else do append(&while_stack, auto_cast current_instr^)

      case "dup":
        st = {
          instr_id  = n_instr.dup,
          data_type = n_type.ops,
        }
        stack_len += 1

      case "do":
        st = {
          instr_id  = n_instr.ndo,
          data_type = n_type.cjmp,
        }
        if is_fn do append(&while_stack, ins_cnt)
        else do append(&while_stack, auto_cast current_instr^)

        stack_len -= 1

      case "end":
        st = {
          instr_id  = n_instr.nend,
          data_type = n_type.cjmp,
        }

        do_i := pop(&while_stack)
        while_i := pop(&while_stack)
        instrs[do_i].data = cast(i64)current_instr^
        _ = pop(&while_stack)

        // TODO: check for stack size before and after loop but with macros
        // cause for now they are broken
        st.data = cast(i64)while_i
        instrs[do_i].data = cast(i64)current_instr^


      case "swap":
        st = {
          instr_id  = n_instr.swap,
          data_type = n_type.ops,
        }
        stack_len -= 1

      case "mems":
        st = {
          instr_id  = n_instr.nmems,
          data_type = n_type.mem,
        }
        stack_len -= 2

      case "meml":
        st = {
          instr_id  = n_instr.nmeml,
          data_type = n_type.mem,
        }
        stack_len += 1

      case "fn":
        if lex == nil do get_token(&l)
        else do get_token(lex)

        if l.token.type == .either_end_or_failure || l.token.type == .null_char {
          fmt.eprintln("no fn name?")
          os.exit(1)
        }

        if lex == nil {
          if !check_type(&l, .id) do os.exit(1)
        } else {
          if !check_type(lex, .id) do os.exit(1)
        }

        mac := fn_def {
          name = l.token.str,
        }

        tmp_macro: [dynamic]instr
        parse_instrs_intern(&tmp_macro, fn_list, current_instr, file, &l, "fend", true)
        mac.content = tmp_macro[:]
        append(fn_list, mac)
        get_token(&l)
        continue

      case "jmp":
        if lex == nil do get_token(&l)
        else do get_token(lex)

        if lex == nil {
          if !check_type(&l, .id) do os.exit(1)
        } else {
          if !check_type(lex, .id) do os.exit(1)
        }

        st = {
          instr_id = n_instr.jmp,
          data     = l.token.str,
        }

      case "load":
        if lex == nil do get_token(&l)
        else do get_token(lex)

        if l.token.type == .either_end_or_failure || l.token.type == .null_char {
          fmt.eprintln("no import path specified")
          os.exit(1)
        }

        if lex == nil {
          if !check_type(&l, .dqstring) && !check_type(&l, .sqstring)  do os.exit(1)
        } else {
          if !check_type(lex, .dqstring) && !check_type(lex, .sqstring) do os.exit(1)
        }

        if l.token.str == "" || l.token.str == " " {
          fmt.eprintfln("%s:%d:%d expected a path but got an empty string", l.file, l.row, l.col)
          os.exit(1)
        }

        file_load_path: string
        if ODIN_OS == .Windows do file_load_path = strings.trim_right_proc(l.file, proc(t: rune) -> bool {
          return t != '\\'
        })
        else do file_load_path = strings.trim_right_proc(l.file, proc(t: rune) -> bool {
          return t != '/'
        })
        file_load_path = strings.concatenate({file_load_path, l.token.str, ".stg"})

        parse_instrs_intern(instrs, fn_list, current_instr, file_load_path, nil)

        if lex == nil do get_token(&l)
        else do get_token(lex)

        continue

      case:
        fmt.eprintfln("%s:%d:%d unknown id '{}'", l.file, l.row, l.col, l.token.str)
        os.exit(1)
      }

    case:
      fmt.eprintf("%s:%d:%d unknown ", l.file, l.row, l.col)
      fmt.println(l.token.type)
      os.exit(1)
    }

    append(instrs, st)

    if l.token.str == delimiter && is_fn do fmt.println("maybe")

    if lex == nil do get_token(&l)
    else do get_token(lex)

    if !is_fn do current_instr^ += 1
    else do ins_cnt += 1
  }
}

parse_instrs :: proc(
  instrs: ^[dynamic]instr,
  fn_list: ^[dynamic]fn_def,
  files: []string,
) {
  current_instr: uint = 0
  for file in files {
    parse_instrs_intern(instrs, fn_list, &current_instr, file, nil)
  }
}
