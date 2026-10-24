"""Overnight automation: every 10 seconds, look at the screen for the finished-part marker, and when it
is there, start the next session by typing into the Claude Code chat box.

The marker is the lone line "q7Zk#x2" that a part or microplan session ends with. The script reads the
text in `BOX`, a strip of the screen (at 1920 x 1080) just above the chat box where that last line
appears, with Windows' own OCR, and it fires only when a line reads exactly the marker. The VS Code
window and its layout must stay as they were when `BOX` was chosen.

Run it with `auto_next.bat` in the repository root. Stop it with Ctrl+C in its window, or by
throwing the mouse into a corner of the screen (pyautogui's fail-safe).
Needs Pillow, pyautogui, pyperclip and the winrt packages (winrt-runtime, winrt-Windows.Media.Ocr,
winrt-Windows.Graphics.Imaging, winrt-Windows.Storage.Streams, winrt-Windows.Globalization,
winrt-Windows.Foundation, winrt-Windows.Foundation.Collections).
"""
import asyncio
import io
import time

import pyautogui
import pyperclip
from PIL import ImageGrab
from winrt.windows.graphics.imaging import BitmapDecoder
from winrt.windows.media.ocr import OcrEngine
from winrt.windows.storage.streams import DataWriter, InMemoryRandomAccessStream

MARKER = "q7Zk#x2"
BOX = (1320, 750, 1600, 785)  # left, top, right, bottom on the screen
SCALE = 3  # the strip is enlarged before reading
CHAT_BOX = (1580, 863)  # where to click so the chat box has the keyboard
START_WAIT = 5  # seconds before the first look, to get out of the way
CHECK_EVERY = 10  # seconds
NUDGE_AFTER = 900  # seconds without a detection before the reminder is sent
COOLDOWN = 300  # seconds after a start before it may fire again
AFTER_CLEAR = 10
AFTER_PROMPT = 5
PROMPT = (
    'Read the README. If the most recent part was a multiple of 3, invoke microplanning. '
    'If not, then implement whatever is the next part. At the end of whichever you do, write '
    '"q7Zk#x2" as a lone line. If README says that the process is over, do nothing, also don\'t '
    'write the lone line at the end.'
)

NUDGE = (
    "Don't forget the automation line. This message is only sent if it hasn't detected anything "
    "for 15 minutes. If you receive this repeatedly, stop trying to fix it so we can save tokens. "
    'Just say "Okay.".'
)

pyautogui.FAILSAFE = True


async def read_lines(engine: OcrEngine) -> list[str]:
    img = ImageGrab.grab(bbox=BOX, all_screens=True).convert("RGB")
    img = img.resize((img.width * SCALE, img.height * SCALE))
    buf = io.BytesIO()
    img.save(buf, "PNG")
    stream = InMemoryRandomAccessStream()
    writer = DataWriter(stream)
    writer.write_bytes(buf.getvalue())
    await writer.store_async()
    stream.seek(0)
    decoder = await BitmapDecoder.create_async(stream)
    result = await engine.recognize_async(await decoder.get_software_bitmap_async())
    return [line.text.strip() for line in result.lines]


def marker_is_showing(engine: OcrEngine) -> bool:
    return MARKER in asyncio.run(read_lines(engine))


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


def send_nudge() -> None:
    pyautogui.click(*CHAT_BOX)
    time.sleep(0.5)
    pyperclip.copy(NUDGE)
    pyautogui.hotkey("ctrl", "v")
    time.sleep(1)
    pyautogui.press("enter")


def main() -> None:
    engine = OcrEngine.try_create_from_user_profile_languages()
    print(f"Watching {BOX} every {CHECK_EVERY} s for the text {MARKER}, after {START_WAIT} s. Ctrl+C stops it.", flush=True)
    time.sleep(START_WAIT)
    last_fired = -COOLDOWN
    last_activity = time.monotonic()  # the last start or nudge, or the launch
    while True:
        if time.monotonic() - last_fired >= COOLDOWN and marker_is_showing(engine):
            print(time.strftime("%H:%M:%S"), "marker found: starting the next session", flush=True)
            start_next_session()
            last_fired = last_activity = time.monotonic()
        elif time.monotonic() - last_activity >= NUDGE_AFTER:
            print(time.strftime("%H:%M:%S"), "nothing detected for 15 minutes: sending the reminder", flush=True)
            send_nudge()
            last_activity = time.monotonic()
        time.sleep(CHECK_EVERY)


if __name__ == "__main__":
    main()
