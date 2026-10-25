package staga

import "core:fmt"
import "core:os"
import "core:strings"

stack: [dynamic]str_int

// Memory is a sparse map now, so slots have no arbitrary 4096 limit and a
// negative index is a normal key instead of an out-of-bounds panic.
memory: map[i64]str_int

frame_kind :: enum {
  macro,
  function,
}

frame :: struct {
  kind:     frame_kind,
  code:     []instr,
  ip:       int,
  base:     int,
  name:     string,
  nreturns: int,
  loc:      src_loc,
}

frames: [dynamic]frame

MAX_CALL_DEPTH :: 100_000

pop_value :: proc(ins: instr) -> str_int {
  if len(stack) == 0 {
    runtime_fail(ins.loc, "'%s' needs a value, but the stack is empty", n_instr_names[ins.op])
  }
  return pop(&stack)
}

as_int :: proc(ins: instr, v: str_int, what: string) -> i64 {
  n, ok := v.(i64)
  if !ok {
    runtime_fail(ins.loc, "'%s' expected an int, but got a %s", what, value_kind(v))
  }
  return n
}

misuse :: proc(ins: instr, op: string, a: str_int, b: str_int) -> ! {
  runtime_fail(ins.loc, "cannot use '%s' on %s and %s", op, value_kind(a), value_kind(b))
}

cmp_int :: proc(ins: instr, op: string, a, b: i64) -> i64 {
  switch op {
  case "=":
    return i64(a == b)
  case ">":
    return i64(a > b)
  case "<":
    return i64(a < b)
  case ">=":
    return i64(a >= b)
  case "<=":
    return i64(a <= b)
  }
  runtime_fail(ins.loc, "unsupported comparison '%s'", op)
}

cmp_float :: proc(ins: instr, op: string, a, b: f64) -> i64 {
  switch op {
  case "=":
    return i64(a == b)
  case ">":
    return i64(a > b)
  case "<":
    return i64(a < b)
  case ">=":
    return i64(a >= b)
  case "<=":
    return i64(a <= b)
  }
  runtime_fail(ins.loc, "unsupported comparison '%s'", op)
}

cmp_string :: proc(ins: instr, op: string, a, b: string) -> i64 {
  c := strings.compare(a, b)
  switch op {
  case "=":
    return i64(c == 0)
  case ">":
    return i64(c > 0)
  case "<":
    return i64(c < 0)
  case ">=":
    return i64(c >= 0)
  case "<=":
    return i64(c <= 0)
  }
  runtime_fail(ins.loc, "unsupported comparison '%s'", op)
}

arith :: proc(ins: instr, op: string) -> str_int {
  rhs := pop_value(ins)
  lhs := pop_value(ins)

  switch r in rhs {
  case i64:
    l, ok := lhs.(i64)
    if !ok do misuse(ins, op, lhs, rhs)
    if op == "+" do return l + r
    if op == "-" do return l - r
    if op == "*" do return l * r
    if op == "/" {
      if r == 0 do runtime_fail(ins.loc, "division by zero")
      return l / r
    }
    misuse(ins, op, lhs, rhs)

  case f64:
    l, ok := lhs.(f64)
    if !ok do misuse(ins, op, lhs, rhs)
    if op == "+" do return l + r
    if op == "-" do return l - r
    if op == "*" do return l * r
    if op == "/" {
      if r == 0 do runtime_fail(ins.loc, "division by zero")
      return l / r
    }
    misuse(ins, op, lhs, rhs)

  case string:
    if op != "+" do misuse(ins, op, lhs, rhs)
    l, ok := lhs.(string)
    if !ok do misuse(ins, op, lhs, rhs)
    return strings.concatenate({l, r})
  }

  misuse(ins, op, lhs, rhs)
}

compare :: proc(ins: instr, op: string) -> i64 {
  rhs := pop_value(ins)
  lhs := pop_value(ins)

  switch r in rhs {
  case i64:
    l, ok := lhs.(i64)
    if !ok do misuse(ins, op, lhs, rhs)
    return cmp_int(ins, op, l, r)

  case f64:
    l, ok := lhs.(f64)
    if !ok do misuse(ins, op, lhs, rhs)
    return cmp_float(ins, op, l, r)

  case string:
    l, ok := lhs.(string)
    if !ok do misuse(ins, op, lhs, rhs)
    return cmp_string(ins, op, l, r)
  }

  misuse(ins, op, lhs, rhs)
}

write_value :: proc(ins: instr, v: str_int, newline: bool) {
  switch x in v {
  case string:
    fmt.print(x)
  case i64:
    fmt.print(x)
  case f64:
    fmt.print(x)
  case:
    runtime_fail(ins.loc, "cannot print an unset value")
  }
  if newline do fmt.println()
}

push_frame :: proc(
  ins: instr,
  kind: frame_kind,
  code: []instr,
  ip, base: int,
  name: string,
  nreturns: int,
  loc: src_loc,
) {
  if len(frames) >= MAX_CALL_DEPTH {
    runtime_fail(
      ins.loc,
      "maximum call depth (%d) exceeded; is '%s' recursing forever?",
      MAX_CALL_DEPTH,
      name,
    )
  }
  append(
    &frames,
    frame {
      kind = kind,
      code = code,
      ip = ip,
      base = base,
      name = name,
      nreturns = nreturns,
      loc = loc,
    },
  )
}

return_from_function :: proc(ins: instr, fr: frame) {
  available := len(stack) - fr.base
  if available < fr.nreturns {
    runtime_fail(
      ins.loc,
      "function '%s' must return %d value(s), but only %d would be on the stack",
      fr.name,
      fr.nreturns,
      available,
    )
  }
  // Keep the top `nreturns` values, drop everything above the frame base.
  if fr.nreturns > 0 {
    for k in 0 ..< fr.nreturns {
      stack[fr.base + k] = stack[len(stack) - fr.nreturns + k]
    }
  }
  resize(&stack, fr.base + fr.nreturns)
}

run :: proc(p: program) {
  stack = make([dynamic]str_int)
  frames = make([dynamic]frame)
  memory = make(map[i64]str_int)

  defer {
    delete(stack)
    delete(frames)
    delete(memory)
  }

  code := p.code
  ip := 0

  for {
    if ip >= len(code) {
      if len(frames) == 0 do break
      fr := frames[len(frames) - 1]
      if fr.kind == .function {
        runtime_fail(fr.loc, "function '%s' reached the end of its body without 'ret'", fr.name)
      }
      // A macro simply ends; it keeps whatever it left on the shared stack.
      resize(&frames, len(frames) - 1)
      code = fr.code
      ip = fr.ip
      continue
    }

    ins := code[ip]

    switch ins.op {
    case .none:
    // nothing

    case .push:
      append(&stack, ins.data)

    case .pop:
      _ = pop_value(ins)

    case .add:
      append(&stack, arith(ins, "+"))
    case .minus:
      append(&stack, arith(ins, "-"))
    case .mult:
      append(&stack, arith(ins, "*"))
    case .div:
      append(&stack, arith(ins, "/"))
    case .eq:
      append(&stack, compare(ins, "="))
    case .gr:
      append(&stack, compare(ins, ">"))
    case .less:
      append(&stack, compare(ins, "<"))
    case .gre:
      append(&stack, compare(ins, ">="))
    case .lesse:
      append(&stack, compare(ins, "<="))

    case .dup:
      v := pop_value(ins)
      append(&stack, v)
      append(&stack, v)

    case .swap:
      n := as_int(ins, pop_value(ins), "swap")
      if n < 2 {
        runtime_fail(ins.loc, "'swap' needs a depth of at least 2, but got %d", n)
      }
      if n > i64(len(stack)) {
        runtime_fail(ins.loc, "'swap' depth %d exceeds the stack size %d", n, len(stack))
      }
      a := len(stack) - 1
      b := len(stack) - int(n)
      stack[a], stack[b] = stack[b], stack[a]

    case .nif:
      cond := as_int(ins, pop_value(ins), "if")
      if cond == 0 do ip = ins.target
    case .nelse:
      ip = ins.target
    case .ndone, .nwhile:
    // no-op markers
    case .ndo:
      cond := as_int(ins, pop_value(ins), "do")
      if cond == 0 do ip = ins.target
    case .nend:
      ip = ins.target

    case .nmems:
      idx := as_int(ins, pop_value(ins), "mems")
      val := pop_value(ins)
      memory[idx] = val
    case .nmeml:
      idx := as_int(ins, pop_value(ins), "meml")
      val, ok := memory[idx]
      if !ok {
        runtime_fail(ins.loc, "memory slot %d has not been written to", idx)
      }
      append(&stack, val)

    case .stack:
      fmt.print("stack (", len(stack), "): ")
      for v in stack {
        switch x in v {
        case string:
          fmt.printf("%q ", x)
        case i64, f64:
          fmt.printf("%v ", x)
        case:
          fmt.print("<unset> ")
        }
      }
      fmt.println()

    case .int3:
      // TODO: maybe do something better ? or remove it entirely
      buf: [1]byte
      _, err := os.read(os.stdin, buf[:])
      if err != nil do runtime_fail(ins.loc, "failed to read from stdin: %v", err)

    case .print:
      write_value(ins, pop_value(ins), false)
    case .dot:
      write_value(ins, pop_value(ins), true)

    case .jmp:
      m, found := find_macro(p, ins.name)
      if !found do runtime_fail(ins.loc, "unknown macro '%s'", ins.name)
      push_frame(ins, .macro, code, ip + 1, 0, m.name, 0, m.loc)
      code = m.body
      ip = 0
      continue

    case .call:
      f, found := find_fn(p, ins.name)
      if !found do runtime_fail(ins.loc, "unknown function '%s'", ins.name)
      if len(stack) < f.nargs {
        runtime_fail(
          ins.loc,
          "function '%s' expects %d argument(s), but only %d are on the stack",
          f.name,
          f.nargs,
          len(stack),
        )
      }
      push_frame(ins, .function, code, ip + 1, len(stack) - f.nargs, f.name, f.nreturns, f.loc)
      code = f.body
      ip = 0
      continue

    case .ret:
      if len(frames) == 0 do runtime_fail(ins.loc, "'ret' outside of a function")
      fr := frames[len(frames) - 1]
      if fr.kind != .function do runtime_fail(ins.loc, "'ret' inside macro '%s'", fr.name)
      return_from_function(ins, fr)
      resize(&frames, len(frames) - 1)
      code = fr.code
      ip = fr.ip
      continue
    }

    ip += 1
  }
}
