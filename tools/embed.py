#!/usr/bin/env python3
"""Base64-embed the wasm module and stamp into the HTML template."""
import base64
import os
import sys

wasm_path, template_path, out_path = sys.argv[1:]
stamp = os.environ.get("STAMP", "v0.0 b00000000-0000 0000000")
source_sha = os.environ.get("SOURCE_SHA", "0000000").rstrip("+")
data = open(wasm_path, "rb").read()
b64 = base64.b64encode(data).decode("ascii")
html = open(template_path, encoding="utf-8").read()
html = html.replace("{{WASM_BASE64}}", b64)
html = html.replace("{{STAMP}}", stamp)
html = html.replace("{{SOURCE_SHA}}", source_sha)
os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
open(out_path, "w", encoding="utf-8").write(html)
print(f"wrote {out_path} ({len(html)} bytes, wasm {len(data)})")
