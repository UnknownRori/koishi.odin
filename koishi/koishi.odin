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

/**
 * @brief A coroutine entry point.
 *
 * The entry point is a function that is called inside a coroutine context when
 * it is resumed for the first time.
 *
 * Once the entry point returns, control flow jumps back to the last #koishi_resume
 * call for this coroutine, as if it yielded. Its state is set to #KOISHI_DEAD
 * and it may not be resumed again.
 *
 * @param data User data that was passed to the first call to #koishi_resume.
 *
 * @return Value to be returned from the corresponding #koishi_resume call.
 */
entrypoint :: #type proc "c" (data: rawptr) -> rawptr

@(default_calling_convention = "c", link_prefix = "koishi_")
foreign koishi {

	/**
 * @brief Query the currently running coroutine context.
 *
 * @return The coroutine currently running on this thread. This function may be
 * called from the thread's main context as well, in which case it returns a
 * pseudo-coroutine that represents that context. Attempting to yield from such
 * pseudo-coroutines leads to undefined behavior. Pseudo-coroutines are never
 * in the #KOISHI_SUSPENDED state.
 */
	active :: proc() -> ^Coroutine ---

	/**
 * @brief Initialize a #koishi_coroutine_t structure.
 *
 * This function must be called before using any of the other APIs with a particular
 * coroutine instance. It allocates a stack at least @p min_stack_size bytes big
 * and sets up an initial jump context.
 *
 * After this function returns, the coroutine is in the #KOISHI_SUSPENDED state.
 * When resumed (see #koishi_resume), @p entry_point will begin executing in the
 * coroutine's context.
 *
 * @param co The coroutine to initialize.
 * @param min_stack_size Minimum size of the stack. The actual size will be a multiple of the system page size and at least two pages big. If 0, the default size will be used (currently 65536).
 * @param entry_point Function that will be called when the coroutine is first resumed.
 */
	init :: proc(co: ^Coroutine, min_stack: c.size_t, entry: entrypoint) ---

	/**
 * @brief Recycle a previously initialized coroutine.
 *
 * This is a light-weight version of #koishi_init. It will set up a new context,
 * but reuse the existing stack, if allowed by the implementation. This is useful
 * for applications that want to create lots of short-lived coroutines fairly often.
 * They can avoid expensive stack allocations and deallocations by pooling and
 * recycling completed tasks.
 *
 * @param co The coroutine to recycle. It must be initialized.
 * @param entry_point Function that will be called when the coroutine is first resumed.
 */
	recycle :: proc(co: ^Coroutine, entry: entrypoint) ---

	/**
 * @brief Deinitialize a #koishi_coroutine_t structure.
 *
 * This will free the stack and any other resources associated with the coroutine.
 *
 * Memory allocated for the structure itself will not be freed, this is your
 * responsibility.
 *
 * After calling this function, the coroutine becomes invalid, and must not be
 * passed to any of the API functions other than #koishi_init. In particular,
 * it **may not** be recycled.
 *
 * @param co The coroutine to deinitialize.
 */
	deinit :: proc(co: ^Coroutine) ---

	/**
 * @brief Resume a suspended coroutine.
 *
 * Transfers control flow to the coroutine context, putting it into the
 * #KOISHI_RUNNING state. The calling context is put into the #KOISHI_IDLE
 * state.
 *
 * If the coroutine is resumed for the first time, \p arg will be passed
 * as a parameter to its entry point (see #koishi_entrypoint_t). Otherwise, it
 * will be returned from the corresponding #koishi_yield call.
 *
 * This function returns when the coroutine yields or finishes executing.
 *
 * @param co The coroutine to jump into. Must be in the #KOISHI_SUSPENDED state.
 * @param arg A value to pass into the coroutine.
 *
 * @return Value returned from the coroutine once it yields or returns.
 */
	resume :: proc(co: ^Coroutine, arg: rawptr) -> rawptr ---

	/**
 * @brief Suspend the currently running coroutine.
 *
 * Transfers control flow out of the coroutine back to where it was last resumed,
 * putting it into the #KOISHI_SUSPENDED state. The calling context is put into
 * the #KOISHI_RUNNING state.
 *
 * This function must be called from a real coroutine context.
 *
 * This function returns when and if the coroutine is resumed again.
 *
 * @param arg Value to return from the corresponding #koishi_resume call.
 * @return Value passed to a future #koishi_resume call.
 */
	yield :: proc(arg: rawptr) -> rawptr ---

	/**
 * @brief Return from the currently running coroutine.
 *
 * Like #koishi_yield, except the coroutine is put into the #KOISHI_DEAD state
 * and may not be resumed again. For that reason, this function does not return.
 * This is equivalent to returning from the entry point.
 *
 * @param arg Value to return from the corresponding #koishi_resume call.
 */
	die :: proc(arg: rawptr) ---

	/**
 * @brief Stop a coroutine.
 *
 * Puts @p co into the #KOISHI_DEAD state, indicating that it must not be resumed
 * again. If @p co is the currently running coroutine, then this is equivalent
 * to calling #koishi_die with @p arg as the argument.
 *
 * If @p co is in the #KOISHI_IDLE state, the coroutine it's waiting on would yield
 * to the caller of @p co, as if @p co called #koishi_yield(@p arg). This applies
 * to both explicit and implicit yields (e.g. by return from the entry point),
 * recursively.
 *
 * @param co The coroutine to stop.
 * @param arg Value to return from the corresponding #koishi_resume call.
 */
	kill :: proc(co: ^Coroutine, arg: rawptr) ---

	/**
 * @brief Query the currently running coroutine context.
 *
 * @return The coroutine currently running on this thread. This function may be
 * called from the thread's main context as well, in which case it returns a
 * pseudo-coroutine that represents that context. Attempting to yield from such
 * pseudo-coroutines leads to undefined behavior. Pseudo-coroutines are never
 * in the #KOISHI_SUSPENDED state.
 */
	state :: proc(co: ^Coroutine) -> State ---
}
