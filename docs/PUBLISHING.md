# Publishing Guide

This package is configured for:

- Mooncakes package: `zhangbowen2006/moonbvhkit`
- GitHub repository: `https://github.com/zhangbowen2006/MoonBVHKit.git`

Release `0.2.0` has been published successfully. The commands below document
the repeatable process for maintenance releases.

## Before Publishing

Confirm the GitHub repository exists and is public.

If the package name changes later, update `moon.mod`, `cmd/main/moon.pkg`, `examples/basic/moon.pkg`, `conformance.mbt`, `moonbvhkit_wbtest.mbt`, and README install instructions, then run `moon info`.

The local Git remote should be:

```bash
git remote add origin https://github.com/zhangbowen2006/MoonBVHKit.git
```

Push the first public commit:

```bash
git branch -M main
git push -u origin main
```

## Final Local Verification

```bash
moon fmt
moon info
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

## Publish

After logging in to Mooncakes:

```bash
moon publish --dry-run
moon publish
```

Do not publish until the GitHub repository URL is reachable publicly.
