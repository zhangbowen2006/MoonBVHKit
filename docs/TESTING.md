# Testing and Acceptance Evidence

MoonBVHKit uses unit, white-box, error-path, and end-to-end acceptance tests.
All fixtures are deterministic, handwritten BVH strings, so the suite does not
depend on external files, network access, Unity, or Blender.

## Coverage Areas

- tokenization, hierarchy parsing, motion parsing, and structured errors
- joint, channel, frame, root-motion, and timing queries
- validation, statistics, quality scoring, and import gate decisions
- skeleton comparison, retarget planning, slicing, and normalization
- text, JSON, CSV, Unity-plan, and Blender-plan output
- valid asset approval and malformed asset rejection across the full pipeline

## Reproduce Locally

Run the complete Windows verification script from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1
```

When `moon` is not on `PATH`, provide its full executable path:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1 -MoonPath "C:\path\to\moon.exe"
```

The same checks can be run individually:

```bash
moon check --deny-warn
moon build
moon test --deny-warn
moon fmt --check
moon info
moon run cmd/main
moon run cmd/main -- --quality --json
moon run cmd/main -- --profiles --csv
moon run cmd/main -- --bounds --json
moon run cmd/main -- --resample 12
moon run cmd/main -- --batch --profile strict-ci --csv
moon run cmd/main -- --junit
moon run examples/basic
```

## CI Gate

`.github/workflows/ci.yml` installs MoonBit on Ubuntu and runs strict check and
test commands across all supported targets. It also checks formatting, verifies
that `moon info` does not change the committed public API snapshots, executes
the CLI output modes, and runs the basic example.

## Recorded Result

On 2026-08-18, the local acceptance run used MoonBit compiler 0.10.8 and
completed with 72 tests passed and 0 failed. Strict checking, build, formatting,
API snapshot generation, CLI text, JSON and CSV output, and the basic example
all completed successfully. GitHub Actions provides the independently
reproducible remote result for each pushed commit on the default branch.
