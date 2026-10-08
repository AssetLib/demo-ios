#!/usr/bin/env python3
"""Generate an ignored local project without changing the committed remote dependency."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
sdk = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root.parent / "sdk-swift"
if not (sdk / "Package.swift").is_file():
    raise SystemExit("SDK checkout must contain Package.swift")
build = root / "LocalBuild"
build.mkdir(exist_ok=True)
spec = (root / "project.yml").read_text()
remote = "    url: https://github.com/AssetLib/sdk-swift.git\n    exactVersion: 0.2.0-preview.1"
if remote not in spec:
    raise SystemExit("Expected remote SDK declaration was not found")
spec = spec.replace(remote, "    path: " + str(sdk))
path = build / "project.local.yml"
path.write_text(spec)
subprocess.run(["xcodegen", "generate", "--spec", str(path), "--project", str(build), "--project-root", str(root)], check=True)
