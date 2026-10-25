package staga

// The value type of the language: everything on the stack is one of these.
var_types :: union {
  string,
  i64,
  f64,
}

value_kind :: proc(v: var_types) -> string {
  switch _ in v {
  case i64:
    return "int"
  case f64:
    return "float"
  case string:
    return "string"
  case:
    return "unset"
  }
}

// Where an instruction came from. Every diagnostic uses this.
src_loc :: struct {
  file: string,
  row:  int,
  col:  int,
}

instr :: struct {
  op:     n_instr,
  data:   var_types, // value for `push`, unused otherwise
  target: int,     // jump target, patched by the parser
  name:   string,  // callee for `call` / `jmp`
  loc:    src_loc,
}

// Functions get a real call frame (arguments, return values, recursion).
fn_def :: struct {
  name:     string,
  nargs:    int,
  nreturns: int,
  body:     []instr,
  loc:      src_loc,
}

// Macros are the old "fn" implementation: inline-ish jumps that share the
// caller's stack, with no frame and no argument checking.
macro_def :: struct {
  name: string,
  body: []instr,
  loc:  src_loc,
}

program :: struct {
  code:   []instr,
  fns:    []fn_def,
  macros: []macro_def,
}

n_instr :: enum {
  none,
  push,
  pop,
  add,
  minus,
  mult,
  div,
  eq,
  gr,
  less,
  gre,
  lesse,
  dup,
  swap,
  nif,
  nelse,
  ndone,
  nwhile,
  ndo,
  nend,
  nmems,
  nmeml,
  stack,
  int3,
  print,
  dot,
  jmp,
  call,
  ret,
}

n_instr_names := []string {
  n_instr.none   = "none",
  n_instr.push   = "push",
  n_instr.pop    = "pop",
  n_instr.add    = "+",
  n_instr.minus  = "-",
  n_instr.mult   = "*",
  n_instr.div    = "/",
  n_instr.eq     = "=",
  n_instr.gr     = ">",
  n_instr.less   = "<",
  n_instr.gre    = ">=",
  n_instr.lesse  = "<=",
  n_instr.dup    = "dup",
  n_instr.swap   = "swap",
  n_instr.nif    = "if",
  n_instr.nelse  = "else",
  n_instr.ndone  = "done",
  n_instr.nwhile = "while",
  n_instr.ndo    = "do",
  n_instr.nend   = "end",
  n_instr.nmems  = "mems",
  n_instr.nmeml  = "meml",
  n_instr.stack  = "stack",
  n_instr.int3   = "int3",
  n_instr.print  = "print",
  n_instr.dot    = ".",
  n_instr.jmp    = "jmp",
  n_instr.call   = "call",
  n_instr.ret    = "ret",
}

find_fn :: proc(p: program, name: string) -> (fn_def, bool) {
  for f in p.fns {
    if f.name == name do return f, true
  }
  return {}, false
}

find_macro :: proc(p: program, name: string) -> (macro_def, bool) {
  for m in p.macros {
    if m.name == name do return m, true
  }
  return {}, false
}
