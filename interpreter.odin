package staga

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"

MEM_SIZE :: 1024 * 4

stack := [dynamic]stack_struct{}
mem := [MEM_SIZE]stack_struct{}

interpret_instrs :: proc(instr_list: []instr) {
  i := 0
  for i < len(instr_list) {
    ins := instr_list[i]
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, stack_struct{data = ins.data, type = ins.data_type})

    case n_instr.dup:
      val := pop(&stack)
      append(&stack, val)
      append(&stack, val)

    case n_instr.add:
      check_type(n_type.nint, n_instr_names[n_instr.add])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val + val2), type = n_type.nint})

    case n_instr.minus:
      check_type(n_type.nint, n_instr_names[n_instr.minus])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint, n_instr_names[n_instr.minus])
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 - val), type = n_type.nint})

    case n_instr.mult:
      check_type(n_type.nint, n_instr_names[n_instr.mult])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint, n_instr_names[n_instr.mult])
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val * val2), type = n_type.nint})

    case n_instr.div:
      check_type(n_type.nint, n_instr_names[n_instr.div])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint, n_instr_names[n_instr.div])
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 / val), type = n_type.nint})

    case n_instr.eq:
      check_type(n_type.nint, n_instr_names[n_instr.eq])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint, n_instr_names[n_instr.eq])
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val == val2), type = n_type.nint})

    case n_instr.gr:
      check_type(n_type.nint, n_instr_names[n_instr.gr])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint, n_instr_names[n_instr.gr])
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 > val), type = n_type.nint})

    case n_instr.less:
      check_type(n_type.nint, n_instr_names[n_instr.less])
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint, n_instr_names[n_instr.less])
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 < val), type = n_type.nint})

    case n_instr.nif:
      check_type(n_type.nint, n_instr_names[n_instr.nif])
      val := strconv.atoi(pop(&stack).data)
      if val == 0 {
        i = strconv.atoi(instr_list[i].data)
      }

    case n_instr.nelse:
      i = strconv.atoi(instr_list[i].data)

    case n_instr.ndone, n_instr.none, n_instr.nwhile:

    case n_instr.ndo:
      check_type(n_type.nint, n_instr_names[n_instr.ndo])
      // fmt.println("jmp")
      cmp := pop(&stack)
      if strconv.atoi(cmp.data) == 0 do i = strconv.atoi(instr_list[i].data)

    case n_instr.nend:
      i = strconv.atoi(instr_list[i].data)

    case n_instr.nmems:
      check_type(n_type.nint, n_instr_names[n_instr.nmems])
      val := pop(&stack)
      mem[strconv.atoi(val.data)] = pop(&stack)

    case n_instr.nmeml:
      check_type(n_type.nint, n_instr_names[n_instr.nmeml])
      val := pop(&stack)
      append(&stack, mem[strconv.atoi(val.data)])

    case n_instr.swap:
      check_type(n_type.nint, n_instr_names[n_instr.swap])
      swap_num := strconv.atoi(pop(&stack).data)
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
        fmt.print(n.data, "")
      }

    case n_instr.int3:
      buf: [1]byte
      _, err := os.read(os.stdin, buf[:])
      if err != nil {
        fmt.eprintln("err {}", err)
        os.exit(1)
      }

    case n_instr.dot:
      val := pop(&stack)
      if val.type == n_type.nint {
        fmt.println(val.data)
      } else if val.type == n_type.nstring {
        print_str(val.data[1:len(val.data) - 1])
        fmt.println("")
      } else {
        a_assert(
          true,
          false,
          "expected int or string for '.' but got '",
          n_type_names[val.type],
          "'",
        )
      }

    case n_instr.print:
      val := pop(&stack)
      if val.type == n_type.nint {
        fmt.print(val.data)
      } else if val.type == n_type.nstring {
        print_str(val.data[1:len(val.data) - 1])
      } else {
        a_assert(
          true,
          false,
          "expected int or string for 'print' but got '",
          n_type_names[val.type],
          "'",
        )
      }

    case:
      a_assert(true, false, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
    }
    i += 1

  }
}

check_type :: proc(type: n_type, instr: string = "") {
  a_assert(true, len(stack) > 0, "stack is empty")
  val := pop(&stack)
  a_assert(
    true,
    val.type == type,
    "wrong type expected '",
    n_type_names[type],
    "' got '",
    n_type_names[val.type],
    "' for ",
    instr,
  )
  append(&stack, val)
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

