#!/usr/bin/env python3
"""Narrates the README showcase: one voice clip per line of lib/showcase/narration.tsv.

For each line it asks Kass (the local dictation app, which runs Kokoro voices on this Mac) for
the audio, then asks whisper.cpp where every word falls, and matches those words back onto the
script. It writes:

  lib/showcase/narration.g.dart   the timings the showcase timeline is built from (committed)
  build/showcase/voiceover.wav    every clip placed at its time, for render_showcase.sh to mux

and FAILS when a clip does not say what the script says. A voice can clip a line or garble a
word and still return a valid WAV; Whisper hearing something else is how that is caught.

Whisper's words carry no punctuation and spell sound-alikes its own way ("docks" comes back
"docs", "moors" as "mores", "quay" as "key"), so words are matched loosely and the TIMES come
from Whisper while the WORDS always come from the script.

Needs: Kass running (its server stops when the app quits), whisper-cli and a ggml model, ffmpeg.
  python3 tool/narrate.py                       # voice am_liam, speed 1.0
  NARRATION_VOICE=am_michael python3 tool/narrate.py
"""
import difflib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
import wave

EXAMPLE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(EXAMPLE, "lib", "showcase", "narration.tsv")
DART = os.path.join(EXAMPLE, "lib", "showcase", "narration.g.dart")
BUILD = os.path.join(EXAMPLE, "build", "showcase")
KASS = os.environ.get("NARRATION_KASS", "http://127.0.0.1:17493/speech")
VOICE = os.environ.get("NARRATION_VOICE", "am_liam")
SPEED = float(os.environ.get("NARRATION_SPEED", "1.0"))
MODEL = os.path.expanduser(os.environ.get("NARRATION_WHISPER_MODEL", "~/.whisper-cpp/models/ggml-medium.bin"))

LEAD_IN = 0.6          # silence before the first line
BETWEEN_LINES = 0.35   # within a chapter
BETWEEN_CHAPTERS = 0.9
TAIL = 1.5             # after the last line
MIN_MATCH = 0.85       # share of a line's words Whisper must have heard, or the clip is wrong

# Spellings Whisper chooses for words the script spells otherwise. Matching only: the script's
# spelling is what is written out.
SOUND_ALIKES = {"docs": "docks", "mores": "moors", "key": "quay", "keys": "quays", "pier": "pier", "peer": "pier"}


def words(text):
    return [w for w in re.findall(r"[a-z0-9']+", text.lower().replace("’", "'"))]


def normal(word):
    word = word.strip("'")
    return SOUND_ALIKES.get(word, word)


def speak(text, path):
    body = json.dumps({"text": text, "voice": VOICE, "speed": SPEED}).encode()
    request = urllib.request.Request(KASS, data=body, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            audio = response.read()
    except OSError as error:
        sys.exit(f"narrate: Kass did not answer at {KASS} ({error}). Is the Kass app running?")
    if not audio.startswith(b"RIFF"):
        sys.exit(f"narrate: Kass returned something that is not a WAV for: {text!r}")
    with open(path, "wb") as fh:
        fh.write(audio)


def duration(path):
    with wave.open(path) as wav:
        return wav.getnframes() / wav.getframerate()


def heard(path):
    """Whisper's words in the clip, each with its start and end in seconds."""
    with tempfile.TemporaryDirectory() as tmp:
        mono = os.path.join(tmp, "clip.wav")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", path, "-ar", "16000", "-ac", "1", mono], check=True)
        out = os.path.join(tmp, "clip")
        subprocess.run(["whisper-cli", "-m", MODEL, "-f", mono, "-ml", "1", "-sow", "-oj", "-of", out, "-np"],
                       check=True, capture_output=True)
        with open(out + ".json") as fh:
            segments = json.load(fh)["transcription"]
    found = []
    for segment in segments:
        for word in words(segment["text"]):
            found.append((word, segment["offsets"]["from"] / 1000, segment["offsets"]["to"] / 1000))
    return found


def align(script_words, transcript):
    """Each script word with a start and end, timed from the transcript; the share matched."""
    a = [normal(w) for w in script_words]
    b = [normal(w) for w, _, _ in transcript]
    matcher = difflib.SequenceMatcher(None, a, b, autojunk=False)
    times = [None] * len(a)
    for block in matcher.get_matching_blocks():
        for k in range(block.size):
            _, start, end = transcript[block.b + k]
            times[block.a + k] = (start, end)
    matched = sum(1 for t in times if t is not None) / max(1, len(a))
    # Words Whisper spelt too differently to match get the time between their neighbours.
    for i, t in enumerate(times):
        if t is None:
            before = next((times[j][1] for j in range(i - 1, -1, -1) if times[j]), 0.0)
            after = next((times[j][0] for j in range(i + 1, len(times)) if times[j]), before)
            times[i] = (before, max(before, after))
    return times, matched


def place(clips, out, rate):
    """One WAV with every clip at its start time, silence between."""
    total = max(start for _, start in clips)
    frames = {}
    with wave.open(out, "wb") as mix:
        mix.setnchannels(1)
        mix.setsampwidth(2)
        mix.setframerate(rate)
        cursor = 0.0
        for path, start in clips:
            with wave.open(path) as clip:
                if clip.getframerate() != rate or clip.getnchannels() != 1 or clip.getsampwidth() != 2:
                    sys.exit(f"narrate: {path} is not {rate} Hz mono 16-bit like the others")
                mix.writeframes(b"\x00\x00" * int(round((start - cursor) * rate)))
                data = clip.readframes(clip.getnframes())
                mix.writeframes(data)
                cursor = start + clip.getnframes() / rate
        mix.writeframes(b"\x00\x00" * int(TAIL * rate))
    return total


def dart_string(text):
    return "'" + text.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main():
    with open(SCRIPT) as fh:
        lines = [tuple(row.rstrip("\n").split("\t", 1)) for row in fh if row.strip()]
    os.makedirs(os.path.join(BUILD, "voice"), exist_ok=True)

    cursor, previous, placed, failures, rate = LEAD_IN, None, [], [], None
    for index, (chapter, text) in enumerate(lines):
        path = os.path.join(BUILD, "voice", f"{index:02d}.wav")
        speak(text, path)
        with wave.open(path) as wav:
            rate = rate or wav.getframerate()
        if previous is not None:
            cursor += BETWEEN_LINES if chapter == previous else BETWEEN_CHAPTERS
        length = duration(path)
        script_words = words(text)
        transcript = heard(path)
        times, matched = align(script_words, transcript)
        heard_text = " ".join(w for w, _, _ in transcript)
        print(f"{index:02d} {chapter:<5} {cursor:6.2f}s +{length:5.2f}s  heard {matched:4.0%}  {text}")
        if matched < MIN_MATCH:
            failures.append(f"  line {index} ({chapter}): heard {matched:.0%} of it\n    script: {text}\n    heard : {heard_text}")
        placed.append((chapter, text, cursor, length, [(w, cursor + s, cursor + e) for w, (s, e) in zip(script_words, times)]))
        cursor += length
        previous = chapter

    if failures:
        sys.exit("narrate: a clip does not say what the script says. Reword the line or re-render:\n" + "\n".join(failures))

    mix = os.path.join(BUILD, "voiceover.wav")
    place([(os.path.join(BUILD, "voice", f"{i:02d}.wav"), start) for i, (_, _, start, _, _) in enumerate(placed)], mix, rate)

    out = ["// GENERATED by tool/narrate.py from narration.tsv. Do not edit; re-run the tool.", "",
           "import 'narration.dart';", "",
           f"/// Voice: {VOICE} at {SPEED}x, by Kass (Kokoro-82M). The timeline is built from these times.",
           "const List<NarrationLine> narrationLines = <NarrationLine>["]
    for chapter, text, start, length, timed in placed:
        word_list = ", ".join(f"NarrationWord({dart_string(w)}, {s:.3f}, {e:.3f})" for w, s, e in timed)
        out.append(f"  NarrationLine(chapter: {dart_string(chapter)}, text: {dart_string(text)}, start: {start:.3f}, "
                   f"duration: {length:.3f}, words: <NarrationWord>[{word_list}]),")
    out += ["];", "", f"/// When the voiceover ends, tail included.", f"const double narrationEnd = {cursor + TAIL:.3f};", ""]
    with open(DART, "w") as fh:
        fh.write("\n".join(out))
    print(f"narrate: {len(placed)} lines, {cursor + TAIL:.1f}s, voice {VOICE} -> {os.path.relpath(DART, EXAMPLE)}, {os.path.relpath(mix, EXAMPLE)}")


if __name__ == "__main__":
    main()
