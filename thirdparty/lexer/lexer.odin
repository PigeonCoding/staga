package lexer
// vendored from https://github.com/PigeonCoding/pigeon.odin (lexer/lexer.odin)
// v0.5.0
// - v0.5.0 changelog:
// -- added token_id.custom + lexer.custom hook
//    (proc(l: ^lexer), mutates l.token to override)
// -- added peek_token lookahead helper so the hook can detect
//    patterns like `<name> :: fn` without affecting the lexer
// - v0.4.0 changelog:
// -- added basic math/single-char ops: plus, minus, mult, div, mod, xor, power,
//    and, or, tilde, not, less, greater, assign (single-char ops no longer
//    fall back to punct)
// - v0.3.1 changelog:
// -- get_token() now returns a bool to indicate if it reached the EOF
// - v0.3 changelog:
// -- use punct token_id and put the char/punt in intlit
// -- added custom bases for numbers ex: 12#AAA
// -- added more error checking for number parsing
// - v0.2 changelog:
// -- added check_type
// -- added the ascii character for most token_ids
// -- init_lexer now handles errors
// -- fixed l.col and l.row sometimes not being correct
// -- added a row and col and file to token


import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

token_id :: enum {
	none,
	punct,
	either_end_or_failure,
	intlit,
	charlit,
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
	// basic math / single-char ops (v0.4.0, no longer punct fallback)
	plus,
	minus,
	mult,
	div,
	mod,
	xor,
	power,
	and,
	or,
	tilde,
	not,
	less,
	greater,
	assign,
	custom,
}

lexer :: struct {
	file:    string,
	content: []u8,
	cursor:  uint,
	token:   token,
	row:     uint,
	col:     uint,
	// Optional hook for user-defined keywords / special types.
	// Called at the end of `get_token`, before returning, after the token is
	// fully lexed — so it can hijack/override any original type, not just `.id`.
	// Gets both the live lexer (`l`) and a copy (`c`) it may modify freely
	// (cursor, row, col, token, ...). Mutate the copy and return it; the
	// returned copy replaces the real lexer. Use `l` for inspection and
	// lookahead, `c` for mutation.
	// Inspect `c.token.type` / `c.token.str` for the lexer's choice and set
	// `m.token.type` (usually to `.custom`) to override it. Return `m`
	// unmodified to keep the original lexing.
	// (Note: Odin procedure parameters are immutable, so copy to a mutable
	// local first: `m := c`, mutate `m`, then `return m`.)
	// Use `peek_token(l, n)` for lookahead: it lexes the nth next token
	// from a copy, so the real lexer is unaffected. Peeked tokens are raw
	// (the `custom` hook is disabled while peeking, so a hook calling
	// `peek_token` cannot recurse into itself).
	// Example - plain keywords:
	//   is_my_keyword :: proc(l: ^lexer, c: lexer) -> lexer {
	//     m := c
	//     if m.token.type == .id && (m.token.str == "mytype" || m.token.str == "foreach") {
	//       m.token.type = .custom
	//     }
	//     return m
	//   }
	//   l.custom = is_my_keyword
	// Example - hijack an original type (e.g. treat `**` power as custom):
	//   hijack :: proc(l: ^lexer, c: lexer) -> lexer {
	//     m := c
	//     if m.token.type == .power do m.token.type = .custom
	//     return m
	//   }
	// Example - detect `<name> :: fn` (vcode fn definition):
	//   (`::` lexes as two `:` puncts, so look 3 tokens ahead.)
	//   is_fn_name :: proc(l: ^lexer, c: lexer) -> lexer {
	//     m := c
	//     if m.token.type != .id do return m
	//     c1, ok1 := peek_token(l, 1)
	//     c2, ok2 := peek_token(l, 2)
	//     c3, ok3 := peek_token(l, 3)
	//     if !ok1 || !ok2 || !ok3 do return m
	//     if c1.type != .punct || c1.intlit != ':' do return m
	//     if c2.type != .punct || c2.intlit != ':' do return m
	//     if c3.type == .id && c3.str == "fn" do m.token.type = .custom
	//     return m
	//   }
	custom:  proc(l: ^lexer, c: lexer),
}

token :: struct {
	type:        token_id,
	intlit:      i64,
	floatlit:    f64,
	str:         string,
	file:        string,
	row:         uint,
	col:         uint,
	custom_data: u64,
}

decode_escapes :: proc(raw: string, file: string, row: uint, col: uint) -> (string, bool) {
	out: [dynamic]u8
	i := 0
	for i < len(raw) {
		ch := raw[i]
		if ch != '\\' {
			append(&out, ch)
			i += 1
			continue
		}
		if i + 1 >= len(raw) {
			fmt.eprintfln("%s:%d:%d invalid trailing escape in string literal", file, row, col)
			return "", false
		}

		esc := raw[i + 1]
		switch esc {
		case 'n':
			append(&out, '\n')
		case 'r':
			append(&out, '\r')
		case 't':
			append(&out, '\t')
		case '\\':
			append(&out, '\\')
		case '\'':
			append(&out, '\'')
		case '"':
			append(&out, '"')
		case:
			fmt.eprintfln("%s:%d:%d unknown escape sequence '\\%c'", file, row, col, esc)
			return "", false
		}
		i += 2
	}
	return string(out[:]), true
}

string_to_u8 :: proc(s: ^string) -> Maybe([]u8) {
	return slice.from_ptr(cast(^u8)strings.clone_to_cstring(s^), len(s))
}

check_type :: proc(l: ^lexer, expected: token_id, prt: bool = true) -> bool {
	if l.token.type != expected && prt {
		fmt.eprintfln(
			"%s:%d:%d expected {} but got {}",
			l.token.file,
			l.token.row + 1,
			l.col,
			expected,
			l.token.type,
		)
	}
	return l.token.type == expected
}


init_lexer :: proc(file: string) -> lexer {
	l: lexer
	l.file = file
	l.token.file = file

	str, err := read_file(file)
	if err != nil {
		fmt.eprintfln("could not open file %s, because {}", file, err)
	}
	str, _ = strings.replace_all(str, "\r\n", "\n")
	str = expand_includes(file, str, 0)
	l.content, _ = string_to_u8(&str).?
	if len(l.content) == 0 {
		fmt.println("file", file, "is empty")
		os.exit(1)
	}
	delete(str)

	return l
}

is_path_sep :: proc(c: byte) -> bool {
	return c == '/' || c == '\\'
}

is_abs_path :: proc(p: string) -> bool {
	if len(p) == 0 do return false
	if is_path_sep(p[0]) do return true
	if len(p) >= 2 && p[1] == ':' do return true
	return false
}

path_dir :: proc(p: string) -> string {
	if len(p) == 0 do return ""
	for i := int(len(p)) - 1; i >= 0; i -= 1 {
		if is_path_sep(p[auto_cast i]) {
			if i == 0 do return string(p[:1])
			return string(p[:i])
		}
	}
	return ""
}

join_path :: proc(dir: string, rel: string) -> string {
	if dir == "" do return rel
	if len(dir) == 0 do return rel
	if is_path_sep(dir[len(dir) - 1]) {
		return strings.concatenate({dir, rel})
	}
	return strings.concatenate({dir, "/", rel})
}

parse_include_line :: proc(line: string) -> (path: string, ok: bool) {
	i := 0
	for i < len(line) && (line[i] == ' ' || line[i] == '\t') do i += 1
	if i + 8 > len(line) do return "", false
	if line[i] != '$' do return "", false
	if string(line[i:i + 8]) != "$include" do return "", false
	i += 8
	for i < len(line) && (line[i] == ' ' || line[i] == '\t') do i += 1
	if i >= len(line) || line[i] != '"' do return "", false
	i += 1
	start := i
	for i < len(line) && line[i] != '"' do i += 1
	if i >= len(line) do return "", false
	return string(line[start:i]), true
}

expand_includes :: proc(file: string, content: string, depth: int) -> string {
	if depth > 32 {
		fmt.eprintfln("include depth exceeded while processing %s", file)
		os.exit(1)
	}

	dir := path_dir(file)
	b: strings.Builder
	strings.builder_init(&b)

	line_start := 0
	i := 0
	for i <= len(content) {
		if i == len(content) || content[i] == '\n' {
			line := string(content[line_start:i])
			inc_path, ok := parse_include_line(line)
			if ok {
				full := inc_path
				if !is_abs_path(inc_path) {
					full = join_path(dir, inc_path)
				}
				inc_str, err := read_file(full)
				if err != nil {
					fmt.eprintfln("could not open include file %s, because {}", full, err)
					os.exit(1)
				}
				inc_str, _ = strings.replace_all(inc_str, "\r\n", "\n")
				inc_str = expand_includes(full, inc_str, depth + 1)
				fmt.sbprintf(&b, "%s", inc_str)
				if len(inc_str) == 0 || inc_str[len(inc_str) - 1] != '\n' {
					fmt.sbprintf(&b, "\n")
				}
				delete(inc_str)
			} else {
				fmt.sbprintf(&b, "%s", line)
				if i < len(content) {
					fmt.sbprintf(&b, "\n")
				}
			}
			line_start = i + 1
		}
		i += 1
	}

	return strings.to_string(b)
}

get_token :: proc(l: ^lexer) -> bool {
	l.token.type = .none
	l.token.intlit = 0
	l.token.floatlit = 0
	l.token.str = ""

	if l.cursor >= len(l.content) {
		l.token.type = .either_end_or_failure
		return false
	}

	for l.cursor < len(l.content) && (l.content[l.cursor] == ' ' || l.content[l.cursor] == '\t') {
		l.cursor += 1
		l.col += 1
	}

	if l.cursor >= len(l.content) {
		l.token.type = .either_end_or_failure
		return false
	}

	if b, ok := (peek_at_index(l.content, l.cursor + 1)).?;
	   ok == true && l.content[l.cursor] == '/' && b == '/' {
		l.cursor += 1
		for l.cursor < len(l.content) && l.content[l.cursor] != '\n' {
			l.cursor += 1
			l.col += 1
		}

		return get_token(l)
	}

	if is_alphabetical(l.content[l.cursor]) {
		s := l.cursor

		l.token.col = l.col
		l.token.row = l.row + 1

		l.cursor += 1
		for l.cursor < len(l.content) && is_alphanumerical(l.content[l.cursor]) do l.cursor += 1
		l.token.str = (string(l.content[s:l.cursor]))
		l.token.type = .id
		l.col += l.cursor - s
	} else if b, ok := peek_at_index(l.content, l.cursor + 1).?;
	   is_numerical(l.content[l.cursor]) || (ok && l.content[l.cursor] == '-' && is_numerical(b)) {

		digits: []byte = {
			'1',
			'2',
			'3',
			'4',
			'5',
			'6',
			'7',
			'8',
			'9',
			'A',
			'B',
			'C',
			'D',
			'E',
			'F',
		}

		s := l.cursor
		base := 10
		l.token.col = l.col
		l.token.row = l.row + 1

		l.cursor += 1
		for l.cursor < len(l.content) && (is_numerical(l.content[l.cursor]) || l.content[l.cursor] == '.') do l.cursor += 1

		if l.cursor < len(l.content) &&
		   (l.content[l.cursor] == 'x' ||
				   l.content[l.cursor] == 'o' ||
				   l.content[l.cursor] == 'b' ||
				   l.content[l.cursor] == '#') {

			switch l.content[l.cursor] {
			case 'b':
				base = 2
			case 'o':
				base = 8
			case 'x':
				base = 16
			case '#':
				base, _ = strconv.parse_int(string(l.content[s:l.cursor]))
			}

			if base > 16 || base < 1 {
				fmt.eprintfln(
					"%s:%d:%d ERROR: base must be between 1-16",
					l.file,
					l.token.row,
					l.token.col,
				)
				os.exit(1)
			}

			l.cursor += 1
			s = l.cursor

			for l.cursor < len(l.content) && is_alphanumerical(l.content[l.cursor]) do l.cursor += 1
		}
		ok: bool
		if strings.contains(string(l.content[s:l.cursor]), ".") {
			l.token.type = .floatlit
			l.token.floatlit, ok = strconv.parse_f64(string(l.content[s:l.cursor]))
			if !ok {
				fmt.eprintfln(
					"there was an error parsing the the number '%s'",
					string(l.content[s:l.cursor]),
				)
				os.exit(1)
			}
		} else {
			l.token.type = .intlit
			if l.token.intlit, ok = strconv.parse_i64_of_base(
				string(l.content[s:l.cursor]),
				base,
				auto_cast &l.token.intlit,
			); !ok {
				fmt.eprintfln(
					"there was an error parsing the the number '%s' in the base '%d', max valid digit is '%c'",
					string(l.content[s:l.cursor]),
					base,
					digits[base - 2],
				)
				os.exit(1)
			}
		}
		l.col += l.cursor - s

	} else if l.content[l.cursor] == '\n' {
		l.row += 1
		l.col = 0
		l.cursor += 1

		return get_token(l)
	} else if l.content[l.cursor] == '\'' {
		l.cursor += 1
		l.token.type = .sqstring

		l.token.col = l.col
		l.token.row = l.row + 1

		s := l.cursor
		for l.cursor < len(l.content) && l.content[l.cursor] != '\'' {
			if l.content[l.cursor] == '\\' do l.cursor += 1
			l.cursor += 1
		}
		if l.cursor >= len(l.content) {
			fmt.eprintfln(
				"%s:%d:%d unterminated single-quoted literal",
				l.file,
				l.token.row,
				l.token.col,
			)
			os.exit(1)
		}
		l.col += l.cursor - s + 2

		raw := string(l.content[s:l.cursor])
		decoded, ok := decode_escapes(raw, l.file, l.token.row, l.token.col)
		if !ok {
			os.exit(1)
		}

		if len(decoded) == 1 {
			l.token.intlit = auto_cast decoded[0]
			l.token.type = .charlit
		} else {
			l.token.str = decoded
		}
		l.cursor += 1
	} else if l.content[l.cursor] == '"' {
		l.cursor += 1
		l.token.type = .dqstring

		l.token.col = l.col
		l.token.row = l.row + 1

		s := l.cursor
		for l.cursor < len(l.content) && l.content[l.cursor] != '"' {
			if l.content[l.cursor] == '\\' do l.cursor += 1
			l.cursor += 1
		}
		if l.cursor >= len(l.content) {
			fmt.eprintfln(
				"%s:%d:%d unterminated double-quoted literal",
				l.file,
				l.token.row,
				l.token.col,
			)
			os.exit(1)
		}
		l.col += l.cursor - s + 2
		raw := string(l.content[s:l.cursor])
		decoded, ok := decode_escapes(raw, l.file, l.token.row, l.token.col)
		if !ok {
			os.exit(1)
		}
		l.token.str = decoded
		l.cursor += 1
	} else if b, ok := (peek_at_index(l.content, l.cursor + 1)).?; ok == true {
		if l.content[l.cursor] == '=' && b == '=' {

			l.token.col = l.col
			l.token.row = l.row + 1

			l.token.type = .eq
			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '<' && b == '=' {

			l.token.col = l.col
			l.token.row = l.row + 1

			l.token.type = .lesseq
			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '>' && b == '=' {
			l.token.type = .greatereq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '+' && b == '=' {
			l.token.type = .pluseq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '-' && b == '=' {
			l.token.type = .minuseq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '/' && b == '=' {
			l.token.type = .diveq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '*' && b == '=' {
			l.token.type = .multeq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '%' && b == '=' {
			l.token.type = .modeq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '&' && b == '=' {
			l.token.type = .andeq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '|' && b == '=' {
			l.token.type = .oreq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '^' && b == '=' {
			l.token.type = .xoreq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '-' && b == '>' {
			l.token.type = .arrow

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '=' && b == '>' {
			l.token.type = .eqarrow

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '!' && b == '=' {
			l.token.type = .notq

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '&' && b == '&' {
			l.token.type = .andand

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '|' && b == '|' {
			l.token.type = .oror

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '+' && b == '+' {
			l.token.type = .plusplus

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '-' && b == '-' {
			l.token.type = .minusminus

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if l.content[l.cursor] == '<' && b == '<' {
			l.token.type = .shl

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 1
			a, ok2 := peek_at_index(l.content, l.cursor + 1).?
			if ok2 && a == '=' {
				l.token.type = .shleq
				l.col += 1
				l.cursor += 1
			}
			l.cursor += 1
		} else if l.content[l.cursor] == '>' && b == '>' {
			l.token.type = .shr

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 1
			a, ok2 := peek_at_index(l.content, l.cursor + 1).?
			if ok2 && a == '=' {
				l.token.type = .shreq
				l.col += 1
				l.cursor += 1
			}
			l.cursor += 1
		} else if l.content[l.cursor] == '*' && b == '*' {
			l.token.type = .power

			l.token.col = l.col
			l.token.row = l.row + 1

			l.col += 2
			l.cursor += 2
		} else if op, is_op := single_char_op(l.content[l.cursor]).?; is_op {
			l.token.type = op
			l.token.col = l.col
			l.token.row = l.row + 1
			l.cursor += 1
			l.col += 1
		} else {
			l.token.intlit = auto_cast l.content[l.cursor]
			l.token.type = .punct
			l.token.col = l.col
			l.token.row = l.row + 1
			l.cursor += 1
			l.col += 1
		}
	} else {
		if op, is_op := single_char_op(l.content[l.cursor]).?; is_op {
			l.token.type = op
			l.token.col = l.col
			l.token.row = l.row + 1
			l.cursor += 1
			l.col += 1
		} else {
			l.token.intlit = auto_cast l.content[l.cursor]
			l.token.type = .punct
			l.token.col = l.col
			l.token.row = l.row + 1
			l.cursor += 1
			l.col += 1
		}
	}

	// User hook: runs at the end, before returning, so it can hijack/override
	// any lexed token (id, number, string, op, punct, ...). The hook gets the
	// live lexer plus a copy it may modify freely;
	if l.custom != nil {
		l.custom(l, l^)
	}

	return true
}

single_char_op :: proc(c: byte) -> Maybe(token_id) {
	switch c {
	case '+':
		return .plus
	case '-':
		return .minus
	case '*':
		return .mult
	case '/':
		return .div
	case '%':
		return .mod
	case '^':
		return .xor
	case '&':
		return .and
	case '|':
		return .or
	case '~':
		return .tilde
	case '!':
		return .not
	case '<':
		return .less
	case '>':
		return .greater
	case '=':
		return .assign
	}
	return nil
}

peek_at_index :: proc(l: []u8, index: uint) -> Maybe(byte) {
	if index >= len(l) do return nil
	return l[index]
}

// Non-destructive lookahead for `custom` hooks (and parsers).
// Lexes the nth next token from a copy of the lexer; the real lexer
// (cursor/row/col/token) is unaffected. `n` starts at 1. Returns the token
// plus false on EOF (token.type is `.either_end_or_failure` then).
// Peeked tokens are raw: the `custom` hook is disabled while peeking so a
// hook calling `peek_token` cannot recurse into itself.
peek_token :: proc(l: ^lexer, n: int = 1) -> (t: token, ok: bool) {
	if n < 1 do return {}, false
	c := l^
	c.custom = nil
	for _ in 0 ..< n {
		if !get_token(&c) do return c.token, false
	}
	return c.token, true
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
