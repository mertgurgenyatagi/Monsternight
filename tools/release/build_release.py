"""Builds the Windows release of Monsternight without the Godot MCP.

Run it from the repository root: python tools/release/build_release.py [<out_dir>]
       python tools/release/build_release.py --web [--debug] [<out_dir>]   (the itch.io zip: build/web/ and monsternight_web.zip;
                    --debug keeps ?bot, ?turns and ?mini for browser tests: build/web_debug/, no zip)
       python tools/release/build_release.py --stage <empty_dir>   (only the stripped copy, to test it)

It copies only what the game needs into a scratch folder, drops the MCP's three autoloads and its
editor plugin from that copy's project.godot, imports the assets and exports the "Windows Desktop"
preset from export_presets.cfg. The development project is never touched, so it keeps the MCP.
Needs the Godot 4.7.2 export templates (Editor > Manage Export Templates) and only Python.
"""
import re
import zipfile
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENGINE = ROOT / "Godot_v4.7.2-stable_win64_console.exe"
KEEP = ["assets", "src", "locale", "web", "default_bus_layout.tres", "project.godot", "export_presets.cfg"]
MCP_LINES = re.compile(r'^(MCP\w+="\*res://addons/godot_mcp/.*)\n', re.M)
ITCH_MAX_FILES = 1000
ITCH_MAX_FILE = 200 * 1000 * 1000
PLUGINS = re.compile(r'\[editor_plugins\]\n\nenabled=PackedStringArray\([^\n]*\)\n\n?')


def stage(work: Path) -> None:
    """Copies the game into `work` and cuts the MCP out of its project.godot."""
    for name in KEEP:
        src = ROOT / name
        if src.is_dir():
            shutil.copytree(src, work / name)
        else:
            shutil.copy2(src, work / name)
    project = (work / "project.godot").read_text(encoding="utf-8")
    project = PLUGINS.sub("", MCP_LINES.sub("", project))
    assert "godot_mcp" not in project, "the MCP is still in project.godot"
    (work / "project.godot").write_text(project, encoding="utf-8")


def build_web(out: Path, debug: bool) -> int:
    """Exports the Web preset to `out` and zips it the way itch.io wants: index.html at the top."""
    work = Path(tempfile.mkdtemp(prefix="monsternight_web_"))
    try:
        stage(work)
        subprocess.run([str(ENGINE), "--headless", "--path", str(work), "--import"], check=True)
        if out.exists():
            shutil.rmtree(out)
        out.mkdir(parents=True)
        subprocess.run([str(ENGINE), "--headless", "--path", str(work),
                        "--export-debug" if debug else "--export-release",
                        "Web", str(out / "index.html")], check=True)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    files = sorted(p for p in out.rglob("*") if p.is_file())
    assert (out / "index.html").exists(), "the export has no index.html"
    assert len(files) <= ITCH_MAX_FILES, f"{len(files)} files, itch.io allows {ITCH_MAX_FILES}"
    for f in files:
        assert f.stat().st_size < ITCH_MAX_FILE, f"{f.name} is {f.stat().st_size} bytes, itch.io allows under 200 MB"
        if f.suffix == ".pck":
            assert b"godot_mcp" not in f.read_bytes(), "the MCP is in the export"
    if debug:
        print(f"debug build in {out}, no zip")
        return 0
    archive = out.parent / "monsternight_web.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for f in files:
            z.write(f, f.relative_to(out).as_posix())
    print(f"{len(files)} files, {sum(f.stat().st_size for f in files) / 1e6:.1f} MB, "
          f"zip {archive.stat().st_size / 1e6:.1f} MB: {archive}")
    return 0


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "--web":
        rest = [a for a in sys.argv[2:] if a != "--debug"]
        debug = "--debug" in sys.argv
        return build_web(Path(rest[0]).resolve() if rest else ROOT / "build" / ("web_debug" if debug else "web"), debug)
    if len(sys.argv) > 2 and sys.argv[1] == "--stage":
        stage(Path(sys.argv[2]).resolve())
        return 0
    out = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "build"
    work = Path(tempfile.mkdtemp(prefix="monsternight_release_"))
    try:
        stage(work)
        subprocess.run([str(ENGINE), "--headless", "--path", str(work), "--import"], check=True)
        out.mkdir(parents=True, exist_ok=True)
        exe = out / "Monsternight.exe"
        subprocess.run([str(ENGINE), "--headless", "--path", str(work), "--export-release",
                        "Windows Desktop", str(exe)], check=True)
        print("Built", exe)
        return 0
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
