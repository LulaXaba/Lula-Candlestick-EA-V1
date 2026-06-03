# 07 — AI Rulebook: Agent Constraints

## Purpose
This document governs every AI agent session working on this codebase.
Non-compliance with these rules requires a rewrite before continuing.

---

## Session Protocol (MANDATORY ORDER)
1. **READ `HANDOVER.md` FIRST** — Always start with the baton pass file.
2. **READ `PROGRESS_TRACKER.md`** — Know what is done and what is next.
3. **DO THE WORK** — Implement only what is in the current sprint scope.
4. **VERIFY:** Confirm MetaEditor compiles with 0 errors and 0 warnings.
5. **UPDATE `PROGRESS_TRACKER.md`** — Mark tasks `[x]` only after compile verification.
6. **UPDATE `HANDOVER.md` LAST** — Write next steps clearly before ending.

---

## Code Quality Rules (Non-Negotiable)

### Rule 1: No Magic Numbers
Every numeric literal must be a named constant in `Defines.mqh` or an EA input parameter.
```mql5
// WRONG
if(adxValue < 20) ...

// CORRECT
if(adxValue < ADX_CHOPPY_THRESHOLD) ...  // defined in Defines.mqh
```

### Rule 2: No Placeholder Stubs in Active Sprints
`// TODO` comments are only allowed in scaffold files.
Once a sprint is marked ACTIVE, all logic must be implemented.

### Rule 3: No Global Variables
All state lives in class members (`m_` prefix). No module-level globals
except constants defined in `Defines.mqh`.

### Rule 4: All Handles Validated
```mql5
m_handle = iATR(_Symbol, PERIOD_H4, 14);
if(m_handle == INVALID_HANDLE) {
    PrintFormat("[ERROR] %s: Handle creation failed", __FUNCTION__);
    return false;
}
```

### Rule 5: All Array Operations Guarded
```mql5
double buf[1];
ArraySetAsSeries(buf, true);
if(CopyBuffer(m_handle, 0, 1, 1, buf) < 1) return;  // retry next bar
```

---

## Architecture Rules
1. Each `.mqh` file contains **exactly one class**.
2. All classes must have: constructor, destructor, `Init()`, `Deinit()`.
3. `Init()` must return `bool`. `false` triggers `INIT_FAILED`.
4. Use `ENUM_` prefix for all custom enumerations.
5. Use `#ifndef` / `#define` / `#endif` include guards in every `.mqh` file.
6. Do NOT modify files outside the assigned sprint without logging the reason in HANDOVER.md.

---

## Testing Rules
1. Every sprint MUST include at least one `Print()`-based unit test logged to Journal.
2. No sprint is marked complete until MetaEditor shows: **0 errors, 0 warnings**.
3. Backtests must be run in MT5 Strategy Tester before Sprint 4 is marked complete.
