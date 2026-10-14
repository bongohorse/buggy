# Gameplay update — 2026-10-14

Current update: 597m Alpine Challenge, reverse gear, four physics surfaces, sound, landing feedback, optional practice checkpoints, three tokens and local best-time medals. Full details: `GAMEPLAY.md`.

## Passed for the gameplay source

- Actual native Box2D 3.1.1: controlled complete course in 54.38s, 29 landings, zero roof-contact frames; the upper trail is actually ridden (130 simulation frames), and the lower valley is checked independently.
- Holding gas alone crashes at about 495.8m. This is a deterministic simulation check, not a claim that every driver or tuning configuration has identical difficulty.
- Braking before reverse engagement, sustained reverse (~4.28m/s), return to forward, both airborne torque directions, suspension/drop bounds and bridge load/reset.
- Dirt/grass/stone/wood coasting retention after two seconds: .912/.653/.785/.870. Material differences affect real physics.
- 100 reset cycles, zero Box2D bytes remaining after destruction, live tuning without pose reset, all tuning extremes and invalid-value handling.
- Emscripten 4.0.6 WASM executed in Node: complete new course in 3263 steps, reverse/forward, surfaces, gaps, raised route, gas-only crash, resets and tuning.
- Production Lua/C++ binding via the Lua 5.4 test adapter: 6401 points, optional gap data, extra route, wheel surfaces, returned plank poses and eight world recreations. Separate progress assertions check medal boundaries, persistent best-time ordering and practice exclusion. The adapter is not a replacement for the actual Defold SDK test below.
- Actual Defold 1.14.0 native extension compilation/link and headless scene loading. GUI tests in 1280x720 and 390x844 validate sliders, simultaneous touch + gas, sound toggle, practice checkpoint activation, gas retry and full-run reset. No script/GUI/resource/game-system/game-object errors remain.
- Shared visible geometry: 6401 main samples every 0.1m; maximum visible adjacent turn 5.28 degrees; aligned terrain strips; no static road in bridge/ravine openings; raised route render/collision profiles match. Curves inside the empty ravines are not rendered or collided.
- Camera assertions: forward/portrait framing, reverse look-ahead, high-jump framing, zoom, suspension filtering and orientation.
- Official Defold HTML5 release compilation and bundling succeeded. The final cached build and both engine/GUI runs after toolbar text-size adjustment passed in the packaging workflow. Bundle sizes/hashes are recorded in `html5-bundle.json`.

The checkpoint test harness now advances on actual fixed simulation ticks, rather than arbitrary render frame counts. Initial render-count timing caused a premature checkpoint assertion; this was a test timing error, corrected before passing both engine runs.

## Scope and verification limits

The user accepted the preceding mobile/visual state and explicitly requested that acceptance work be skipped. No new browser visual, real-device touch, listening or smartphone performance acceptance is claimed. Defold headless uses a null graphics/sound adapter; it validates resource/API integration and control logic, not audible quality. The known DLIB socket-initialization result 19 is an environment warning; game checks and graceful exit pass. Native host timing is not a phone benchmark.

Native extension upload to https://build.defold.com and publication were explicitly authorized earlier in this conversation. The update uses Defold/Box2D; no substitute JS game was introduced.

## Reproduce

```sh
bash tools/test_physics.sh
bash tools/test_lua_bridge.sh
python3 tools/check_source.py
python3 tools/check_track_geometry.py
python3 tools/test_camera.py
BUGGY_EMSDK_DIR=/path/to/emsdk bash tools/test_web_physics.sh
BUGGY_JAVA_BIN=/path/to/java25 bash tools/test_runtime.sh
BUGGY_JAVA_BIN=/path/to/java25 bash tools/build.sh wasm-web
```

---

## Historical art update checks

# Current art/terrain update — 2026-10-14

The current source contains the painted landscape, wheels and dashboard, smooth shared terrain and dynamic bridge. Defold engine/GUI integration now passes in landscape and portrait; The HTML5 release bundle compiled successfully and is ready for publication.

Passed for this source:

- Native Box2D: complete 237m course including the 12-plank bridge, 15 landings and no roof-contact frames in the automated run; 100 resets and zero allocated bytes after destruction.
- Bridge load check: 1.386m maximum deck sag under a stationary buggy; reset restores the initial deck pose.
- Emscripten 4.0.6 WASM executed in Node: same full course in 1257 steps, controls, resets and live tuning.
- Production C++ Lua binding with a test-only Lua 5.4 SDK adapter: 2,801 input points, 12 returned plank poses, eight world recreations and no-bridge fallback. This is not an actual Defold SDK/engine test.
- Shared geometry: 2,801 samples every 0.1m, maximum adjacent surface turn 5.28 degrees, all three terrain surfaces aligned, no static deck across the moving bridge gap.
- Resource references, Lua syntax, upstream hashes and existing camera framing tests pass.

- Official Defold native extension compilation/link succeeded after the user explicitly approved the upload to https://build.defold.com.
- Actual Defold headless engine loaded the new collection/art/UI in 1280x720 and 390x844. GUI assertions passed for mouse, captured drag, simultaneous touch + gas, defaults and pose preservation. The buggy drove 21 metres at 43.14km/h. No script, GUI, game-system, resource or game-object errors.
- An initial 2048x1024 panorama atlas exceeded the headless adapter's 1024 limit. Splitting the three panoramas into independent atlases fixes the error and keeps each texture at most 1024x1024.

- Defold HTML5 native compilation, engine link, resource/archive compilation and release bundling succeeded. Bundle hashes and size are recorded in `html5-bundle.json`.

Browser visual QA and real-phone acceptance remain unverified. The headless DLIB socket initialization warning (result 19) is an environment limitation, separate from game-script validation.

Reproduce local checks:

```sh
python3 tools/check_source.py
python3 tools/check_track_geometry.py
python3 tools/test_camera.py
bash tools/test_physics.sh
bash tools/test_lua_bridge.sh
BUGGY_EMSDK_DIR=/path/to/emsdk-4.0.6 bash tools/test_web_physics.sh
```

---

## Previous deployed build: historical checks

### Previous validation — 2026-10-14

## Passed

- Compiled the actual vendored Box2D **3.1.1** sources with GCC on Linux; runtime version asserted.
- Native suite: acceleration, braking, suspension/drop limits, both air-control directions, full track completion, 100 restarts and zero Box2D allocated bytes after destruction.
- Built the same sources with **Emscripten 4.0.6** as a WASM static library, matching Defold 1.14.0's extension toolchain.
- Executed that WASM library in Node: acceleration, braking, both air-control directions, full track completion in 1313 steps, 100 restarts and zero leaked Box2D bytes.
- Defold **1.14.0** (a81dbb0478e8b73931dc2d671563204f6ac0ef82), Java **25**: native extension compilation, engine link, resource/archive compilation and HTML5 bundling succeeded.
- Actual Defold headless engine smoke: loaded the game collection, initialized UI and art, ran the normal fixed/update loops, drove 18 metres, and exited normally. No script, game-object, GUI, resource or game-system errors remained. An initial Sprite capacity failure was corrected by explicitly setting sprite.max_count=256.
- Resource references, terrain stream lengths, Lua syntax and upstream hashes checked. HTML template placeholders resolved; local loader script references exist.
- The final standalone browser bundle is recorded in html5-bundle.json (file sizes and hashes).

## Verification limits

- Browser visual QA was unavailable: the prescribed control-browser capability is not installed. No browser was installed or an alternate preview route improvised.
- No real-phone touch, orientation, browser visibility/resume, visual layout or mobile performance acceptance is claimed. Native/WASM simulation tests and headless engine execution do not replace that acceptance.
- Native timing in physics-results.json is a Linux host measurement, not a smartphone or browser benchmark.
- The headless environment emits a DLIB socket initialization warning (result code 19); the smoke assertion and graceful exit succeed. This is separate from game-script correctness.
- GitHub Actions and Pages configuration are supplied as source; no GitHub workflow run is claimed.

## Reproduce

- Native physics: `bash tools/test_physics.sh`.
- WASM library rebuild: `BUGGY_EMSDK_DIR=/path/to/emsdk-4.0.6 bash tools/build_box2d.sh wasm-web`.
- WASM physics: `BUGGY_EMSDK_DIR=/path/to/emsdk-4.0.6 bash tools/test_web_physics.sh`.
- Source/resource checks: `python3 tools/check_source.py`.
- Full HTML5: `bash tools/build.sh wasm-web` with Java 25 and network access to Defold's official native build service.
- Actual engine smoke: `bash tools/test_runtime.sh` on Linux (GCC, Java 25, network access).

The native source upload to build.defold.com was explicitly approved by the user after an earlier automatic approval rejection. The delivered browser build uses Defold and Box2D; it is not a separate JavaScript game implementation.

## First tuning update

- Defaults: 125% motor power, 4.2 Hz spring, 0.65 damping, 110% air control and 120% zoom.
- The native and WASM tests validate live tuning without changing the body pose or destroying the vehicle, persistence across vehicle reset, and genuine response to the power and air sliders. Native tests also cover repeated extreme-setting changes and invalid-value bounds.
- Updated default setup completes the track in 1262 steps (21.03 seconds). Native flat-ground speed after 3 seconds is 14.877 m/s; the motor target/top speed is unchanged.
- Actual Defold GUI tests drive the production input handler: mouse click/drag, captured dragging beyond the rail, simultaneous touch on zoom and gas, release, defaults and folding the panel. Both wide and 390×844 portrait layouts are checked in the headless engine.
- Camera tests cover zoom response, maximum portrait zoom at speed, suspension-bounce filtering and immediate reframing after orientation change.
- A closer road-following camera and the five top-bar sliders are the scope of this update. Tracks, trick scoring, ghosts and new audio/art are separate future work.
- This is engine/logic verification; visual browser and real-device touch acceptance remain open.
