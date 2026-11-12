#!/bin/sh
# Regenerates every procedural asset. Needs python3 with pillow, numpy, scipy, plus ffmpeg.
# Optional first argument: path to the original web project (to re-crop the painted sheets).
cd "$(dirname "$0")/.." || exit 1
python3 tools/make_visuals.py "$@"
python3 tools/make_audio.py
python3 tools/check_gd.py scripts
