# Verification — October 7, 2026 (ET)

This record distinguishes compilation, SDK execution on macOS, and native app UI execution.

## Confirmed locally

Toolchain: Apple Swift 6.4, Xcode with iOS 27 SDKs, XcodeGen 2.45.4, XcodeBuildMCP 2.5.2. Project deployment target is iOS 17 and language mode is Swift 6.

1. Generated typed catalog output exactly matches the committed `Sources/Artwork.generated.swift`.
2. The local SDK override built for generic iOS and generic iOS Simulator destinations.
3. The **committed public project** resolved `https://github.com/AssetLib/sdk-swift.git` at exact version **0.1.0-preview.2**, revision **520ab21a5fe7c732558834428ff8d1d2f57385f0**. `Package.resolved` records that public source pin.
4. Fresh public-dependency builds succeeded for iOS and iOS Simulator. XcodeBuildMCP reported zero warnings and zero errors. Actual build products included `Debug-iphoneos/Elsewhere.app` and `Debug-iphonesimulator/Elsewhere.app`; logs showed the simulator SDK being used.
5. The built application contains both its own `PrivacyInfo.xcprivacy` and the SDK resource bundle's privacy manifest.

The commands below reproduce the public build from this repository's root. The second command appends the generic Simulator destination; XcodeBuildMCP's device workflow also supplies the generic iOS destination, so both platforms build. They compile without signing and do not install or run the app.

```sh
python3 scripts/generate-catalog.py assetlib.catalog.json /tmp/Artwork.generated.swift
diff -u Sources/Artwork.generated.swift /tmp/Artwork.generated.swift

xcodebuildmcp device build \
  --project-path "$PWD/Elsewhere.xcodeproj" \
  --scheme Elsewhere --configuration Debug \
  --derived-data-path "$PWD/output/PublicDerivedData" \
  --json '{"extraArgs":["CODE_SIGNING_ALLOWED=NO"]}'

xcodebuildmcp device build \
  --project-path "$PWD/Elsewhere.xcodeproj" \
  --scheme Elsewhere --configuration Debug \
  --derived-data-path "$PWD/output/PublicSimulatorDerivedData" \
  --json '{"extraArgs":["-destination","generic/platform=iOS Simulator","CODE_SIGNING_ALLOWED=NO"]}'
```

## SDK execution evidence

The Swift SDK test suite passed on macOS: ten executed tests plus an optional hosted test disabled by default. One test exercises all 43 shared signed-manifest verification cases. Other tests cover real native ImageIO WebP decoding, different physical/logical dimensions, signed rollback, exact-byte equivocation, corrupted downloads, persisted history, cross-instance sequence protection, offline restart, corrupt storage, and connection-state cancellation behavior. Offline code generation validation/determinism checks also passed. The generated example is an actual SwiftPM compilation target, so CI type-checks its nested actor-isolated accessors.

A separate read-only hosted acceptance run accepted signed release 3 from the existing preview service, downloaded and natively decoded all three starter WebP assets, and verified that a restarted client with an offline transport used the verified disk cache. It did not modify the workspace or publish content. No real workspace configuration is included here.

## Still unverified

The build machine had no installed iOS Simulator runtime available for launch. The SwiftUI application was therefore **not launched on an iPhone simulator or physical device**. Its visual layout, VoiceOver behavior, saved-place interactions, connection sheet, and an end-to-end publish/rollback while the native screen remains open still require runtime verification. A generic Simulator compile is not a simulator run.

No App Store submission, signing, or TestFlight distribution was performed.

GitHub Actions status, checked October 9, 2026 with `gh run list -R AssetLib/demo-ios`: the `SwiftUI demo` workflow (macos-15: accessor drift check, then the generic iOS Simulator build against the public package) passed for this first commit, `e3e60e7` on `main`, in run 37719325030 on October 7, 2026 at 22:44 ET. It also passed for `b300e1e` on `main` (run 37724116585) and for `9a1f7b4` on `codex/accessibility-release` (push run 37729848239 and pull request run 37729938700).

## Rendition extension — 0.2.0-preview.1

The updated app compiled against the ignored local SDK override using XcodeBuildMCP with both generic iOS and generic iOS Simulator destinations. The build succeeded without Swift compiler errors. Xcode emitted its expected AppIntents metadata-skipped warning because this demo has no AppIntents dependency. The committed public project then resolved exact version `0.2.0-preview.1`, revision `82adbbc9229691675ef08b820ee1842e84f5a50c`, from `https://github.com/AssetLib/sdk-swift.git`. Its updated `Package.resolved` pins that public revision. A new `output/PublicRenditionDerivedData` directory fetched a remote source-control checkout and successfully built both generic iOS and generic iOS Simulator products with signing disabled; it did not use the local SDK override. The older public-resolution evidence above remains historical evidence for `0.1.0-preview.2`.

The updated SDK passed 17 executed tests on macOS, including all 65 shared signed-manifest cases, four shared target selections, native PNG/WebP decoding, exact dimensions/type/hash verification, target propagation, legacy cache migration, candidate failure and historical cache-only fallback. The ordinary suite disabled its optional hosted acceptance test. A separate read-only run using private local public configuration passed against the existing service: signed release 3, all three native WebP decodes, and an independently restarted offline client using verified cache. No workspace data was published or modified, and no configuration is committed. This validates backward compatibility with the hosted legacy release, not hosted PNG publication. Two code-generation tests and a release build passed.

The demo supplies known frame dimensions multiplied by SwiftUI display scale, requests a smaller target for the garden illustration, and displays actual delivered format and pixel dimensions on travel cards. Native SVG remains unsupported: SVG sources use server-prepared PNG/WebP renditions. No native interactive UI or live PNG publication is claimed by these compile checks.

Reproduce the clean public dependency compile:

```sh
xcodebuildmcp device build \
  --project-path "$PWD/Elsewhere.xcodeproj" \
  --scheme Elsewhere --configuration Debug \
  --derived-data-path "$PWD/output/PublicRenditionDerivedData" \
  --json '{"extraArgs":["-destination","generic/platform=iOS Simulator","CODE_SIGNING_ALLOWED=NO"]}'
```

## Accessibility preview — 0.2.1-preview.1

The committed public dependency now resolves `0.2.1-preview.1`, revision `2477bc2b88c36ef72cc088ab68e5a4148f5b9bc7`, from the public Swift SDK repository. A fresh `output/PublicAccessibilityDerivedData` source-control checkout resolved that exact public revision and passed generic iOS and generic iOS Simulator builds through XcodeBuildMCP with signing disabled. Generated accessors match a fresh offline code-generation run.

The travel-card image is decorative inside an explicitly labeled action button. The detail view uses the current locale and a paired artwork snapshot, marks it as an image, and requires a description before displaying remote artwork; otherwise it retains the described bundled illustration. Its status reflects that displayed fallback. The small garden remains decorative. Bundled English/Thai descriptions were checked against the included illustrations.

The released SDK separately passed native macOS accessibility-tree checks for image role, locale changes, verified cached/offline pixels, bundle restoration, decorative hiding, and button labels. That evidence does not establish iPhone runtime or VoiceOver listening acceptance. This machine has no usable iOS Simulator runtime; generic compilation remains the iOS check.
