# Factorio regression checks

Requires Python 3 and a local Factorio 2.1 installation with the Quality expansion.

From the repository root:

```
python tests/regression/run.py . --factorio "C:/path/to/Factorio/bin/x64/factorio.exe"
```

To run only selected checks, append `--only ground held overflow reset reset-remote reset-cheat reset-full`.

The runner creates a temporary copy of the mod and a separate Factorio data directory. Test-only remote interfaces expose production helpers in that copy. Installed mods and saves are not modified. Logs are written under `tests/regression/results/`.

The checks cover item quality on the ground and in inserter hands; partial insertion leftovers; reserved-material refunds on reset, repeated reset, remote view, full inventory and cheat mode; construction cancellation; remote demolition; logistics interface signals; and repair targeting in dense factories without repair packs.

On 5.9.18, the ground, held, overflow, reset and reset-remote checks fail. These failures reproduce the problems addressed by 5.9.19. The cheat-mode check already passes and guards against introducing free-item duplication.
