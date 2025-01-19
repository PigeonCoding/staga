package staga

import "core:fmt"
import "core:slice"
import "core:strconv"

MEM_SIZE :: 1024 * 4

stack := [dynamic]stack_struct{}
mem := [MEM_SIZE]stack_struct{}

builtin_funcs := []builtin_fn {
  builtin_fn{name = []string{"println", "."}, fn = nprintln_str, args_type = []n_type{.nstring}},
  builtin_fn{name = []string{"println", "."}, fn = nprintln_int, args_type = []n_type{.nint}},
  builtin_fn{name = []string{"print"}, fn = nprint_str, args_type = []n_type{.nstring}},
  builtin_fn{name = []string{"print"}, fn = nprint_int, args_type = []n_type{.nint}},
}

builtin_fn :: struct {
  name:      []string,
  fn:        proc(i: int) -> bool,
  args_type: []n_type,
}

check_type :: proc(type: n_type) {
  a_assert(true, len(stack) > 0, "stack is empty")
  val := pop(&stack)
  a_assert(
    true,
    val.type == type,
    "wrong type expected '",
    n_type_names[type],
    "' got '",
    n_type_names[val.type],
    "'",
  )
  append(&stack, val)
}

interpret_instrs :: proc() {
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
    case n_instr.consume:
      exec_relevant_fn(ins, i)
    case n_instr.add:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val + val2), type = n_type.nint})
    case n_instr.minus:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 - val), type = n_type.nint})
    case n_instr.mult:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val * val2), type = n_type.nint})
    case n_instr.div:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 / val), type = n_type.nint})
    case n_instr.eq:
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val == val2), type = n_type.nint})
    case n_instr.gr:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 > val), type = n_type.nint})
    case n_instr.less:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      check_type(n_type.nint)
      val2 := strconv.atoi(pop(&stack).data)
      append(&stack, stack_struct{data = itos(val2 < val), type = n_type.nint})
    case n_instr.nif:
      check_type(n_type.nint)
      val := strconv.atoi(pop(&stack).data)
      if val == 0 {
        i = strconv.atoi(instr_list[i].data)
      }
    case n_instr.nelse:
      i = strconv.atoi(instr_list[i].data)
    case n_instr.ndone, n_instr.none, n_instr.nwhile:
    case n_instr.ndo:
      check_type(n_type.nint)
      cmp := pop(&stack)
      if strconv.atoi(cmp.data) == 0 do i = strconv.atoi(instr_list[i].data)
    case n_instr.nend:
      i = strconv.atoi(instr_list[i].data)
    case n_instr.nmems:
      check_type(n_type.nint)
      val := pop(&stack)
      mem[strconv.atoi(val.data)] = pop(&stack)
    case n_instr.nmeml:
      check_type(n_type.nint)
      val := pop(&stack)
      append(&stack, mem[strconv.atoi(val.data)])
    case n_instr.swap:
      check_type(n_type.nint)
      swap_num := strconv.atoi(pop(&stack).data)
      if swap_num > 1 {
        tmp := stack[len(&stack) - 1]
        stack[len(&stack) - 1] = stack[len(&stack) - swap_num]
        stack[len(&stack) - swap_num] = tmp
      }
    case:
      a_assert(true, false, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
    }
    i += 1

  }
}
exec_relevant_fn :: proc(st: instr, i: int) {


  a_assert(
    true,
    stack[len(stack) - 1].type != n_type.none,
    "memory case non initialized tried to be used",
  )

  a_assert(true, len(stack) > 0, "the stack is empty")
  for fn in builtin_funcs {
    for f in fn.name {
      if st.data == f && slice.contains(fn.args_type, stack[len(stack) - 1].type) {
        fn.fn(i)
        return
      }
    }
  }

  fmt.println(stack)
  a_assert(
    true,
    false,
    "no fn '",
    st.data,
    "' for arg_type '",
    n_type_names[stack[len(stack) - 1].type],
    "'",
  )
}
nprint_str :: proc(i: int) -> bool {
  to_print := stack[len(stack) - 1].data[1:(len(stack[len(stack) - 1].data) - 1)]
  print_str(to_print)
  pop(&stack)
  return len(stack) == 0
}

nprint_int :: proc(i: int) -> bool {
  to_print := stack[len(stack) - 1].data
  print_str(to_print)
  pop(&stack)
  return len(stack) == 0
}

nprintln_str :: proc(i: int) -> bool {
  defer fmt.println()
  return nprint_str(i)
}

nprintln_int :: proc(i: int) -> bool {
  defer fmt.println()
  return nprint_int(i)
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
    } else if str[i] == '\\' && str[i + 1] == '"' {
      fmt.print("\"")
      i += 1
    } else {
      fmt.printf("%c", str[i])
    }

    i += 1
  }
}

