# Buggy Ridge

A mobile 2D alpine buggy game for **Defold 1.14.0** using **Box2D 3.1.1**.

Canonical source: **https://github.com/bongohorse/buggy**. All future development, reviews and releases use this repository.

Browser game: **https://bongohorse.github.io/buggy/** (after the Pages deployment succeeds).

## Play

Hold **GAS** to accelerate, **BRAKE** to slow down; keep holding at rest to reverse. In the air, gas pitches the nose up and brake pitches it down. Reach the flag at 600 world metres (597 metres from the starting position). Land jumps for points. Retry immediately after a crash. Keyboard: D/right, A/left, R and space.

The optional **PRACTICE** mode uses six checkpoints; practice runs do not earn records. **SOUND ON/OFF** persists on this device. Normal runs earn a local personal best and Gold (65s), Silver (90s) or Bronze medals. There are three optional trail tokens. See `docs/GAMEPLAY.md` for the course and controls.

The UI adapts to portrait and landscape. The game pauses on focus loss; resume explicitly. Long-press menus and page scrolling are suppressed on the game surface.

## Live tuning

Open **TUNE +** in the top bar. Adjust while driving; no restart is required. The panel folds away and uses a compact row on wide screens or five rows in portrait. **DEFAULTS** restores all five values. Settings are stored on this device.

| Setting | Default | Range | Effect |
| --- | --- | --- | --- |
| Power | 125% | 60–180% | Wheel motor torque / acceleration |
| Spring | 4.2 Hz | 2–7 Hz | Suspension stiffness |
| Damping | 0.65 | 0.30–1.10 | Suspension bounce damping |
| Air control | 110% | 40–180% | Airborne pitch-control torque |
| Zoom | 120% | 80–160% | Camera closeness |

The camera follows the road with slower vertical motion, keeps the buggy in frame at maximum portrait zoom, and adds look-ahead plus slight widening at speed.

## Build

Open `game.project` with Defold **1.14.0**, then Project → Bundle → HTML5 Application. The first build requires network access to Defold's native extension build server. A stock dev app does not contain this native extension.

Command line (Linux/macOS, Java **25**, Python 3, curl):

```sh
bash tools/build.sh wasm-web
python3 -m http.server 8080 --directory dist
```

Open `http://localhost:8080`. Serve the whole bundle through HTTP(S); do not double-click index.html. `BUGGY_JAVA_BIN` can select a Java 25 executable. Bob is pinned by SHA-256 in `tools/defold-version.env`. Supported script targets: wasm-web and x86_64-linux (with GCC).

The `Defold HTML5` GitHub Actions workflow checks the physics, Lua bridge, resources, track geometry and camera, builds the real Defold HTML5 bundle, uploads a downloadable artifact, and deploys successful `main` builds to GitHub Pages. Pull requests validate and build without deploying. Pages must use **GitHub Actions** as its source.

The web static Box2D library is included so ordinary CI does not need to download an Emscripten SDK. When modifying the vendored Box2D C sources, rebuild it with Emscripten 4.0.6 and run `tools/test_web_physics.sh` before committing. The C++ game/binding code is compiled by the official Defold extension service on each changed build. See `docs/MIGRATION.md` for imported provenance.

## Physics and architecture

- Upstream Box2D **v3.1.1** is vendored, MIT licensed, with hashes in `box2d311/UPSTREAM-SHA256.json`.
- Defold's built-in physics libraries are excluded. `physics_null` supplies engine stubs; our native extension owns one Box2D world.
- The supplied prebuilt web static library is generated from the included C source with Emscripten **4.0.6**. To rebuild it: `BUGGY_EMSDK_DIR=/path/to/emsdk bash tools/build_box2d.sh wasm-web`. Native Linux builds rebuild that library with GCC. An Android native library is not supplied; browser play on Android uses the WASM library.
- Three dynamic bodies: chassis and two wheels. Two motorized wheel joints, live-adjustable springs (4.2 Hz default), 0.65 damping ratio by default, ±0.22 m suspension limits.
- Fixed 60 Hz simulation with four Box2D substeps, single thread, no worker/SAB requirement.
- Smooth cubic hills sampled every 0.1m share their profile between collision and three terrain meshes. Terrain chains leave real openings for the dynamic wooden bridge and two ravine jumps; a one-sided raised trail forms the Skyline shortcut.
- Bounded airborne torque, real contact-based grounding, roof-contact crash detection.
- Lua implements camera, score, game states, touch input and rendering. the C++ bridge in `box2d311/src/bridge.cpp` exposes the small physics API.
- Fifteen dynamic bodies including twelve jointed bridge planks, pooled dust, separate world/parallax atlases, no per-frame world creation, standard-DPI rendering to limit mobile GPU load.

Painted wheel, tree, grass, rock, timber and dashboard assets match the orange chassis. Three parallax layers, dense mature trees and foreground plants frame eleven themed trail sections. Small utility sprites are procedural. The earlier concept sheet is a visual direction, not a screenshot of this build. Generator script and generated assets are included. DejaVu font license is included.

## Verification

```sh
bash tools/test_physics.sh
python3 tools/check_source.py
```

The physics suite compiles the actual vendored C engine and tests acceleration, braking, air controls, landing/suspension limits, track completion, 100 resets, and zero Box2D allocations after destruction. Results are in `docs/physics-results.json`. Linux host timings are not mobile performance measurements. The source check validates resource references, terrain buffers, upstream hashes and Lua syntax when liblua5.4 is available; Defold's own Lua build remains authoritative.

The WASM physics suite also runs the compiled web library in Node. A Defold headless smoke loads the actual game scene, updates the UI/art and drives using the normal game loop (`tools/test_runtime.sh`). Browser visual and real-device touch checks remain open.

See `docs/VALIDATION.md` for the exact build and runtime verification status.
