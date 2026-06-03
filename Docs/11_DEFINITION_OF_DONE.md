# Definition of Done (DoD)

> A feature (Implementation Plan) is **only** considered COMPLETE when ALL items below are checked.
> Partial completion = NOT DONE. Do not mark a task `[x]` in PROGRESS_TRACKER.md until every gate passes.

---

## The 7 DoD Gates

### Gate 1: Compilation ✅
- [ ] Code compiles in MetaEditor 5 with **ZERO Errors**.
- [ ] Code compiles in MetaEditor 5 with **ZERO Warnings**.
- No exceptions. Not even "informational" warnings.

### Gate 2: No Magic Numbers ✅
- [ ] Every numeric literal is a named constant in `Include/Defines.mqh` OR an EA input parameter.
- [ ] No hardcoded values anywhere in the feature's `.mqh` file(s).
- Run a search for bare numbers in the diff before committing.

### Gate 3: Architecture Compliance ✅
- [ ] Follows SOLID principles (single responsibility per class/method).
- [ ] Does not violate `Docs/02_ARCHITECTURE.md` class hierarchy.
- [ ] New class has constructor, destructor, `Init()` returning `bool`, and `Deinit()`.
- [ ] `Init()` returning `false` causes EA to return `INIT_FAILED`.

### Gate 4: Performance ✅
- [ ] No heavy loops inside `OnTick()`.
- [ ] No `CopyBuffer()` calls inside `OnTick()` — all indicator reads in `Update()` (bar-close).
- [ ] No indicator handle creation inside `OnTick()`.

### Gate 5: Error Handling ✅
- [ ] All indicator handles validated against `INVALID_HANDLE`.
- [ ] All `CopyBuffer()` calls check return value (>= 1).
- [ ] Missing history / insufficient data handled gracefully — log and return, do not crash.
- [ ] Error messages use format: `PrintFormat("[ERROR] %s: <message>", __FUNCTION__)`.

### Gate 6: Testing ✅
- [ ] At least one `Print()`-based unit test added that logs the feature's output to Journal.
- [ ] Output visually verified against MetaTrader chart (for sensor/pattern features).
- [ ] Edge cases tested: missing data, zero ATR, invalid handle.

### Gate 7: Documentation & Git ✅
- [ ] `CHANGELOG.md` updated with the new feature entry.
- [ ] `PROGRESS_TRACKER.md` task marked `[x]`.
- [ ] `HANDOVER.md` updated with next steps.
- [ ] Commit message follows `Docs/10_GIT_WORKFLOW.md` convention.
- [ ] Feature branch merged into `develop` (not directly to `main`).
- [ ] `Docs/12_PR_TEMPLATE.md` checklist completed and reviewed.

---

## Quick Reference Card

```
DoD = Compile(0 err, 0 warn)
    + NoMagicNumbers
    + SOLID
    + BarCloseOnly
    + ErrorHandling
    + PrintTest
    + DocsAndGit
```

If ANY gate fails → feature is NOT done → fix and re-check from Gate 1.
