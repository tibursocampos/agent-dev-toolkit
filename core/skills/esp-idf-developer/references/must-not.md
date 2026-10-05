# esp-idf-developer — must not

- Infer ESP-IDF, Arduino Core, MicroPython, or CPython from an ESP32 board or family name alone.
- Turn a preview project's ESP-IDF version, target, configuration, or toolchain into a global default.
- Replace project CMake/`idf.py`, Component Manager resolution, lockfiles, `sdkconfig.defaults`, or local configuration without explicit review.
- Prescribe PowerShell paths or ESP-IDF-managed Python commands without observing the applicable host installation.
- Treat CMake Tools or VS Code as required, or as a replacement for `idf.py` and the project's CMake configuration.
- Claim flashing, boot, device runtime, HIL, heap, PSRAM, buffers, timing, or recovery from source inspection or compile-only evidence.
- Recommend security or irreversible provisioning behavior without target, version, configuration, and recovery context.
- Put credentials, tokens, private keys, signing material, or device secrets in versioned material, examples, logs, or evidence.
- Auto-commit, auto-push, or claim hardware validation that was not exercised.
