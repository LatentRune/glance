#!/usr/bin/env python3
"""Checks the layout rules that keep Glance easy to work on. Run before a PR; CI runs it too.

    python3 tools/check.py

- Every .lua file under src/ is listed in Glance.toc, and every listed file exists.
- features/ only works things out: no frames, textures, font strings, or drawing.
- ui/ and settings/ don't read the combat log or register events of their own except
  through ns.Listen (so /glance cpu can see what they cost).
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "src")

# What features/ may not call: these make or draw things, which is ui/'s job.
FEATURE_FORBIDDEN = re.compile(r"CreateFrame|CreateTexture|CreateFontString|:SetPoint\(|:SetScript\(|:Show\(\)|:Hide\(\)|:SetShown\(|SetColorTexture|SetStatusBarColor")
# What only core/ may call: frames listen through ns.Listen / ns.ListenUnits.
EVENT_DIRECT = re.compile(r":RegisterEvent\(|:RegisterUnitEvent\(|CombatLogGetCurrentEventInfo")
EVENT_OK = {"core", "features", "dev"}  # dev/Debug.lua counts combat log lines on its own panel


def strip_comments(line):
    return line.split("--", 1)[0]


def main():
    problems = []
    listed = []
    with open(os.path.join(ADDON, "Glance.toc")) as f:
        for line in f:
            m = re.match(r"^\s*([^#\s]\S*\.lua)\s*$", line)
            if m:
                listed.append(m.group(1).replace("\\", "/"))
    on_disk = sorted(os.path.relpath(os.path.join(d, n), ADDON).replace(os.sep, "/")
                     for d, _, files in os.walk(ADDON) for n in files if n.endswith(".lua"))
    for f in listed:
        if f not in on_disk:
            problems.append(f"Glance.toc lists {f}, which doesn't exist")
    for f in on_disk:
        if f not in listed:
            problems.append(f"{f} isn't listed in Glance.toc, so the game won't load it")
    if len(set(listed)) != len(listed):
        problems.append("Glance.toc lists a file twice")

    for rel in on_disk:
        top = rel.split("/", 1)[0]
        with open(os.path.join(ADDON, rel)) as f:
            lines = f.readlines()
        if not lines or not lines[0].startswith("-- "):
            problems.append(f"{rel}: start with a comment saying what the file is for")
        for i, line in enumerate(lines, 1):
            code = strip_comments(line)
            if top == "features" and FEATURE_FORBIDDEN.search(code):
                problems.append(f"{rel}:{i}: features/ works things out and doesn't draw; move this to ui/")
            if top not in EVENT_OK and EVENT_DIRECT.search(code):
                problems.append(f"{rel}:{i}: listen with ns.Listen (core/Hooks.lua) so /glance cpu can count it")

    if problems:
        print("\n".join(problems))
        sys.exit(1)
    print(f"ok: {len(on_disk)} files, all listed, layers clean")


if __name__ == "__main__":
    main()
