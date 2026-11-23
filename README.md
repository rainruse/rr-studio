# rr-studio

This repo records behind the scenes glimpses into experiments with L5,
SuperCollider, etc. as part of a studio practice. 

Project subfolders here each address some aspect of me incrementally exploring
bits and pieces of plans for stuff that I want to make. Things here may lack a
full explanation of relevant context or be otherwise incomplete. In many cases,
a project subfolder will contain a sketch or patch used in one of my videos.
But, I may not link to the videos from here.

TL;DR This is not "software". Rather it's fragmentary documentation of an art
practice.


## L5 and Font Dependencies

The L5.lua file isn't included here. Sketches in this repo use a package path
that expects L5 to be located at `../../L5/L5.lua`. That works if you git clone
https://github.com/L5lua/L5.git and https://github.com/rainruse/rr-studio.git
into the same parent directory. This avoids the potential versioning chaos of
maintaining a copy of L5.lua for each sketch.

I take a similar approach to fonts. Some of the sketches here use `io.open()`
to read my local fonts from `~/.local/share/fonts`. I don't want to commit
those fonts to a public git repo. So, the code is written to use löve's default
font if my local font can't be loaded.


## SuperCollider Usage

This starts jackd silently in the background (stop with pkill jackd). Doing it
this way avoids the need for tmux, so sclang scrollback is easier to access.

```
./jack.sh
./sclang.sh
```

sclang REPL command to stop all sound:
```
s.freeAll;
```


## Install Packages

```
sudo apt install supercollider-language supercollider-server love
# say yes to realtime audio permissions prompt
```

## Jack & ALSA Stuff

Find USB audio device name to use with `jackd -P`:
```
$ aplay -l | grep '^card .*USB'
card 1: Notepad8FX [Notepad-8FX], device 0: USB Audio [USB Audio]
# Notepad8FX is what I need
```
Optional: Check graph in VNC with `qjackctl`


## load file in sclang

```
"whatever.sc".load;
```


