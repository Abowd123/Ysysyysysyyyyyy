#!/usr/bin/env bash
# Regenerates every binary asset from source, so the repository can stay
# 100% text (SVG, JSON, Dart, Python). Used by CI; safe to run locally.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m pip install --quiet numpy scipy cairosvg shapely
mkdir -p assets/audio/sfx assets/audio/music assets/fonts
# sounds + music (original, generated)
python3 tools/gen_sfx.py
for f in music_meadow music_dream; do
  if [ -f assets/audio/sfx/$f.wav ]; then
    ffmpeg -loglevel error -y -i assets/audio/sfx/$f.wav -c:a libvorbis -q:a 3 assets/audio/music/$f.ogg
    rm assets/audio/sfx/$f.wav
  fi
done
# launcher icons + store icon from tools/icon/lolo.svg
python3 - <<'PY'
import cairosvg, os
for name, px in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    os.makedirs(f'tools/icon/mipmap-{name}', exist_ok=True)
    cairosvg.svg2png(url='tools/icon/lolo.svg', write_to=f'tools/icon/mipmap-{name}/ic_launcher.png', output_width=px)
cairosvg.svg2png(url='tools/icon/lolo.svg', write_to='tools/icon/play_store_512.png', output_width=512)
PY
# font (SIL Open Font License) from the official Google Fonts repository
if [ ! -f assets/fonts/BalooBhaijaan2.ttf ]; then
  curl -fsSL -o assets/fonts/BalooBhaijaan2.ttf \
    "https://github.com/google/fonts/raw/main/ofl/baloobhaijaan2/BalooBhaijaan2%5Bwght%5D.ttf"
fi
echo "binary assets ready"
