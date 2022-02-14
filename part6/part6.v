module main
import os

const (
	integer = 'INTEGER'
	plus = 'PLUS'
	minus = 'MINUS'
	mul = 'MUL'
	div = 'DIV'
	lparen = 'LPAREN'
	rparen = 'RPAREN'
	eof = 'EOF'
)

struct Token {
	kind string
	value string
}

fn new_token(kind string, value string) Token {
	return Token{
		kind: kind
		value: value
	}
}

fn (mut t Token) str() string {
	return "Token(${t.kind}, ${t.value})"
}

struct Lexer {
	text string
mut:
	pos int
	current_char byte
}

fn new_lexer(text string) Lexer {
	mut l := Lexer {
		text: text
		pos: 0
	}
	l.current_char = l.text[l.pos]
	return l
}

fn (mut l Lexer) advance() {
	l.pos += 1
	if l.pos >= l.text.len {
		l.current_char = 0
	} else {
		l.current_char = l.text[l.pos]
	}
}

fn (mut l Lexer) skip_whitespace() {
	for l.current_char != 0 && l.current_char.is_space() {
		l.advance()
	}
}

fn (mut l Lexer) integer() string {
	mut lexeme := ""
	for l.current_char != 0 && l.current_char.is_digit() {
		lexeme += l.current_char.ascii_str()
		l.advance()
	}
	return lexeme
}

fn (mut l Lexer) get_next_token() ?Token {
	for l.current_char != 0 {
		if l.current_char.is_space() {
			l.skip_whitespace()
			continue
		}
		if l.current_char.is_digit() {
			return new_token(integer, l.integer())
		}
		if l.current_char == `+` {
			l.advance()
			return new_token(plus, '+')
		}
		if l.current_char == `-` {
			l.advance()
			return new_token(minus, '-')
		}
		if l.current_char == `*` {
			l.advance()
			return new_token(mul, '*')
		}
		if l.current_char == `/` {
			l.advance()
			return new_token(div, '/')
		}
		if l.current_char == `(` {
			l.advance()
			return new_token(lparen, '(')
		}
		if l.current_char == `)` {
			l.advance()
			return new_token(rparen, ')')
		}
		return error('Unknown character `${l.current_char.ascii_str()}`')
	}
	return new_token(eof, '')
}

struct Interpreter {
mut:
	lexer Lexer
	current_token Token
}

fn new_interpreter(mut lexer Lexer) ?Interpreter {
	mut i := Interpreter {
		lexer: lexer
	}
	i.current_token = i.lexer.get_next_token() or { return err }
	return i
}

fn (mut i Interpreter) eat(token_kind string) ? {
	if i.current_token.kind == token_kind {
		i.current_token = i.lexer.get_next_token() or { return err }
	} else {
		return error('Unexpected token `${i.current_token.kind}` expected `${token_kind}`')
	}
}

fn (mut i Interpreter) factor() ?int {	
	mut token := i.current_token
	if token.kind == integer {		
		i.eat(integer) or { return err }
		return token.value.int()
	} else if token.kind == lparen {
		i.eat(lparen) or { return err }
		result := i.expr() or { return err }
		i.eat(rparen) or { return err }
		return result
	}
	return error('Unknown token `${token.kind}`')
}

fn (mut i Interpreter) term() ?int {
	mut result := i.factor() or { return err }
	for i.current_token.kind in ['MUL', 'DIV'] {
		mut token := i.current_token
		if token.kind == mul {
			i.eat(mul) or { return err }
			result *= i.factor() or { return err }
		} else if token.kind == div {
			i.eat(div) or { return err }
			result /= i.factor() or { return err }
		}
	}
	return result
}

fn (mut i Interpreter) expr() ?int {
	mut result := i.term() or { return err }
	for i.current_token.kind in ['PLUS', 'MINUS'] {
		mut token := i.current_token
		if token.kind == plus {
			i.eat(plus) or { return err }
			result += i.term() or { return err }
		} else if token.kind == minus {
			i.eat(minus) or { return err }
			result -= i.term() or { return err }
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
		mut l := new_lexer(text)
		mut i := new_interpreter(mut l) or {
			println(err.msg)
			continue
		}
		result := i.expr() or {
			println(err.msg)
			continue
		}
		println(result)
	}
}