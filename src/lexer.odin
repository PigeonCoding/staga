// v0.1.5 from https://github.com/PigeonCoding/lexer.odin
package staga

import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"


token_id :: enum {
  null_char,
  soh_char,
  stx_char,
  etx_char,
  eot_char,
  enq_char,
  ack_char,
  bel_char,
  backspace_char,
  horizontal_tab_char,
  line_feed_char,
  vertical_tab_char,
  form_feed_char,
  carriage_return_char,
  shift_out_char,
  shift_in_char,
  data_link_escape_char,
  device_control_1_char,
  device_control_2_char,
  device_control_3_char,
  device_control_4_char,
  negative_acknowledge_char,
  synchronous_idle_char,
  end_of_transmission_block_char,
  cancel_char,
  end_of_medium_char,
  substitute_char,
  escape_char,
  file_separator_char,
  group_separator_char,
  record_separator_char,
  unit_separator_char,
  space_char,
  exclamation_mark,
  double_quote,
  hash_sign,
  dollar_sign,
  percent_sign,
  ampersand,
  single_quote,
  open_parenthesis,
  close_parenthesis,
  asterisk,
  plus_sign,
  comma_char,
  minus_sign,
  dot,
  forward_slash,
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  colon,
  semicolon,
  less_than_sign,
  equals_sign,
  greater_than_sign,
  question_mark,
  at_sign,
  capital_a,
  capital_b,
  capital_c,
  capital_d,
  capital_e,
  capital_f,
  capital_g,
  capital_h,
  capital_i,
  capital_j,
  capital_k,
  capital_l,
  capital_m,
  capital_n,
  capital_o,
  capital_p,
  capital_q,
  capital_r,
  capital_s,
  capital_t,
  capital_u,
  capital_v,
  capital_w,
  capital_x,
  capital_y,
  capital_z,
  open_bracket,
  backslash,
  close_bracket,
  caret,
  underscore,
  backtick,
  small_a,
  small_b,
  small_c,
  small_d,
  small_e,
  small_f,
  small_g,
  small_h,
  small_i,
  small_j,
  small_k,
  small_l,
  small_m,
  small_n,
  small_o,
  small_p,
  small_q,
  small_r,
  small_s,
  small_t,
  small_u,
  small_v,
  small_w,
  small_x,
  small_y,
  small_z,
  open_brace,
  pipe,
  close_brace,
  tilde,
  delete_char,
  // ------------------------------------
  maybe_euro_sign_unassigned_128,
  maybe_high_sierra_a,
  maybe_high_sierra_e,
  maybe_high_sierra_i,
  maybe_high_sierra_o,
  maybe_high_sierra_u,
  maybe_dagger,
  maybe_double_dagger,
  maybe_bullet,
  maybe_ellipsis,
  maybe_per_mille_sign,
  maybe_euro_sign_unassigned_139,
  maybe_euro_sign_unassigned_140,
  maybe_open_curly_quote_single,
  maybe_close_curly_quote_single,
  maybe_open_curly_quote_double,
  maybe_close_curly_quote_double,
  maybe_bullet_alt,
  maybe_dash_en,
  maybe_dash_em,
  maybe_trade_mark_sign,
  maybe_ellipsis_alt,
  maybe_copyright_sign,
  maybe_registered_sign,
  maybe_euro_sign_159,
  maybe_non_breaking_space,
  maybe_inverted_exclamation,
  maybe_cent_sign,
  maybe_pound_sign,
  maybe_currency_sign,
  maybe_yen_sign,
  maybe_broken_bar,
  maybe_section_sign,
  maybe_diaeresis,
  maybe_copyright_sign_alt,
  maybe_feminine_ordinal,
  maybe_right_angle_quote_single,
  maybe_half_fraction,
  maybe_quarter_fraction,
  maybe_inverted_question,
  maybe_registered_sign_alt,
  maybe_macron,
  maybe_degree_sign,
  maybe_plus_minus_sign,
  maybe_superscript_two,
  maybe_superscript_three,
  maybe_acute_accent,
  maybe_micro_sign,
  maybe_paragraph_sign,
  maybe_middle_dot,
  maybe_cedilla,
  maybe_superscript_one,
  maybe_masculine_ordinal,
  maybe_right_angle_quote_double,
  maybe_three_quarters_fraction,
  maybe_ae_ligature,
  maybe_soft_hyphen,
  maybe_a_with_grave,
  maybe_a_with_acute,
  maybe_a_with_circumflex,
  maybe_a_with_tilde,
  maybe_a_with_diaeresis,
  maybe_a_with_ring,
  maybe_ae_capital_ligature,
  maybe_c_with_cedilla,
  maybe_e_with_grave,
  maybe_e_with_acute,
  maybe_e_with_circumflex,
  maybe_e_with_diaeresis,
  maybe_i_with_grave,
  maybe_i_with_acute,
  maybe_i_with_circumflex,
  maybe_i_with_diaeresis,
  maybe_eth_capital,
  maybe_n_with_tilde,
  maybe_o_with_grave,
  maybe_o_with_acute,
  maybe_o_with_circumflex,
  maybe_o_with_tilde,
  maybe_o_with_diaeresis,
  maybe_multiply_sign,
  maybe_o_slash,
  maybe_u_with_grave,
  maybe_u_with_acute,
  maybe_u_with_circumflex,
  maybe_u_with_diaeresis,
  maybe_y_with_acute,
  maybe_thorn_capital,
  maybe_sharp_s,
  maybe_eth_small,
  maybe_n_with_tilde_capital,
  maybe_o_with_grave_capital,
  maybe_o_with_acute_capital,
  maybe_o_with_circumflex_capital,
  maybe_o_with_tilde_capital,
  maybe_o_with_diaeresis_capital,
  maybe_division_sign,
  maybe_o_slash_capital,
  maybe_u_with_grave_capital,
  maybe_u_with_acute_capital,
  maybe_u_with_circumflex_capital,
  maybe_u_with_diaeresis_capital,
  maybe_y_with_acute_capital,
  maybe_thorn_small,
  maybe_y_with_diaeresis,
  // ------------------------------------
  either_end_or_failure = 256,
  intlit,
  floatlit,
  id,
  dqstring,
  sqstring,
  eq,
  notq,
  lesseq,
  greatereq,
  andand,
  oror,
  shl,
  shr,
  plusplus,
  minusminus,
  pluseq,
  minuseq,
  multeq,
  diveq,
  modeq,
  andeq,
  oreq,
  xoreq,
  arrow,
  eqarrow,
  shleq,
  shreq,
}

lexer :: struct {
  file:    string,
  content: []u8,
  cursor:  uint,
  row:     uint,
  col:     uint,
  token:   token,
}


token :: struct {
  type:      token_id,
  int_lit:   i64,
  float_lit: f64,
  str:       string,
}

string_to_u8 :: proc(s: ^string) -> Maybe([]u8) {
  return slice.from_ptr(cast(^u8)strings.clone_to_cstring(s^), len(s))
}


init_lexer :: proc(file: string) -> lexer {
  l: lexer
  l.file = file

  str, _ := read_file(file)
  str, _ = strings.replace_all(str, "\r\n", "\n")
  l.content, _ = string_to_u8(&str).? // TODO: maybe check this?
  delete(str)

  return l
}

get_token :: proc(l: ^lexer) {
  l.token.type = .null_char
  l.token.int_lit = 0
  l.token.float_lit = 0
  l.token.str = ""

  if l.cursor == len(l.content) {
    l.token.type = .either_end_or_failure
    return
  }

  for l.content[l.cursor] == ' ' || l.content[l.cursor] == '\t' {
    l.cursor += 1
    l.col += 1
  }

  if b, ok := (peek_at_index(l.content, l.cursor + 1)).?;
     ok == true && l.content[l.cursor] == '/' && b == '/' {
    l.cursor += 1
    for l.cursor < len(l.content) && l.content[l.cursor] != '\n' do l.cursor += 1
    get_token(l)
    return
  }

  if is_alphabetical(l.content[l.cursor]) {
    s := l.cursor
    l.cursor += 1
    for l.cursor < len(l.content) && is_alphanumerical(l.content[l.cursor]) do l.cursor += 1
    l.token.str = (string(l.content[s:l.cursor]))
    l.token.type = .id
    l.col += l.cursor - s
  } else if b, ok := peek_at_index(l.content, l.cursor + 1).?;
     is_numerical(l.content[l.cursor]) || (ok && l.content[l.cursor] == '-' && is_numerical(b)) {
    s := l.cursor
    l.cursor += 1
    for l.cursor < len(l.content) &&
        (is_numerical(l.content[l.cursor]) || l.content[l.cursor] == '.') {l.cursor += 1}
    if l.cursor < len(l.content) && l.content[l.cursor] == 'x' {
      l.cursor += 1
      for l.cursor < len(l.content) && is_hex_numerical(l.content[l.cursor]) do l.cursor += 1
    }
    if l.cursor < len(l.content) && l.content[l.cursor] == 'o' {
      l.cursor += 1
      for l.cursor < len(l.content) && is_octal_numerical(l.content[l.cursor]) do l.cursor += 1
    }
    if l.cursor < len(l.content) && l.content[l.cursor] == 'b' {
      l.cursor += 1
      for l.cursor < len(l.content) && is_binary_numerical(l.content[l.cursor]) do l.cursor += 1
    }
    if strings.contains(string(l.content[s:l.cursor]), ".") {
      l.token.type = .floatlit
      l.token.float_lit, _ = strconv.parse_f64(string(l.content[s:l.cursor]))
    } else {
      l.token.type = .intlit
      l.token.int_lit, _ = strconv.parse_i64(string(l.content[s:l.cursor]))
    }
    l.col += l.cursor - s
  } else if l.content[l.cursor] == '\n' {
    l.row += 1
    l.col = 0
    l.cursor += 1
    get_token(l)
    return
  } else if l.content[l.cursor] == '\'' {
    l.cursor += 1
    l.token.type = .sqstring
    s := l.cursor
    for l.cursor < len(l.content) && l.content[l.cursor] != '\'' {
      if l.content[l.cursor] == '\\' do l.cursor += 1
      l.cursor += 1
    }
    l.col += l.cursor - s + 2

    if l.cursor - s == 1 {
      l.token.type = auto_cast l.content[s]
    } else {
      l.token.str = string(l.content[s:l.cursor])
    }
    l.cursor += 1
  } else if l.content[l.cursor] == '"' {
    l.cursor += 1
    l.token.type = .dqstring
    s := l.cursor
    for l.cursor < len(l.content) && l.content[l.cursor] != '"' {
      if l.content[l.cursor] == '\\' do l.cursor += 1
      l.cursor += 1
    }
    l.col += l.cursor - s + 2
    l.token.str = string(l.content[s:l.cursor])
    l.cursor += 1
  } else if b, ok := (peek_at_index(l.content, l.cursor + 1)).?; ok == true {
    if l.content[l.cursor] == '=' && b == '=' {
      l.token.type = .eq
      l.cursor += 2
    } else if l.content[l.cursor] == '<' && b == '=' {
      l.token.type = .lesseq
      l.cursor += 2
    } else if l.content[l.cursor] == '>' && b == '=' {
      l.token.type = .greatereq
      l.cursor += 2
    } else if l.content[l.cursor] == '+' && b == '=' {
      l.token.type = .pluseq
      l.cursor += 2
    } else if l.content[l.cursor] == '-' && b == '=' {
      l.token.type = .minuseq
      l.cursor += 2
    } else if l.content[l.cursor] == '/' && b == '=' {
      l.token.type = .diveq
      l.cursor += 2
    } else if l.content[l.cursor] == '*' && b == '=' {
      l.token.type = .multeq
      l.cursor += 2
    } else if l.content[l.cursor] == '%' && b == '=' {
      l.token.type = .modeq
      l.cursor += 2
    } else if l.content[l.cursor] == '&' && b == '=' {
      l.token.type = .andeq
      l.cursor += 2
    } else if l.content[l.cursor] == '|' && b == '=' {
      l.token.type = .oreq
      l.cursor += 2
    } else if l.content[l.cursor] == '^' && b == '=' {
      l.token.type = .xoreq
      l.cursor += 2
    } else if l.content[l.cursor] == '-' && b == '>' {
      l.token.type = .arrow
      l.cursor += 2
    } else if l.content[l.cursor] == '=' && b == '>' {
      l.token.type = .eqarrow
      l.cursor += 2
    } else if l.content[l.cursor] == '!' && b == '=' {
      l.token.type = .notq
      l.cursor += 2
    } else if l.content[l.cursor] == '&' && b == '&' {
      l.token.type = .andand
      l.cursor += 2
    } else if l.content[l.cursor] == '|' && b == '|' {
      l.token.type = .oror
      l.cursor += 2
    } else if l.content[l.cursor] == '+' && b == '+' {
      l.token.type = .plusplus
      l.cursor += 2
    } else if l.content[l.cursor] == '-' && b == '-' {
      l.token.type = .minusminus
      l.cursor += 2
    } else if l.content[l.cursor] == '<' && b == '<' {
      l.token.type = .shl
      l.cursor += 1
      a, ok2 := peek_at_index(l.content, l.cursor + 1).?
      if ok2 && a == '=' {
        l.token.type = .shleq
        l.cursor += 1
      }
      l.cursor += 1
    } else if l.content[l.cursor] == '>' && b == '>' {
      l.token.type = .shr
      l.cursor += 1
      a, ok2 := peek_at_index(l.content, l.cursor + 1).?
      if ok2 && a == '=' {
        l.token.type = .shreq
        l.cursor += 1
      }
      l.cursor += 1
    } else {
      l.token.type = auto_cast l.content[l.cursor]
      l.cursor += 1
      l.col += 1
    }
  } else {
    l.token.type = auto_cast l.content[l.cursor]
    l.cursor += 1
    l.col += 1
  }
}

peek_at_index :: proc(l: []u8, index: uint) -> Maybe(byte) {
  if index >= len(l) do return nil
  return l[index]
}

read_file :: proc(file: string) -> (res: string, err: os.Error) {
  file, ferr := os.open(file)
  if ferr != nil {
    return "", ferr
  }
  defer os.close(file)

  buff_size, _ := os.file_size(file)
  buf := make([]byte, buff_size)
  for {
    n, _ := os.read(file, buf)
    if n == 0 do break
  }

  return string(buf), nil
}

is_whitespace :: proc(c: byte) -> bool {
  return c == ' ' || c == '\t' || c == '\r'
}

is_numerical :: proc(c: byte) -> bool {
  return c >= '0' && c <= '9'
}

is_alphabetical :: proc(c: byte) -> bool {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

is_hex_numerical :: proc(c: byte) -> bool {
  cc := c
  if c <= 'z' && c >= 'a' do cc -= 32
  return is_numerical(cc) || (cc <= 'F' && cc >= 'A')
}

is_binary_numerical :: proc(c: byte) -> bool {
  return c == '0' || c == '1'
}

is_octal_numerical :: proc(c: byte) -> bool {
  return c >= '0' && c <= '7'
}

is_alphanumerical :: proc(c: byte) -> bool {
  return is_numerical(c) || is_alphabetical(c) || c == '_'
}