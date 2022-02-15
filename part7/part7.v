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

// ======================================================================== //
// PARSER
// ======================================================================== //
type Ast = BinOp | Num | int

struct BinOp {
mut:
	left Ast
	token Token
	op Token
	right Ast
}

fn new_bin_op(left Ast, token Token, right Ast) BinOp {
	return BinOp {
		left: left
		token: token
		op: token
		right: right
	}
}

struct Num {
mut:
	token Token
	value int
}

fn new_num(token Token, value int) Num {
	return Num {
		token: token
		value: value
	}
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

fn (mut p Parser) factor() ?Ast {
	mut token := p.current_token
	if token.kind == integer {
		p.eat(integer) or { return err }
		return new_num(token, token.value.int())
	} else if token.kind == lparen {
		p.eat(lparen) or { return err }
		node := p.expr() or { return err }
		p.eat(rparen) or { return err }
		return node
	} else {
		return error('Unknown token `${token.kind}`')
	}
}

fn (mut p Parser) term() ?Ast {
	mut node := p.factor() or { return err }
	for p.current_token.kind in ['MUL', 'DIV'] {
		token := p.current_token
		p.eat(token.kind) or { return err }
		node = new_bin_op(node, token, p.factor() or { return err })
	}
	return node
}

fn (mut p Parser) expr() ?Ast {
	mut node := p.term() or { return err }
	for p.current_token.kind in ['PLUS', 'MINUS'] {
		token := p.current_token
		p.eat(token.kind) or { return err }
		node = new_bin_op(node, token, p.term() or { return err })
	}
	return node
}

fn (mut p Parser) parse() ?Ast {
	return p.expr() or { return err }
}

// ======================================================================== //
// INTERPRETER
// ======================================================================== //

interface NodeVisitor {
	visit(node Ast) Ast
}


struct Interpreter {
mut:
	parser Parser
}

fn new_interpreter(mut parser Parser) Interpreter {
	mut i := Interpreter {
		parser: parser
	}
	return i
}

fn (mut i Interpreter) visit(mut node Ast) ?Ast {
	match node.type_name() {
		'BinOp' { 
			mut bin_op := node as BinOp
			return i.visit_bin_op(mut bin_op) 
		}
		'Num' {
			mut num := node as Num
			return i.visit_num(mut num)
		}
		else {
			return error('No visit method for ast: `${typeof(node).name}`')
		}
	}
	return error('Unknown node ${node.type_name()}')
}

fn (mut i Interpreter) visit_bin_op(mut node BinOp) ?Ast {
	mut left := 0
	mut right := 0
	mut result := i.visit(mut node.left) or { return err }
	if result.type_name() == 'int' {
		left = result as int
	}

	result = i.visit(mut node.right) or { return err }
	if result.type_name() == 'int' {
		right = result as int
	}

	if node.op.kind == plus {
		return left + right
	} else if node.op.kind == minus {
		return left - right
	} else if node.op.kind == mul {
		return left * right
	} else if node.op.kind == div {
		return left / right
	} else { return error('error visit_bin_op')}
}

fn (mut i Interpreter) visit_num(mut node Num) int {
	return node.value
}

fn (mut i Interpreter) interpret() ?Ast {
	mut tree := i.parser.parse() or { return err }
	return i.visit(mut tree) or { return err }
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
		mut i := new_interpreter(mut p)
		result := i.interpret() or {
			println(err.msg)
			continue
		}
		if result.type_name() == 'int' {
			println(result as int)
		}
	}
}