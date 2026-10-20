#!/usr/bin/env python3
"""Zip Glance up, either as the whole project or as a player-ready addon.

    python3 tools/package.py            # dist/glance-<version>-source.zip: everything in the repo
    python3 tools/package.py release    # dist/Glance-<version>.zip: src/ as Glance/, plus LICENSE

The source zip is what you hand a contributor: README, .github, tools, prompts, docs and all.
The release zip is what players unzip into Interface/AddOns, with nothing GitHub-specific in it.
Both skip .git and anything .gitignore covers. The addon lives in src/ in the repo; in the release zip it becomes the Glance/ folder
the game expects. The version comes from src/Glance.toc.
"""

import fnmatch
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist")


def version():
    with open(os.path.join(ROOT, "src", "Glance.toc"), encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("## Version:"):
                return line.split(":", 1)[1].strip()
    sys.exit("No ## Version line in src/Glance.toc")


def ignored_patterns():
    # Simple .gitignore reading: one pattern per line, a trailing slash means a folder.
    pats = [".git/", "dist/"]
    path = os.path.join(ROOT, ".gitignore")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            pats += [l.strip() for l in fh if l.strip() and not l.startswith("#")]
    return pats


def skip(name, is_dir, pats):
    for p in pats:
        if p.endswith("/"):
            if is_dir and fnmatch.fnmatch(name, p[:-1]):
                return True
        elif fnmatch.fnmatch(name, p):
            return True
    return False


def files_under(top, pats):
    for here, dirs, files in os.walk(top):
        dirs[:] = sorted(d for d in dirs if not skip(d, True, pats))
        for f in sorted(files):
            if not skip(f, False, pats):
                yield os.path.join(here, f)


def write_zip(out, entries):
    os.makedirs(DIST, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for src, arc in entries:
            z.write(src, arc)
    print(out)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "source"
    v, pats = version(), ignored_patterns()
    if mode == "release":
        # Players get the addon folder with the license inside it, nothing else.
        src = os.path.join(ROOT, "src")
        entries = [(p, os.path.join("Glance", os.path.relpath(p, src))) for p in files_under(src, pats)]
        entries.append((os.path.join(ROOT, "LICENSE"), "Glance/LICENSE"))
        write_zip(os.path.join(DIST, "Glance-%s.zip" % v), entries)
    elif mode == "source":
        top = "glance-%s" % v
        entries = [(p, os.path.join(top, os.path.relpath(p, ROOT))) for p in files_under(ROOT, pats)]
        write_zip(os.path.join(DIST, "glance-%s-source.zip" % v), entries)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
