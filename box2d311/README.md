Box2D v3.1.1
==============

The 63 upstream C/header files are vendored from https://github.com/erincatto/box2d/tree/v3.1.1. They are unmodified. SHA-256 hashes are recorded in UPSTREAM-SHA256.json. MIT license: LICENSE.

Local files: vendor_src/buggy_core.c, include/buggy_core.h, src/bridge.cpp and ext.manifest. The custom world is stepped at 60 Hz with four substeps. Built-in Defold physics and bindings are excluded in main/box2d3.appmanifest; physics_null provides the engine stubs. This avoids accidentally linking Defold's different embedded Box2D build.

SIMD is disabled for portable compilation across HTML5 and mobile architectures. This scene has only three dynamic bodies and two wheel joints.

The unmodified upstream C sources are stored in vendor_src/. The web static library is compiled locally with Emscripten 4.0.6 (the same version as the Defold 1.14.0 extension toolchain) using tools/build_box2d.sh, and linked by the standard native extension. Defold's remote build compiles the C++ Lua bridge and links the engine. This avoids forcing its generated C++ engine entry point to use C language mode. The compiled library is included for normal editor/HTML5 builds.
