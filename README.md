# Lula Price Action Execution Engine V1.0

> **Multi-Timeframe Candlestick EA for VIX75 & Forex**
> Weekly Bias → Daily Confirmation → 4H Primary Signal → 1H Structure → 15M/5M Execution

## Overview
Lula V1 is a fully automated, rules-based Expert Advisor built in MQL5.
It applies a strict top-down market analysis protocol before placing any trade,
using a 7-Gate Decision Tree to ensure high-probability setups only.

## Quick Start
1. Open `Source/Lula_V1.mqproj` in MetaEditor.
2. Compile `Lula_V1.mq5`.
3. Attach to VIX75 (Volatility 75 Index) on MT5 — recommended TF: 15M.

## Documentation Index
| File | Purpose |
|------|---------|
| Docs/01_PROJECT_OVERVIEW.md | Goals & mandate |
| Docs/02_ARCHITECTURE.md | SOLID / OOP class map |
| Docs/03_CODING_STANDARDS.md | MQL5 naming conventions |
| Docs/04_TRADING_RULES.md | Timeframe protocol |
| Docs/05_RISK_MANAGEMENT.md | Drawdown & ATR sizing |
| Docs/06_DECISION_TREE.md | 7-Gate boolean logic |
| Docs/07_AI_RULEBOOK.md | Agent constraints |
| Docs/08_MASTER_SPRINT_SPEC.md | Sprint 1-4 plan |

## Sprint Status
- [ ] Sprint 1 — Sensors (The Eyes)
- [ ] Sprint 2 — Patterns (The Language)
- [ ] Sprint 3 — State Machine (The Judgment)
- [ ] Sprint 4 — Execution Engine (The Trigger)
