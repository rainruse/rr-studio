-- RtMidi FFI Test
-- Use RtMidi library (Debian librtmidi7 package) to test MIDI IO in L5

package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../L5/?.lua"
require("L5")
local rtmidi = require("rtmidi")

-- ==========================================================================

local function launchpadPalette(page)
    if (not page) or page<0 or page>1 then
        error("palette page out of range: "..tostring(page))
    end
    for i=0,63 do
        local x,y = math.floor(i%8),math.floor(i/8)
        local chan,note,color = 1,81-y*10+x,i+page*64
        rtmidi.noteOn(chan,note,color)
    end
end

local function launchpadFill(color)
    local chan=1
    for cc=104,127 do rtmidi.cc(chan,cc,color) end
    for row=0,7 do
        for col=1,9 do rtmidi.noteOn(chan,80-row*10+col,color) end
    end
end

-- ==========================================================================

local labelA,labelB="",""
function setup()
    frameRate(60)
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
    rtmidi.openPortsContaining("Launchpad")
    launchpadFill(26)
    labelA="--"
    labelB="color=26"
end

-- ==========================================================================

local getMsg = rtmidi.getMessage
local hue,luma = 0,0
function love.update(dt)
    for i=1,10 do
        local cin,chan,num,val = getMsg(true)
        -- stop loop if message queue is empty
        if not cin then break end
        -- Update button highlight color
        local tag=({on="note-on",off="note-off"})[cin] or cin
        labelA = ("%s  ch%d  %3d  %3d"):format(tag,chan,num,val)
        if val==0 then labelB = "" end
        if     cin=="on" and val==127 then rtmidi.noteOn(chan,num,8)
        elseif cin=="on" and val==0   then rtmidi.noteOn(chan,num,0)
        elseif cin=="cc" and val==127 then rtmidi.cc(chan,num,8)
        elseif cin=="cc" and val==0   then rtmidi.cc(chan,num,0)
        else print(cin,num,val)
        end
        -- Do color fill cycling for first 4 cc buttons
        if cin=="cc" and val==0 then
            if num>=104 and num<=107 then
                if     num==104 then hue  = math.min(15, hue+1) labelB="hue+"
                elseif num==105 then hue  = math.max(0,  hue-1) labelB="hue-"
                elseif num==106 then luma = math.max(0, luma-1) labelB="luma-"
                elseif num==107 then luma = math.min(3, luma+1) labelB="luma+"
                end
                local color = hue*4+luma
                labelB = labelB.." / color="..tostring(color)
                launchpadFill(hue*4+luma)
            elseif num==108 then
                labelB="Palette Page 0"
                launchpadPalette(0)
            elseif num==109 then
                labelB="Palette Page 1"
                launchpadPalette(1)
            elseif num==110 then
                labelB="Clear"
                launchpadFill(0)
            end
        end
    end
end

-- ==========================================================================

local skipDraw = true
function draw()
    -- Skip every other draw (60 fps update to poll midi, 30 fps for draw)
    skipDraw = not skipDraw
    if skipDraw then return end
    -- Clear screen to background color
    clear()
    background(0)
    -- Title
    fill(225)
    textSize(52)
    text("L5 RtMidi FFI Test", width/10, 80)
    -- Labels
    textSize(30)
    text(labelA, width/9.5, 130)
    text(labelB, width/9.5, 180)
end
