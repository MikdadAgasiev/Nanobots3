# Release command

From the project folder on Windows:

```powershell
.\release.ps1                 # check, package, PR/review/merge, portal, install
.\release.ps1 check -Native   # bounded checks only; no publication
.\release.ps1 status          # compact saved receipt
```

Python, `requests`, and `lupa` (Lua 5.2) are required. Release credentials are entered with `python tools/setup_access.py` and encrypted with Windows user-bound DPAPI under `%LOCALAPPDATA%/FactorioRelease/secrets`. They are never stored in the repository or ZIP. Use a fine-grained GitHub token restricted to blueprint-from-helmod and Nanobots3 (Contents and Pull requests: write; Actions: read; Workflows: write when changing CI), and a Factorio API key with **Upload Mods** and **Edit Mods**. Never paste keys into issues or chat.

Local configuration is `%LOCALAPPDATA%/FactorioRelease/projects/<mod>/config.json`: `engine` is the Factorio executable, `fixture` is an isolated fixture directory containing `mods/` and `source-save.zip`, `output` is the release directory, `mods` is the installation directory, and `faq` is an optional local English FAQ file. Private saves and internal rules stay outside the repository.

Successful quick checks are reused only for matching fingerprints. Game checks also include the engine, fixture and mod environment. Source changes invalidate the appropriate cache. Receipts and logs survive failures; rerunning reconciles GitHub and the portal before repeating mutations. The same published version can never be silently replaced with different ZIP bytes.

Publication creates an exact-snapshot branch, waits for Graphify's explicit PASS on that exact commit and completed GitHub checks, then merges without force pushes. It verifies the published portal checksum and attaches the exact ZIP to a GitHub release (prerelease for Blueprint from Helmod). The script uses GitHub's APIs directly, so a separate GitHub CLI installation is unnecessary. Local Git history is not rewritten. A second simultaneous invocation is refused; changes to the snapshot during a run stop publication.

The default time budget is 15 minutes, including waits. A timeout is a stopped run, never a pass. Full performance matrices are never started implicitly. `.\release.ps1 full -Budget 10800` only runs an explicitly configured local `full_command`; ordinary publication does not repeat an hours-long matrix. Quick startup checks are not a claim of arbitrary-plan throughput or smooth multiplayer behavior. Add focused regressions for changed algorithms. An optional local `targeted_commands` array runs focused regression commands as part of quick checks; changed test scripts invalidate their cache.

The public package is built from `tools/package-files.json`, not a recursive ZIP of the working directory. New production Lua modules require an explicit allowlist update. Developer tools, credentials, local rules and private test fixtures are excluded.
