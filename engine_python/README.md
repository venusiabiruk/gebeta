# engine_python

Python Gebeta engine (used for training and as the reference implementation).

## Setup
```
cd engine_python
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pytest
```

## Planned modules (inside `gebeta_engine/`)
- `engine.py`: board state, legal moves, sowing, captures, game end
- `minimax.py`: alpha-beta baseline opponent
- later: self-play, MCTS, model training, export
