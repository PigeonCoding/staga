package staga

import "core:fmt"
import "core:os"
import "core:strings"

Tokenizer :: struct {
  res:        string,
  last_token: string,
  len:        int,
  cursor:     int,
}

get_next_token :: proc(tok: ^Tokenizer) -> string {
  for is_whitespace(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}
  if (tok.res[tok.cursor] == '/' && tok.res[tok.cursor + 1] == '/') || tok.res[tok.cursor] == '#' {
    tok.cursor += 2
    for tok.res[tok.cursor] != '\n' &&
        tok.res[tok.cursor] != '\r' &&
        tok.cursor < tok.len - 1 {tok.cursor += 1}
    // tok.cursor += 1
  }
  // for is_whitespace(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

  token: string
  if tok.res[tok.cursor] == '-' && is_numerical(tok.res[tok.cursor + 1]) {

    start := tok.cursor
    tok.cursor += 1
    for is_numerical(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

    token = tok.res[start:tok.cursor]
    return token
  } else if is_numerical(tok.res[tok.cursor]) {
    start := tok.cursor

    for is_numerical(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

    token = tok.res[start:tok.cursor]
    return token
  } else if is_alphabetical(tok.res[tok.cursor]) {
    start := tok.cursor

    for (is_alphabetical(tok.res[tok.cursor]) ||
          is_numerical(tok.res[tok.cursor]) ||
          tok.res[tok.cursor] == '_') &&
        tok.cursor < tok.len - 1 {tok.cursor += 1}

    token = tok.res[start:tok.cursor]
    return token
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

    token = tok.res[start:tok.cursor]
    return token

  } else if tok.res[tok.cursor] == '-' && tok.res[tok.cursor + 1] == '>' {
    tok.cursor += 2
    return "->"
  } else if tok.res[tok.cursor] == '<' && tok.res[tok.cursor + 1] == '-' {
    tok.cursor += 2
    return "<-"
  } else if is_operand(tok.res[tok.cursor]) {
    start := tok.cursor

    for is_operand(tok.res[tok.cursor]) && tok.cursor < tok.len - 1 {tok.cursor += 1}

    token = tok.res[start:tok.cursor]
    return token
  } else {
    token, _ = strings.clone_from_bytes([]u8{tok.res[tok.cursor]})
    tok.cursor += 1
  }

  return token
}

get_tokens :: proc(file: string, token_list: ^[dynamic]string) {
  tok: Tokenizer
  f_err: os.Error
  tok.res, f_err = read_file(file)
  if f_err != nil {
    fmt.eprintfln("could not read because {}", f_err)
    os.exit(1)
  }
  tok.len = len(tok.res)
  if tok.len == 0 {
    fmt.eprintfln("file '{}' is empty", file)
    os.exit(1)
  }

  for tok.cursor < tok.len - 1 {append(token_list, get_next_token(&tok))}

  append(token_list, " ")
}

