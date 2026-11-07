"""Runs the shared test cases that both Python and Dart engines must pass."""
import json
from pathlib import Path

import pytest

CASES_FILE = Path(__file__).resolve().parents[2] / "tests" / "test_cases.json"


def load_cases():
    with open(CASES_FILE, encoding="utf-8") as f:
        return json.load(f)["cases"]


def test_file_is_valid_json():
    data = json.loads(CASES_FILE.read_text(encoding="utf-8"))
    assert "cases" in data


@pytest.mark.parametrize("case", load_cases(), ids=lambda c: c["id"])
def test_case(case):
    # TODO (Dev A): once engine.py exists, apply case["move"] to case["state"]
    # and compare with case["expected"].
    pytest.skip("engine not implemented yet")
