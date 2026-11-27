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

-- Tested only on Debian Trixie (`sudo apt install librtmidi7`).
-- This likely would need modification to work on Windows or macOS.
local rtmidi = ffi.load("librtmidi.so.7")
local InDev  = rtmidi.rtmidi_in_create_default()
local OutDev = rtmidi.rtmidi_out_create_default()
local Buf    = ffi.new("char[255]")
local BufLen = ffi.new("int[1]", 255)

local M = {}

function M.version()
    local cstr = rtmidi.rtmidi_get_version()
    return cstr == nil and "NULL" or ffi.string(cstr)
end

function M.getPortCountIn()  return rtmidi.rtmidi_get_port_count(InDev) end
function M.getPortCountOut() return rtmidi.rtmidi_get_port_count(OutDev) end

-- RtMidi ports are C-style 0 indexed, but port argument here should be Lua-style 1-indexed
function M.getPortNameIn(port)
    if port<1 or port>M.getPortCountIn() then return "ERROR: port out of range" end
    local len = rtmidi.rtmidi_get_port_name(InDev, port-1, Buf, BufLen)
    return len>0 and ffi.string(Buf, math.min(len, 255)) or ""
end

-- RtMidi ports are C-style 0 indexed, but port argument here should be Lua-style 1-indexed
function M.getPortNameOut(port)
    if port<1 or port>M.getPortCountOut() then return "ERROR: port out of range" end
    local len = rtmidi.rtmidi_get_port_name(OutDev, port-1, Buf, BufLen)
    return len>0 and ffi.string(Buf, math.min(len, 255)) or ""
end

-- Install an automatic cleanup handler, chained to existing love.quit handler
-- see https://love2d.org/wiki/love.quit
local previousQuit = love.quit
function love.quit()
    print("\nQUIT: Closing MIDI Devices...")
    rtmidi.rtmidi_in_free(InDev)
    rtmidi.rtmidi_out_free(OutDev)
    -- Call previous quit function, if there was one
    if previousQuit then
        return previousQuit()
    end
end

return M
