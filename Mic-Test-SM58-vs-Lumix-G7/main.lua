-- Mic Test SM58 vs Lumix G7
-- Visualizer for a mic test video with Shure SM58 vs Lumix G7 internal mic.

package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../L5/?.lua"
require("L5")


-- Joystick event callbacks to update jsAxis, jsBttn, and jsDpad
local jsAxis,jsBttn,jsDpad = {},{},nil
function love.joystickadded(js)
    -- Expected mapping:
	-- * axis 1-6: L stick, L trigger, R stick, R trigger
	-- * bttn 1-9: ABXY, L shoulder, R shoulder, Start, Select, Home
    -- * hat 1: dpad
	for i=1,math.min(6,js:getAxisCount())   do jsAxis[i] = js:getAxis(i) end
	for i=1,math.min(9,js:getButtonCount()) do jsBttn[i] = js:isDown(i)  end
	for i=1,math.min(1,js:getHatCount())    do jsDpad    = js:getHat(i)  end
end
function love.joystickaxis(js, a, v)    jsAxis[a] = v     end
function love.joystickpressed(js, b)    jsBttn[b] = true  end
function love.joystickreleased(js, b)   jsBttn[b] = false end
function love.joystickhat(js, hat, dir) jsDpad    = dir   end


-- ==========================================================================

local cam, mic, pow,x0,y0,x1,y1,x2,y2
function setup()
	frameRate(30)
	-- Load font using io.open to get around löve's filesystem sandboxing.
	-- If you don't have the font file, text will use löve's default font.
	local path = os.getenv("HOME") .. "/.local/share/fonts/Grammish.ttf"
	local f = io.open(path, "rb")
	if f then
		textFont(loadFont(love.filesystem.newFileData(f:read("*a"), "f.ttf")))
		f:close()
	end
	-- cache images
	pow = loadImage('pow.png')
	mic = loadImage('mic.png')
	cam = loadImage('camera.png')
	x1,y1 = 37,156    -- initial mic position
	x2,y2 = 616,133   -- initial camera position
	-- clear background
	background(0)
end

-- ==========================================================================

function love.draw(t)
	-- Clear screen to background color
	clear()
	background("#5f13b7")
	-- Title
	fill("#b8f6ad")
	textAlign(CENTER)
	textSize(52)
	text("Mic Test SM58 vs Lumix G7", width/2, 80)
	textAlign(LEFT)
	-- When gamepad B is up (SNES cluster layout), mic is selected
	if not jsBttn[1] then
		-- dpad UDLR moves anchor point for mic image
		if jsDpad == "u" then y1 = math.max(0, y1-1) print(x1, y1, x2, y2)
		elseif jsDpad == "d" then y1 = math.min(720, y1+1) print(x1, y1, x2, y2)
		elseif jsDpad == "l" then x1 = math.max(0, x1-1) print(x1, y1, x2, y2)
		elseif jsDpad == "r" then x1 = math.max(0, x1+1) print(x1, y1, x2, y2)
		end
		image(pow, x1, y1)
	end
	-- When gamepad A and B are down (SNES cluster layout), camera is selected
	if jsBttn[1] and jsBttn[2] then
		-- dpad UDLR moves anchor point for camera image
		if jsDpad == "u" then y2 = math.max(0, y2-1) print(x1, y1, x2, y2)
		elseif jsDpad == "d" then y2 = math.min(720, y2+1) print(x1, y1, x2, y2)
		elseif jsDpad == "l" then x2 = math.max(0, x2-1) print(x1, y1, x2, y2)
		elseif jsDpad == "r" then x2 = math.max(0, x2+1) print(x1, y1, x2, y2)
		end
		image(pow, x2, y2)
	end
	image(mic, x1, y1)
	image(cam, x2, y2)
end
