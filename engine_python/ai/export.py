"""export.py: writes the Gebeta network weights file (guide section 6).

For now only --random works: fake weights of the right shape, so the Dart work
does not have to wait for a trained model. The --ckpt mode comes later.

Run from the repo root:
    python engine_python/ai/export.py --random --seed 1
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

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = REPO_ROOT / "app_flutter" / "assets" / "model" / "model_weights.json"


def random_layer(rng, name, n_in, n_out, activation, input_name=None):
    """One layer. weights[o][i] is the weight from input i to output o."""
    std = math.sqrt(2.0 / n_in)
    layer = {"name": name, "in": n_in, "out": n_out, "activation": activation}
    if input_name is not None:
        layer["input"] = input_name
    layer["weights"] = [
        [round(rng.gauss(0.0, std), 6) for _ in range(n_in)] for _ in range(n_out)
    ]
    layer["bias"] = [round(rng.gauss(0.0, 0.01), 6) for _ in range(n_out)]
    return layer


def build_random_weights(seed):
    """The section 6 file: h1 14->128, h2 128->128, policy 128->6, value 128->1."""
    rng = random.Random(seed)
    return {
        "format": "gebeta-mlp",
        "version": 1,
        "input_size": INPUT_SIZE,
        "input_scale": INPUT_SCALE,
        "layers": [
            random_layer(rng, "h1", INPUT_SIZE, HIDDEN, "relu"),
            random_layer(rng, "h2", HIDDEN, HIDDEN, "relu"),
            random_layer(rng, "policy", HIDDEN, POLICY_SIZE, "linear", "h2"),
            random_layer(rng, "value", HIDDEN, 1, "tanh", "h2"),
        ],
    }


def build_manifest(seed):
    """Fake weights are never used for Master, so useNetworkForMaster is false."""
    return {
        "useNetworkForMaster": False,
        "source": "random",
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
    parser.add_argument("--seed", type=int, default=1, help="random seed (default 1)")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="weights file path")
    args = parser.parse_args()

    if not args.random:
        parser.error("only --random is supported so far")

    write_json(args.out, build_random_weights(args.seed))
    write_json(args.out.parent / "manifest.json", build_manifest(args.seed))


if __name__ == "__main__":
    main()