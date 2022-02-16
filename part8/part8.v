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
	return Token {
		kind: kind
		value: value
	}
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
		return error('Unkown character `${l.current_char.ascii_str()}`')
	}
	return new_token(eof, '')
}


type Ast = int | Num | BinOp | Unary
struct BinOp {
mut:
	left Ast
	token Token
	op Token
	right Ast
}

fn new_bin_op(mut left Ast, mut token Token, mut right Ast) BinOp {
	return BinOp {
		left: left
		token: token
		op: token
		right: right
	}
}

struct Unary {
mut:
	token Token
	op Token
	right Ast
}

fn new_unary(mut token Token, mut right Ast) Unary {
	return Unary {
		token: token
		op: token
		right: right
	}
}

struct Num {
mut:
	value int
}

fn new_num(value int) Num {
	return Num{value}
}

struct Parser {
mut:
	lexer Lexer
	current_token Token
}

fn new_parser(mut lexer Lexer) ?Parser {
	mut p := Parser {
		lexer: lexer
	}
	p.current_token = p.lexer.get_next_token() or { return err }
	return p
}

fn (mut p Parser) eat(token_kind string) ? {
	if p.current_token.kind == token_kind {
		p.current_token = p.lexer.get_next_token() or { return err }
	} else {
		return error('Unexpected token `${p.current_token.kind}` expected `${token_kind}`')
	}
}

fn (mut p Parser) expr() ?Ast {
	mut node := p.term() or { return err }
	for p.current_token.kind in ['PLUS', 'MINUS'] {
		mut token := p.current_token
		p.eat(token.kind) or { return err }
		mut left := node
		mut right := p.term() or { return err }
		node = new_bin_op(mut left, mut token, mut right)
	}
	return node
}

fn (mut p Parser) term() ?Ast {
	mut node := p.factor() or { return err }
	for p.current_token.kind in ['MUL', 'DIV'] {
		mut token := p.current_token
		p.eat(token.kind) or { return err }
		mut left := node
		mut right := p.factor() or { return err }
		node = new_bin_op(mut left, mut token, mut right)
	}
	return node
}

fn (mut p Parser) factor() ?Ast {
	mut token := p.current_token
	match token.kind {
		'PLUS' {
			p.eat(plus) or { return err }
			mut right := p.factor() or { return err }
			return new_unary(mut token, mut right)
		}
		'MINUS' {
			p.eat(minus) or { return err }
			mut right := p.factor() or { return err }
			return new_unary(mut token, mut right)
		}
		'INTEGER' {
			p.eat(integer) or { return err }
			return new_num(token.value.int())
		}
		'LPAREN' {
			p.eat(lparen) or { return err }
			mut node := p.expr() or { return err }
			p.eat(rparen) or { return err }
			return node
		} else {
			return error('Unknown token `${token.kind}`')
		}
	}
}

fn (mut p Parser) parse() ?Ast {
	mut node := p.expr() or { return err }
	/*
	if p.current_token.kind != eof {
		return error('Expected ${eof} at the end of the parsing proccess.')
	}
	*/
	return node
}

fn visit(mut node Ast) ?Ast {
	match node.type_name() {
		'int' {
			return node as int
		}
		'BinOp' {
			mut bin_op := node as BinOp
			return visit_bin_op(mut bin_op) or { return err }
		}
		'Unary' {
			mut unary := node as Unary
			return visit_unary(mut unary) or { return err }
		}
		'Num' {
			mut num := node as Num
			return visit_num(mut num) or { return err }
		} else {
			return error('Invalid sum type `${node.type_name()}`')
		}
	}
}

fn visit_bin_op(mut bin_op BinOp) ?int {
	mut result := visit(mut bin_op.left) or { return err }
	left := result as int
	result = visit(mut bin_op.right) or { return err }
	right := result as int
	match bin_op.op.kind {
		'PLUS' {
			return left + right
		}
		'MINUS' {
			return left - right
		}
		'MUL' {
			return left * right
		}
		'DIV' {
			return left / right
		}
		else {
			return error('Unknown token in binary operation `${bin_op.op.kind}`')
		}
	}
}

fn visit_unary(mut unary Unary) ?int {
	mut result := visit(mut unary.right) or { return err }
	right := result as int
	match unary.op.kind {
		'MINUS' {
			return right * -1
		}
		'PLUS' {
			return right
		}
		else {
			return error('Unknown token in unary operation `${unary.op.kind}`')
		}
	}
}

fn visit_num(mut num Num) ?int {
	return num.value
}


fn main() {
	for {
		text := os.input('spi> ')
		if text.len == 0 {
			continue
		}
		mut l := new_lexer(text)
		mut p := new_parser(mut l) or {
			println(err.msg)
			continue
		}
		mut ast := p.parse() or {
			println(err.msg)
			continue
		}
		result := visit(mut ast) or {
			println(err.msg)
			continue
		}
		println(result as int)
	}
}