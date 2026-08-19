# 07 — AI Rulebook: Agent Constraints (V2)

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
if(zigZagVal == 0) ...

// CORRECT
if(zigZagVal == EMPTY_VALUE) ...  // defined in Defines.mqh or native
```

### Rule 2: No Placeholder Stubs in Active Sprints
`// TODO` comments are only allowed in scaffold files.
Once a sprint is marked ACTIVE, all logic must be implemented.

### Rule 3: No Global Variables
All state lives in class members (`m_` prefix). No module-level globals
except constants defined in `Defines.mqh`.

### Rule 4: All Handles Validated
```mql5
m_handle = iCustom(_Symbol, PERIOD_H4, "Examples\\ZigZag", 12, 5, 3);
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
3. Backtests must be run in MT5 Strategy Tester before Sprint 5 is marked complete.

---

## The Implementation Contract Workflow

> **You (the AI Agent) are strictly FORBIDDEN from writing unprompted feature code.**
> No code may be written for any feature until its `Docs/Plans/` contract file has been read and acknowledged.

### The Mandatory Feature Lifecycle
```
Feature Request
      ↓
Read Docs/Plans/<plan-file>.md   ← MUST happen first
      ↓
Acknowledge branch name
      ↓
Execute (write code strictly within Plan scope)
      ↓
Provide exact Git commit message
      ↓
Fill out Docs/12_PR_TEMPLATE.md  ← Proof of Definition of Done
      ↓
Merge to develop
```

### Step-by-Step Agent Instructions

1. **Plan:** When assigned a feature, ask: *"Please confirm which `Docs/Plans/` file I should read."* Do not write a single line of code until you have read and quoted the Plan's Objective.

2. **Branch:** Before coding, state the exact branch name: *"I am working on `feature/v2-trend-structure`."*

3. **Execute:** Write code that implements **only** what the Plan specifies. Nothing more. Nothing outside the Plan's defined Scope.

4. **Commit:** Provide the exact commit message string from the Plan's Git Deliverables table.

5. **Review:** Fill out `Docs/12_PR_TEMPLATE.md` with every checkbox ticked. Present it to prove the Definition of Done (`Docs/11_DEFINITION_OF_DONE.md`) has been met.

### Example Trigger Prompt (use this exact format)
```
"Read HANDOVER.md. We are starting Sprint 2.
Please read Docs/Plans/v2-architecture-spec.md
and implement CTrendStructure logic."
```
