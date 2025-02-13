package staga

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"

MEM_SIZE :: 1024 * 4

stack := [dynamic]str_int{}
mem := [MEM_SIZE]str_int{}

interpret_instrs :: proc(instr_list: []instr) {
  i := 0
  for i < len(instr_list) {
    ins := instr_list[i]
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, ins.data)

    case n_instr.dup:
      val := pop(&stack)
      append(&stack, val)
      append(&stack, val)

    case n_instr.add:
      append(&stack, pop(&stack).(int) + pop(&stack).(int))

    case n_instr.minus:
      val := pop(&stack).(int)
      val2 := pop(&stack).(int)
      append(&stack, val2 - val)

    case n_instr.mult:
      append(&stack, pop(&stack).(int) * pop(&stack).(int))

    case n_instr.div:
      val := pop(&stack).(int)
      val2 := pop(&stack).(int)
      append(&stack, val2 / val)
    case n_instr.eq:
      append(&stack, cast(int)(pop(&stack).(int) == pop(&stack).(int)))

    case n_instr.gr:
      append(&stack, cast(int)(pop(&stack).(int) < pop(&stack).(int)))

    case n_instr.less:
      append(&stack, cast(int)(pop(&stack).(int) > pop(&stack).(int)))

    case n_instr.gre:
      append(&stack, cast(int)(pop(&stack).(int) <= pop(&stack).(int)))

    case n_instr.lesse:
      append(&stack, cast(int)(pop(&stack).(int) >= pop(&stack).(int)))

    case n_instr.nif:
      if pop(&stack).(int) == 0 {
        i = instr_list[i].data.(int)
      }

    case n_instr.nelse:
      i = instr_list[i].data.(int)

    case n_instr.ndone, n_instr.none, n_instr.nwhile:

    case n_instr.ndo:
      if pop(&stack).(int) == 0 do i = instr_list[i].data.(int)

    case n_instr.nend:
      i = instr_list[i].data.(int)

    case n_instr.nmems:
      mem[pop(&stack).(int)] = pop(&stack)

    case n_instr.nmeml:
      // check_type(n_type.nint, n_instr_names[n_instr.nmeml])
      // val := pop(&stack)
      append(&stack, mem[pop(&stack).(int)])

    case n_instr.swap:
      // check_type(n_type.nint, n_instr_names[n_instr.swap])
      swap_num := pop(&stack).(int)
      if swap_num > 1 {
        tmp := stack[len(&stack) - 1]
        stack[len(&stack) - 1] = stack[len(&stack) - swap_num]
        stack[len(&stack) - swap_num] = tmp
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
      buf: [1]byte
      _, err := os.read(os.stdin, buf[:])
      if err != nil {
        fmt.eprintln("err {}", err)
        os.exit(1)
      }

    case n_instr.dot:
      val := pop(&stack)

      switch _ in val {
      case int:
        fmt.println(val.(int))
      case string:
        print_str(val.(string)[1:len(val.(string)) - 1])
        fmt.println()
      }

    case n_instr.print:
      val := pop(&stack)

      switch _ in val {
      case int:
        fmt.print(val.(int))
      case string:
        print_str(val.(string)[1:len(val.(string)) - 1])
      }
    case:
      a_assert(true, false, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
    }
    i += 1

  }
}

// i know this looks stupid but it's the best solution
// i have
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
    } else if str[i] == '\\' && str[i + 1] == '"' {
      fmt.print("\"")
      i += 1
    } else {
      fmt.printf("%c", str[i])
    }

    i += 1
  }
}

