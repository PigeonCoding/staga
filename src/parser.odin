package staga

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import lx "../thirdparty/lexer"

block_kind :: enum {
  top,
  function,
  macro,
}

if_ctx :: struct {
  if_idx:   int,
  else_idx: int,
  has_else: bool,
  loc:      src_loc,
}

loop_ctx :: struct {
  while_idx: int,
  do_idx:    int,
  has_do:    bool,
  loc:       src_loc,
}

block_tag :: enum {
  if_block,
  while_block,
}

loc_of :: proc(t: lx.token) -> src_loc {
  // token.row is 1-based, token.col is 0-based. Normalise both to 1-based.
  return {file = t.file, row = int(t.row), col = int(t.col) + 1}
}

token_desc :: proc(t: lx.token) -> string {
  #partial switch t.type {
  case .either_end_or_failure:
    return "end of file"
  case .intlit:
    return fmt.tprintf("integer %d", t.intlit)
  case .floatlit:
    return fmt.tprintf("float %v", t.floatlit)
  case .dqstring, .sqstring:
    return fmt.tprintf("string %q", t.str)
  case .id:
    return fmt.tprintf("word '%s'", t.str)
  case .punct:
    return fmt.tprintf("'%c'", rune(t.intlit))
  }
  return fmt.tprintf("%v", t.type)
}

advance :: proc(l: ^lx.lexer) {
  lx.get_token(l)
}

// Advance to the next token and require it to be a word.
take_id :: proc(l: ^lx.lexer, what: string) -> lx.token {
  advance(l)
  if l.token.type != .id {
    fail(loc_of(l.token), "expected %s, but found %s", what, token_desc(l.token))
  }
  return l.token
}

// Advance to the next token and require it to be an integer.
take_int :: proc(l: ^lx.lexer, what: string) -> i64 {
  advance(l)
  if l.token.type != .intlit {
    fail(loc_of(l.token), "expected %s, but found %s", what, token_desc(l.token))
  }
  return l.token.intlit
}

// Advance to the next token and require it to be a string.
take_string :: proc(l: ^lx.lexer, what: string) -> lx.token {
  advance(l)
  if l.token.type != .dqstring && l.token.type != .sqstring {
    fail(loc_of(l.token), "expected %s, but found %s", what, token_desc(l.token))
  }
  return l.token
}

name_taken :: proc(fns: ^[dynamic]fn_def, macros: ^[dynamic]macro_def, name: string) -> bool {
  for f in fns^ {
    if f.name == name do return true
  }
  for m in macros^ {
    if m.name == name do return true
  }
  return false
}

emit :: proc(code: ^[dynamic]instr, op: n_instr, loc: src_loc) {
  append(code, instr{op = op, loc = loc})
}

// Parses instructions until EOF (top level) or until `fend` (function/macro
// body). The lexer is left on the token that ended the block.
parse_block :: proc(
  l: ^lx.lexer,
  code: ^[dynamic]instr,
  fns: ^[dynamic]fn_def,
  macros: ^[dynamic]macro_def,
  kind: block_kind,
) {
  if_stack: [dynamic]if_ctx
  defer delete(if_stack)
  loop_stack: [dynamic]loop_ctx
  defer delete(loop_stack)
  blocks: [dynamic]block_tag
  defer delete(blocks)

  for {
    tok := l.token
    // The body terminator is a word, not a string that happens to say "fend".
    if kind != .top && tok.type == .id && tok.str == "fend" {
      break
    }
    if tok.type == .either_end_or_failure {
      if kind != .top {
        name := "function" if kind == .function else "macro"
        fail(loc_of(tok), "unexpected end of file: this %s is missing its 'fend'", name)
      }
      break
    }

    loc := loc_of(tok)

    #partial switch tok.type {
    case .intlit, .charlit:
      append(code, instr{op = .push, data = tok.intlit, loc = loc})

    case .floatlit:
      append(code, instr{op = .push, data = tok.floatlit, loc = loc})

    case .dqstring, .sqstring:
      append(code, instr{op = .push, data = tok.str, loc = loc})

    case .punct:
      switch tok.intlit {
      case '.':
        emit(code, .dot, loc)
      case:
        fail(loc, "unknown punctuation '%c'", rune(tok.intlit))
      }

    case .plus:
      emit(code, .add, loc)
    case .minus:
      emit(code, .minus, loc)
    case .mult:
      emit(code, .mult, loc)
    case .div:
      emit(code, .div, loc)
    case .less:
      emit(code, .less, loc)
    case .greater:
      emit(code, .gr, loc)
    case .assign:
      emit(code, .eq, loc)
    case .lesseq:
      emit(code, .lesse, loc)
    case .greatereq:
      emit(code, .gre, loc)

    case .id:
      switch tok.str {
      case "stack":
        emit(code, .stack, loc)
      case "pop":
        emit(code, .pop, loc)
      case "dup":
        emit(code, .dup, loc)
      case "swap":
        emit(code, .swap, loc)
      case "print":
        emit(code, .print, loc)
      case "mems":
        emit(code, .nmems, loc)
      case "meml":
        emit(code, .nmeml, loc)
      case "int3":
        emit(code, .int3, loc)

      case "if":
        append(code, instr{op = .nif, loc = loc})
        append(&if_stack, if_ctx{if_idx = len(code) - 1, else_idx = -1, loc = loc})
        append(&blocks, .if_block)

      case "else":
        if len(if_stack) == 0 {
          fail(loc, "'else' without a matching 'if'")
        }
        if len(blocks) == 0 || blocks[len(blocks) - 1] != .if_block {
          fail(loc, "'else' does not match the innermost open block (it is a 'while')")
        }
        ctx := &if_stack[len(if_stack) - 1]
        if ctx.has_else {
          fail(
            loc,
            "second 'else' for the 'if' opened at %s:%d:%d",
            ctx.loc.file,
            ctx.loc.row,
            ctx.loc.col,
          )
        }
        ctx.has_else = true
        ctx.else_idx = len(code)
        append(code, instr{op = .nelse, loc = loc})
        code[ctx.if_idx].target = ctx.else_idx

      case "done":
        if len(if_stack) == 0 {
          fail(loc, "'done' without a matching 'if'")
        }
        if len(blocks) == 0 || blocks[len(blocks) - 1] != .if_block {
          fail(loc, "'done' does not match the innermost open block (it is a 'while')")
        }
        _ = pop(&blocks)
        ctx := pop(&if_stack)
        append(code, instr{op = .ndone, loc = loc})
        done_idx := len(code) - 1
        if ctx.has_else {
          code[ctx.else_idx].target = done_idx
        } else {
          code[ctx.if_idx].target = done_idx
        }

      case "while":
        append(code, instr{op = .nwhile, loc = loc})
        append(&loop_stack, loop_ctx{while_idx = len(code) - 1, do_idx = -1, loc = loc})
        append(&blocks, .while_block)

      case "do":
        if len(loop_stack) == 0 {
          fail(loc, "'do' without a matching 'while'")
        }
        if len(blocks) == 0 || blocks[len(blocks) - 1] != .while_block {
          fail(loc, "'do' does not match the innermost open block (it is an 'if')")
        }
        ctx := &loop_stack[len(loop_stack) - 1]
        if ctx.has_do {
          fail(
            loc,
            "second 'do' for the 'while' opened at %s:%d:%d",
            ctx.loc.file,
            ctx.loc.row,
            ctx.loc.col,
          )
        }
        ctx.has_do = true
        ctx.do_idx = len(code)
        append(code, instr{op = .ndo, loc = loc})

      case "end":
        if len(loop_stack) == 0 {
          fail(loc, "'end' without a matching 'while'")
        }
        if len(blocks) == 0 || blocks[len(blocks) - 1] != .while_block {
          fail(loc, "'end' does not match the innermost open block (it is an 'if')")
        }
        _ = pop(&blocks)
        ctx := pop(&loop_stack)
        if !ctx.has_do {
          fail(
            loc,
            "the 'while' opened at %s:%d:%d has no 'do'",
            ctx.loc.file,
            ctx.loc.row,
            ctx.loc.col,
          )
        }
        append(code, instr{op = .nend, loc = loc})
        end_idx := len(code) - 1
        code[ctx.do_idx].target = end_idx
        code[end_idx].target = ctx.while_idx

      case "ret":
        if kind != .function {
          fail(loc, "'ret' is only allowed inside a function")
        }
        emit(code, .ret, loc)

      case "fn":
        parse_fn(l, fns, macros)

      case "macro":
        parse_macro(l, fns, macros)

      case "call":
        parse_call(l, code, loc, .call)

      case "jmp":
        parse_call(l, code, loc, .jmp)

      case "load":
        path_tok := take_string(l, "a file path after 'load'")
        if len(path_tok.str) == 0 {
          fail(loc_of(path_tok), "expected a file path, but got an empty string")
        }
        name := path_tok.str
        if !strings.ends_with(name, ".stg") {
          name = strings.concatenate({name, ".stg"})
        }
        dir := filepath.dir(l.file)
        path, _ := filepath.join([]string{dir, name})
        if !os.exists(path) {
          fail(loc_of(path_tok), "cannot load '%s': file not found", path)
        }
        parse_file(path, code, fns, macros)

      case "fend":
        fail(loc, "'fend' without a matching 'fn' or 'macro'")

      case:
        fail(loc, "unknown word '%s'", tok.str)
      }

    case:
      fail(loc, "unexpected %s", token_desc(tok))
    }

    advance(l)
  }

  if len(if_stack) > 0 {
    ctx := if_stack[len(if_stack) - 1]
    fail(ctx.loc, "'if' opened here is never closed (missing 'done')")
  }
  if len(loop_stack) > 0 {
    ctx := loop_stack[len(loop_stack) - 1]
    fail(ctx.loc, "'while' opened here is never closed (missing 'end')")
  }
}

parse_fn :: proc(
  l: ^lx.lexer,
  fns: ^[dynamic]fn_def,
  macros: ^[dynamic]macro_def,
) {
  name_tok := take_id(l, "a function name")
  nargs := take_int(l, fmt.tprintf("the number of arguments for '%s'", name_tok.str))
  nreturns := take_int(l, fmt.tprintf("the number of return values for '%s'", name_tok.str))

  if nargs < 0 || nreturns < 0 {
    fail(loc_of(name_tok), "argument and return counts must not be negative")
  }
  if name_taken(fns, macros, name_tok.str) {
    fail(loc_of(name_tok), "'%s' is already defined", name_tok.str)
  }

  body: [dynamic]instr
  advance(l) // first token of the body
  parse_block(l, &body, fns, macros, .function)

  append(
    fns,
    fn_def {
      name = name_tok.str,
      nargs = int(nargs),
      nreturns = int(nreturns),
      body = body[:],
      loc = loc_of(name_tok),
    },
  )
}

parse_macro :: proc(
  l: ^lx.lexer,
  fns: ^[dynamic]fn_def,
  macros: ^[dynamic]macro_def,
) {
  name_tok := take_id(l, "a macro name")

  if name_taken(fns, macros, name_tok.str) {
    fail(loc_of(name_tok), "'%s' is already defined", name_tok.str)
  }

  body: [dynamic]instr
  advance(l) // first token of the body
  parse_block(l, &body, fns, macros, .macro)

  append(macros, macro_def{name = name_tok.str, body = body[:], loc = loc_of(name_tok)})
}

parse_call :: proc(l: ^lx.lexer, code: ^[dynamic]instr, loc: src_loc, op: n_instr) {
  name_tok := take_id(l, "a name after 'call'/'jmp'")
  append(code, instr{op = op, name = name_tok.str, loc = loc})
}

parse_file :: proc(
  file: string,
  code: ^[dynamic]instr,
  fns: ^[dynamic]fn_def,
  macros: ^[dynamic]macro_def,
) {
  if !os.exists(file) {
    fail({file = file, row = 1, col = 1}, "cannot open file '%s'", file)
  }
  l := lx.init_lexer(file)
  advance(&l)
  parse_block(&l, code, fns, macros, .top)
}

parse_program :: proc(file: string) -> program {
  code: [dynamic]instr
  fns: [dynamic]fn_def
  macros: [dynamic]macro_def

  parse_file(file, &code, &fns, &macros)

  return program{code = code[:], fns = fns[:], macros = macros[:]}
}
