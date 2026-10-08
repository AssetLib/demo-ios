# Elsewhere — an Assetlib SwiftUI demo

A small, fictional travel app with original bundled illustrations, saved places, and a live Assetlib connection. It starts without an account or network access. No booking or purchase flow is included.

The app uses the public [AssetLib Swift SDK](https://github.com/AssetLib/sdk-swift), pinned to **0.1.0-preview.2**. iOS 17+ and Xcode 16+ with Swift 6 are required.

## Run

```sh
git clone https://github.com/AssetLib/demo-ios.git
cd demo-ios
open Elsewhere.xcodeproj
```

Allow Xcode to resolve the public Swift package. Select the **Elsewhere** scheme and an installed iOS simulator, then Run. For a physical device, select your own development team in Signing & Capabilities; this repo does not include a team, certificates, or provisioning profiles.

The committed Xcode project is ready to open. XcodeGen is only necessary if you change `project.yml`, not for normal use.

## Try your own workspace

1. Open the connection button in the top-right corner, then **Create or open a workspace**. Sign in at [assetlib-console.vercel.app](https://assetlib-console.vercel.app).
2. Copy your workspace's **public SDK configuration**. Paste the JSON into the demo and choose **Use this workspace**. It contains no editor token or private signing key.
3. The starter workspace provides `travel.coast`, `travel.ridge`, and `tasks.garden`. Both travel placements are 1200×900; the garden is 600×400.
4. Change the image bound to `travel.coast` in the console and publish. Choose **Check for updates**, or pull to refresh, in the running demo.
5. Roll back in the console. Check again; the SDK accepts the new release sequence that points to the earlier artwork.
6. Close and reopen the app offline. Previously verified artwork comes from this device's cache. A new installation starts from the bundled illustrations.

Each card shows whether its image is bundled, cached, or from a workspace release. Disconnecting restores bundled artwork immediately and removes the saved public configuration, while retaining verified cache and release history for safe reconnection. Saved destinations stay on your device.

## Native images; your layout

The generated accessor returns an ordinary SwiftUI `Image`:

```swift
session.artwork.travel.coast
    .resizable()
    .scaledToFill()
    .frame(height: 240)
    .clipped()
```

No proprietary layout wrapper is required. The observable SDK store supplies verified pixels; SwiftUI controls rendering, accessibility, composition, and interaction. Read the accessor in a SwiftUI body: holding an `Image` elsewhere does not create a live subscription. Refresh work is explicit and independent of rendering.

`assetlib.catalog.json` and `Sources/Artwork.generated.swift` are checked in. To regenerate offline:

```sh
python3 scripts/generate-catalog.py assetlib.catalog.json Sources/Artwork.generated.swift
```

Changing an existing placement's compatible artwork needs no new app build. New symbols or changed layout contracts need a build. Manifest dimensions describe a placement; an image can have different decoded pixels at the same aspect ratio.

## Develop with a local SDK checkout

```sh
brew install xcodegen
python3 scripts/use-local-sdk.py ../sdk-swift
open LocalBuild/Elsewhere.xcodeproj
```

This creates an ignored local project. It leaves the committed project and its exact public package dependency unchanged. Regenerate the public project after changing its spec:

```sh
xcodegen generate
```

CI builds the committed public dependency for a generic iOS Simulator destination. A compile pass does not prove runtime behavior. Core signed-manifest, native WebP decode, corruption, cache, rollback, and offline tests live in the SDK repository. An installed simulator or device is needed to validate the actual SwiftUI screen, VoiceOver, and interactions.

## Boundaries

This is a prerelease demonstration, not a travel service. No automatic screen tracking, experiments, Figma synchronization, or purchase flow is implemented. Updates arrive only after a successful refresh; unreachable delivery retains verified or bundled artwork.

Only validated public configuration is persisted. Do not paste private keys or editor credentials. The SDK and demo include privacy manifests for app-container cache metadata and app-owned UserDefaults respectively. Network providers may log ordinary delivery requests; see [SECURITY.md](SECURITY.md) and your service's privacy disclosures.

MIT licensed, including the original Assetlib illustrations. This project does not copy a travel brand or imply affiliation.
