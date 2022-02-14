module main
import os

const (
	integer = 'INTEGER'
	plus = 'PLUS'
	minus = 'MINUS'
	eof = 'EOF'
)


struct Token {
	kind string
	value string
}

fn token_new(kind string, value string) Token {
	mut t := Token {
		kind: kind
		value: value
	}
	return t
}

fn (mut t Token) str() string {
	return "Token(${t.kind}, ${t.value})"
}

struct Interpreter {
	text string
mut:
	pos int
	current_token Token
	current_char byte
}

fn interpreter_new(text string) Interpreter {
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
	for i.current_char != 0 && i.current_char.is_space() {
		i.advance()
	}
}

fn (mut i Interpreter) integer() string {
	mut result := ""
	for i.current_char != 0 && i.current_char.is_digit() {
		result += i.current_char.ascii_str()
		i.advance()
	}
	return result
}

fn (mut i Interpreter) get_next_token() ?Token {
	for i.current_char != 0 {
		if i.current_char.is_space() {
			i.skip_whitespace()
			continue
		}

		if i.current_char.is_digit() {
			return token_new(integer, i.integer())
		}

		if i.current_char == `+` {
			i.advance()
			return token_new(plus, '+')
		}

		if i.current_char == `-` {
			i.advance()
			return token_new(minus, '-')
		}

		return error('Error parsing input')
	}
	return token_new(eof, '')
}

fn (mut i Interpreter) eat(token_type string) ? {
	if i.current_token.kind == token_type {
		i.current_token = i.get_next_token() or { return err }
	} else {
		return error('Error parsing input')
	}
}

fn (mut i Interpreter) term() ?int {
	mut token := i.current_token
	i.eat(integer) or { return err }

	return token.value.int()
}

fn (mut i Interpreter) expr() ?int {
	i.current_token = i.get_next_token() or { return err }

	mut result := i.term() or { return err }
	for i.current_token.kind in ['MINUS', 'PLUS'] {
		mut token := i.current_token
		if token.kind == plus {
			i.eat(plus) or { return err }
			result = result + i.term() or { return err }
		} else if token.kind == minus {
			i.eat(minus) or { return err }
			result = result - i.term() or { return err }
		}
	}

	return result
}

fn main() {
	for {
		text := os.input('calc> ')
		if text.len == 0 {
			continue
		}
		mut i := interpreter_new(text)
		result := i.expr() or {
			println(err.msg)
			break
		}
		println(result)
		/*
		mut tok := i.get_next_token() or { panic(err) }
		for tok.kind != eof {
			println(tok.str())
			tok = i.get_next_token() or { panic(err) }
		}
		println(tok.str())
		*/
	}
}