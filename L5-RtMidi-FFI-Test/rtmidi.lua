local ffi = require("ffi")
-- Use LuaJIT BitOp for bitwise operations, see https://bitop.luajit.org/api.html
local bit = require("bit")
local band,bor,lshift,rshift = bit.band,bit.bor,bit.lshift,bit.rshift


ffi.cdef[[
// C interface definitions copied from https://github.com/thestk/rtmidi/blob/master/rtmidi_c.h
// see https://github.com/thestk/rtmidi/blob/master/LICENSE
struct RtMidiWrapper {
    void* ptr;
    void* callback_proxy;
    void* error_callback_proxy;
    bool ok;
    char* msg;
};
typedef struct RtMidiWrapper* RtMidiPtr;
typedef struct RtMidiWrapper* RtMidiInPtr;
typedef struct RtMidiWrapper* RtMidiOutPtr;
const char*    rtmidi_get_version         ();
void           rtmidi_open_port           (RtMidiPtr device, unsigned int portNumber, const char *portName);
void           rtmidi_open_virtual_port   (RtMidiPtr device, const char *portName);
void           rtmidi_close_port          (RtMidiPtr device);
unsigned int   rtmidi_get_port_count      (RtMidiPtr device);
int            rtmidi_get_port_name       (RtMidiPtr device, unsigned int portNumber, char * bufOut, int * bufLen);
RtMidiInPtr    rtmidi_in_create_default   (void);
void           rtmidi_in_free             (RtMidiInPtr device);
void           rtmidi_in_ignore_types     (RtMidiInPtr device, bool midiSysex, bool midiTime, bool midiSense);
double         rtmidi_in_get_message      (RtMidiInPtr device, unsigned char *message, size_t *size);
RtMidiOutPtr   rtmidi_out_create_default  (void);
void           rtmidi_out_free            (RtMidiOutPtr device);
int            rtmidi_out_send_message    (RtMidiOutPtr device, const unsigned char *message, int length);
]]

-- C string buffer for checking port names
local Buf    = ffi.new("char[255]")
local BufLen = ffi.new("int[1]", 255)

-- C byte buffer for MIDI messages
local Msg    = ffi.new("unsigned char[1024]")
local MsgLen = ffi.new("size_t[1]", 1024)

-- Private state vars
local rtmidi, InDev, OutDev

-- Load and initialize RtMidi library (meant for use with pcall).
-- The ffi.load() is tested on Debian Trixie (`sudo apt install librtmidi7`).
-- Load filename likely needs modification to work on Windows or macOS.
function loadAndInit()
    rtmidi = ffi.load("librtmidi.so.7")
    InDev  = rtmidi.rtmidi_in_create_default()
    OutDev = rtmidi.rtmidi_out_create_default()
end
local ok, result = pcall(loadAndInit)
if ok then
    -- Load OK: install midi device cleanup handler
    -- CAUTION: this will break if main.lua defines its own love.quit()
    local previousQuit = love.quit
    function love.quit()
        print("\nQUIT: Closing MIDI Devices...")
        rtmidi.rtmidi_in_free(InDev)
        rtmidi.rtmidi_out_free(OutDev)
        -- Call previous quit function, if there was one
        if previousQuit then return previousQuit() end
    end
else
    -- Load FAIL: Likely an OS-specific issue with the filename for ffi.load()
    print("RtMidi library load error:", result)
    return nil
end

local function portIterator(device)
    local n = rtmidi.rtmidi_get_port_count(device)
    local port = -1
    return function()
        port = port+1
        if port<n then
            local len = rtmidi.rtmidi_get_port_name(device, port, Buf, BufLen)
            local name = len>0 and ffi.string(Buf, math.min(len, 255)) or ""
            return port,name
        end
    end
end

local function midiOpen(device, port, name, tag)
    io.write(("Opening %s port %d: \"%s\"... "):format(tag, port, name))
    rtmidi.rtmidi_open_port(device, port, "L5 love2d "..tag)
    print(device.ok and "OK" or "ERROR")
    return device.ok
end

local M = {}

function M.version() return ffi.string(rtmidi.rtmidi_get_version()) end

function M.inputPorts() return portIterator(InDev) end

function M.outputPorts() return portIterator(OutDev) end

-- Open the lowest numbered input & ouput ports whose names contain pattern
function M.openPortsContaining(pattern)
    for port,name in portIterator(InDev) do
        if name:find(pattern) then midiOpen(InDev, port, name, "IN") break end
    end
    for port,name in portIterator(OutDev) do
        if name:find(pattern) then midiOpen(OutDev, port, name, "OUT") break end
    end
end

local function validate(chan,num,val)
    if not chan or chan<1 or chan>16 then error("chan out of range: "..tostring(chan)) end
    if not num or num<0 or num>127 then error("num out of range: "..tostring(num)) end
    if not val or val<0 or val>127 then error("val out of range: "..tostring(val)) end
end

-- Send note on using Lua-style 1-indexed channel numbers (1..16)
function M.noteOn(ch,num,val)
    validate(ch,num,val)
    Msg[0],Msg[1],Msg[2] = bor(0x90,ch-1),num,val
    rtmidi.rtmidi_out_send_message(OutDev, Msg, 3)
end

-- Send note off using Lua-style 1-indexed channel numbers (1..16)
function M.noteOff(ch,num,val)
    validate(ch,num,val)
    Msg[0],Msg[1],Msg[2] = bor(0x80,ch-1),num,val
    rtmidi.rtmidi_out_send_message(OutDev, Msg, 3)
end

-- Send CC using Lua-style 1-indexed channel numbers (1..16)
function M.cc(ch,num,val)
    validate(ch,num,val)
    Msg[0],Msg[1],Msg[2] = bor(0xb0,ch-1),num,val
    rtmidi.rtmidi_out_send_message(OutDev, Msg, 3)
end

-- Get MIDI message. Channels are returned with 1-based numbering (1-16).
function M.getMessage(debug)
    -- CRITICAL: Must set MsgLen[0] every time as rtmidi_in_get_message() uses
    -- it both for input (buffer length) and output (size of copied message)
    MsgLen[0] = ffi.sizeof(Msg)
    rtmidi.rtmidi_in_get_message(InDev, Msg, MsgLen)
    local len = tonumber(MsgLen[0])
    -- Filter out boring results (focus on note on/off, cc, pitch bend)
    if len==0 then
        -- message queue was empty
        return nil
    elseif len~=3 then
        -- unexpected payload length (maybe SysEx?)
        if debug then print(("MsgLen[0] = %d"):format(len)) end
        return nil
    end
    -- Decode 3-byte payload according to status byte message type nibble.
    -- RtMidi strips the USB MIDI packet header byte, so there's no CN nibble.
    -- Technically, the upper status byte nibble is the MIDI message type.
    -- Message type is subtly different from CIN. But, they usually have the
    -- same value and CIN is shorter. So, whatever. I'm calling it CIN.
    local cin,chan = band(Msg[0],0xf0),band(Msg[0],0x0f)+1
    local num,val = tonumber(Msg[1]),tonumber(Msg[2])
    if     cin==0x90 then return "on",chan,num,val   -- Note On
    elseif cin==0x80 then return "off",chan,num,val  -- Note Off
    elseif cin==0xb0 then return "cc",chan,num,val   -- Control Change
    elseif cin==0xe0 then return "pb",chan,num,val   -- Pitch Bend
    elseif debug then
        print(("%02x %02x %02x %02x"):format(cin,chan,num,val))
    end
    return nil
end

return M
