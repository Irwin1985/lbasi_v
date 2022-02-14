module main
import os

pub const (
	integer = 'INTEGER'
	plus = 'PLUS'
	minus = 'MINUS'
	eof = 'EOF'
)

pub struct Token {
mut:
	kind string
pub mut:
	value string	
}

pub fn new_token(kind string, value string) Token {
	return Token {
		kind: kind
		value: value
	}
}

pub fn (mut t Token) str() string {
	return "Token(${t.kind}, ${t.value})"
}

pub struct Interpreter {
	text string
mut:
	pos int
	current_token Token
	current_char byte
}

pub fn new_interpreter(text string) Interpreter {
	mut i := Interpreter {
		text: text
		pos: 0
		current_token: Token{}
		current_char: 0
	}
	i.current_char = i.text[i.pos]
	return i
}

fn (mut i Interpreter) advance() {
	i.pos += 1
	if i.pos >= i.text.len {
		i.current_char = 0
	} else {
		i.current_char = i.text[i.pos]
	}
}

fn (mut i Interpreter) skip_whitespace() {
	for i.current_char != 0 && isspace(i.current_char) {
		i.advance()
	}
}

fn (mut i Interpreter) integer() string {
	mut result := ""
	for i.current_char != 0 && isdigit(i.current_char) {
		result += i.current_char.ascii_str()
		i.advance()
	}
	return result
}

pub fn (mut i Interpreter) get_next_token() ?Token {
	for i.current_char != 0 {
		if isspace(i.current_char) {
			i.skip_whitespace()
			continue
		}

		if isdigit(i.current_char) {
			return new_token(integer, i.integer())
		}

		if i.current_char == `+` {
			i.advance()
			return new_token(plus, "+")
		}

		if i.current_char == `-` {
			i.advance()
			return new_token(minus, "-")
		}

		return error('Error parsing input.')
	}
	return new_token(eof, '')
}

fn (mut i Interpreter) eat(token_type string) ? {
	if i.current_token.kind == token_type {
		i.current_token = i.get_next_token() or { return err }
	} else {
		return error('Error parsing input')
	}
}

pub fn (mut i Interpreter) expr() ?int {
	i.current_token = i.get_next_token() or { return err }

	mut left := i.current_token
	i.eat(integer) or { return err }

	op := i.current_token
	if op.kind == plus {
		i.eat(plus) or { return err }
	} else {
		i.eat(minus) or { return err }
	}

	mut right := i.current_token
	i.eat(integer) or { return err }

	mut result := 0
	l := left.value.int()
	r := right.value.int()
	if op.kind == plus {
		result = l + r
	} else {
		result = l - r
	}
	return result
}

fn isspace(c byte) bool {
	return c == `\r` || c == `\n` || c == `\t` || c == ` `
}

fn isdigit(c byte) bool {
	return `0` <= c && c <= `9`
}


fn main() {
	for {
		text := os.input('calc> ')
		if text.len == 0 {
			continue
		}
		mut i := new_interpreter(text)
		result := i.expr() or { panic(err) }
		println(result)
	}
}
