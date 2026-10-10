# AGENTS.md

Elsewhere is a small, fictional SwiftUI travel app. It is a public, MIT-licensed example of a customer's iOS app using the public Assetlib Swift SDK ([AssetLib/sdk-swift](https://github.com/AssetLib/sdk-swift), Swift module `AssetLib`) with three placements and bundled fallbacks. Targets iOS 17+ with Swift 6 and complete strict concurrency; README asks for Xcode 16+. Signed-manifest, decoding, cache and rollback tests live in the SDK repo, not here. Users create workspaces in the hosted console (https://console.assetlib.dev).

## Commands

Taken from `README.md`, `VERIFICATION.md` and `.github/workflows/ci.yml`. There is no Makefile, `Package.swift` or test target in this repo.

```sh
open Elsewhere.xcodeproj   # scheme Elsewhere, any installed iOS simulator

# Regenerate typed accessors after editing assetlib.catalog.json (offline, deterministic)
python3 scripts/generate-catalog.py assetlib.catalog.json Sources/Artwork.generated.swift

# Regenerate the committed Xcode project after editing project.yml
xcodegen generate

# What CI runs on macos-15: accessor drift check, then an unsigned generic-simulator build
python3 scripts/generate-catalog.py assetlib.catalog.json /tmp/Artwork.generated.swift
diff -u Sources/Artwork.generated.swift /tmp/Artwork.generated.swift
npm install --global xcodebuildmcp@2.5.2
xcodebuildmcp device build --project-path "$PWD/Elsewhere.xcodeproj" --scheme Elsewhere \
  --configuration Debug --derived-data-path "$PWD/output/PublicDerivedData" \
  --json '{"extraArgs":["-destination","generic/platform=iOS Simulator","CODE_SIGNING_ALLOWED=NO"]}'
```

Work is done when the accessor diff is empty and the build against the public package succeeds. A compile is not a runtime check. If you change UI, connection or accessibility behavior, run the app on a simulator (connect, pull to refresh or **Check for updates**, relaunch offline, **Disconnect**, VoiceOver) and add a dated section to `VERIFICATION.md` that says what was and was not verified.

Local SDK development: `python3 scripts/use-local-sdk.py ../sdk-swift` (needs `xcodegen`) writes an ignored `LocalBuild/Elsewhere.xcodeproj` that points at a local SDK checkout. Use it only while developing the SDK; the committed project keeps the public pin.

## Layout

- `assetlib.catalog.json`: placements `travel.coast` and `travel.ridge` (1200 × 900) and `tasks.garden` (600 × 400), each with a `fallbackImageName` and optional `bundledAccessibility` descriptions (en, th).
- `Sources/Artwork.generated.swift`: generated `AssetCatalog` references and `AppArtwork` accessors. Never edit by hand.
- `Sources/ElsewhereApp.swift`: the whole app. `DemoSession` owns connection, persistence, refresh and display-size targets; then the travel list, `TripDetail` and `ConnectionSheet`.
- `Sources/Assets.xcassets`: bundled fallbacks `coast`, `ridge`, `garden`, and the app icon.
- `Sources/PrivacyInfo.xcprivacy`: declares the app's UserDefaults use.
- `project.yml`: XcodeGen spec that produces `Elsewhere.xcodeproj`.

## Invariants

- **Placements come from the catalog.** Edit `assetlib.catalog.json`, regenerate the accessors, and commit both. Use `session.artwork.<group>.<name>` and `AssetCatalog.<Group>.<name>` rather than key strings, and do not build a flow where placements are typed into the console first. The console's starter workspace has these same three placements, so keys and sizes must keep matching. Compatible artwork changes need no app build; new symbols or changed contracts do.
- **Bundled fallbacks always render.** Every `fallbackImageName` must exist in `Assets.xcassets`. The generated accessors return a plain SwiftUI `Image` that shows the bundled image with no connection, no accepted release, or a failed download, verification or decode. Do not remove an imageset or bypass the accessors.
- **Accessibility is deliberate.** Card images are hidden inside a button labeled "View <trip name>". The detail view asks for a described artwork (`requireDescription: true`) and otherwise keeps the described bundled illustration. The garden is decorative. Bundled descriptions live in the catalog and must describe the actual bundled image; published descriptions stay with their release through cache and rollback.
- **Public config only.** `AssetConfiguration.parse` validates the pasted JSON, and only the re-encoded validated config is saved (UserDefaults key `assetlib-public-configuration`; saved trips use `saved-trips`). Never commit private keys, editor tokens or a real workspace config. Disconnect clears the saved config but keeps verified cache and the release watermark by design. Configurations saved before the console moved name the legacy host `assetlib-console.vercel.app`; never add a host check that rejects them, while links people click go to https://console.assetlib.dev. If you add stored data, update `PrivacyInfo.xcprivacy`.
- **SDK pin.** The committed project depends on `https://github.com/AssetLib/sdk-swift.git` at an `exactVersion` that is a published release tag, never a local path or branch; it is currently `0.4.0-preview.1` (revision `ec0ac4bb54890b6ac8bb40b4f54ee1ecb1a60012`). A version change updates together: `project.yml`, `Elsewhere.xcodeproj` (via `xcodegen generate`), `Package.resolved` (run `xcodebuild -resolvePackageDependencies -project Elsewhere.xcodeproj -scheme Elsewhere` and commit the new revision), the version string in `scripts/use-local-sdk.py` (it exits if it cannot find the pin), and `README.md`. Then regenerate accessors, build, and add a dated `VERIFICATION.md` section.
- **The app keeps its own identity.** Elsewhere uses system colors, serif display type and SF Symbols. Assetlib appears only as quiet text: the connection sheet title, the toolbar button's accessibility label, and the "An Assetlib demo · bundled artwork" line. Do not add Assetlib logos, colors or marketing copy.
- **Copy.** In prose and UI text the product is "Assetlib"; `AssetLib` is only the GitHub org and the Swift module name. Keep claims plain and specific; label unbuilt features as planned; no invented customers or metrics. Verification notes carry absolute dates and must stay true.
- **Fix what you find.** Fix a confirmed defect in the same change and record how you verified it. If a fix is unsafe right now, say so in the PR and say when it will be done.

## Release and versioning

There are no tags or GitHub releases. The app version is `MARKETING_VERSION` (0.1.0) and `CURRENT_PROJECT_VERSION` (1) in `project.yml`, mirrored in the generated project; the bundle ID is `dev.assetlib.elsewhere`. No signing team, certificates or provisioning profiles are committed, and none should be.

## Don'ts

- Don't hand-edit `Sources/Artwork.generated.swift`, and don't edit `project.pbxproj` directly: change `project.yml` and run `xcodegen generate`.
- Don't point the committed project at a local SDK path, a branch, or a version range.
- Don't commit `LocalBuild/`, `output/`, DerivedData, `.env*` or `*.private.*` files.
- Don't add analytics, booking or purchase flows; the app is a fictional demo.
- Don't publish, tag, or change repository settings from an agent session.
