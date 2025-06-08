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
parse_instrs :: proc(
  index: ^int,
  token_list: []Token,
  instrs: ^[dynamic]instr,
  current_instr: ^int,
  fn_list: ^[dynamic]fn_def,
  delimiter: string = " ",
  is_fn: bool = false,
) -> int {
  stack_len := 0
  base := len(instrs)

  ins_cnt := 0

  tmp_macro := [dynamic]instr{}
  defer delete(tmp_macro)

  if_stack := [dynamic]int{}
  defer delete(if_stack)
  while_stack := [dynamic]int{}
  defer delete(while_stack)

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

      if is_fn do append(&if_stack, ins_cnt)
      else do append(&if_stack, current_instr^)

    } else if num {
      st = {
        instr_id  = n_instr.push,
        data      = token_list[index^].content.(int),
        data_type = n_type.nint,
      }
      stack_len += 1
    } else if token_list[index^].content.(string) == "else" {
      st = {
        instr_id  = n_instr.nelse,
        data_type = n_type.cjmp,
      }

      if is_fn do instrs[pop(&if_stack)].data = ins_cnt
      else do instrs[pop(&if_stack)].data = current_instr^

      if is_fn do append(&if_stack, ins_cnt)
      else do append(&if_stack, current_instr^)

    } else if token_list[index^].content.(string) == "done" {
      st = {
        instr_id  = n_instr.ndone,
        data_type = n_type.cjmp,
      }

      if is_fn do instrs[pop(&if_stack)].data = ins_cnt
      else do instrs[pop(&if_stack)].data = current_instr^

    } else if token_list[index^].content.(string) == "dup" {
      st = {
        instr_id  = n_instr.dup,
        data_type = n_type.ops,
      }
      stack_len += 1
    } else if token_list[index^].content.(string) == "while" {
      st = {
        instr_id  = n_instr.nwhile,
        data_type = n_type.cjmp,
      }
      append(&while_stack, stack_len)
      append(&while_stack, current_instr^)
    } else if token_list[index^].content.(string) == "do" {
      st = {
        instr_id  = n_instr.ndo,
        data_type = n_type.cjmp,
      }
      append(&while_stack, current_instr^)
      stack_len -= 1

    } else if token_list[index^].content.(string) == "end" {
      st = {
        instr_id  = n_instr.nend,
        data_type = n_type.cjmp,
      }
      do_i := pop(&while_stack)
      while_i := pop(&while_stack)
      instrs[do_i].data = current_instr^
      old_stack := pop(&while_stack)

      // TODO: check for stack size before and after loop but with macros
      // cause for now they are broken
      st.data = while_i
      instrs[do_i].data = current_instr^
    } else if token_list[index^].content.(string) == "mems" {
      st = {
        instr_id  = n_instr.nmems,
        data_type = n_type.mem,
      }
      stack_len -= 2
    } else if token_list[index^].content.(string) == "meml" {
      st = {
        instr_id  = n_instr.nmeml,
        data_type = n_type.mem,
      }
    } else if token_list[index^].content.(string) == "swap" {
      st = {
        instr_id  = n_instr.swap,
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if token_list[index^].content.(string) == "fn" {
      // TODO: nested macros are not supported yet
      index^ += 1
      clear(&tmp_macro)

      mac := fn_def {
        name = token_list[index^].content.(string),
      }
      index^ += 1

      parse_instrs(index, token_list, &tmp_macro, current_instr, fn_list, "fend", true)
      mac.content = slice.clone(tmp_macro[:])

      index^ += 1
      append(fn_list, mac)
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
    } else if token_list[index^].content == ">" {
      st = {
        instr_id  = n_instr.gr,
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if token_list[index^].content == "<" {
      st = {
        instr_id  = n_instr.less,
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if token_list[index^].content == ">=" {
      st = {
        instr_id  = n_instr.gre,
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if token_list[index^].content == "<=" {
      st = {
        instr_id  = n_instr.lesse,
        data_type = n_type.ops,
      }
      stack_len -= 1
    } else if token_list[index^].content == "load" {

      index^ += 1

      a_assert(
        true,
        token_list[index^].content.(string) != "\"\"",
        "load path is empty ",
        token_list[index^].file,
      )

      base_path := ""

      if runtime.Odin_OS_Type.Windows == os.OS do base_path = strings.trim_right_proc(token_list[index^].file, proc(t: rune) -> bool {
        return t != '\\'
      })
      else do base_path = strings.trim_right_proc(token_list[index^].file, proc(t: rune) -> bool {
        return t != '/'
      })
      base_path = strings.concatenate(
        {
          base_path,
          token_list[index^].content.(string)[1:len(token_list[index^].content.(string)) - 1],
          ".stg",
        },
      )

      // fmt.println(base_path)
      // assert(false)


      n_token_list := [dynamic]Token{}
      // defer delete(n_token_list)
      get_tokens(base_path, &n_token_list)
      // print_tokens(n_token_list[:])

      ind := 0
      parse_instrs(&ind, n_token_list[:], instrs, current_instr, fn_list)

      index^ += 1
      continue


    } else if token_list[index^].content.(string) == "jmp" {
      index^ += 1
      st = {
        instr_id = n_instr.jmp,
        data     = token_list[index^].content.(string),
      }

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
      case:
      // if st.instr_id == n_instr.none {
      //   f := false
      //   for macro in fn_list {
      //     if macro.name == token_list[index^].content {
      //       // fmt.println(macro.name)
      //       // nn := current_instr^
      //       // for ins in macro.content {
      //       //   k := ins
      //       //   if k.instr_id == n_instr.nif ||
      //       //      k.instr_id == n_instr.nelse ||
      //       //      k.instr_id == n_instr.ndo ||
      //       //      k.instr_id == n_instr.nend {

      //       //     k.data = k.data.(int) + nn
      //       //   }
      //       //   append(instrs, k)
      //       //   current_instr^ += 1
      //       // }
      //       index^ += 1
      //       f = true
      //       break
      //     }
      //   }
      //   // if f do continue
      // }

      }
    }


    {
      str := false
      #partial switch _ in token_list[index^].content {
      case string:
        str = true
      }
      if st.instr_id == n_instr.none && str {
        st.instr_id = n_instr.additional
        st.name = token_list[index^].content.(string)
        // os.exit(1)
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

    append(instrs, st)

    if !is_fn do current_instr^ += 1
    else do ins_cnt += 1
    index^ += 1
  }

  if_num := 0
  while_num := 0
  stack_len = 0

  // TODO: check for stack_len not < 0 after some instrs

  for ins in instrs {
    #partial switch ins.instr_id {
    case n_instr.nif:
      if_num += 1
    case n_instr.ndone:
      if_num -= 1
    case n_instr.ndo:
      while_num += 1
    case n_instr.nend:
      while_num -= 1
    case n_instr.push, n_instr.dup:
      stack_len += 1
    case n_instr.pop,
         n_instr.add,
         n_instr.minus,
         n_instr.mult,
         n_instr.div,
         n_instr.swap,
         n_instr.dot,
         n_instr.print,
         n_instr.gr,
         n_instr.less,
         n_instr.gre,
         n_instr.lesse,
         n_instr.eq:
      stack_len -= 1
    case n_instr.nmems:
      stack_len -= 2
    case n_instr.none,
         n_instr.nwhile,
         n_instr.int3,
         n_instr.stack,
         n_instr.nelse,
         n_instr.nmeml,
         n_instr.additional,
         n_instr.jmp:
      case:
        l: for n in custom_instrs {
          if n.name == ins.name {
            stack_len += n.stack_change
            break l 
          }
        }
    }
  }


  a_assert(true, if_num == 0, "an if-else block was not closed")
  a_assert(true, while_num == 0, "an while block was not closed")

  // fmt.println(fn_list)

  return current_instr^
}
