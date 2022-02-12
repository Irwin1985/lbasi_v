module main
import os
import interpreter


fn main() {
	for {
		text := os.input('calc> ')
		if text.len == 0 {
			continue
		}
		mut i := interpreter.new(text)
		result := i.expr() or { panic(err) }
		println(result)
	}
}