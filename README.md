# MoonBVHKit

[简体中文](README_zh_CN.md)

[![CI](https://github.com/zhangbowen2006/MoonBVHKit/actions/workflows/ci.yml/badge.svg)](https://github.com/zhangbowen2006/MoonBVHKit/actions/workflows/ci.yml)
[![Mooncakes](https://img.shields.io/badge/mooncakes-0.2.0-orange)](https://mooncakes.io/docs/zhangbowen2006/moonbvhkit@0.2.0)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

MoonBVHKit is a MoonBit-native BVH motion capture parser, validator, analysis helper library, and asset-pipeline reporting toolkit.

## Status

Version `0.2.0` is published on [Mooncakes](https://mooncakes.io/docs/zhangbowen2006/moonbvhkit@0.2.0). The release contains a reusable library, multi-mode CLI, basic example, 90 tests, complete documentation, strict CI, and Mooncakes metadata for `zhangbowen2006/moonbvhkit`.

Repository target: `https://github.com/zhangbowen2006/MoonBVHKit.git`.

Author/submission: 张博文.

## Supported Scope

- ASCII BVH `HIERARCHY` parsing for `ROOT`, nested `JOINT`, and `End Site`.
- `OFFSET`, standard position channels, and standard rotation channels.
- `MOTION` parsing with `Frames:` and `Frame Time:`.
- Fixed-width frame data as `Array[Array[Double]]`.
- Query helpers for joint names, paths, channel order, per-joint frame values, root position, and root motion.
- Skeleton summaries, signatures, compatibility diffs, and name-based retarget maps.
- Motion slicing, frame lookup by time, root-speed sampling, root teleport detection, and root-origin normalization.
- Duration-preserving nearest-neighbor resampling and root-motion spatial bounds.
- Validation for malformed source, channel offsets, unknown channels, frame counts, frame widths, and importer-oriented warnings.
- Import quality scoring with severity signals and recommended CI actions.
- Unity, Blender, strict CI, and preview import profiles for reusable asset-gate decisions.
- Named multi-asset gates with aggregate decisions and per-asset results.
- Text, JSON, CSV, and JUnit XML reporting for automation.
- Unity and Blender integration metadata plans, without depending on either application.

## Not Supported in 0.2

- Blender Python add-on or Unity Editor plug-in.
- Binary/private BVH variants.
- Rotation baking, retargeting, IK, skeleton solving, or coordinate-system conversion.
- Reading external files from the CLI. The CLI uses a built-in fixture so it is deterministic in CI.
- GLTF, FBX, USD, or other model formats.

## Install

```bash
moon add zhangbowen2006/moonbvhkit@0.2.0
```

For local development, clone the repository and run the commands below from the project root.

```bash
moon check
moon build
moon test
moon run cmd/main
moon run cmd/main -- --json
moon run cmd/main -- --csv
moon run cmd/main -- --quality --json
moon run cmd/main -- --profiles --csv
moon run cmd/main -- --bounds --json
moon run cmd/main -- --resample 12
moon run cmd/main -- --batch --profile strict-ci --csv
moon run cmd/main -- --junit
moon run examples/basic
```

On Windows, the complete acceptance sequence can also be reproduced with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1
```

## Minimal Example

```mbt
test "parse a BVH clip" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  let doc = parsed.document
  let stats = @moonbvhkit.analyze_bvh(doc)
  assert_eq(stats.joint_count, 4)
  assert_eq(stats.channel_count, 15)
}
```

## CLI

The CLI parses the built-in walk fixture and prints a deterministic report.

```bash
moon run cmd/main
moon run cmd/main -- --json
moon run cmd/main -- --csv
moon run cmd/main -- --quality
moon run cmd/main -- --quality --json
moon run cmd/main -- --profile unity
moon run cmd/main -- --profile blender --json
moon run cmd/main -- --profile strict-ci --csv
moon run cmd/main -- --profiles
moon run cmd/main -- --bounds --json
moon run cmd/main -- --resample 12
moon run cmd/main -- --batch --profile strict-ci --json
moon run cmd/main -- --junit
moon run cmd/main -- --help
```

Supported profiles are `unity`, `blender`, `strict-ci`, and `preview`.

## API Summary

| Area | Public API |
| --- | --- |
| Parse | `tokenize_bvh`, `parse_bvh`, `parse_bvh_or_empty` |
| Model | `BvhDocument`, `BvhJoint`, `BvhMotion`, `BvhChannel`, `BvhVec3` |
| Query | `joint_names`, `joint_paths`, `find_joint`, `find_joint_by_path`, `channels_in_motion_order` |
| Frames | `frame_values_for_joint`, `frame_values_for_joint_name`, `root_position_at`, `joint_rotation_at` |
| Analysis | `analyze_bvh`, `channel_ranges`, `widest_channel_range`, `detect_static_channels`, `sample_root_motion` |
| Skeleton | `skeleton_bones`, `summarize_skeleton`, `compare_skeletons`, `build_name_based_retarget_map` |
| Motion Tools | `slice_document`, `resample_document_nearest`, `frame_at_time`, `root_motion_bounds`, `root_speed_samples`, `detect_root_teleports`, `normalize_root_origin` |
| Validation | `validate_bvh`, `validate_document`, `validation_summary` |
| Quality | `quality_report`, `quality_report_from_bvh`, `quality_report_to_text`, `quality_report_to_json`, `quality_report_to_csv`, `quality_report_to_junit_xml`, `quality_action_for_bvh` |
| Import Profiles | `unity_import_profile`, `blender_import_profile`, `strict_ci_import_profile`, `evaluate_import_profile`, `evaluate_bvh_batch`, `import_decision_to_json` |
| Export | `document_to_json`, `joint_table_csv`, `channel_range_csv`, `root_motion_csv` |
| Integration | `build_unity_clip_plan`, `build_blender_import_plan`, `bvh_runtime_manifest` |
| Report | `build_report`, `format_report`, `bvh_fixture_report` |

## Project Positioning

MoonBVHKit fills a MoonBit ecosystem gap for motion-capture asset inspection. It is useful for game developers, tool authors, and CI pipelines that need to inspect BVH clips before importing them into Unity, Blender, Godot, or custom runtimes.

The project deliberately does not bind to Unity or Blender. Instead, it provides portable validation and metadata that those workflows can consume.

No functionally equivalent MoonBit BVH or motion-capture asset-gate package was found in the Mooncakes ecosystem during the final project review on 2026-08-18.

## Documentation

- [Chinese README](README_zh_CN.md)
- [Public API](docs/API.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Integration guide](docs/INTEGRATION.md)
- [Testing and acceptance evidence](docs/TESTING.md)
- [Source and license provenance](docs/PROVENANCE.md)
- [Publishing guide](docs/PUBLISHING.md)
- [Final acceptance report](submission/ACCEPTANCE_REPORT.md)

## Originality and References

This is an original MoonBit implementation. It references the public BVH text format structure commonly used by motion-capture tools, but does not copy code from another project.

All fixtures in this repository are handwritten synthetic data and do not contain third-party motion-capture assets.

See [Source and Provenance](docs/PROVENANCE.md) for dependency, generated-file, fixture, and AI-assistance disclosure. The project is maintained by 张博文 through the GitHub account `zhangbowen2006`; author information is recorded in [AUTHORS.md](AUTHORS.md).

Personal contact details are intentionally not stored in this public repository;
the official hackathon registration form is the source of truth for contact
information.

## License

MIT.
