"""Runs the game headless-ish with --write-movie and builds one contact sheet from it.

python tools/godot/capture.py <out_dir> <frames> [<every_n>] [<scene> [<game args>...]]

Run it from the repository root. Frames are recorded at 25 FPS (the game's own rate) at the
project's window size. Look at the one sheet it writes, <out_dir>/sheet.png, instead of
reading single frames. Needs Pillow.
"""
import subprocess, sys, pathlib
from PIL import Image, ImageDraw

out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
frames = int(sys.argv[2]); every = int(sys.argv[3]) if len(sys.argv) > 3 else 25
scene = sys.argv[4:5]
game_args = ["--", *sys.argv[5:]] if len(sys.argv) > 5 else []
for old in out.glob("f*.png"): old.unlink()
subprocess.run(["./Godot_v4.7.2-stable_win64_console.exe", "--path", ".", *scene,
                "--write-movie", str(out / "f.png"), "--fixed-fps", "25",
                "--quit-after", str(frames), *game_args], check=True)
picked = sorted(out.glob("f0*.png"))[::every]
w, h, cols = 480, 270, 3
sheet = Image.new("RGB", (w * cols, h * ((len(picked) + cols - 1) // cols)))
for k, path in enumerate(picked):
    im = Image.open(path).convert("RGB").resize((w, h))
    ImageDraw.Draw(im).text((6, 6), path.stem[-5:], fill="yellow")
    sheet.paste(im, ((k % cols) * w, (k // cols) * h))
sheet.save(out / "sheet.png")
print(out / "sheet.png", len(picked), "frames")
