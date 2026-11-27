local ffi = require("ffi")

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

local M = {}

function M.version() return ffi.string(rtmidi.rtmidi_get_version()) end

function M.inputPorts() return portIterator(InDev) end

function M.outputPorts() return portIterator(OutDev) end

return M
