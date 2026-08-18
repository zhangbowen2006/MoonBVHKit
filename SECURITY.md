# Security Policy

## Supported Version

The published `0.1.x` line receives correctness and security fixes.

## Reporting

Report parser crashes, unbounded resource use, malformed-output issues, or other
security concerns through the repository issue tracker. Do not include private
motion files, credentials, access tokens, or personal data in a public issue.

## Input Trust Model

BVH text should be treated as untrusted input. MoonBVHKit validates hierarchy,
channels, frame declarations, frame widths, and timing, but a host application
remains responsible for limiting input size and deciding whether validation or
quality findings should block an asset.

The library does not execute content from BVH files, access the network, load
native libraries, or invoke Unity or Blender. JSON and CSV reports contain
metadata derived from the supplied document; callers should still escape or
isolate reports when embedding them into another output format.
