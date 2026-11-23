--[[
L5 Joystick HUD Test 1

IMPORTANT: SDL will ignore joystick events when game window is not focused
unless you start love with environtment variable enabling background events:
    SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1 love .
or use the ffi module to call SDL's SDL_SetHint() function.

Useful Related Stuff:
- https://love2d.org/wiki/love.joystick
- https://love2d.org/wiki/love#Joystick (love.gamepadaxis, etc)
- https://love2d.org/wiki/Joystick
- https://luajit.org/ext_ffi_api.html
- debian package jstest-gtk (to verify axis and button mapping)
--]]

-- CAUTION: This package path expects that you have the L5 repo checked out
-- next in the same parent directory as the rr-studio repo.
package.path = package.path .. ";" .. love.filesystem.getSource()
	.. "../../L5/?.lua"
require("L5")


-- =========================================================================
-- Enable background joystick polling
-- =========================================================================

local ffi = require("ffi")  -- for access to SDL_SetHint()
ffi.cdef"int SDL_SetHint(const char *name, const char *value);"
function setSDLJoystickHint()
	--[[
	Tell SDL to always poll the joystick, even if game window does not have
	focus (allow LÖVE to generate HUD overlays for OBS). If this gives an
	error, comment it out and start love with shell environment variable:
	`SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1 love .`	
	--]]
	local key = "SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS"
	if ffi.os == "Windows" then ffi.load("SDL2").SDL_SetHint(key, "1")
	else ffi.C.SDL_SetHint(key, "1")
	end
end


-- =========================================================================
-- Joystick event callbacks
-- =========================================================================

local jsAxis,jsBttn,jsHat = {},{},{}

function love.joystickadded(js)
	print("\njoystick added: " .. js:getName())
	--[[
    - 7 axes covers left X/Y/trig, right X/Y/trig on gamepad and Throttle/Yaw,
      S1, Pitch/Roll, S2, S3 6-position switch on EdgeTX radio
	- 9 buttons covers ABXY, L, R, Start, Select, Home on gamepad and SA, SB,
      SC, SD, SE, SF on EdgeTX radio
	--]]
	for i=1,math.min(7,js:getAxisCount()) do jsAxis[i]=js:getAxis(i) end
	for i=1,math.min(9,js:getButtonCount()) do jsBttn[i]=js:isDown(i) end
	for i=1,js:getHatCount() do jsHat[i]=js:getHat(i) end
end

function love.joystickremoved(js)
	print("\njoystick removed: " .. js:getName())
end

function love.joystickaxis(js, a, v)  if  8>a then jsAxis[a] = v end end
function love.joystickpressed(js, b)  if 10>b then jsBttn[b] = true end end
function love.joystickreleased(js, b) if 10>b then jsBttn[b] = false end end
function love.joystickhat(js, hat, dir) jsHat[hat] = dir end


-- =========================================================================
-- setup
-- =========================================================================

function setup()
	-- no size() here because it gets set in conf.lua
	frameRate(30)
	setSDLJoystickHint()
	-- Load font using io.open to get around löve's filesystem sandboxing.
	-- This trick unlocks ability to commit sketch folders to a public git
	-- repo without having to include include local fonts. If you don't have
	-- the font file, text should still render using löve's default font.
	local path = os.getenv("HOME") .. "/.local/share/fonts/Grammish.ttf"
	local file = io.open(path, "rb")
	if file then
		local data = file:read("*a")
		file:close()
		textFont(loadFont(love.filesystem.newFileData(data, "font.ttf")))
	else
		-- Font wasn't found, so just use default font
	end
	textSize(16)
	background(0)
end


-- =========================================================================
-- draw
-- =========================================================================

function love.draw(t)
	local dx,dy,pad = width/10,50,30
	-- Clear screen to background color
	clear()
	background(100)
	-- Title
	color(255)
	textSize(51)
	text("L5 Joystick HUD Test 1", dx, dy*2)
	-- Lay out a grid of joystick/gamepad axes, buttons, and hats (dpad)
	textSize(24)
	textAlign(LEFT) text("Axes:  ", dx, 1*pad + dy*4) textAlign(LEFT)
	for i=1,#jsAxis do
		local x = dx*(2.8+((i-1)%3))
		local y = 1*pad + dy*(math.floor((i-1)/3)+4)
		text(("%5.2f "):format(jsAxis[i]), x, y)
	end
	textAlign(LEFT) text("Buttons:  ", dx, 2*pad + dy*7) textAlign(LEFT)
	for i=1,#jsBttn do
		local x = dx*(2.8+((i-1)%3))
		local y = 2*pad + dy*(math.floor((i-1)/3)+7)
		text(jsBttn[i] and " 1" or " 0", x, y)
	end
	textAlign(LEFT) text("Hats:  ", dx, 3*pad + (dy*10)) textAlign(LEFT)
	for i=1,#jsHat do
		local x = dx*(2.8+((i-1)%3))
		local y = 3*pad + dy*(math.floor((i-1)/3)+10)
		text(" " .. jsHat[i], x, y)
	end
end
