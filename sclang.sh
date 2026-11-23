#!/bin/sh
# Start SuperCollider without the gui. This is mostly useful for remote
# control over ssh. For a terminal running in X11, just use normal sclang.
QT_QPA_PLATFORM=offscreen sclang
