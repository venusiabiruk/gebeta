"""Checks that export.py --random writes the section 6 format."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

EXPORT = Path(__file__).resolve().parent / "export.py"
EXPECTED = [
    ("h1", 14, 128, "relu"),
    ("h2", 128, 128, "relu"),
    ("policy", 128, 6, "linear"),
    ("value", 128, 1, "tanh"),
]
failures = 0


def check(label, ok):
    global failures
    print(("PASS  " if ok else "FAIL  ") + label)
    if not ok:
        failures += 1


def run(out_dir, seed):
    out = Path(out_dir) / "model_weights.json"
    subprocess.run(
        [sys.executable, str(EXPORT), "--random", "--seed", str(seed), "--out", str(out)],
        check=True, capture_output=True,
    )
    return out


with tempfile.TemporaryDirectory() as d1, tempfile.TemporaryDirectory() as d2:
    out1 = run(d1, 1)
    w = json.loads(out1.read_text())
    manifest = json.loads((out1.parent / "manifest.json").read_text())

    check("header: format, version, input_size, input_scale",
          w["format"] == "gebeta-mlp" and w["version"] == 1
          and w["input_size"] == 14 and w["input_scale"] == 48)
    check("four layers h1, h2, policy, value in order",
          [l["name"] for l in w["layers"]] == [e[0] for e in EXPECTED])

    shapes_ok = True
    for layer, (name, n_in, n_out, act) in zip(w["layers"], EXPECTED):
        if (layer["in"], layer["out"], layer["activation"]) != (n_in, n_out, act):
            shapes_ok = False
        if len(layer["weights"]) != n_out or any(len(r) != n_in for r in layer["weights"]):
            shapes_ok = False
        if len(layer["bias"]) != n_out:
            shapes_ok = False
    check("every layer has the right shapes (weights[o][i], bias[o])", shapes_ok)

    check("policy and value read h2",
          w["layers"][2].get("input") == "h2" and w["layers"][3].get("input") == "h2")
    check("manifest: useNetworkForMaster is false and gates exist",
          manifest["useNetworkForMaster"] is False and "gates" in manifest)

    same_seed = run(d2, 1).read_text() == out1.read_text()
    check("same seed gives the same file", same_seed)

print("\nAll checks passed." if failures == 0 else "\n%d check(s) FAILED." % failures)
sys.exit(1 if failures else 0)