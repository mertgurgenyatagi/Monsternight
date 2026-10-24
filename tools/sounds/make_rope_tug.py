"""Makes assets/audio/sfx/rope_tug.ogg: a soft rope rustle with a dull thump, for Tug of War's
presses. It replaces rope_pull.ogg there, whose strained creak was grating when repeated on every
press. Run from the repository root: python tools/sounds/make_rope_tug.py . (needs ffmpeg, numpy and scipy)"""
import os
import subprocess
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

root = sys.argv[1] if len(sys.argv) > 1 else "."
rate = 44100
rng = np.random.default_rng(7)
n = int(rate * 0.16)
t = np.arange(n) / rate

# the rustle: noise through a low band, in a quick swell and a fall
noise = rng.standard_normal(n)
sos = butter(2, [250, 1800], btype="band", fs=rate, output="sos")
rustle = sosfilt(sos, noise)
env = np.minimum(t / 0.015, 1.0) * np.exp(-t / 0.05)
rustle *= env

# the thump: a low sine that drops a little
freq = 120.0 - 400.0 * t
thump = np.sin(2 * np.pi * np.cumsum(freq) / rate) * np.exp(-t / 0.045) * 0.9

sound = rustle / np.abs(rustle).max() * 0.55 + thump * 0.45
sound = np.tanh(sound * 1.2)
sound *= 0.6 / np.abs(sound).max()
fade = np.minimum(1.0, (n - np.arange(n)) / (0.02 * rate))
sound *= fade

wav = os.path.join(root, "audio_raw", "sfx", "rope_tug.wav")
wavfile.write(wav, rate, (sound * 32767).astype(np.int16))
out = os.path.join(root, "assets", "audio", "sfx", "rope_tug.ogg")
ffmpeg = os.environ.get("FFMPEG", "ffmpeg")
subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", out], check=True)
print("wrote", out)
