#!/bin/sh
# Start jack for ouput only (-P) on Soundcraft Notepad-8FX
echo starting jackd in background...
echo "============================"
echo "=== To Stop: pkill jackd ==="
echo "============================"
# nohup prevents ssh from killing jackd when shell session exits
# std{in,out,err} redirects allow terminal to be reused for sclang
# CAUTION: skipping the stdin redirect leads to audio deadline miss glitches
nohup jackd --realtime -d alsa -P hw:Notepad8FX </dev/null >/dev/null 2>&1 &
