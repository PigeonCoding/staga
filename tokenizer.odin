package staga

import "core:fmt"
import "core:os"
import "core:strings"

Tokenizer :: struct {
  file:      string,
  res:       string,
  len:       uint,
  cursor:    uint,
  start_row: uint,
  row:       uint,
}

Token :: struct {
  content:  string,
  row, col: uint,
  file:     string,
  skip:     bool,
}

get_next_token :: proc(tok: ^Tokenizer) -> (t: Token, end: bool = false) {
  for tok.cursor < tok.len - 1 && is_whitespace(tok.res[tok.cursor]) {tok.cursor += 1}
  if tok.cursor >= tok.len do return Token{}, true
  if (tok.res[tok.cursor] == '/' && tok.res[tok.cursor + 1] == '/') || tok.res[tok.cursor] == '#' {
    tok.cursor += 2
    for tok.res[tok.cursor] != '\n' &&
        tok.res[tok.cursor] != '\r' &&
        tok.cursor < tok.len - 1 {tok.cursor += 1}
  }
  if tok.res[tok.cursor] == '\n' {
    tok.start_row = tok.cursor + 1
    tok.cursor += 1
    tok.row += 1
  }

  if tok.cursor >= tok.len do return Token{}, true


  token: Token
  token.file = tok.file
  token.row = tok.row
  if tok.res[tok.cursor] == '-' &&
     tok.cursor < tok.len - 1 &&
     is_numerical(tok.res[tok.cursor + 1]) {
    start := tok.cursor
    tok.cursor += 1
    for is_numerical(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

    token.content = tok.res[start:tok.cursor]
    token.col = start - tok.start_row
    return token, false
  } else if is_numerical(tok.res[tok.cursor]) {
    start := tok.cursor

    for is_numerical(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

    token.content = tok.res[start:tok.cursor]
    token.col = start - tok.start_row
    return token, false
  } else if is_alphabetical(tok.res[tok.cursor]) {
    start := tok.cursor

    for (is_alphabetical(tok.res[tok.cursor]) ||
          is_numerical(tok.res[tok.cursor]) ||
          tok.res[tok.cursor] == '_') &&
        tok.cursor < tok.len - 1 {tok.cursor += 1}

    token.content = tok.res[start:tok.cursor]
    token.col = start - tok.start_row
    return token, false
  } else if tok.res[tok.cursor] == '"' {
    start := tok.cursor
    tok.cursor += 1

    for tok.res[tok.cursor] != '"' && tok.cursor < tok.len - 1 {
      if tok.res[tok.cursor] == '\\' {
        tok.cursor += 1
      }
      tok.cursor += 1
    }
    tok.cursor += 1

    token.content = tok.res[start:tok.cursor]
    token.col = start - tok.start_row
    return token, false

  } else if tok.res[tok.cursor] == '-' && tok.res[tok.cursor + 1] == '>' {
    tok.cursor += 2
    token.content = "->"
    token.col = tok.cursor - 2 - tok.start_row
  } else if tok.res[tok.cursor] == '<' && tok.res[tok.cursor + 1] == '-' {
    tok.cursor += 2
    token.content = "<-"
    token.col = tok.cursor - 2 - tok.start_row
  } else if is_operand(tok.res[tok.cursor]) {
    start := tok.cursor

    for is_operand(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

    token.content = tok.res[start:tok.cursor]
    token.col = start - tok.start_row
    return token, false
  } else {
    token.content, _ = strings.clone_from_bytes([]u8{tok.res[tok.cursor]})
    token.col = tok.cursor - tok.start_row
    tok.cursor += 1
  }

  return token, false
}


get_tokens :: proc(file: string, token_list: ^[dynamic]Token) {
  tok: Tokenizer
  f_err: os.Error
  tok.res, f_err = read_file(file)
  tok.file = file
  tok.row = 1
  if f_err != nil {
    fmt.eprintfln("could not read because {}", f_err)
    os.exit(1)
  }
  tok.len = len(tok.res)
  if tok.len == 0 {
    fmt.eprintfln("file '{}' is empty", file)
    os.exit(1)
  }

  for {
    token, end := get_next_token(&tok)
    if end {
      break
    }
    append(token_list, token)
  }

  append(token_list, Token{content = " ", file = file, row = tok.row, col = tok.cursor - tok.row})
}

