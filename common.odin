package staga

stack_struct :: struct {
  data: str_int,
  type: n_type,
}

str_int :: union {
  string,
  i64,
  f64
}

n_type_names := []string {
  n_type.none    = "none",
  n_type.nstring = "string",
  n_type.nint    = "int",
  n_type.ops     = "ops",
  // n_type.fn      = "fn",
  n_type.cjmp    = "cjmp",
  n_type.mem     = "mem",
}

n_type :: enum {
  none,
  nstring,
  nint,
  ops,
  nfloat,
  // fn,
  cjmp,
  mem,
}

instr :: struct {
  instr_id:  n_instr,
  data:      str_int,
  data_type: n_type,
  name:      string,
}

n_instr_names := []string {
  n_instr.none       = "none",
  n_instr.push       = "push",
  n_instr.pop        = "pop",
  n_instr.add        = "add",
  n_instr.minus      = "minus",
  n_instr.mult       = "mult",
  n_instr.div        = "div",
  n_instr.eq         = "eq",
  n_instr.gr         = "gr",
  n_instr.less       = "less",
  n_instr.gre        = ">=",
  n_instr.lesse      = "<=",
  n_instr.nif        = "if",
  n_instr.ndone      = "done",
  n_instr.nelse      = "else",
  n_instr.dup        = "dup",
  n_instr.nwhile     = "while",
  n_instr.ndo        = "do",
  n_instr.nend       = "end",
  n_instr.nmems      = "nmems",
  n_instr.nmeml      = "nmeml",
  n_instr.swap       = "swap",
  n_instr.stack      = "stack",
  n_instr.int3       = "int3",
  n_instr.print      = "print",
  n_instr.dot        = ".",
  n_instr.jmp        = "jmp",
  n_instr.additional = "",
  n_instr.read       = "read",
  n_instr.split      = "split",
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
  gre,
  less,
  lesse,
  nif,
  nelse,
  ndone,
  dup,
  nwhile,
  ndo,
  nend,
  nmems,
  nmeml,
  swap,
  stack,
  int3,
  print,
  dot,
  jmp,
  read,
  split,
  additional, // unused
}
