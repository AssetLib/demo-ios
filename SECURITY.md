# Security

Use this demonstration with public SDK configuration only. The connection sheet decodes the supported fields and persists only those validated fields; private signing keys and editor tokens are never needed. Do not commit your workspace configuration.

The Swift SDK verifies pinned Ed25519 signatures, app scope, exact UTF-8 payloads, monotonic release sequences, PNG and WebP image hashes, exact dimensions and decoding bounds. Its security model is described in [AssetLib/sdk-swift](https://github.com/AssetLib/sdk-swift/blob/main/SECURITY.md). Disconnect preserves the rollback watermark and clears the active public connection. Uninstalling/resetting app data clears that watermark.

Saved places and the public configuration use this app's UserDefaults. No account credentials, payment details, analytics identifiers, or travel bookings are collected by this app. Opening the console hands account creation to the browser. Ordinary network access logs remain a service-side privacy consideration.

Do not include secrets or personal data in public bug reports. Use the SDK's committed test-only fixture configuration for reproducible protocol failures. Report vulnerabilities privately through GitHub Security advisory reporting if enabled.
