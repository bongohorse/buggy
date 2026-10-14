# Buggy Ridge repository instructions

## Source of truth

- Work exclusively from `bongohorse/buggy` for this game. Do not push future changes to the former Sites source repository.
- Preserve the current 2D game and its established art unless the user requests a redesign.
- Engine: Defold 1.14.0; physics: vendored Box2D 3.1.1 native extension. Do not replace the game with a JavaScript or different-engine implementation.
- Keep the UI in English and support portrait/landscape touch input.

## Validation and deployment

- For physics/gameplay changes run `bash tools/test_physics.sh` and the applicable bridge/geometry/camera checks. For resource changes run `python3 tools/check_source.py`.
- If Box2D vendor C sources change, rebuild the web static library with Emscripten 4.0.6 and run the WASM suite. Do not leave a stale prebuilt library.
- Real HTML5 builds use `bash tools/build.sh wasm-web` and Java 25. Build output, caches and credentials must stay out of Git.
- `main` builds deploy via `.github/workflows/html5.yml` to GitHub Pages; PRs only validate/build. Inspect CI/deployment results and report material limitations honestly.
- Do not claim native/headless tests constitute a visual browser, sound or physical-device acceptance test.
- Finish the requested phase and report briefly; do not start unrelated feature packages.
