# AI Agent Handover Document

**CONTEXT TO NEW AGENT:** You are an MQL5 Quantitative Developer Agent. We are building the "Lula Price Action Engine V1". You are taking over at the very beginning of the coding phase.

---

**CURRENT STATE:**
- **Active Sprint:** Sprint 1 (The Sensor Array)
- **Last Completed Task:** All governance and architecture files successfully mapped to the IDE. All 5 misalignments between generated scaffold and actual specification have been corrected.
- **Current Active File:** `Source/Include/Defines.mqh`

---

**KNOWN ROADBLOCKS / BUGS:**
- None. Starting fresh code generation.

---

**YOUR IMMEDIATE NEXT INSTRUCTION:**
1. Read `Docs/08_MASTER_SPRINT_SPEC.md` to understand Sprint 1 fully.
2. Read `Docs/03_CODING_STANDARDS.md` to format your MQL5 correctly.
3. Read `Docs/00_DISCOVERY.md` — the 4 Discovered Solutions drive architecture decisions.
4. Read `Docs/09_RESEARCH_NOTES.md` — VIX75 ATR threshold and measurement rules are mandatory.
5. Write the MQL5 code for `Include/Defines.mqh`. It must contain:
   - Global Enums: Market State, Zone Type, Zone Rank, Pattern Type, Trade Direction, Gate ID
   - Hardcoded constants: `VIX75_MIN_ATR = 800`, `MAX_WEEKLY_DRAWDOWN = -6.0`
   - All other constants from Docs/09_RESEARCH_NOTES.md (rollover window, 26-bar lookback, etc.)

---

**ARCHITECTURE DECISIONS LOCKED BY DISCOVERY:**

| Decision | Rule |
|----------|------|
| Retracement = valid state | `STATE_RETRACEMENT` passes Gate 5 — do not reject it |
| Grade A Engulfing Override | Gate 5 bypassed if `SPatternResult.isGradeA == true` |
| False Breakout body rule | 15M close must be inside 4H **body** (Open/Close), not wick (High/Low) |
| VIX75 ATR gate | All entries blocked if `ATR(14) < VIX75_MIN_ATR (800)` |
| Rollover filter | No new trades between broker 23:55–00:05 |
| Weekly scan depth | 26 bars only for Engine 3 (WeeklyMacro) |

---

**ENGINE NAMING (Sprint 1 — non-negotiable):**

| Engine | File | Function |
|--------|------|----------|
| Engine 1 | `CEngine1_SupplyDemand.mqh` | `SupplyDemand()` — identify S/D zones |
| Engine 2 | `CEngine2_StandardSR.mqh` | `StandardSR()` — horizontal S/R levels |
| Engine 3 | `CEngine3_WeeklyMacro.mqh` | `WeeklyMacro()` — weekly bias & macro levels |
| Engine 4 | `CEngine4_RoleReversal.mqh` | `RoleReversal()` — broken S/R flips to opposite |
