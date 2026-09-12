# Changelog

## Unreleased - 2026-09-12

- Corrected the public submission materials to identify 张博文 and
  `zhangbowen2006` consistently.
- Removed personal contact details from the public repository; the official
  hackathon form is now the source of truth for phone and email information.
- Documented the frozen Mooncakes publishing command and package-list check.

## 0.2.0 - 2026-08-18

- Added root-motion bounds with min/max/size metrics and JSON/CSV exporters.
- Added deterministic nearest-neighbor motion resampling that preserves clip duration.
- Added escaped JUnit XML quality reports for CI test-report integration.
- Added named multi-asset batch gates with aggregate JSON and CSV reports.
- Extended the CLI with bounds, resampling, batch-gate, and JUnit modes.

## Repository acceptance hardening - 2026-08-18

- Added authorship mapping and source, dependency, fixture, and AI-assistance provenance.
- Added end-to-end acceptance tests, bringing the suite to 72 passing tests.
- Strengthened CI with warning denial, all-target checks, formatting, and API snapshot verification.
- Added a reproducible Windows acceptance script and recorded testing evidence.
- Added Chinese documentation, architecture, security policy, and final acceptance report.
- Finalized the proposal as a completed-project declaration with explicit scope boundaries.
- Synchronized public API snapshots with the stable MoonBit 0.10.8 toolchain used by CI.

## 0.1.0 - 2026-07-28

- Added ASCII BVH tokenizer with token position metadata.
- Added hierarchy parser for ROOT, JOINT, End Site, OFFSET, and CHANNELS.
- Added MOTION frame parser for frame count, frame time, and fixed-width frame values.
- Added query helpers for joints, paths, channels, frame values, rotations, and root motion.
- Added validation report for parser errors, channel offsets, unknown channels, and frame data issues.
- Added analysis helpers for clip stats, channel ranges, static channels, and root-motion samples.
- Added skeleton summaries, signatures, compatibility diffs, and retarget map planning.
- Added motion slicing, time-based frame lookup, root-speed samples, teleport detection, and root-origin normalization.
- Added quality scoring with text, JSON, and CSV output.
- Added Unity, Blender, strict CI, and preview import profiles with decision exporters.
- Added JSON and CSV exporters.
- Added Unity and Blender metadata plan builders.
- Added CLI report, quality, and import-profile modes.
- Added basic example, tests, docs, CI, and MIT license.
