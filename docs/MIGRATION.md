# Repository migration — 2026-10-15

Canonical repository: https://github.com/bongohorse/buggy

Imported from the exact source of Buggy Ridge published version 4: original commit `c0f9bfb00cfb3cc2d30b515cf24a04168e70801a`. The source includes the 597m Alpine Challenge, reverse gear, four physical surface materials, original audio, practice checkpoints, local best time, medals and three trail tokens.

All game source, painted/procedural assets, vendored Box2D sources and licenses, static libraries, generators, tests and validation reports were copied. Only the former hosting-specific `.openai/hosting.json` was excluded. No cache, credentials, private access policy, local toolchain or old Git metadata was transferred. This repository starts its own Git history and retains the original source commit here for provenance.

The workflow now adds Lua bridge, geometry and camera regression checks before compiling the real Defold HTML5 bundle. GitHub Pages is the intended deployment target. Earlier validation reports describe earlier source checks; GitHub Actions results establish this repository's build/deployment status.

Future changes must be made in this repository. The existing ChatGPT Sites deployment is a historical published copy and is no longer the source of truth.
