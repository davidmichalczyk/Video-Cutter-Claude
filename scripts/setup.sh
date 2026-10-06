#!/usr/bin/env bash
# Sets up video-use + assets for the reel workflow (idempotent).
# Usage: bash scripts/setup.sh   (then put ELEVENLABS_API_KEY into ~/Developer/video-use/.env)
set -euo pipefail

REPO=~/Developer/video-use
ASSETS=~/Developer/video-use-assets
GF=https://raw.githubusercontent.com/google/fonts/main/ofl

# 1. video-use clone + python deps
mkdir -p ~/Developer
test -d "$REPO" && git -C "$REPO" pull --ff-only || git clone https://github.com/browser-use/video-use "$REPO"
(cd "$REPO" && (command -v uv >/dev/null && uv sync || pip install -e .))
pip install mediapipe opencv-python-headless fonttools

# 2. ffmpeg + EGL (mediapipe needs libEGL even on CPU)
command -v ffmpeg >/dev/null || (apt-get update && apt-get install -y ffmpeg)
apt-get install -y libegl1 libgles2 libgl1 >/dev/null

# 3. register skill for Claude Code
mkdir -p ~/.claude/skills && ln -sfn "$REPO" ~/.claude/skills/video-use

# 4. fonts: Montserrat (static ExtraBold/Black from the variable font), Anton, Instrument Serif
mkdir -p "$ASSETS/fonts" "$ASSETS/models" ~/.fonts
cd "$ASSETS/fonts"
curl -sSfL -o Montserrat-VF.ttf "$GF/montserrat/Montserrat%5Bwght%5D.ttf"
curl -sSfLO "$GF/anton/Anton-Regular.ttf"
curl -sSfLO "$GF/instrumentserif/InstrumentSerif-Italic.ttf"
curl -sSfLO "$GF/instrumentserif/InstrumentSerif-Regular.ttf"
python3 -m fontTools.varLib.instancer Montserrat-VF.ttf wght=800 -o Montserrat-ExtraBold.ttf -q
python3 -m fontTools.varLib.instancer Montserrat-VF.ttf wght=900 -o Montserrat-Black.ttf -q
cp ./*.ttf ~/.fonts/ && fc-cache -f >/dev/null

# 5. person segmentation model
cd "$ASSETS/models"
test -f selfie_multiclass_256x256.tflite || curl -sSfLO \
  https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_multiclass_256x256/float32/latest/selfie_multiclass_256x256.tflite

echo "setup done. ElevenLabs key: printf 'ELEVENLABS_API_KEY=%s\n' \"\$KEY\" > $REPO/.env && chmod 600 $REPO/.env"
