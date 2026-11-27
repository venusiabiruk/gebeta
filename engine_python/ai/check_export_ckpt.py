"""Checks that export.py reads the 8 GebetaNet state_dict keys (PR #77)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export

failures = 0


def check(label, ok):
    global failures
    print(("PASS  " if ok else "FAIL  ") + label)
    if not ok:
        failures += 1


def zeros(rows, cols=None):
    if cols is None:
        return [0.0] * rows
    return [[0.0] * cols for _ in range(rows)]


def good_state_dict():
    return {
        "h1.weight": zeros(128, 14), "h1.bias": zeros(128),
        "h2.weight": zeros(128, 128), "h2.bias": zeros(128),
        "policy.weight": zeros(6, 128), "policy.bias": zeros(6),
        "value.weight": zeros(1, 128), "value.bias": zeros(1),
    }


def error_of(sd):
    try:
        export.build_from_state_dict(sd)
    except ValueError as e:
        return str(e)
    return ""


# 1. A correct state_dict is converted.
out = export.build_from_state_dict(good_state_dict())
check("reads all 8 keys with the right shapes",
      [l["name"] for l in out["layers"]] == ["h1", "h2", "policy", "value"])
check("header matches section 6",
      out["format"] == "gebeta-mlp" and out["version"] == 1
      and out["input_size"] == 14 and out["input_scale"] == 48)

# 2. Weights are copied unchanged.
sd = good_state_dict()
sd["h1.weight"][3][5] = 0.123456789
check("weights are exported unchanged",
      export.build_from_state_dict(sd)["layers"][0]["weights"][3][5] == 0.123456789)

# 3. Missing key: the error names the key.
sd = good_state_dict()
del sd["h2.bias"]
check("missing key error names h2.bias", "h2.bias" in error_of(sd))

# 4. Wrong shape: the error names the key.
sd = good_state_dict()
sd["policy.weight"] = zeros(6, 127)
check("wrong shape error names policy.weight", "policy.weight" in error_of(sd))

# 5. A dict that holds the state_dict inside is accepted.
inner = good_state_dict()
check("accepts {'state_dict': ...}", export.extract_state_dict({"state_dict": inner}) is inner)
check("accepts {'model_state_dict': ...}",
      export.extract_state_dict({"model_state_dict": inner}) is inner)
check("accepts a plain state_dict", export.extract_state_dict(inner) is inner)

print("\nAll checks passed." if failures == 0 else "\n%d check(s) FAILED." % failures)
sys.exit(1 if failures else 0)
