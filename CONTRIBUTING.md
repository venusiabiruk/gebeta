# Contributing

## Branches
- `main`: always working, protected
- `feature/<name>`: your work, one branch per task

## Daily flow
```
git checkout main
git pull
git checkout -b feature/my-task
# ... work ...
git add .
git commit -m "engine: add sowing logic"
git push -u origin feature/my-task
```
Then open a Pull Request on GitHub.

## Commit message prefixes
`engine:` `app:` `tests:` `docs:` `ci:`

## Shared tests
If you change game rules or engine behavior, update `tests/test_cases.json`
and make sure BOTH engines pass.
