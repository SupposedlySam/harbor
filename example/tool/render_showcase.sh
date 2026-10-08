#!/usr/bin/env bash
# Records the README showcase and encodes it: doc/media/showcase.mp4 and doc/media/showcase.gif.
#
# The frames come from test/render_showcase_test.dart, which plays the real showcase widget on
# the test clock, so every run produces the same video. Needs macOS (the fonts it loads are the
# system's), fvm and ffmpeg.
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

rm -rf "$frames"
mkdir -p "$frames" "$media"
(cd "$example" && SHOWCASE_OUT="$frames" SHOWCASE_FPS="$fps" fvm flutter test test/render_showcase_test.dart)

count=$(find "$frames" -name 'frame_*.png' | wc -l | tr -d ' ')
if [[ "$count" -eq 0 ]]; then
  echo "render_showcase: the recorder wrote no frames" >&2
  exit 1
fi
echo "render_showcase: $count frames"

ffmpeg -loglevel error -y -framerate "$fps" -i "$frames/frame_%05d.png" \
  -c:v libx264 -pix_fmt yuv420p -crf 20 -movflags +faststart "$media/showcase.mp4"

# Two passes so the GIF gets a palette made for these frames, not a generic one.
filters="fps=$gif_fps,scale=$gif_width:-1:flags=lanczos"
ffmpeg -loglevel error -y -i "$frames/frame_%05d.png" -vf "$filters,palettegen=stats_mode=diff" "$frames/palette.png"
ffmpeg -loglevel error -y -framerate "$fps" -i "$frames/frame_%05d.png" -i "$frames/palette.png" \
  -lavfi "$filters [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" "$media/showcase.gif"

ls -lh "$media/showcase.mp4" "$media/showcase.gif"
