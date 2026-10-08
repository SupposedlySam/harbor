#!/usr/bin/env bash
# Records the README showcase and encodes it: doc/media/showcase.mp4 (narrated) and
# doc/media/showcase.gif (silent, as every GIF is).
#
# First tool/narrate.py voices lib/showcase/narration.tsv with Kass, times every word with
# whisper.cpp and writes lib/showcase/narration.g.dart, which the showcase's timeline is built
# from. Then test/render_showcase_test.dart plays the real showcase widget on the test clock, so
# every run produces the same video, and ffmpeg lays the voiceover under it. Needs macOS (the
# fonts are the system's), fvm, ffmpeg, whisper-cli, and the Kass app running.
#
#   SKIP_NARRATION=1 ./tool/render_showcase.sh   keep the committed timings; the MP4 is silent
#
#   ./tool/render_showcase.sh            30 fps MP4; 800 px, 12 fps GIF (about 4.6 MB)
#   GIF_WIDTH=960 GIF_FPS=15 ./tool/render_showcase.sh
set -euo pipefail

example="$(cd "$(dirname "$0")/.." && pwd)"
media="$example/../doc/media"
frames="$example/build/showcase/frames"
fps=30
gif_fps="${GIF_FPS:-12}"
gif_width="${GIF_WIDTH:-800}"

FLUTTER_ROOT="$(fvm flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["flutterRoot"])')"
export FLUTTER_ROOT

voiceover="$example/build/showcase/voiceover.wav"
if [[ "${SKIP_NARRATION:-0}" != "1" ]]; then
  python3 "$example/tool/narrate.py"
else
  echo "render_showcase: SKIP_NARRATION=1, using the committed narration timings with no voice"
  voiceover=""
fi

rm -rf "$frames"
mkdir -p "$frames" "$media"
(cd "$example" && SHOWCASE_OUT="$frames" SHOWCASE_FPS="$fps" fvm flutter test test/render_showcase_test.dart)

count=$(find "$frames" -name 'frame_*.png' | wc -l | tr -d ' ')
if [[ "$count" -eq 0 ]]; then
  echo "render_showcase: the recorder wrote no frames" >&2
  exit 1
fi
echo "render_showcase: $count frames"

if [[ -n "$voiceover" ]]; then
  ffmpeg -loglevel error -y -framerate "$fps" -i "$frames/frame_%05d.png" -i "$voiceover" \
    -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -b:a 128k -shortest -movflags +faststart "$media/showcase.mp4"
else
  ffmpeg -loglevel error -y -framerate "$fps" -i "$frames/frame_%05d.png" \
    -c:v libx264 -pix_fmt yuv420p -crf 20 -movflags +faststart "$media/showcase.mp4"
fi

# Two passes so the GIF gets a palette made for these frames, not a generic one.
filters="fps=$gif_fps,scale=$gif_width:-1:flags=lanczos"
ffmpeg -loglevel error -y -i "$frames/frame_%05d.png" -vf "$filters,palettegen=stats_mode=diff" "$frames/palette.png"
ffmpeg -loglevel error -y -framerate "$fps" -i "$frames/frame_%05d.png" -i "$frames/palette.png" \
  -lavfi "$filters [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" "$media/showcase.gif"

ls -lh "$media/showcase.mp4" "$media/showcase.gif"
