## Pull Request — Lula Price Action Engine V2.0

---

## Feature / Implementation Plan
<!-- Link to the Plans/ file this PR implements -->
- **Plan File:** `Docs/Plans/[filename].md`
- **Sprint:** Sprint [N] — [Sprint Name]
- **Branch:** `feature/[feature-name]`

## Purpose
<!-- One sentence: what does this feature do and why does it exist? -->

## Files Changed
<!-- List every file modified or created -->
| File | Change Type |
|------|-------------|
| `Source/...` | [CREATED / MODIFIED] |

---

## AI Developer Checklist (Definition of Done)

### Compilation
- [ ] Compiles with **0 errors** in MetaEditor 5.
- [ ] Compiles with **0 warnings** in MetaEditor 5.

### Code Quality
- [ ] Conforms strictly to `Docs/Plans/[filename].md` scope.
- [ ] **No magic numbers.** All numeric constants are in `Include/Defines.mqh`.
- [ ] Follows SOLID principles per `Docs/02_ARCHITECTURE.md`.

### Performance & Safety
- [ ] No `CopyBuffer()` or indicator reads inside `OnTick()`.
- [ ] All indicator handles validated against `INVALID_HANDLE`.
- [ ] Missing data / insufficient history handled safely (log + return, no crash).

### Testing
- [ ] Unit test `Print()` added — output verified in MetaTrader Journal tab.
- [ ] Edge case tested: missing history / invalid handle.

### Documentation & Git
- [ ] `CHANGELOG.md` updated.
- [ ] `PROGRESS_TRACKER.md` task marked `[x]`.
- [ ] `HANDOVER.md` next steps updated.
- [ ] Commit message follows convention: `feat: [description]`

---

## Commit Message
```
feat: [exact commit message here]
```

## Architectural Impact
<!-- Does this change affect other classes? Does it modify a shared struct? -->

## Notes / Known Limitations
<!-- Anything the reviewer should be aware of -->
