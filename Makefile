KOISHI_DIR=external/koishi
DEFAULT_FLAG=-Ddefault_library=both

windows:
	meson setup build $(KOISHI_DIR) $(DEFAULT_FLAG) -Dimpl=win32fiber
