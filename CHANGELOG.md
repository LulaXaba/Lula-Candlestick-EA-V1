# Changelog

All notable changes to Lula V1 will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- Initial project scaffold (Sprint 0)
- Full directory and file structure created
- Placeholder MQH class files for all four sprints

---

## [0.1.0] - Sprint 0 — Scaffold
### Added
- README, CHANGELOG, HANDOVER, PROGRESS_TRACKER root files
- Docs/ folder with 10 specification documents (00–09)
- Source/ folder with sprint sub-directories
- Lula_V1.mq5 main EA execution shell
- Lula_V1.mqproj MetaEditor project file
- Include/Defines.mqh — all global enums and constants
- Include/DTOs.mqh — SSensorData, SPatternResult, SMarketState structs
- Sprint1_Sensors/ — CSensorArray, C_ATRModule, C_KAMAModule, CPriceZone + 4 detector engines
- Sprint2_Patterns/ — CPatternEngine + 4 detectors (skeleton)
- Sprint3_State/ — CStateMachine + 5 analyzers (skeleton)
- Sprint4_Execution/ — CDecisionTree, CRiskManager, CTradeExecutor, CCorrelationFilter (skeleton)
