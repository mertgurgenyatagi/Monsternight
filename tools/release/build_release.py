"""Builds the Windows release of Monsternight without the Godot MCP.

Run it from the repository root: python tools/release/build_release.py [<out_dir>]
       python tools/release/build_release.py --stage <empty_dir>   (only the stripped copy, to test it)

It copies only what the game needs into a scratch folder, drops the MCP's three autoloads and its
editor plugin from that copy's project.godot, imports the assets and exports the "Windows Desktop"
preset from export_presets.cfg. The development project is never touched, so it keeps the MCP.
Needs the Godot 4.7.2 export templates (Editor > Manage Export Templates) and only Python.
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENGINE = ROOT / "Godot_v4.7.2-stable_win64_console.exe"
KEEP = ["assets", "src", "locale", "default_bus_layout.tres", "project.godot", "export_presets.cfg"]
MCP_LINES = re.compile(r'^(MCP\w+="\*res://addons/godot_mcp/.*)\n', re.M)
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


def main() -> int:
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
