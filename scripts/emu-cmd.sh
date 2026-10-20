#!/bin/zsh
# Sends a debug command to Spofity running in a Light Touch emulator (debug builds only, see music/App/MMDebug.m)
# and optionally prints a file the command wrote. Needs ../Emulators (ltm helper) next to this repo.
#   scripts/emu-cmd.sh ipad "orient 3"
#   scripts/emu-cmd.sh ipad layout layout.txt     # prints Library/Riff/layout.txt
#   scripts/emu-cmd.sh usb audiostate             # the real phone on USB
set -eu
if (( $# < 2 )); then
    sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
fi
dev=$1 cmd=$2 out=${3:-}
here=${0:A:h}
ltm="$here/../../Emulators/ltm"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# afcclient does not exit by itself: run it in the background and stop it after a few seconds
# dev "usb" = the real device on USB (plain afcclient), otherwise a Light Touch emulator via ltm
if [[ $dev == usb ]]; then
afc() { afcclient --container com.onionjumoke.spofity "$@" </dev/null >/dev/null 2>&1 & local p=$!; sleep 4; kill $p 2>/dev/null || true; }
else
afc() { "$ltm" "$dev" afcclient --container com.onionjumoke.spofity "$@" </dev/null >/dev/null 2>&1 & local p=$!; sleep 4; kill $p 2>/dev/null || true; }
fi
print -r -- "$cmd" > "$tmp/cmd"
[[ -n $out ]] && afc rm "/Library/Riff/$out"   # no stale output if the app is not running
afc put "$tmp/cmd" /Library/Riff/.cmd
if [[ -n $out ]]; then
    sleep 2   # the app polls .cmd once per second
    afc get "/Library/Riff/$out" "$tmp/out"
    cat "$tmp/out"
fi
