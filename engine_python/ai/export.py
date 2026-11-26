"""export.py: writes the Gebeta network weights file (guide section 6).

Two modes, run from the repo root:
    python engine_python/ai/export.py --random --seed 1
    python engine_python/ai/export.py --ckpt runs/stage1/best.pt
"""
import argparse
import json
import math
import random
from pathlib import Path

INPUT_SIZE = 14
INPUT_SCALE = 48
HIDDEN = 128
POLICY_SIZE = 6

# (name, inputs, outputs, activation, which layer it reads). Same names as the
# PyTorch layers in model.py, so "h1" reads "h1.weight" and "h1.bias".
LAYERS = [
    ("h1", INPUT_SIZE, HIDDEN, "relu", None),
    ("h2", HIDDEN, HIDDEN, "relu", None),
    ("policy", HIDDEN, POLICY_SIZE, "linear", "h2"),
    ("value", HIDDEN, 1, "tanh", "h2"),
]

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = REPO_ROOT / "app_flutter" / "assets" / "model" / "model_weights.json"


def layer_dict(name, n_in, n_out, activation, input_name, weights, bias):
    layer = {"name": name, "in": n_in, "out": n_out, "activation": activation}
    if input_name is not None:
        layer["input"] = input_name
    layer["weights"] = weights
    layer["bias"] = bias
    return layer


def file_dict(layers):
    return {
        "format": "gebeta-mlp",
        "version": 1,
        "input_size": INPUT_SIZE,
        "input_scale": INPUT_SCALE,
        "layers": layers,
    }


# ---------- fake weights (--random) ----------

def build_random_weights(seed):
    """Section 6 file with random numbers of the right shape."""
    rng = random.Random(seed)
    layers = []
    for name, n_in, n_out, act, inp in LAYERS:
        std = math.sqrt(2.0 / n_in)
        weights = [[round(rng.gauss(0.0, std), 6) for _ in range(n_in)]
                   for _ in range(n_out)]
        bias = [round(rng.gauss(0.0, 0.01), 6) for _ in range(n_out)]
        layers.append(layer_dict(name, n_in, n_out, act, inp, weights, bias))
    return file_dict(layers)


# ---------- real weights (--ckpt) ----------

def to_list(x):
    """A torch tensor or numpy array becomes nested lists; lists stay lists."""
    if hasattr(x, "detach"):
        x = x.detach().cpu()
    if hasattr(x, "tolist"):
        return x.tolist()
    return x


def shape_of(x):
    shape = []
    while isinstance(x, list):
        shape.append(len(x))
        if not x:
            break
        x = x[0]
    return tuple(shape)


def extract_state_dict(obj):
    """Accepts a plain state_dict, or a dict that holds one inside."""
    if isinstance(obj, dict):
        for key in ("state_dict", "model_state_dict", "model"):
            if key in obj and isinstance(obj[key], dict):
                return obj[key]
    return obj


def build_from_state_dict(sd):
    """Section 6 file from the 8 GebetaNet keys. Weights are written unchanged."""
    layers = []
    for name, n_in, n_out, act, inp in LAYERS:
        weights = bias = None
        for suffix, expected in (("weight", (n_out, n_in)), ("bias", (n_out,))):
            key = name + "." + suffix
            if key not in sd:
                raise ValueError("missing key %s in the checkpoint" % key)
            value = to_list(sd[key])
            found = shape_of(value)
            if found != expected:
                raise ValueError("%s has the wrong shape: expected %s, found %s"
                                 % (key, expected, found))
            if suffix == "weight":
                weights = value
            else:
                bias = value
        layers.append(layer_dict(name, n_in, n_out, act, inp, weights, bias))
    return file_dict(layers)


def load_checkpoint(path):
    import torch  # only needed for --ckpt
    return extract_state_dict(torch.load(path, map_location="cpu"))


# ---------- manifest and writing ----------

def build_manifest(source, seed=None):
    """useNetworkForMaster stays false until the gate results are measured."""
    return {
        "useNetworkForMaster": False,
        "source": source,
        "seed": seed,
        "gates": {
            "sanity_random": None,
            "sanity_greedy": None,
            "amateur": None,
            "master": None,
        },
    }


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
    print("Wrote", path)


def main():
    parser = argparse.ArgumentParser(description="Write the Gebeta weights file.")
    parser.add_argument("--random", action="store_true", help="write fake random weights")
    parser.add_argument("--seed", type=int, default=1, help="seed for --random")
    parser.add_argument("--ckpt", type=Path, help="path to a PyTorch checkpoint (best.pt)")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="weights file path")
    args = parser.parse_args()

    if args.random == (args.ckpt is not None):
        parser.error("use exactly one of --random or --ckpt")

    if args.random:
        weights = build_random_weights(args.seed)
        manifest = build_manifest("random", args.seed)
    else:
        weights = build_from_state_dict(load_checkpoint(args.ckpt))
        manifest = build_manifest("checkpoint:" + args.ckpt.name)

    write_json(args.out, weights)
    write_json(args.out.parent / "manifest.json", manifest)


if __name__ == "__main__":
    main()