# 10 — Git Workflow & Branching Strategy

> **Read this before creating any branch or writing any commit message.**

---

## Core Branch Model

```
main
│  Production-ready, live-account safe code only.
│
└─ develop
   │  Integration branch. All completed sprint features merge here.
   │
   ├─ feature/v2-architecture-docs
   ├─ feature/v2-trend-structure
   ├─ feature/v2-risk-manager
   ├─ feature/v2-trade-monitor
   │
   ├─ bugfix/zigzag-node-read
   └─ hotfix/order-send-crash
```

---

## Branch Naming Convention

### Feature Branches
Must map directly to our sprint tasks:
```
feature/v2-architecture-docs
feature/v2-trend-structure
feature/v2-kama-dynamic-sr
feature/v2-risk-manager
feature/v2-trade-executor
feature/v2-confluence-grader
feature/v2-trade-setup-manager
feature/v2-active-trade-manager
```

### Bugfix Branches
Non-critical fixes found during development:
```
bugfix/zigzag-node-read
bugfix/lot-calculation-clamp
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
| `feat:` | New feature | `feat: implement CTrendStructure node reader` |
| `fix:` | Bug fix | `fix: correct zigzag buffer EMPTY_VALUE check` |
| `refactor:` | Restructure | `refactor: extract zone rank logic` |
| `test:` | Tests | `test: add CTrendStructure output validation test` |
| `docs:` | Documentation | `docs: update HANDOVER.md for Sprint 2` |
| `chore:` | Maintenance | `chore: update .gitignore` |

---

## Pull Request Workflow

1. Create feature branch from `develop`: `git checkout -b feature/v2-trend-structure develop`
2. Implement the feature per its `Docs/Plans/` Implementation Contract.
3. Verify: MetaEditor compiles with **0 errors, 0 warnings**.
4. Fill out `Docs/12_PR_TEMPLATE.md` checklist.
5. Commit: `git commit -m "feat: implement CTrendStructure node reader"`
6. Merge to `develop`: `git checkout develop` → `git merge --no-ff feature/...`
7. Delete feature branch: `git branch -d feature/...`

---

## AI Agent Git Rules

When the AI implements a feature it MUST:
1. Acknowledge the current branch before writing any code.
2. Make ONE logical change per commit — not a dump of all changes.
3. Never modify files outside the scope of the current `Plans/` contract.
4. Provide the exact commit message string using our convention above.
5. Explain any architectural impacts before committing.
6. Update `PROGRESS_TRACKER.md` and `CHANGELOG.md` as part of the commit.
