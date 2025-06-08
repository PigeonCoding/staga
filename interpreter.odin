package staga

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

MEM_SIZE :: 1024 * 4

stack := [dynamic]str_int{}
mem := [MEM_SIZE]str_int{}

// maybe move most of the instructions handling here
// it would be more ergonomic
custom_instrs := [?]custom_instr_t {
  {name = "split", function = proc(instr_list: []instr, fn_list: []fn_def) {
      spliter := pop(&stack).(string)
      str := pop(&stack).(string)
      for s in strings.split(str, spliter[1:len(spliter) - 1]) {
        append(&stack, s)
      }
    }},
}


n := 0

interpret_instrs :: proc(instr_list: []instr, fn_list: []fn_def) {
  n += 1
  a_assert(true, n < 2000, "too much recusion try less")
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
      val := pop(&stack)
      switch _ in val {
      case int:
        append(&stack, val.(int) + pop(&stack).(int))
      case string:
        val2 := pop(&stack)
        // print_str handles the string to start with " and end with "
        res := strings.concatenate(
          {val2.(string)[0:len(val2.(string)) - 1], val.(string)[1:len(val.(string))]},
        )
        append(&stack, res)
      }

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
      append(&stack, mem[pop(&stack).(int)])

    case n_instr.swap:
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
      // TODO: maybe do something better ?
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
        print_str(val.(string))
        fmt.println()
      }

    case n_instr.print:
      val := pop(&stack)

      switch _ in val {
      case int:
        fmt.print(val.(int))
      case string:
        print_str(val.(string))
      }
    // case n_instr.additional:
    //   for ad in custom_instrs {
    //     if ad.name == ins.data.(string) {
    //       ad.function(&stack, mem[:], instr_list, fn_list)
    //     }
    //   }
    case n_instr.jmp:
      for m in fn_list {
        if m.name == ins.data.(string) {
          interpret_instrs(m.content, fn_list)
        }
      }
    case:
      yes := false
      for cu in custom_instrs {
        if cu.name == ins.name {
          fmt.println("found")
          cu.function(instr_list, fn_list)
          fmt.println(stack)
          yes = true
        }
      }

      a_assert(true, yes, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
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
