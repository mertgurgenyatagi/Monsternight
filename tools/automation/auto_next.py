"""Overnight automation: every minute, look at the screen for the finished-part marker, and when it
is there, start the next session by typing into the Claude Code chat box.

The marker is the lone line "q7Zk#x2" that a part or microplan session ends with. Its picture is
`crop.png` in the repository root, an 85 x 90 px grab of the screen at (1325, 780) to (1410, 870),
which ends just inside the top border of the chat box. The match is pixel for pixel, so the
VS Code window, its layout, the zoom and the screen must stay as they were when `crop.png` was made.

Run it with `auto_next.bat` in the repository root. Stop it with Ctrl+C in its window, or by
throwing the mouse into a corner of the screen (pyautogui's fail-safe).
Needs Pillow, numpy, pyautogui and pyperclip.
"""
import time
from pathlib import Path

import numpy as np
import pyautogui
import pyperclip
from PIL import Image, ImageGrab

ROOT = Path(__file__).resolve().parents[2]
CROP = ROOT / "crop.png"
BOX = (1325, 780, 1410, 870)  # left, top, right, bottom on the screen
CHAT_BOX = (1580, 892)  # where to click so the chat box has the keyboard
CHECK_EVERY = 60  # seconds
AFTER_CLEAR = 10
AFTER_PROMPT = 5
PROMPT = (
    'Read the README. If the most recent part was a multiple of 3, invoke microplanning. '
    'If not, then implement whatever is the next part. At the end of whichever you do, write '
    '"q7Zk#x2" as a lone line. If README says that the process is over, do nothing, also don\'t '
    'write the lone line at the end.'
)

pyautogui.FAILSAFE = True


def marker_is_showing(wanted: np.ndarray) -> bool:
    seen = np.asarray(ImageGrab.grab(bbox=BOX, all_screens=True).convert("RGB"))
    return seen.shape == wanted.shape and np.array_equal(seen, wanted)


def start_next_session() -> None:
    pyautogui.click(*CHAT_BOX)
    time.sleep(0.5)
    pyautogui.write("/clear", interval=0.05)
    time.sleep(0.5)
    pyautogui.press("enter")
    time.sleep(AFTER_CLEAR)
    pyautogui.click(*CHAT_BOX)
    time.sleep(0.5)
    pyperclip.copy(PROMPT)  # pasted, because typing a long text key by key is slow and fragile
    pyautogui.hotkey("ctrl", "v")
    time.sleep(AFTER_PROMPT)
    pyautogui.press("enter")


def main() -> None:
    wanted = np.asarray(Image.open(CROP).convert("RGB"))
    print(f"Watching {BOX} every {CHECK_EVERY} s for {CROP.name}. Ctrl+C stops it.", flush=True)
    while True:
        if marker_is_showing(wanted):
            print(time.strftime("%H:%M:%S"), "marker found: starting the next session", flush=True)
            start_next_session()
            time.sleep(CHECK_EVERY)  # the old marker is gone after /clear; don't re-fire on a stale frame
        time.sleep(CHECK_EVERY)


if __name__ == "__main__":
    main()
