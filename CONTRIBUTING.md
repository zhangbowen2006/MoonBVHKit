# Contributing

MoonBVHKit keeps v1 intentionally small and portable.

## Development

```bash
moon check
moon build
moon test
moon run cmd/main
moon run cmd/main -- --quality --json
moon run cmd/main -- --profiles --csv
moon run examples/basic
```

Run `moon fmt` before sending changes.

## Scope Rules

- Keep core BVH parsing and validation in MoonBit.
- Add fixtures as small handwritten samples.
- Do not commit `_build`, `.mooncakes`, `target`, generated logs, or editor caches.
- Do not add Unity, Blender, or Python runtime requirements to the core package.

## Tests

Add tests for both successful parsing and error paths. New format support should include at least one fixture, one parser test, one validation test, and one export/report test.
