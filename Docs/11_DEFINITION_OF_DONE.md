# 11 — Definition of Done (DoD)

> A feature (Implementation Plan) is **only** considered COMPLETE when ALL items below are checked.
> Partial completion = NOT DONE. Do not mark a task `[x]` in PROGRESS_TRACKER.md until every gate passes.

---

## The 7 DoD Gates

### Gate 1: Compilation ✅
- [ ] Code compiles in MetaEditor 5 with **ZERO Errors**.
- [ ] Code compiles in MetaEditor 5 with **ZERO Warnings**.

### Gate 2: No Magic Numbers ✅
- [ ] Every numeric literal is a named constant in `Include/Defines.mqh` OR an EA input parameter.
- [ ] No hardcoded values anywhere in the feature's `.mqh` file(s).

### Gate 3: Architecture Compliance ✅
- [ ] Follows SOLID principles (single responsibility per class/method).
- [ ] Does not violate `Docs/02_ARCHITECTURE.md` class hierarchy (V2 classes).
- [ ] New class has constructor, destructor, `Init()` returning `bool`, and `Deinit()`.

### Gate 4: Performance ✅
- [ ] No heavy loops inside `OnTick()`.
- [ ] No `CopyBuffer()` calls inside `OnTick()` — all indicator reads in `Update()` (bar-close).
- [ ] No indicator handle creation inside `OnTick()`.

### Gate 5: Error Handling ✅
- [ ] All indicator handles validated against `INVALID_HANDLE`.
- [ ] All `CopyBuffer()` calls check return value (>= 1).
- [ ] Missing history / insufficient data handled gracefully.

### Gate 6: Testing ✅
- [ ] At least one `Print()`-based unit test added that logs the feature's output to Journal.
- [ ] Output visually verified against MetaTrader chart (e.g., ZigZag nodes match).
- [ ] Edge cases tested: missing data, invalid handle.

### Gate 7: Documentation & Git ✅
- [ ] `CHANGELOG.md` updated with the new feature entry.
- [ ] `PROGRESS_TRACKER.md` task marked `[x]`.
- [ ] `HANDOVER.md` updated with next steps.
- [ ] Commit message follows `Docs/10_GIT_WORKFLOW.md` convention.
- [ ] `Docs/12_PR_TEMPLATE.md` checklist completed and reviewed.
