package staga

token_list := [dynamic]string{}
instr_list := [dynamic]instr{}

stack_struct :: struct {
  data: string,
  type: n_type,
}

n_type_names := []string {
  n_type.none    = "none",
  n_type.nstring = "string",
  n_type.nint    = "int",
  n_type.ops     = "ops",
  n_type.fn      = "fn",
  n_type.cjmp    = "cjmp",
}

n_type :: enum {
  none,
  nstring,
  nint,
  ops,
  fn,
  cjmp,
}

instr :: struct {
  instr_id:  n_instr,
  data:      string,
  data_type: n_type,
}

n_instr_names := []string {
  n_instr.none    = "none",
  n_instr.consume = "consume",
  n_instr.push    = "push",
  n_instr.add     = "add",
  n_instr.minus   = "minus",
  n_instr.mult    = "mult",
  n_instr.div     = "div",
  n_instr.eq      = "eq",
  n_instr.gr      = "gr",
  n_instr.less    = "less",
  n_instr.nif     = "if",
  n_instr.ndone   = "done",
  n_instr.nelse   = "else",
  n_instr.dup     = "dup",
  n_instr.nwhile  = "while",
  n_instr.ndo     = "do",
  n_instr.nend    = "end",
  n_instr.nmemp   = "nmemp",
  n_instr.nmeml   = "nmeml",
}

n_instr :: enum {
  none,
  consume,
  push,
  add,
  minus,
  mult,
  div,
  eq,
  gr,
  less,
  nif,
  nelse,
  ndone,
  dup,
  nwhile,
  ndo,
  nend,
  nmemp,
  nmeml,
}

