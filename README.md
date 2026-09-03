# Task Bubble

Task Bubble is a tiny macOS whiteboard that stays above ordinary app windows and playfully glides away from the side your pointer approaches.

Flip the whiteboard into an apple to start a focused 30-minute session. The board remains intact while the timer runs.

## macOS v2

- Always-on-top, borderless floating panel
- Visible across desktop Spaces and alongside full-screen apps
- Directional pointer avoidance that can cross connected displays
- Hold `Option` to catch the bubble, then use its pin button when you want to interact
- Ordered whiteboard lines that remain in place when crossed out
- 30-minute apple focus timer with pause, resume, reset, progress, sound, and notification
- Timer deadlines persist through sleep and relaunch
- Menu-bar controls and no Dock icon
- Respects Reduce Motion

### Build and run

Task Bubble requires:

- macOS 14 or newer
- Xcode or Apple's free Xcode Command Line Tools
- An internet connection for the initial Git clone

It has no external Swift packages and does not require Homebrew, Node, npm, Chrome, or an Apple Developer membership when built locally from source.

```bash
git clone https://github.com/AdamLinCodes/task-bubble-extension.git
cd task-bubble-extension
swift test
./scripts/build-app.sh
open "dist/Task Bubble.app"
```

If `swift` is unavailable, install Apple's build tools first with `xcode-select --install`. The build script checks its requirements before starting and explains anything that is missing. The generated `dist/Task Bubble.app` is intentionally not committed to Git, so every source clone must run `build-app.sh` before trying to open it.

The build script creates a universal, ad-hoc signed local app for Apple silicon and Intel Macs. A Developer ID signature and notarization are needed before distributing it to other Macs without Gatekeeper warnings.

### Distribute to other Macs

M1, M2, M3, and M4 Macs all use the included `arm64` build. The app also includes an `x86_64` build for Intel Macs and supports macOS 14 or newer.

Do not send someone the output of `build-app.sh`: it is ad-hoc signed for local development, so Gatekeeper correctly rejects it after it is downloaded on another Mac. A shareable release must be signed with a **Developer ID Application** certificate and notarized by Apple.

One-time release setup:

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) and install a [Developer ID Application certificate](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) in Keychain Access.
2. Store notarization credentials in the macOS keychain:

   ```bash
   xcrun notarytool store-credentials "task-bubble-notary"
   ```

3. Build the signed, hardened, notarized, and stapled release:

   ```bash
   TASK_BUBBLE_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
   TASK_BUBBLE_NOTARY_PROFILE="task-bubble-notary" \
   ./scripts/package-release.sh
   ```

The release script produces a universal `.dmg`, a `.zip`, and SHA-256 checksums in `dist/`. It refuses to create a release from an ad-hoc signature, submits both the app and disk image to Apple's notary service, staples the returned tickets, and checks the finished artifacts with Gatekeeper.

Publish those files on GitHub Releases:

```bash
VERSION="$(plutil -extract CFBundleShortVersionString raw Packaging/Info.plist)"
gh release create "v$VERSION" \
  "dist/Task-Bubble-$VERSION-macOS-universal.dmg" \
  "dist/Task-Bubble-$VERSION-macOS-universal.zip" \
  "dist/Task-Bubble-$VERSION-SHA256SUMS.txt" \
  --generate-notes
```

Recipients should download the `.dmg` from the repository's **Releases** page, open it, and drag Task Bubble into Applications. They do not need Xcode, Homebrew, source code, or a package manager.

### Interaction

- Approach the unpinned whiteboard or apple and it moves away from the contact side.
- Keep nudging at a display edge to float the bubble to the center of an adjacent screen.
- Hold `Option` while approaching it to suppress the dodge.
- While holding `Option`, click the pin button to leave it in place for editing or timer controls.
- Use the pin button or menu-bar item to let it roam again.
- Pinning persists when you flip between the whiteboard and focus timer.
- Click the `x` button on either side to quit Task Bubble completely.
- Click the timer button on the whiteboard to flip into the apple and start 30 minutes.
- Crossed-out lines stay on the board and can be restored by clicking the checkmark.
- Right-click a line to delete it permanently.
- Use the trash button to clear the whole whiteboard after confirming the permanent deletion.

## Chrome extension v0.2

The original Chrome extension remains in the repository as `manifest.json`, `background.js`, `content.js`, and `content.css`. It can still be loaded unpacked from `chrome://extensions`; v2 is the native macOS experience.
