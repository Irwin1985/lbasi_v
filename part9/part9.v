module main
import os
// SPI - Simple Pascal Interpreter. Part 9.

/*
 This version will parse this grammar:
 program				::= compound_statement DOT
 compound_statement		::= BEGIN statement_list END
 statement_list			::= statement | statement SEMI statement_list
 statement 			 	::= compound_statement | assignment_statement | empty
 assignment_statement 	::= variable ASSIGN expr
 empty					::= NONE
 expr					::= term ((PLUS | MINUS) term)*
 term					::= factor ((MUL | DIV) factor)*
 factor					::= PLUS factor | MINUS factor | INTEGER | LPAREN expr RPAREN | variable
 variable				::= IDENTIFIER
*/

/*
###############################################################################
#                                                                             #
#  LEXER                                                                      #
#                                                                             #
###############################################################################

# Token types
#
# EOF (end-of-file) token is used to indicate that
# there is no more input left for lexical analysis
*/

const (
	integer = 'INTEGER'
	plus = 'PLUS'
	minus = 'MINUS'
	mul = 'MUL'
	div = 'DIV'
	lparen = 'LPAREN'
	rparen = 'RPAREN'
	id = 'ID'
	assign = 'ASSIGN'
	begin = 'BEGIN'
	end = 'END'
	semi = 'SEMI'
	dot = 'DOT'
	eof = 'EOF'
	reserved_keywords = {
		'BEGIN': Token{begin, 'BEGIN'}
		'END': Token{end, 'END'}
	}
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

fn (mut l Lexer) peek() byte {
	peek_pos := l.pos + 1
	if peek_pos >= l.text.len {
		return 0
	}
	return l.text[peek_pos]
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

fn (mut l Lexer) id() Token {
	mut lexeme := ""
	for l.current_char != 0 && l.current_char.is_letter() {
		lexeme += l.current_char.ascii_str()
		l.advance()
	}

	return reserved_keywords[lexeme] or { return new_token(id, lexeme) }
}

fn (mut l Lexer) get_next_token() ?Token {
	for l.current_char != 0 {
		if l.current_char.is_space() {
			l.skip_whitespace()
			continue
		}
		if l.current_char.is_letter() {
			return l.id()
		}
		if l.current_char.is_digit() {
			return new_token(integer, l.integer())
		}
		if l.current_char == `:` && l.peek() == `=` {
			l.advance()
			l.advance()
			return new_token(assign, ':=')
		}
		if l.current_char == `;` {
			l.advance()
			return new_token(semi, ';')
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
		if l.current_char == `.` {
			l.advance()
			return new_token(dot, '.')
		}
	}
	return new_token(eof, '')
}

/*
###############################################################################
#                                                                             #
#  AST                                                                        #
#                                                                             #
###############################################################################
*/

interface Ast {
mut:
	str() string	
}

struct BinOp {
	token Token
	op Token // op no es necesario porque token hace lo mismo.
mut:
	left Ast
	right Ast
}

fn new_bin_op(mut left Ast, token Token, mut right Ast) BinOp {
	return BinOp {
		left: left
		token: token
		op: token
		right: right
	}
}

fn (mut b BinOp) str() string {
	return "binary"
}

struct Unary {
	token Token
	op Token
mut:
	right Ast
}

fn new_unary(token Token, mut right Ast) Unary {
	return Unary{
		token: token
		op: token
		right: right
	}
}

fn (mut u Unary) str() string {
	return "unary"
}

struct Num {
	value int
}

fn new_num(value int) Num {
	return Num {value}
}

fn (mut n Num) str() string {
	return n.value.str()
}

struct Compound {
mut:
	children []Ast
}

fn new_compound(mut children []Ast) Compound {
	return Compound {
		children: children
	}
}

fn (mut c Compound) str() string {
	return "compound"
}

struct Assign {
	op Token
	left string
mut:
	right Ast
}

fn new_assign(left string, op Token, mut right Ast) Assign {
	return Assign {
		left: left
		op: op
		right: right
	}
}

fn (mut a Assign) str() string {
	return "assign"
}

struct Var { // un identificador e.g: foo, bar
	token Token
	value string
}

fn new_var(token Token, value string) Var {
	return Var {
		token: token
		value: value
	}
}

fn (mut v Var) str() string {
	return "var"
}

struct NoOp {
	// nada
}

fn new_no_op() NoOp {
	return NoOp{}
}

fn (mut n NoOp) str() string {
	return "empty"
}

/*
###############################################################################
#                                                                             #
#  PARSER                                                                     #
#                                                                             #
###############################################################################
*/

struct Parser {
mut:
	l Lexer
	current_token Token
}

fn new_parser(mut l Lexer) ?Parser {
	mut p := Parser {
		l: l
	}
	p.current_token = p.l.get_next_token() or { return err }
	return p
}

fn (mut p Parser) eat(token_kind string) ? {
	if p.current_token.kind == token_kind {
		p.current_token = p.l.get_next_token() or { return err }
	} else {
		return error('Unexpected token `${p.current_token.kind}` expected `${token_kind}`')
	}
}

// program: compound_statement DOT
fn (mut p Parser) program() ?Ast {
	mut node := p.compound_statement() or { return err }
	p.eat(dot) or { return err }
	return node
}

// compound_statement: BEGIN statement_list END
fn (mut p Parser) compound_statement() ?Ast {
	
	p.eat(begin) or { return err }
	mut nodes := p.statement_list() or { return err }
	p.eat(end) or { return err }

	mut compound := Compound{
		children: []Ast{}
	}

	for node in nodes {
		compound.children << node
	}

	return compound
}

fn (mut p Parser) statement_list() ?[]Ast {
	// statement_list : statement | statement SEMI statement_list
	mut results := []Ast{}
	mut node := p.statement() or { return err }
	results << node

	for p.current_token.kind == semi {
		p.eat(semi) or { return err }
		results << p.statement() or { return err }
	}

	if p.current_token.kind == id {
		return error('Invalid token id in statement_list parsing proccess.')
	}

	return results
}

fn (mut p Parser) statement() ?Ast {
	// statement: compound_statement | assignment_statement | empty
	if p.current_token.kind == begin {
		return p.compound_statement() or { return err }
	} else if p.current_token.kind == id {
		return p.assignment_statement() or { return err }
	} else {
		return error('invalid token')
	}
}

fn (mut p Parser) assignment_statement() ?Ast {
	return error('error')
}

fn main() {
	for {
		text := os.input('spi> ')
		if text.len == 0 {
			continue
		}

	}
}