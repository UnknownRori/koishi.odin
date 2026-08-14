# Koishi.odin

Binding for beloved (Koishi)[https://github.com/taisei-project/koishi] Komeiji 
for Odin Programming Language

## How to use

Currently there is no easy way to include the compiled library into these bindings
so deal with it.

```sh
git clone --recursive https://github.com/UnknownRori/koishi.odin
cd koishi.odin

# You need to compile it yourself
meson setup build external/koishi -Ddefault_library=both
meson compile -C build

# Copy the result of .a and .dll or .so into the root of project
# and also copy the definition of library into koishi folder that
# has .odin in it
```
