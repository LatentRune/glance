#!/usr/bin/env python3
"""Redraw the website's screenshots from the current code, as small WebP files.

    python3 tools/site-images.py            # every picture docs/ uses
    python3 tools/site-images.py combat     # just these

Runs the glance-shots scenarios of the same names (tools/glance-shots/scenarios/) and saves
each as docs/images/shots/<name>.webp. WebP keeps the pages light: about a tenth of the PNG.
Needs what glance-shots needs, plus Pillow (pip install pillow).
"""

import glob
import os
import re
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "docs", "images", "shots")


def used_names():
    # Every images/shots/<name>.webp the site's pages point at.
    names = set()
    for page in glob.glob(os.path.join(ROOT, "docs", "*.html")):
        names.update(re.findall(r"images/shots/([a-z0-9-]+)\.webp", open(page, encoding="utf-8").read()))
    return sorted(names)


def main():
    names = sys.argv[1:] or used_names()
    with tempfile.TemporaryDirectory() as tmp:
        env = dict(os.environ, GLANCE_SHOTS_OUT=tmp)
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "glance-shots", "shoot.py")] + names,
                       env=env, check=True)
        os.makedirs(SHOTS, exist_ok=True)
        for name in names:
            out = os.path.join(SHOTS, name + ".webp")
            Image.open(os.path.join(tmp, name + ".png")).convert("RGB").save(out, "WEBP", quality=82, method=6)
            print("saved %s (%d KB)" % (os.path.relpath(out, ROOT), os.path.getsize(out) // 1024))


if __name__ == "__main__":
    main()
