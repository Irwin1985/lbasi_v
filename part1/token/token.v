module token

/*
	Token types
	eof (enf-of-file) token is used to indicate that
	there is no more input left for lexical analysis.
*/
pub const (
	integer = 'INTEGER'
	plus = 'PLUS'
	eof = 'EOF'
)

pub struct Token {
pub:
	kind string
pub mut:
	value string
}

pub fn new(kind string, value string) Token {
	return Token {
		kind: kind
		value: value
	}
}

pub fn (mut t Token) str() string {
	/*
	  String representation of the class instance.
	  Examples:
	  	Token(integer, 3)
	  	Token(plus, '+')
	*/
	return "Token(${t.kind}, ${t.value})"
}