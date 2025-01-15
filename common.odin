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
}

n_type :: enum {
  none,
  nstring,
  nint,
  ops,
  fn,
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
  n_instr.pop     = "pop",
  n_instr.add     = "add",
  n_instr.minus   = "minus",
  n_instr.mult    = "mult",
  n_instr.div     = "div",
  n_instr.tmp     = "tmp",
  n_instr.eq      = "eq",
  n_instr.gr      = "gr",
  n_instr.less    = "less",
}

n_instr :: enum {
  none,
  consume,
  push,
  pop,
  add,
  minus,
  mult,
  div,
  tmp,
  eq,
  gr,
  less,
}

