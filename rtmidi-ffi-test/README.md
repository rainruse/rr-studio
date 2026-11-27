# RtMidi FFI Test

This explores how to get MIDI in and out of an L5 sketch by using
[LuaJIT ffi](https://luajit.org/ext_ffi_api.html) to load the
[RtMidi](https://github.com/thestk/rtmidi) library's
[C interface](https://github.com/thestk/rtmidi/blob/master/rtmidi_c.h).

I've only tested this on Debian Trixie using Debian's `librtmidi7` package.
Odds are good that RtMidi can be made to work on Windows or macOS by adding
some additional logic around the `ffi.load()` call.

To run this sketch on Debian, first ensure the RtMidi library is installed:
```
sudo apt install librtmidi7
```

Note that the librtmidi7 package installs a `.so` file with a `.7` version
suffix, so the default `ffi.load()` library name resolution mechanism won't
work with just a `ffi.load("rtmidi")`. It's necessary to specify the full
library file name as `ffi.load("librtmidi.so.7")`. For examples of how this
might be adapted to load the correct library name on Windows or some other OS,
have a look at the
[LuaJIT FFI Tutorial](https://luajit.org/ext_ffi_tutorial.html).
