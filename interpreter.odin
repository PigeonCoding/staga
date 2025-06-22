package staga

import "core:fmt"
import "core:os"
import "core:strings"

MEM_SIZE :: 1024 * 4

stack := [dynamic]str_int{}
mem := [MEM_SIZE]str_int{}

n := 0

interpret_instrs :: proc(instr_list: []instr, fn_list: []fn_def) {
  n += 1
  a_assert(true, n < 2000, "too much recusion try less")
  i : i64 = 0
  for i < auto_cast len(instr_list) {
    ins := instr_list[i]
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, ins.data)

    case n_instr.dup:
      val := pop(&stack)
      append(&stack, val)
      append(&stack, val)

    case n_instr.add:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, val.(f64) + pop(&stack).(f64))
      case i64:
        append(&stack, val.(i64) + pop(&stack).(i64))
      case string:
        val2 := pop(&stack)
        res := strings.concatenate(
          {val2.(string), val.(string)},
        )
        append(&stack, res)
      }

    case n_instr.minus:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, pop(&stack).(f64) - val.(f64))
      case i64:
        append(&stack, pop(&stack).(i64) - val.(i64))
      case string:
        assert(false, "string minus does not exist")
      }

    case n_instr.mult:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, pop(&stack).(f64) * val.(f64))
      case i64:
        append(&stack, pop(&stack).(i64) * val.(i64))
      case string:
        assert(false, "string mult does not exist")
      }

    case n_instr.div:
      val := pop(&stack)

      switch _ in val {
      case f64:
        append(&stack, pop(&stack).(f64) * val.(f64))
      case i64:
        append(&stack, pop(&stack).(i64) * val.(i64))
      case string:
        assert(false, "string mult does not exist")
      }

    case n_instr.eq:
      val := pop(&stack)

      switch _ in val {
      case f64:
        append(&stack, i64(pop(&stack).(f64) == val.(f64)))
      case i64:
        append(&stack, i64(pop(&stack).(i64) == val.(i64)))
      case string:
        assert(false, "string mult does not exist")
      }

    case n_instr.gr:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, i64(pop(&stack).(f64) < val.(f64)))
      case i64:
        append(&stack, i64(pop(&stack).(i64) < val.(i64)))
      case string:
        assert(false, "string mult does not exist")
      }

    case n_instr.less:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, i64(pop(&stack).(f64) > val.(f64)))
      case i64:
        append(&stack, i64(pop(&stack).(i64) > val.(i64)))
      case string:
        assert(false, "string mult does not exist")
      }


    case n_instr.gre:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, i64(pop(&stack).(f64) <= val.(f64)))
      case i64:
        append(&stack, i64(pop(&stack).(i64) <= val.(i64)))
      case string:
        assert(false, "string mult does not exist")
      }

    case n_instr.lesse:
      val := pop(&stack)
      switch _ in val {
      case f64:
        append(&stack, i64(pop(&stack).(f64) >= val.(f64)))
      case i64:
        append(&stack, i64(pop(&stack).(i64) >= val.(i64)))
      case string:
        assert(false, "string mult does not exist")
      }

    case n_instr.nif:
      if pop(&stack).(i64) == 0 {
        i = instr_list[i].data.(i64)
      }

    case n_instr.nelse:
      i = instr_list[i].data.(i64)

    case n_instr.ndone, n_instr.none, n_instr.nwhile:

    case n_instr.ndo:
      if pop(&stack).(i64) == 0 do i = instr_list[i].data.(i64)

    case n_instr.nend:
      i = instr_list[i].data.(i64)

    case n_instr.nmems:
      mem[pop(&stack).(i64)] = pop(&stack)

    case n_instr.nmeml:
      append(&stack, mem[pop(&stack).(i64)])

    case n_instr.swap:
      swap_num := pop(&stack).(i64)
      if swap_num > 1 {
        tmp := stack[len(&stack) - 1]
        stack[len(&stack) - 1] = stack[len(&stack) - auto_cast swap_num]
        stack[len(&stack) - auto_cast swap_num] = tmp
      }

    case n_instr.pop:
      _ = pop(&stack)

    case n_instr.stack:
      fmt.print("stack: ")
      for n, i in stack {
        fmt.print(n, "")
      }
      fmt.println()

    case n_instr.int3:
      // TODO: maybe do something better ? or remove it entirely
      buf: [1]byte
      _, err := os.read(os.stdin, buf[:])
      if err != nil {
        fmt.eprintln("err {}", err)
        os.exit(1)
      }

    case n_instr.dot:
      val := pop(&stack)

      switch _ in val {
      case f64:
        fmt.printfln("%f", val.(f64))
      case i64:
        fmt.println(val.(i64))
      case string:
        print_str(val.(string))
        fmt.println()
      }

    case n_instr.print:
      val := pop(&stack)

      switch _ in val {
      case f64:
        fmt.printf("%f", val.(f64))
      case i64:
        fmt.print(val.(i64))
      case string:
        print_str(val.(string))
      }

    case n_instr.jmp:
      for m in fn_list {
        if m.name == ins.data.(string) {
          interpret_instrs(m.content, fn_list)
        }
      }

    case:
      a_assert(true, false, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
    }
    i += 1

  }
  n -= 1
}

// i know this looks stupid but it's the best solution
// i have
print_str :: proc(str: string) {
  i := 0
  for i < len(str) {
    if (i == len(str) - 1 && str[i] == '"') || (i == 0 && str[i] == '"') {
      i += 1
      continue
    }
    if str[i] == '\\' && str[i + 1] == 'n' {
      fmt.println("")
      i += 1
    } else if str[i] == '\\' && str[i + 1] == 't' {
      fmt.print('\t')
      i += 1
    } else if str[i] == '\\' && str[i + 1] == 'r' {
      fmt.print('\r')
      i += 1
    } else if str[i] == '\\' && str[i + 1] == '"' {
      fmt.print('\"')
      i += 1
    } else {
      fmt.printf("%c", str[i])
    }

    i += 1
  }
}
