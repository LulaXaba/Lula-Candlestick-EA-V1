# Git Workflow & Branching Strategy
> **Read this before creating any branch or writing any commit message.**

---

## Core Branch Model

```
main
│  Production-ready, live-account safe code only.
│  Never commit directly here. Merge via PR from develop only.
│
└─ develop
   │  Integration branch. All completed sprint features merge here.
   │  Must compile with 0 errors before anything merges to main.
   │
   ├─ feature/sprint1-sensor-engine
   ├─ feature/sprint2-pinbar-logic
   ├─ feature/sprint3-choppy-filter
   ├─ feature/sprint4-risk-calc
   │
   ├─ bugfix/vix75-spread-math
   └─ hotfix/order-send-crash
```

---

## Branch Naming Convention

### Feature Branches
Must map directly to our sprint tasks:
```
feature/sprint1-engine3-weekly-macro
feature/sprint1-engine1-supply-demand
feature/sprint1-engine2-standard-sr
feature/sprint1-engine4-role-reversal
feature/sprint2-pinbar-detector
feature/sprint2-engulfing-detector
feature/sprint2-false-breakout-detector
feature/sprint3-state-machine
feature/sprint4-decision-tree
feature/sprint4-risk-manager
feature/sprint4-trade-executor
```

### Bugfix Branches
Non-critical fixes found during development:
```
bugfix/vix75-spread-math
bugfix/lot-calculation-clamp
bugfix/atr-handle-invalid
```

### Hotfix Branches
Emergency fixes to production (`main`) only:
```
hotfix/order-send-crash
hotfix/drawdown-halt-bypass
```

### Forbidden Branch Names
```
newfeature   fix1   testing   branch2   mybranch   update   changes
```
These names become meaningless after weeks. Always use the format above.

---

## Commit Message Standards (Conventional Commits)

| Prefix | Use For | Example |
|--------|---------|---------|
| `feat:` | New feature | `feat: implement Engine 3 WeeklyMacro 26-bar scan` |
| `fix:` | Bug fix | `fix: correct ATR 800 threshold gate logic` |
| `refactor:` | Restructure without behaviour change | `refactor: extract zone rank logic to CPriceZone` |
| `test:` | Add or update tests | `test: add Engine 3 output validation print test` |
| `docs:` | Documentation only | `docs: update HANDOVER.md for sprint 2 start` |
| `chore:` | Maintenance | `chore: update .gitignore for .ex5 artifacts` |

### Examples — Good vs Bad
```
# BAD — never do this
fixed stuff
update
changes
wip

# GOOD
feat: implement CSensorArray.SupplyDemand() base candle scan
fix: correct false breakout body-not-wick boundary check
refactor: move rollover window check to CSensorArray::Update()
```

---

## Pull Request Workflow

1. Create feature branch from `develop`: `git checkout -b feature/sprint1-engine3-weekly-macro develop`
2. Implement the feature per its `Docs/Plans/` Implementation Contract.
3. Verify: MetaEditor compiles with **0 errors, 0 warnings**.
4. Fill out `Docs/12_PR_TEMPLATE.md` checklist.
5. Commit: `git commit -m "feat: implement Engine 3 WeeklyMacro 26-bar scan"`
6. Merge to `develop`: `git checkout develop` → `git merge --no-ff feature/...`
7. Tag sprint completion: `git tag -a v0.x.0-sprintN-complete -m "Sprint N complete"`
8. Delete feature branch: `git branch -d feature/...`

---

## AI Agent Git Rules

When the AI implements a feature it MUST:
1. Acknowledge the current branch before writing any code.
2. Make ONE logical change per commit — not a dump of all changes.
3. Never modify files outside the scope of the current `Plans/` contract.
4. Provide the exact commit message string using our convention above.
5. Explain any architectural impacts before committing.
6. Update `PROGRESS_TRACKER.md` and `CHANGELOG.md` as part of the commit.
