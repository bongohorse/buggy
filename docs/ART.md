# Alpine painted art refresh

Production assets generated with the built-in ImageGen tool, using the existing orange chassis as style reference for wheels, mature pine/birch trees, meadow grass and granite rocks. The brief requested warm illustrated game art, detailed textures, orange sunlight, side view and transparent silhouettes. Separate panoramic forest and wooded hills form the middle and near parallax layers; the existing alpine sky is the far layer. Metal dashboard panels and rubber pedals use the same orange and gunmetal palette. Timber planks are weathered hand-painted oak.

Final assets: `assets/*-painted.png`, `assets/parallax-hills.png`, `assets/parallax-forest.png`. PNG normalization only crops transparent canvas and downsamples; gameplay geometry remains code-driven. `tools/generate_assets.py` rebuilds atlases/metadata and the smooth profile without replacing artwork.

Terrain uses monotone cubic Hermite control curves, sampled every 0.1m. The same points feed three painted meshes and native Box2D collision. Six themed sections add meadow, granite and creek variety. The bridge gap is excluded from static meshes/collision and contains twelve dynamic planks connected by thirteen spring-damped revolute joints. Renderer plank poses come directly from Box2D.

Three independently scrolling panorama layers: 0.055, 0.20, 0.46. Dense world trees and grass use full world motion; nearby plants and stones add a 1.10 foreground layer. Trees are 300-520 world pixels tall versus a 112px buggy body. Static meshes replace thousands of individual road sprites.

## Delivery status

Source implemented; local native/WASM physics, geometry and actual Defold engine/GUI integration checks pass. Three independent panorama atlases keep all textures within 1024px. The HTML5 release bundle compiled successfully. See `docs/VALIDATION.md`.
