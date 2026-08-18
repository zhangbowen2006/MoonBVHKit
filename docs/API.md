# MoonBVHKit API

MoonBVHKit exposes small, reusable APIs for parsing, validating, analyzing, and exporting ASCII BVH motion-capture data.

## Parsing

`tokenize_bvh(input)` splits BVH source into tokens with line and column metadata.

`parse_bvh(input)` returns `BvhParseResult`.

- `ok`: whether parsing succeeded.
- `document`: parsed `BvhDocument` when `ok` is true.
- `error`: structured `BvhError` when `ok` is false.

`parse_bvh_or_empty(input)` is a convenience helper for smoke examples. It returns an empty document on parse failure.

## Core Model

`BvhDocument` contains:

- `root`: the root `BvhJoint`.
- `motion`: `BvhMotion` with frame count, frame time, channel count, and frame data.
- `source_length`: original input length.
- `token_count`: number of parsed tokens.

`BvhJoint` contains name, path, kind, offset, channels, channel start/count, depth, child joints, and end sites.

`BvhChannel` supports standard BVH position and rotation channels:

- `Xposition`, `Yposition`, `Zposition`
- `Xrotation`, `Yrotation`, `Zrotation`
- unknown channel names are preserved as `ChannelUnknown(name)`.

## Query Helpers

- `joint_names(document)`
- `joint_paths(document)`
- `find_joint(document, name)`
- `find_joint_by_path(document, path)`
- `channels_in_motion_order(document)`
- `channel_index_for_path(document, path, channel)`

Frame helpers:

- `frame_values_for_joint(document, joint, frame_index)`
- `frame_values_for_joint_name(document, name, frame_index)`
- `root_position_at(document, frame_index)`
- `joint_rotation_at(document, joint, frame_index)`

## Analysis

`analyze_bvh(document)` returns `BvhStats`:

- joint count
- end-site count
- max skeleton depth
- channel count
- frame count
- frame time
- duration
- root-motion distance

Additional helpers:

- `root_motion_delta(document)`
- `root_motion_distance(document)`
- `channel_ranges(document)`
- `widest_channel_range(document)`
- `detect_static_channels(document, epsilon=0.00001)`
- `sample_root_motion(document, max_samples=8)`

## Skeleton Utilities

`skeleton_bones(document)` returns depth-first bone metadata with parent path, offset length, channel count, and end-site flags.

`summarize_skeleton(document)` returns `BvhSkeletonSummary` with root name, bone count, leaf count, end-site count, max depth, total offset length, and a stable signature.

`compare_skeletons(reference, candidate, offset_epsilon=0.001)` returns `BvhSkeletonDiff` with matched, missing, extra, channel mismatch, and offset warning paths.

`build_name_based_retarget_map(source, target)` builds a simple compatibility map for same-named bones. It does not retarget animation; it gives a safe planning surface for downstream tools.

Export helpers:

- `skeleton_summary_to_json(summary)`
- `skeleton_diff_to_json(diff)`
- `skeleton_bones_csv(document)`
- `retarget_map_to_csv(entries)`

## Motion Tools

Frame helpers:

- `clamp_frame_index(document, frame_index)`
- `frame_at(document, frame_index)`
- `nearest_frame_index_at_time(document, seconds)`
- `frame_at_time(document, seconds)`
- `frame_window(document, start_frame, end_frame)`
- `slice_motion(motion, start_frame, end_frame)`
- `slice_document(document, start_frame, end_frame)`
- `resample_motion_nearest(motion, target_frame_count)`
- `resample_document_nearest(document, target_frame_count)`
- `first_frame(document)`
- `last_frame(document)`

Root-motion helpers:

- `root_motion_bounds(document)`
- `root_motion_bounds_to_json(bounds)`
- `root_motion_bounds_to_csv(bounds)`
- `loop_closure_error(document)`
- `root_speed_samples(document)`
- `average_root_speed(document)`
- `max_root_speed(document)`
- `detect_root_teleports(document, threshold)`
- `normalize_root_origin(document)`

Channel helpers:

- `motion_channel_means(document)`
- `speed_samples_to_csv(samples)`

## Validation

`validate_bvh(input)` parses and validates in one step.

`validate_document(document)` validates an already parsed document.

Validation checks include:

- missing or malformed root hierarchy
- unknown channels
- non-root position channels
- channel offset gaps
- mismatched declared and parsed frame counts
- frame width mismatches
- invalid frame time
- static root motion informational notice

## Quality Reports

`quality_report(document)` converts validation issues and motion heuristics into an importer-oriented score from 0 to 100.

`quality_report_from_bvh(input)` parses, validates, and scores a BVH string in one call.

Quality reports include:

- `grade`: `excellent`, `usable`, `needs-review`, or `blocked`
- `score`: clamped numeric quality score
- `signals`: validation and motion quality signals with score deltas
- `recommended_action`: automation-friendly action such as `accept`, `accept-with-notes`, `inspect-before-import`, or `fix-before-import`

Helpers:

- `quality_report_to_text(report)`
- `quality_report_to_json(report)`
- `quality_report_to_csv(report)`
- `quality_report_to_junit_xml(report, suite_name="moonbvhkit-quality")`
- `quality_action_for_bvh(input)`

## Import Profiles

Import profiles turn validation and quality data into reusable asset-gate decisions.

Built-in profiles:

- `unity_import_profile()`
- `blender_import_profile()`
- `strict_ci_import_profile()`
- `preview_import_profile()`
- `default_import_profiles()`
- `import_profile_by_name(name)`

Evaluation:

- `document_frame_rate(document)`
- `import_profile_issues(document, profile)`
- `evaluate_import_profile(document, profile)`
- `evaluate_bvh_import_profile(input, profile)`
- `evaluate_default_import_profiles(document)`

Export helpers:

- `import_profile_to_json(profile)`
- `import_decision_to_json(decision)`
- `import_decision_to_text(decision)`
- `import_decisions_to_csv(decisions)`
- `import_profiles_to_csv(profiles)`

## Export and Reports

JSON:

- `document_to_json(document)`
- `unity_clip_plan_to_json(plan)`
- `blender_import_plan_to_json(plan)`
- `validation_to_json(report)`
- `quality_report_to_json(report)`
- `import_profile_to_json(profile)`
- `import_decision_to_json(decision)`
- `manifest_to_json(manifest)`

CSV:

- `joint_table_csv(document)`
- `channel_range_csv(document)`
- `root_motion_csv(document)`
- `skeleton_bones_csv(document)`
- `retarget_map_to_csv(entries)`
- `speed_samples_to_csv(samples)`
- `quality_report_to_csv(report)`
- `import_decisions_to_csv(decisions)`
- `import_profiles_to_csv(profiles)`

Reports:

- `build_report(input)`
- `format_report(report, format=ReportText)`
- `bvh_fixture_report(format=ReportText)`

## Error Model

`BvhError` contains:

- `kind`
- `line`
- `column`
- `token`
- `message`

Use `error.code()` for stable machine-readable classification.
