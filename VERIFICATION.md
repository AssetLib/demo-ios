# Simulator run — October 9, 2026 (ET)

First interactive run of the app on an iOS simulator, with the committed public project on Swift SDK `0.3.0-preview.1` (`main` at `2ef91d8`).

- `xcodebuild -project Elsewhere.xcodeproj -scheme Elsewhere -destination 'platform=iOS Simulator,…' CODE_SIGNING_ALLOWED=NO build` succeeded with Xcode 27.0 and the iOS 27.0 simulator runtime.
- On a freshly booted iPhone 17 simulator (iOS 27.0), the app launched and rendered its bundled artwork ("Bundled artwork" under each card).
- With the hosted demo workspace's public configuration in the console's current shape (single pin plus `pinnedPublicKeys` and `keyIds`, manifest on the legacy delivery host `assetlib-console.vercel.app`) stored under the app's `assetlib-public-configuration` default, the relaunched app verified signed release 6 and rendered the coast card from it: "From your workspace · release 6 · WebP 1200×900". The connection sheet showed "Accepted release 6".
- Disconnect cleared the connection and the configuration text and returned the cards to bundled artwork.
- The configuration was pasted through the sheet's editor twice; storing it by tapping "Use this workspace" was not completed in this run because taps sent while the form was still scrolling only stopped the scroll. Buttons in the same sheet responded once the scroll had settled. The stored-default path is the same string the button saves.

Not established: a hosted publish, refresh and rollback loop on the simulator, offline restart in the app, VoiceOver, or a physical device.

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

## SDK 0.3.0-preview.1 — October 9, 2026 (ET)

The committed project now pins `https://github.com/AssetLib/sdk-swift.git` at exact version `0.3.0-preview.1` in `project.yml` (and the regenerated `Elsewhere.xcodeproj`) and in `scripts/use-local-sdk.py`. `xcodebuild -resolvePackageDependencies` with an empty cloned-packages directory resolved revision `d9e6c658ecbdcb926e4948377d8e07e927c8a718`, the commit behind the public `0.3.0-preview.1` tag, and `Package.resolved` records it.

The release only adds API: a `staging` environment, appearance and arm variant cells, an optional `decide` callback, a pinned key set, and appearance and arm overrides on `AssetImageStore`, all with defaults. The demo uses none of them and needed no code change for the upgrade. The storage namespace now derives from the manifest origin, organization, app, and environment, and the SDK migrates the previous cache and release watermark once after verifying them.

The connection sheet's **Create or open a workspace** link and the README now point to `https://console.assetlib.dev`. The demo does not check the configuration's host: `AssetConfiguration.parse` requires an HTTPS manifest URL scoped to the app on any host. A scratch macOS executable built against the resolved `0.3.0-preview.1` checkout parsed a configuration in the shape the 0.2.1 SDK saved, then parsed it again after re-encoding, for both `assetlib-console.vercel.app` and `console.assetlib.dev` and for both the legacy and the environment manifest paths. The app and SDK therefore still accept saved configurations that point at the legacy host; no network request to either host was made in this check.

Checks run, with Xcode 27.0, XcodeGen 2.45.4 and XcodeBuildMCP 2.5.2:

1. `xcodegen generate` changed only the package requirement in `project.pbxproj`.
2. The generated accessors match a fresh offline `generate-catalog.py` run (empty diff).
3. The CI build command with a new `output/Public030DerivedData` directory fetched the public package and succeeded for the generic iOS Simulator destination, with signing disabled. It produced `Debug-iphonesimulator/Elsewhere.app` and `Debug-iphoneos/Elsewhere.app`. The only warnings were Xcode's AppIntents metadata-skipped notices.

Not verified: `xcrun simctl list runtimes` lists no installed iOS Simulator runtime on this machine, so the app was not launched, and VoiceOver, the connection sheet, the console link and a live publish and rollback were not exercised on iOS. A generic Simulator compile is not a simulator run.
