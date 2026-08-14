package main

import "base:runtime"
import "core:fmt"
import "koishi"

my_entry :: proc "c" (data: rawptr) -> rawptr {
	context = runtime.default_context()
	fmt.println("From koishi")
	return nil
}

main :: proc() {
	fmt.printf("Hello\n")
	cr: koishi.Coroutine = {}
	koishi.init(&cr, 4096, my_entry)
	koishi.resume(&cr, nil)
}
