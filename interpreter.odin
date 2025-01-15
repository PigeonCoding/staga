package staga

import "core:fmt"
import "core:slice"
import "core:strconv"

stack := [dynamic]stack_struct{}

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

interpret_instrs :: proc() {
  for ins, i in instr_list {
    #partial switch ins.instr_id {
    case n_instr.push:
      append(&stack, stack_struct{data = ins.data, type = ins.data_type})
    case n_instr.consume:
      exec_relevant_fn(ins, i)
    case n_instr.add:
      val := strconv.atoi(pop(&stack).data)
      val += strconv.atoi(instr_list[i].data)
      stack[len(stack) - 1].data = itos(val)
    case n_instr.eq:
      val := strconv.atoi(pop(&stack).data)
      val2 := strconv.atoi(instr_list[i].data)
      append(&stack, stack_struct{data = itos(auto_cast val == val2), type = n_type.nint})
    case n_instr.gr:
      val := strconv.atoi(pop(&stack).data)
      val2 := strconv.atoi(instr_list[i].data)
      append(&stack, stack_struct{data = itos(val > val2), type = n_type.nint})
    case n_instr.less:
      val := strconv.atoi(pop(&stack).data)
      val2 := strconv.atoi(instr_list[i].data)
      append(&stack, stack_struct{data = itos(val < val2), type = n_type.nint})
    case:
      better_assert(true, false, "instr not implemented \'", n_instr_names[ins.instr_id], "\'")
    }
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
    } else {
      fmt.printf("%c", str[i])
    }

    i += 1
  }
}

