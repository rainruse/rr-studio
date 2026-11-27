-- RtMidi FFI Test
-- Use RtMidi library (Debian librtmidi7 package) to test MIDI IO in L5

package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../L5/?.lua"
require("L5")
local rtmidi = require("rtmidi")


-- ==========================================================================

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
    -- clear background
    background(0)
    -- Check RtMidi
    print("RtMidi version: " .. rtmidi.version())
    local inCount = rtmidi.getPortCountIn()
    local outCount = rtmidi.getPortCountOut()
    print("RtMidi Input Ports (" .. inCount .. "):")
    for i=1,inCount do
        print("  " .. rtmidi.getPortNameIn(i))
    end
    print("RtMidi Output Ports (" .. outCount .. "):")
    for i=1,outCount do
        print("  " .. rtmidi.getPortNameOut(i))
    end
end

-- ==========================================================================

function draw()
    -- Clear screen to background color
    clear()
    background(0)
    -- Title
    fill(255)
    textSize(52)
    textAlign(CENTER)
    text("RtMidi FFI Test", width/2, 80)
    textAlign(LEFT)
end
