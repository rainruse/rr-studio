function love.conf(t)
	t.modules.audio=nil
	t.window.width=1280
	t.window.height=720

	-- Tell SDL to poll joystick even when game window does not have focus
	local ffi = require("ffi")
	ffi.cdef[[int setenv(const char *name, const char *value, int overwrite);]]
	ffi.C.setenv("SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS", "1", 1)
end
