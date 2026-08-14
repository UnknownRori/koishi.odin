package koishi

import "core:c"


// INFO : Modify this
// to your liking
when ODIN_OS == .Windows {
	foreign import koishi "./libkoishi.dll.a"
}

State :: enum {
	Suspended,
	Running,
	Dead,
	Idle,
}

Coroutine :: struct {
	_private: [8]rawptr,
}

entrypoint :: #type proc "c" (data: rawptr) -> rawptr

@(default_calling_convention = "c", link_prefix = "koishi_")
foreign koishi {

	active :: proc() -> ^Coroutine ---
	init :: proc(co: ^Coroutine, min_stack: c.size_t, entry: entrypoint) ---
	recycle :: proc(co: ^Coroutine, entry: entrypoint) ---
	resume :: proc(co: ^Coroutine, arg: rawptr) -> rawptr ---
	yield :: proc(arg: rawptr) -> rawptr ---
	deinit :: proc(co: ^Coroutine) ---

	die :: proc(arg: rawptr) ---

	kill :: proc(co: ^Coroutine, arg: rawptr) ---
	state :: proc(co: ^Coroutine) -> State ---
}
