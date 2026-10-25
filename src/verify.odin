package staga

// Static stack-depth verification.
//
// The parser no longer tracks stack_len inline (that drifted as soon as control
// flow or calls were involved). Instead every instruction list is simulated
// after parsing, where all function signatures are known:
//
//   * underflow (popping more than exists) is a compile error
//   * both arms of an if/else must leave the same depth
//   * a loop body must preserve the depth of the loop header
//   * a function must end with `ret` and leave at least `nreturns` values
//   * macros get an inferred (needs, delta) effect, which is checked at call
//     sites so legacy macro code is still verified
//
// Anything that cannot be proven (recursive macros) is marked "unknown" and
// only the rest of the program is checked.

sim_mode :: enum {
  main,
  function,
  macro,
}

vif :: struct {
  entry_depth:     i64,
  entry_known:     bool,
  entry_reachable: bool,
  true_depth:      i64,
  true_known:      bool,
  true_reachable:  bool,
  has_else:        bool,
  loc:             src_loc,
}

vloop :: struct {
  entry_depth:     i64,
  entry_known:     bool,
  entry_reachable: bool,
  has_do:          bool,
  loc:             src_loc,
}

sim_result :: struct {
  deficit:   i64,
  end_depth: i64,
  known:     bool,
  reachable: bool,
}

macro_effect :: struct {
  needs: int,
  delta: int,
  known: bool,
}

need :: proc(ins: instr, depth: i64, n: int, ok: bool, mode: sim_mode, deficit: ^i64) {
  // How many values this instruction needs beyond what the current scope has
  // pushed itself. Used to infer the requirements of a macro body.
  d := i64(n) - depth
  if d > deficit^ do deficit^ = d

  if !ok || mode == .macro do return
  if depth < i64(n) {
    fail(
      ins.loc,
      "stack underflow: '%s' needs %d value(s), but only %d would be on the stack",
      n_instr_names[ins.op],
      n,
      depth,
    )
  }
}

need_macro :: proc(
  ins: instr,
  depth: i64,
  effect: macro_effect,
  ok: bool,
  mode: sim_mode,
  deficit: ^i64,
) {
  d := i64(effect.needs) - depth
  if d > deficit^ do deficit^ = d

  if !ok || mode == .macro do return
  if depth < i64(effect.needs) {
    fail(
      ins.loc,
      "macro '%s' needs %d value(s) on the stack, but only %d would be there",
      ins.name,
      effect.needs,
      depth,
    )
  }
}

// Infers a macro's stack effect. Recursive macros are treated as unknown.
resolve_macro :: proc(
  p: program,
  name: string,
  cache: ^map[string]macro_effect,
  visiting: ^map[string]bool,
) -> macro_effect {
  if e, ok := cache[name]; ok do return e
  if visiting[name] do return macro_effect{known = false}

  m, found := find_macro(p, name)
  if !found do return macro_effect{known = false}

  visiting[name] = true
  r := simulate(m.body, 0, .macro, 0, p, cache, visiting)
  delete_key(visiting, name)

  // A macro body starts at depth 0. `deficit` is the largest number of values
  // it consumes that it did not push itself, i.e. what the caller must supply.
  needs := r.deficit
  if needs < 0 do needs = 0

  e := macro_effect{}
  if r.known && r.reachable {
    e = macro_effect{needs = int(needs), delta = int(r.end_depth), known = true}
  }
  cache[name] = e
  return e
}

simulate :: proc(
  code: []instr,
  entry_depth: int,
  mode: sim_mode,
  nreturns: int,
  p: program,
  cache: ^map[string]macro_effect,
  visiting: ^map[string]bool,
) -> sim_result {
  stack_len := i64(entry_depth)
  deficit := i64(0)
  known := true
  reachable := true

  if_stack: [dynamic]vif
  defer delete(if_stack)
  loop_stack: [dynamic]vloop
  defer delete(loop_stack)

  for ins in code {
    ok := reachable && known

    switch ins.op {
    case .none:
    // nothing

    case .push:
      stack_len += 1

    case .pop:
      need(ins, stack_len, 1, ok, mode, &deficit)
      stack_len -= 1

    case .dup:
      need(ins, stack_len, 1, ok, mode, &deficit)
      stack_len += 1

    case .swap:
      // `swap` pops a runtime depth and permutes; net effect is -1. The exact
      // depth is checked at runtime.
      need(ins, stack_len, 1, ok, mode, &deficit)
      stack_len -= 1

    case .add, .minus, .mult, .div, .eq, .gr, .less, .gre, .lesse:
      need(ins, stack_len, 2, ok, mode, &deficit)
      stack_len -= 1

    case .nmems:
      need(ins, stack_len, 2, ok, mode, &deficit)
      stack_len -= 2

    case .nmeml:
      need(ins, stack_len, 1, ok, mode, &deficit)
    // pops an index, pushes a value

    case .stack, .int3:
    // no stack effect

    case .print, .dot:
      need(ins, stack_len, 1, ok, mode, &deficit)
      stack_len -= 1

    case .nif:
      need(ins, stack_len, 1, ok, mode, &deficit)
      stack_len -= 1
      append(
        &if_stack,
        vif {
          entry_depth = stack_len,
          entry_known = known,
          entry_reachable = reachable,
          loc = ins.loc,
        },
      )

    case .nelse:
      if len(if_stack) == 0 {
        fail(ins.loc, "'else' without a matching 'if'")
      }
      ctx := &if_stack[len(if_stack) - 1]
      if ctx.has_else {
        fail(ins.loc, "second 'else' for the 'if' opened at %s:%d:%d", ctx.loc.file, ctx.loc.row, ctx.loc.col)
      }
      ctx.has_else = true
      ctx.true_depth = stack_len
      ctx.true_known = known
      ctx.true_reachable = reachable
      stack_len = ctx.entry_depth
      known = ctx.entry_known
      reachable = ctx.entry_reachable

    case .ndone:
      if len(if_stack) == 0 {
        fail(ins.loc, "'done' without a matching 'if'")
      }
      ctx := pop(&if_stack)

      a_depth: i64
      a_known: bool
      a_reachable: bool
      b_depth: i64
      b_known: bool
      b_reachable: bool

      if ctx.has_else {
        a_depth, a_known, a_reachable = ctx.true_depth, ctx.true_known, ctx.true_reachable
        b_depth, b_known, b_reachable = stack_len, known, reachable
      } else {
        // The fall-through path is the true branch; the false path skips the
        // whole block and continues at the entry depth.
        a_depth, a_known, a_reachable = stack_len, known, reachable
        b_depth, b_known, b_reachable = ctx.entry_depth, ctx.entry_known, ctx.entry_reachable
      }

      if a_reachable && b_reachable && a_known && b_known && a_depth != b_depth {
        fail(
          ins.loc,
          "branches of the 'if' opened at %s:%d:%d leave different stack depths (%d and %d)",
          ctx.loc.file,
          ctx.loc.row,
          ctx.loc.col,
          a_depth,
          b_depth,
        )
      }

      if a_reachable && b_reachable {
        stack_len = a_depth
        known = a_known && b_known
      } else if a_reachable {
        stack_len = a_depth
        known = a_known
      } else if b_reachable {
        stack_len = b_depth
        known = b_known
      } else {
        stack_len = ctx.entry_depth
        known = ctx.entry_known
      }
      reachable = a_reachable || b_reachable

    case .nwhile:
      append(
        &loop_stack,
        vloop {
          entry_depth = stack_len,
          entry_known = known,
          entry_reachable = reachable,
          loc = ins.loc,
        },
      )

    case .ndo:
      if len(loop_stack) == 0 {
        fail(ins.loc, "'do' without a matching 'while'")
      }
      ctx := &loop_stack[len(loop_stack) - 1]
      if ctx.has_do {
        fail(ins.loc, "second 'do' for the 'while' opened at %s:%d:%d", ctx.loc.file, ctx.loc.row, ctx.loc.col)
      }
      if ok && stack_len != ctx.entry_depth + 1 {
        fail(
          ins.loc,
          "loop condition must leave exactly one value: expected %d, found %d",
          ctx.entry_depth + 1,
          stack_len,
        )
      }
      need(ins, stack_len, 1, ok, mode, &deficit)
      ctx.has_do = true
      stack_len -= 1

    case .nend:
      if len(loop_stack) == 0 {
        fail(ins.loc, "'end' without a matching 'while'")
      }
      ctx := pop(&loop_stack)
      if !ctx.has_do {
        fail(
          ins.loc,
          "the 'while' opened at %s:%d:%d has no 'do'",
          ctx.loc.file,
          ctx.loc.row,
          ctx.loc.col,
        )
      }
      body_known := known
      if ok && ctx.entry_known && stack_len != ctx.entry_depth {
        fail(
          ins.loc,
          "loop body must leave the stack at depth %d, but it leaves %d",
          ctx.entry_depth,
          stack_len,
        )
      }
      stack_len = ctx.entry_depth
      known = ctx.entry_known && body_known
      reachable = ctx.entry_reachable

    case .call:
      f, found := find_fn(p, ins.name)
      if !found {
        if _, is_macro := find_macro(p, ins.name); is_macro {
          fail(ins.loc, "'%s' is a macro; call it with 'jmp %s'", ins.name, ins.name)
        }
        fail(ins.loc, "unknown function '%s'", ins.name)
      }
      need(ins, stack_len, f.nargs, ok, mode, &deficit)
      stack_len += i64(f.nreturns - f.nargs)

    case .jmp:
      if _, found := find_macro(p, ins.name); !found {
        if _, is_fn := find_fn(p, ins.name); is_fn {
          fail(ins.loc, "'%s' is a function; call it with 'call %s'", ins.name, ins.name)
        }
        fail(ins.loc, "unknown macro '%s'", ins.name)
      }
      effect := resolve_macro(p, ins.name, cache, visiting)
      if !effect.known {
        known = false
      } else {
        need_macro(ins, stack_len, effect, ok, mode, &deficit)
        stack_len += i64(effect.delta)
      }

    case .ret:
      if mode != .function {
        fail(ins.loc, "'ret' is only allowed inside a function")
      }
      if reachable {
        if known && stack_len < i64(nreturns) {
          fail(
            ins.loc,
            "function must leave at least %d return value(s), but only %d would be on the stack",
            nreturns,
            stack_len,
          )
        }
        stack_len = i64(nreturns)
        reachable = false
      }
    }

  }

  if len(if_stack) > 0 {
    ctx := if_stack[len(if_stack) - 1]
    fail(ctx.loc, "'if' opened here is never closed (missing 'done')")
  }
  if len(loop_stack) > 0 {
    ctx := loop_stack[len(loop_stack) - 1]
    fail(ctx.loc, "'while' opened here is never closed (missing 'end')")
  }

  return sim_result {
    deficit = deficit,
    end_depth = stack_len,
    known = known,
    reachable = reachable,
  }
}

verify_program :: proc(p: program) {
  cache := make(map[string]macro_effect)
  defer delete(cache)
  visiting := make(map[string]bool)
  defer delete(visiting)

  for f in p.fns {
    r := simulate(f.body, f.nargs, .function, f.nreturns, p, &cache, &visiting)
    if r.reachable {
      fail(f.loc, "function '%s' reaches the end of its body without 'ret'", f.name)
    }
  }

  // Infer every macro's effect, even unused ones, so errors inside macro
  // bodies are reported.
  for m in p.macros {
    resolve_macro(p, m.name, &cache, &visiting)
  }

  simulate(p.code, 0, .main, 0, p, &cache, &visiting)
}
