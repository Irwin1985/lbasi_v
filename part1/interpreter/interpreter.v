module interpreter
import token

pub struct Interpreter {
	text string
mut:
	pos int
	current_token token.Token
}

pub fn new(text string) Interpreter {
	return Interpreter {
		// client string input, e.g. "3+5"
		text: text
		// pos is an index into text
		pos: 0
		current_token: token.Token{}
	}
}

pub fn (mut i Interpreter) get_next_token() ?token.Token {
	/*
	  Lexical analyzer (also known as scanner or tokenizer)

	  This method is responsible for breaking a sentence 
	  apart into tokens. One token at a time.
	*/

	/*
	  is i.pos index past the end of the i.text ?
	  if so, then return EOF token because there is no more
	  input left to convert into tokens.
	*/

	if i.pos >= i.text.len {
		return token.new(token.eof, '')
	}

	// get a character a the position i.pos and decide
	// what token to create based on the single character
	mut current_char := i.text[i.pos]
	/*
	  if the character is a digit then convert it to
	  integer, create an integer token, increment i.pos
	  index to point to the next character after the digit,
	  and return the integer token
	*/
	if isdigit(current_char) {
		token := token.new(token.integer, current_char.ascii_str())
		i.pos += 1
		return token
	}

	if current_char == `+` {
		token := token.new(token.plus, current_char.ascii_str())
		i.pos += 1
		return token
	}

	return error('Error parsing input')
}

fn (mut i Interpreter) eat(kind string) ? {
	/*
	  compare the current token type with the passed token
	  type and if they match then "eat" the current token
	  and assign the next token to the i.current_token,
	  otherwise return error
	*/
	if i.current_token.kind == kind {
		i.current_token = i.get_next_token() or { return err }
	} else {
		return error('Error parsing input')
	}
}

pub fn (mut i Interpreter) expr() ?int {
	//expr > integer plus integer	  
	
	// set current token to the first token taken from the input
	i.current_token = i.get_next_token() or { return err }
	
	// we expect the current token to be a single-digit integer
	left := i.current_token
	i.eat(token.integer) or { return err }

	// we expect the current token to be a '+' token
	_ := i.current_token
	i.eat(token.plus) or { return err }

	// we expect the current token to be a single-digit integer
	right := i.current_token
	i.eat(token.integer) or { return err }

	// after the above call the i.current_token is set to 
	// EOF token

	/*
	  at this point integer plus integer sequence of tokens
	  has been successfully found and the method can just
	  return the result of adding two integers, thus
	  effectively interpreting client input
	*/
	result := left.value.int() + right.value.int()

	return result
}

fn isdigit(c byte) bool {
	return `0` < c && c < `9`
}
