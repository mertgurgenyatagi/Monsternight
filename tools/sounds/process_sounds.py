# Processes the raw sounds in audio_raw/ into assets/audio/, following the Processing lines in docs/sound_prompts.md.
# Usage: python process_sounds.py <repo root> [<name> ...]   (names like ui_click, hop_1; none means all)
# Needs ffmpeg on the PATH, or its path in the FFMPEG environment variable.
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy import signal

ROOT = Path(sys.argv[1])
WANTED = set(sys.argv[2:])
FFMPEG = os.environ.get("FFMPEG") or shutil.which("ffmpeg") or sys.exit("Install ffmpeg or set FFMPEG first.")
RATE = 48000

# Parts that processing joins into one file, in order. A part isn't a file of its own.
JOIN = {"sfx/thief": ["sfx/thief", "sfx/thief_giggle"]}
PARTS = {p for parts in JOIN.values() for p in parts[1:]}

# Loudness targets in LUFS. One-shots are measured by their loudest 200 ms, which is fairer to short clicks than
# the standard 400 ms, and ambience over its whole length.
TARGET = {"ui": -28.0, "sfx": -22.0, "voices": -19.0, "ambience": -34.0}
WINDOW = 0.2
CEILING = -1.5  # dBFS sample peak, with room for the OGG encoder's overshoot

TRIM_START = -40.0  # dB under the peak where a sound starts
TRIM_END = -50.0  # dB under the peak where its tail ends
PRE_ROLL = 0.002  # seconds kept before the start, faded in, so the attack doesn't click
END_FADE = 0.005  # seconds of fade-out on every one-shot, so it doesn't click
LOOP_FADE = 1.0  # seconds of crossfade between an ambience loop's end and its start


def read(path):
    # Always decoded as stereo: one-shots are mixed down to mono afterwards, and ambience stays stereo.
    raw = subprocess.run(
        [FFMPEG, "-v", "error", "-i", str(path), "-f", "f32le", "-ar", str(RATE), "-ac", "2", "-"],
        capture_output=True, check=True,
    ).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).astype(np.float64)


def write(path, audio):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [FFMPEG, "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", str(audio.shape[1]), "-i", "-",
         "-c:a", "libvorbis", "-q:a", "6", str(path)],
        input=audio.astype(np.float32).tobytes(), check=True,
    )


def db(x):
    return 20 * np.log10(max(x, 1e-12))


def ramp(n):
    return np.linspace(0, 1, n)[:, None]


def trim(audio):
    level = np.abs(audio).max(axis=1)
    peak = level.max()
    loud = np.flatnonzero(level > peak * 10 ** (TRIM_START / 20))
    tail = np.flatnonzero(level > peak * 10 ** (TRIM_END / 20))
    start = max(loud[0] - int(PRE_ROLL * RATE), 0)
    audio = audio[start:tail[-1] + 1].copy()
    n = min(int(PRE_ROLL * RATE), len(audio))
    audio[:n] *= ramp(n)
    return audio


def cut(audio, seconds):
    if len(audio) > seconds * RATE:
        audio = audio[:int(seconds * RATE)].copy()
        fade = min(0.15, 0.2 * seconds)
    else:
        fade = END_FADE
    n = min(int(fade * RATE), len(audio))
    audio[len(audio) - n:] *= ramp(n)[::-1]
    return audio


def loop(audio):
    # The end crossfades into the start, so the last sample leads straight back into the first.
    n = int(LOOP_FADE * RATE)
    t = np.linspace(0, np.pi / 2, n)[:, None]
    out = audio[:-n].copy()
    out[:n] = audio[:n] * np.sin(t) + audio[-n:] * np.cos(t)
    return out


def k_weight(audio):
    # The K-weighting filter from ITU-R BS.1770, at 48 kHz.
    audio = signal.lfilter([1.53512485958697, -2.69169618940638, 1.19839281085285],
                           [1.0, -1.69065929318241, 0.73248077421585], audio, axis=0)
    return signal.lfilter([1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621], audio, axis=0)


def loudness(audio, whole):
    power = (k_weight(audio) ** 2).sum(axis=1)
    if whole:
        mean = power.mean()
    else:
        n = int(WINDOW * RATE)
        power = np.concatenate([power, np.zeros(max(n - len(power), 0))])
        sums = np.cumsum(np.concatenate([[0.0], power]))
        mean = (sums[n:] - sums[:-n]).max() / n
    return -0.691 + 10 * np.log10(max(mean, 1e-12))


def level(audio, target, whole):
    gain = target - loudness(audio, whole)
    gain = min(gain, CEILING - db(np.abs(audio).max()))
    return audio * 10 ** (gain / 20)


doc = (ROOT / "docs" / "sound_prompts.md").read_text(encoding="utf-8")
lengths = {}
for heading, seconds, kind in re.findall(r"^### (.+?)\n.*?^\*\*Processing:\*\* ([\d.]+) s, (one-shot|seamless loop)\.",
                                         doc, re.S | re.M):
    for path in re.findall(r"`([^`]+)\.ogg`", heading):
        lengths[path] = (float(seconds), kind == "seamless loop")

print(f"{'file':28} {'raw s':>6} {'out s':>6} {'ch':>3} {'LUFS':>6} {'peak':>6}")
for path, (seconds, looping) in lengths.items():
    name = Path(path).name
    if path in PARTS or (WANTED and name not in WANTED):
        continue
    folder = path.split("/")[0]
    raws = [next((ROOT / "audio_raw").glob(f"{part}.*")) for part in JOIN.get(path, [path])]
    if looping:
        audio = read(raws[0])
        raw_seconds = len(audio) / RATE
        audio = level(loop(audio), TARGET[folder], whole=True)
    else:
        target = TARGET["ui" if name.startswith("ui_") else folder]
        pieces, raw_seconds = [], 0.0
        for part, raw in zip(JOIN.get(path, [path]), raws):
            audio = read(raw)
            raw_seconds += len(audio) / RATE
            audio = cut(trim(audio.mean(axis=1, keepdims=True)), lengths[part][0])
            pieces.append(level(audio, target, whole=False))
        audio = level(np.concatenate(pieces), target, whole=False)
    write(ROOT / "assets" / "audio" / f"{path}.ogg", audio)
    print(f"{path:28} {raw_seconds:6.2f} {len(audio) / RATE:6.2f} {audio.shape[1]:3} "
          f"{loudness(audio, whole=looping):6.1f} {db(np.abs(audio).max()):6.1f}")
    WANTED.discard(name)

if WANTED:
    print(f"not found in the doc: {sorted(WANTED)}")
