#!/usr/bin/env bash
# Sets up video-use + assets for the reel workflow (idempotent, macOS + Linux).
# Usage: bash scripts/setup.sh
# Danach: ElevenLabs-Key in ~/Developer/video-use/.env eintragen (siehe Ausgabe am Ende).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO=~/Developer/video-use
ASSETS=~/Developer/video-use-assets
GF=https://raw.githubusercontent.com/google/fonts/main/ofl
OS="$(uname -s)"

# 1. system tools: ffmpeg, uv (python env manager)
if [ "$OS" = "Darwin" ]; then
  command -v brew >/dev/null || { echo "Homebrew fehlt: https://brew.sh installieren, dann Skript erneut starten."; exit 1; }
  command -v ffmpeg >/dev/null || brew install ffmpeg
  command -v uv >/dev/null || brew install uv
  FONT_DIR=~/Library/Fonts
else
  command -v ffmpeg >/dev/null || (apt-get update && apt-get install -y ffmpeg)
  # mediapipe needs libEGL even on CPU
  apt-get install -y libegl1 libgles2 libgl1 >/dev/null
  command -v uv >/dev/null || pip install uv
  FONT_DIR=~/.fonts
fi

# 2. video-use clone + python deps (in its own .venv)
mkdir -p ~/Developer
if [ -d "$REPO" ]; then git -C "$REPO" pull --ff-only; else git clone https://github.com/browser-use/video-use "$REPO"; fi
(cd "$REPO" && uv sync && uv pip install mediapipe opencv-python-headless fonttools)
PY="$REPO/.venv/bin/python"

# 3. register skill for Claude Code
mkdir -p ~/.claude/skills && ln -sfn "$REPO" ~/.claude/skills/video-use

# 4. fonts: Montserrat (static ExtraBold/Black from the variable font), Anton, Instrument Serif
mkdir -p "$ASSETS/fonts" "$ASSETS/models" "$FONT_DIR"
cd "$ASSETS/fonts"
curl -sSfL -o Montserrat-VF.ttf "$GF/montserrat/Montserrat%5Bwght%5D.ttf"
curl -sSfLO "$GF/anton/Anton-Regular.ttf"
curl -sSfLO "$GF/instrumentserif/InstrumentSerif-Italic.ttf"
curl -sSfLO "$GF/instrumentserif/InstrumentSerif-Regular.ttf"
"$PY" -m fontTools.varLib.instancer Montserrat-VF.ttf wght=800 -o Montserrat-ExtraBold.ttf -q
"$PY" -m fontTools.varLib.instancer Montserrat-VF.ttf wght=900 -o Montserrat-Black.ttf -q
cp ./*.ttf "$FONT_DIR/"
command -v fc-cache >/dev/null && fc-cache -f >/dev/null || true

# 5. person segmentation model
cd "$ASSETS/models"
test -f selfie_multiclass_256x256.tflite || curl -sSfLO \
  https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_multiclass_256x256/float32/latest/selfie_multiclass_256x256.tflite

# 6. brand logos + config from this repo
mkdir -p "$ASSETS/brands" && cp -r "$REPO_ROOT/brands/." "$ASSETS/brands/"

# 7. global working rules for all local Claude Code sessions (~/.claude/CLAUDE.md)
mkdir -p ~/.claude && touch ~/.claude/CLAUDE.md
grep -q "## Arbeitsweise mit David" ~/.claude/CLAUDE.md || { printf '\n'; cat "$REPO_ROOT/config/user-CLAUDE.md"; } >> ~/.claude/CLAUDE.md

# 8. smoke test
"$PY" - "$ASSETS" <<'EOF'
import sys
from mediapipe.tasks.python import vision, BaseOptions
from PIL import ImageFont
a = sys.argv[1]
vision.ImageSegmenter.create_from_options(vision.ImageSegmenterOptions(
    base_options=BaseOptions(model_asset_path=f"{a}/models/selfie_multiclass_256x256.tflite"),
    output_confidence_masks=True))
for f in ["Montserrat-ExtraBold", "Montserrat-Black", "Anton-Regular", "InstrumentSerif-Italic"]:
    ImageFont.truetype(f"{a}/fonts/{f}.ttf", 40)
print("mediapipe + fonts OK")
EOF
ffprobe -version | head -1

if grep -q '^ELEVENLABS_API_KEY=..' "$REPO/.env" 2>/dev/null; then
  echo "setup done. ElevenLabs key vorhanden."
else
  echo "setup done. Jetzt noch den ElevenLabs-Key eintragen:"
  echo "  printf 'ELEVENLABS_API_KEY=%s\n' 'DEIN_KEY' > $REPO/.env && chmod 600 $REPO/.env"
fi
