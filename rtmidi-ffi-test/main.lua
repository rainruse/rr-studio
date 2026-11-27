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
    print("RtMidi Input Ports:")
    for port,name in rtmidi.inputPorts() do
        print(("  %d: %s"):format(port, name))
    end
    print("RtMidi Output Ports:")
    for port,name in rtmidi.outputPorts() do
        print(("  %d: %s"):format(port, name))
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
