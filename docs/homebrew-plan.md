# Homebrew Distribution Plan

## Summary

Distribute Pod Block as a Homebrew **Cask** (the correct mechanism for macOS `.app` bundles). Start with a **self-hosted tap** (`kokorro-labs/homebrew-pod-block`), then optionally submit to `homebrew/homebrew-cask` once the app gains traction.

## Why a Cask (not a Formula)

- Formulae are for CLI tools built from source
- Casks are for macOS GUI apps (`.app` bundles) distributed as `.dmg` or `.zip`
- Pod Block is becoming a `.app` — Cask is the right fit

## Why a self-hosted tap first

Homebrew's official `homebrew-cask` repo has a **notability threshold** — new/small projects get auto-rejected. A self-hosted tap:
- Has zero gatekeeping — ship whenever you want
- Users install via `brew tap kokorro-labs/pod-block && brew install --cask pod-block`
- Can be promoted to official `homebrew-cask` later when the project is more established

---

## Phase 1: App prerequisites (before any Homebrew work)

- [ ] Build a `.app` bundle (Xcode project or Swift Package Manager + bundler)
- [ ] Code-sign the app with an Apple Developer ID
- [ ] Notarize the app with Apple (required — Homebrew casks that trigger Gatekeeper warnings get rejected)
- [ ] Package as `.dmg` or `.zip` containing the `.app`
- [ ] Create a GitHub Release on `kokorro-labs/pod-block` with the `.dmg`/`.zip` as a release asset
- [ ] Use a stable versioned download URL, e.g.:
  `https://github.com/kokorro-labs/pod-block/releases/download/v1.0.0/PodBlock-1.0.0.dmg`

## Phase 2: Create the Homebrew tap

1. Create a new GitHub repo: `kokorro-labs/homebrew-pod-block`
2. Scaffold it with `brew tap-new kokorro-labs/pod-block` (or manually create the structure)
3. Directory structure:
   ```
   homebrew-pod-block/
     Casks/
       pod-block.rb        # the cask definition
     .github/
       workflows/           # optional: CI to auto-audit the cask
   ```
4. Write the cask file (see `homebrew/cask-template.rb` in this repo)
5. Push to GitHub

## Phase 3: Fill in the cask and test

1. After creating a GitHub Release with the `.dmg`/`.zip`:
   ```bash
   # Get the SHA256 of your release artifact
   shasum -a 256 PodBlock-1.0.0.dmg
   ```
2. Update `pod-block.rb` with the real version, SHA256, and download URL
3. Test locally:
   ```bash
   brew tap kokorro-labs/pod-block
   brew install --cask pod-block
   # Verify the app appears in /Applications
   # Verify it launches and works
   brew uninstall --cask pod-block
   ```
4. Run the audit:
   ```bash
   brew audit --cask pod-block
   brew style --fix Casks/pod-block.rb
   ```

## Phase 4: Ship it

1. Push the final cask to `kokorro-labs/homebrew-pod-block`
2. Update Pod Block's README with install instructions:
   ```bash
   brew tap kokorro-labs/pod-block
   brew install --cask pod-block
   ```
3. The bottles/binary workflow from `brew tap-new` will auto-build if you keep the default GitHub Actions

## Phase 5 (optional): Submit to official homebrew-cask

Once the app has meaningful usage (GitHub stars, downloads, mentions), submit a PR to `Homebrew/homebrew-cask`:
1. Fork `Homebrew/homebrew-cask`
2. Add `Casks/p/pod-block.rb`
3. Run `brew audit --cask --new pod-block` and `brew style Casks/p/pod-block.rb`
4. Open a PR — it will be auto-audited by Homebrew's CI
5. Users can then install with just `brew install --cask pod-block` (no tap needed)

---

## Key requirements checklist

| Requirement | Status | Notes |
|---|---|---|
| macOS `.app` bundle | Pending | Currently a CLI daemon |
| Apple Developer ID signing | Pending | Required for Gatekeeper |
| Apple Notarization | Pending | Required — unsigned casks are rejected |
| Stable download URL (GitHub Release) | Pending | Use release assets |
| SHA256 hash of artifact | Pending | `shasum -a 256` |
| Cask template | Done | See `homebrew/cask-template.rb` |
| Self-hosted tap repo | Pending | `kokorro-labs/homebrew-pod-block` |
