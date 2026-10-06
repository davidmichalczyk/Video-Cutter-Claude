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
  # Prebuilt binaries instead of Homebrew: on older macOS versions Homebrew
  # compiles ffmpeg + ~25 deps from source (hours). These builds include
  # libx265, zscale/zimg and libass.
  BIN=~/.local/bin; mkdir -p "$BIN"
  case "$(uname -m)" in arm64) FFARCH=arm64 ;; *) FFARCH=amd64 ;; esac
  for b in ffmpeg ffprobe; do
    if ! "$BIN/$b" -version >/dev/null 2>&1; then
      curl -sSfL -o "/tmp/$b.zip" "https://ffmpeg.martin-riedl.de/redirect/latest/macos/$FFARCH/release/$b.zip"
      unzip -o -q "/tmp/$b.zip" -d "$BIN" && rm "/tmp/$b.zip" && chmod +x "$BIN/$b"
      xattr -d com.apple.quarantine "$BIN/$b" 2>/dev/null || true
    fi
  done
  command -v uv >/dev/null || [ -x "$BIN/uv" ] || curl -LsSf https://astral.sh/uv/install.sh | sh
  grep -q 'HOME/.local/bin' ~/.zprofile 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
  export PATH="$BIN:$PATH"
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
# replace an older copy of the block so updated rules always land
"$PY" - "$REPO_ROOT/config/user-CLAUDE.md" <<'EOF'
import os, re, sys
p = os.path.expanduser("~/.claude/CLAUDE.md"); s = open(p).read()
s = re.sub(r"\n?## Arbeitsweise mit David.*?(?=\n## |\Z)", "", s, flags=re.S).rstrip()
open(p, "w").write((s + "\n\n" if s else "") + open(sys.argv[1]).read())
EOF

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
