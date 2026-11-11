#!/usr/bin/env bash
#
# Rebuild every native splash asset from the vector masters.
#
# Layer 2 of the launch sequence draws the SVGs directly, so it needs nothing
# from here. Layer 1 cannot: the screen the platform shows before any Dart runs
# is a plain drawable, and a splash drawable renders neither SVG, nor text, nor
# a scaled bitmap. So the frame ① composition — the butterfly at 118dp and 0.92
# opacity with the wordmark 16dp below it — is baked into one PNG per density,
# and Android 12's circular splash icon into another.
#
# Run this whenever the marks or the wordmark change. Nothing is upscaled: every
# size is rendered from the vector at its own resolution.
#
#   ./tool/generate_launch_assets.sh
#
# Requires rsvg-convert (librsvg2-bin) and Python with Pillow.
set -euo pipefail

cd "$(dirname "$0")/.."
command -v rsvg-convert >/dev/null || { echo "need rsvg-convert (apt install librsvg2-bin)"; exit 1; }

python3 tool/generate_launch_assets.py
echo "native splash assets rebuilt from assets/launch/*.svg"
