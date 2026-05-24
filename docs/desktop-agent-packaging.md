# Desktop Agent Packaging

This App Store submission ships an iOS app plus a Mac companion agent. App Review needs a downloadable Mac agent because the iOS app cannot demonstrate its core mouse and keyboard controls without a user-owned Mac on the same local network.

## Build Release Artifacts

From the repository root:

```bash
scripts/package_macos_agent.sh
```

Prerequisites:

- macOS packaging requires Xcode command line tools and Swift.
The scripts write release files under `dist/`:

- `dist/AeroPointAgent-macos-0.1.zip`

Use `AEROPOINT_VERSION` to change artifact names:

```bash
AEROPOINT_VERSION=0.1 scripts/package_macos_agent.sh
```

## macOS Signing and Notarization

Unsigned macOS apps may be blocked by Gatekeeper. For App Review and public users, sign and notarize the Mac agent.

Set these environment variables before running the macOS packaging script:

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
scripts/package_macos_agent.sh
```

The script signs the `.app`, submits it to Apple notarization, staples the notarization ticket, and creates a zip file.

If you only set `DEVELOPER_ID_APPLICATION`, the script signs but does not notarize.

## GitHub URLs

GitHub can host the placeholder URLs.

Recommended setup:

1. Create a GitHub Release, for example `v0.1`.
2. Upload the generated Mac zip file as a release asset.
3. Use release asset URLs in App Review notes:

```text
https://github.com/dannywandesign/AeroPoint/releases/download/v0.1/AeroPointAgent-macos-0.1.zip
```

For the Privacy Policy and Support URL, GitHub Pages is better than raw repository links.

Suggested URLs after enabling Pages for the `docs/` folder:

```text
https://dannywandesign.github.io/AeroPoint/privacy/
https://dannywandesign.github.io/AeroPoint/support/
```

Raw GitHub file URLs can work because they are public, but GitHub Pages looks cleaner and is less likely to confuse reviewers.
