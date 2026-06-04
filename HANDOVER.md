# AI Agent Handover Document

**CONTEXT TO NEW AGENT:** You are an MQL5 Quantitative Developer Agent. We are building the "Lula Price Action Engine V1". You are taking over at the very beginning of the coding phase.

---

**CURRENT STATE:**
- **Active Sprint:** Sprint 2 (Pattern Recognition Engine)
- **Last Completed Task:** Sprint 1 — The Sensor Array — is **fully compiled and locked**.
  All 11 interface gaps from Appendix A are resolved and closed. MetaEditor 5 reports
  **0 errors and 0 warnings** across all 9 Sprint 1 files. Key fixes applied:
  - Unified `ENUM_ZONE_RANK` / `ENUM_ZONE_TYPE` enums in `Defines.mqh` (added 6 missing values).
  - Added missing constants: `ROLE_REVERSAL_MAX_BARS`, `RISK_REDUCTION_THRESHOLD`, `VIX75_MAX_SPREAD`.
  - Replaced all static `CopyBuffer` arrays with `double[]; ArrayResize()` pattern in
    `C_ATRModule`, `C_KAMAModule`, and `CSensorArray`.
  - Removed invalid `CPriceZone::Init()` call in `CEngine2_StandardSR::DetectZones()`.
  - Added missing `GetWeeklyATR()` accessor to `CEngine3_WeeklyMacro`.
- **Current Active File:** `Docs/Plans/sprint2-pattern-engine-manager.md`

---

**KNOWN ROADBLOCKS / BUGS:**
- None. Sprint 1 is fully compiled and locked. Starting Sprint 2 fresh.

---

**YOUR IMMEDIATE NEXT INSTRUCTION:**
1. Read `Docs/Plans/sprint2-pattern-engine-manager.md` to understand Sprint 2 fully.
2. Read `Docs/08_MASTER_SPRINT_SPEC.md` — Section: Sprint 2 (Pattern Recognition).
3. Read `Docs/04_TRADING_RULES.md` — pattern definitions and Grade A Engulfing Override rule.
4. Read `Docs/03_CODING_STANDARDS.md` to format your MQL5 correctly.
5. Sprint 1 is **frozen** — do NOT modify any Sprint 1 files unless a Sprint 2 compilation
   error forces a backport fix (document any such fix in `CHANGELOG.md`).
6. Build Sprint 2 in this order:
   - `C_PinBarDetector.mqh`
   - `C_EngulfingDetector.mqh` (must include `isGradeA` flag)
   - `C_InsideBarDetector.mqh`
   - `C_FalseBreakoutDetector.mqh` (15M close inside 4H **body**, not wick)
   - `CPatternEngine.mqh` (orchestrator — mirrors CSensorArray pattern)

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
