package main

import "base:runtime"
import "core:fmt"
import "core:strings"
import "koishi"

printf :: fmt.printf
strcmp :: strings.compare

str_to_raw_ptr :: #force_inline proc(s: string) -> rawptr {
	return rawptr(raw_data(s))
}

cofunc1 :: proc "c" (data: rawptr) -> rawptr {
	context = runtime.default_context()

	str := data
	printf("C: start coroutine (got %s)\n", cstring(str))
	printf("C: yielding 1\n")
	str = koishi.yield(str_to_raw_ptr("Reimu"))
	printf("C: resumed 1 (got %s)\n", cstring(str))
	printf("C: yielding 2\n")
	str = koishi.yield(str_to_raw_ptr("Marisa"))
	printf("C: resumed 2 (got %s)\n", cstring(str))
	printf("C: yielding 3\n")
	str = koishi.yield(str_to_raw_ptr("Youmu"))
	printf("C: resumed 3 (got %s)\n", cstring(str))
	printf("C: Done\n")
	koishi.die(str_to_raw_ptr("Bye"))
	return nil
}

test1 :: proc(c: ^koishi.Coroutine) {
	koishi.init(c, 128 * 1024, cofunc1)
	printf("O: created coroutine\n")
	printf("O: resume 1\n")
	hello := "Hello"
	str := koishi.resume(c, rawptr(raw_data(hello)))
	printf("O: post yield 1 (got %s)\n", cstring(str))
	tmp := strings.clone_from_cstring(cstring(str))
	defer delete(tmp)
	assert(strcmp(tmp, "Reimu") == 0)
}

cofunc_nested :: proc "c" (data: rawptr) -> rawptr {
	context = runtime.default_context()
	caller := cast(^koishi.Coroutine)data
	assert(koishi.state(caller) == .Idle)
	assert(koishi.state(koishi.active()) == .Running)
	return rawptr(uintptr(42))
}

cofunc2 :: proc "c" (data: rawptr) -> rawptr {
	context = runtime.default_context()

	assert(koishi.state(koishi.active()) == .Running)
	co: koishi.Coroutine
	c2: ^koishi.Coroutine = &co
	koishi.init(c2, 0, cofunc_nested)

	nested_return := cast(i32)uintptr(koishi.resume(c2, koishi.active()))
	assert(koishi.state(koishi.active()) == .Running)
	assert(nested_return == 42)
	koishi.deinit(c2)

	i: i32 = 0
	printf("C: start coroutine\n")
	for {
		i += cast(i32)uintptr(data)
		i = (2 * i) * (3 * i)
		printf("C: yielding %d\n", i)
		assert(koishi.state(koishi.active()) == .Running)
		koishi.yield(rawptr(uintptr(i)))
		assert(koishi.state(koishi.active()) == .Running)
	}

	return nil
}

test2 :: proc(co: ^koishi.Coroutine) {
	i: i32

	koishi.recycle(co, cofunc2)
	assert(koishi.state(co) == .Suspended)

	printf("O: recycled coroutine\n")
	printf("O: resume 1\n")
	i = cast(i32)uintptr(koishi.resume(co, rawptr(uintptr(1))))
	printf("O: post yield 1 (got %d)\n", i)

	printf("O: resume 2\n")
	i = cast(i32)uintptr(koishi.resume(co, rawptr(uintptr(2))))
	printf("O: post yield 2 (got %d)\n", i)

	assert(koishi.state(co) == .Suspended)
}

cancelled_caller_test_inner :: proc "c" (data: rawptr) -> rawptr {
	context = runtime.default_context()
	outer := cast(^koishi.Coroutine)data
	koishi.kill(outer, rawptr(uintptr(42)))
	koishi.yield(nil)
	return nil
}

cancelled_caller_test_outer :: proc "c" (data: rawptr) -> rawptr {
	context = runtime.default_context()
	inner := cast(^koishi.Coroutine)data
	koishi.resume(inner, koishi.active())
	assert(false) // unreacable
	return nil
}

cancelled_caller_test :: proc(result: ^i32) {
	inner: koishi.Coroutine
	outer: koishi.Coroutine
	koishi.init(&inner, 0, cancelled_caller_test_inner)
	koishi.init(&outer, 0, cancelled_caller_test_outer)
	result^ = auto_cast uintptr(koishi.resume(&outer, &inner))
	koishi.deinit(&inner)
	koishi.deinit(&outer)
}

main :: proc() {
	current := koishi.state(koishi.active())
	assert(current == .Running)

	str: rawptr = nil
	co: koishi.Coroutine = {}
	c := &co
	test1(&co)
	printf("O: resume 2\n")
	str = koishi.resume(c, str_to_raw_ptr("Hakurei"))
	printf("O: post yield 2 (got %s)\n", cstring(str))
	str1 := strings.clone_from_cstring(cstring(str))
	defer delete(str1)
	assert(strcmp(str1, "Marisa") == 0)
	printf("O: resume 3\n")
	str = koishi.resume(c, str_to_raw_ptr("Kirisame"))
	printf("O: post yield 3 (got %s)\n", cstring(str))
	str2 := strings.clone_from_cstring(cstring(str))
	defer delete(str2)
	assert(strcmp(str2, "Youmu") == 0)
	printf("O: resume 4\n")
	str = koishi.resume(c, str_to_raw_ptr("Konpaku"))
	printf("O: done (got %s)\n", cstring(str))
	assert(koishi.state(c) == .Dead)

	assert(koishi.state(koishi.active()) == .Running)
	test2(&co)
	koishi.deinit(c)

	result: i32 = 0
	cancelled_caller_test(&result)
	assert(result == 42)

	printf("Done\n")
}
