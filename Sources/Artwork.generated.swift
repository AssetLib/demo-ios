// Generated offline by generate-catalog.py. Commit this file; do not edit it.
import SwiftUI
import AssetLib

enum AssetCatalog {
    enum `Travel` {
        static let `coast` = AssetReference(key: "travel.coast", width: 1200, height: 900)
        static let `ridge` = AssetReference(key: "travel.ridge", width: 1200, height: 900)
    }
    enum `Tasks` {
        static let `garden` = AssetReference(key: "tasks.garden", width: 600, height: 400)
    }
    static let all: [AssetReference] = [`Travel`.`coast`, `Travel`.`ridge`, `Tasks`.`garden`]
}

@MainActor struct AppArtwork {
    let store: AssetImageStore
    var bundle: Bundle = .main
    var `travel`: `Travel` { `Travel`(store: store, bundle: bundle) }
    @MainActor struct `Travel` {
        let store: AssetImageStore
        let bundle: Bundle
        var `coast`: Image { store.image(for: AssetCatalog.`Travel`.`coast`, fallback: Image(decorative: "coast", bundle: bundle)) }
        func `coastArtwork`(locale: Locale = .current, requireDescription: Bool = false) -> AssetArtwork {
            store.artwork(for: AssetCatalog.`Travel`.`coast`, fallback: Image(decorative: "coast", bundle: bundle), bundledAccessibility: try! AssetAccessibility(defaultLocale: "en", descriptions: ["en": "An illustrated seaside house, a sailboat, and the sun over the water.", "th": "\u{e20}\u{e32}\u{e1e}\u{e27}\u{e32}\u{e14}\u{e1a}\u{e49}\u{e32}\u{e19}\u{e23}\u{e34}\u{e21}\u{e17}\u{e30}\u{e40}\u{e25} \u{e40}\u{e23}\u{e37}\u{e2d}\u{e43}\u{e1a} \u{e41}\u{e25}\u{e30}\u{e14}\u{e27}\u{e07}\u{e2d}\u{e32}\u{e17}\u{e34}\u{e15}\u{e22}\u{e4c}\u{e40}\u{e2b}\u{e19}\u{e37}\u{e2d}\u{e1c}\u{e37}\u{e19}\u{e19}\u{e49}\u{e33}"]), locale: locale, requireDescription: requireDescription)
        }
        var `ridge`: Image { store.image(for: AssetCatalog.`Travel`.`ridge`, fallback: Image(decorative: "ridge", bundle: bundle)) }
        func `ridgeArtwork`(locale: Locale = .current, requireDescription: Bool = false) -> AssetArtwork {
            store.artwork(for: AssetCatalog.`Travel`.`ridge`, fallback: Image(decorative: "ridge", bundle: bundle), bundledAccessibility: try! AssetAccessibility(defaultLocale: "en", descriptions: ["en": "An illustrated mountain cabin beside a winding trail and pine trees.", "th": "\u{e20}\u{e32}\u{e1e}\u{e27}\u{e32}\u{e14}\u{e01}\u{e23}\u{e30}\u{e17}\u{e48}\u{e2d}\u{e21}\u{e1a}\u{e19}\u{e20}\u{e39}\u{e40}\u{e02}\u{e32}\u{e02}\u{e49}\u{e32}\u{e07}\u{e17}\u{e32}\u{e07}\u{e40}\u{e14}\u{e34}\u{e19}\u{e04}\u{e14}\u{e40}\u{e04}\u{e35}\u{e49}\u{e22}\u{e27}\u{e41}\u{e25}\u{e30}\u{e15}\u{e49}\u{e19}\u{e2a}\u{e19}"]), locale: locale, requireDescription: requireDescription)
        }
    }
    var `tasks`: `Tasks` { `Tasks`(store: store, bundle: bundle) }
    @MainActor struct `Tasks` {
        let store: AssetImageStore
        let bundle: Bundle
        var `garden`: Image { store.image(for: AssetCatalog.`Tasks`.`garden`, fallback: Image(decorative: "garden", bundle: bundle)) }
        func `gardenArtwork`(locale: Locale = .current, requireDescription: Bool = false) -> AssetArtwork {
            store.artwork(for: AssetCatalog.`Tasks`.`garden`, fallback: Image(decorative: "garden", bundle: bundle), bundledAccessibility: nil, locale: locale, requireDescription: requireDescription)
        }
    }
}
