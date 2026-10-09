import SwiftUI
import Observation
import AssetLib

@main struct ElsewhereApp: App {
    @State private var session = DemoSession()
    var body: some Scene {
        WindowGroup {
            TravelHome(session: session)
                .task { await session.restore() }
        }
    }
}

@MainActor @Observable final class DemoSession {
    let images = AssetImageStore()
    var configText = ""
    var connectionError: String?
    var showingConnection = false
    var selection: Trip?
    var showSaved = false
    var saved: Set<String> = []
    @ObservationIgnored private var didRestore = false
    @ObservationIgnored private var targetPixels: [AssetReference: AssetPixelSize] = [:]
    @ObservationIgnored private let defaults = UserDefaults.standard
    var artwork: AppArtwork { AppArtwork(store: images) }
    var visibleTrips: [Trip] { showSaved ? Trip.all.filter { saved.contains($0.id) } : Trip.all }

    init() { saved = Set(defaults.stringArray(forKey: "saved-trips") ?? []) }
    func toggle(_ trip: Trip) {
        if saved.contains(trip.id) { saved.remove(trip.id) } else { saved.insert(trip.id) }
        defaults.set(Array(saved).sorted(), forKey: "saved-trips")
    }
    func restore() async {
        guard !didRestore else { return }; didRestore = true
        guard let json = defaults.string(forKey: "assetlib-public-configuration") else { return }
        configText = json
        await connect()
    }
    func connect() async {
        do {
            let config = try AssetConfiguration.parse(Data(configText.utf8))
            let storage = try FileAssetStorage(configuration: config)
            let client = try AssetClient(configuration: config, storage: storage)
            images.connect(client)
            // Only the validated public fields are persisted. Unknown JSON fields are discarded.
            let data = try JSONEncoder().encode(config)
            defaults.set(String(decoding: data, as: UTF8.self), forKey: "assetlib-public-configuration")
            connectionError = nil; showingConnection = false
            await refresh()
        } catch { connectionError = error.localizedDescription }
    }
    func disconnect() {
        images.disconnect()
        defaults.removeObject(forKey: "assetlib-public-configuration")
        configText = ""; connectionError = nil
    }
    func refresh() async { await images.refresh(AssetCatalog.all, targetPixels: targetPixels) }
    func setDisplay(containerWidth: CGFloat, scale: CGFloat) async {
        guard containerWidth.isFinite, scale.isFinite, containerWidth > 0, scale > 0 else { return }
        // The largest travel image is a 240pt-tall card or the capped detail image.
        // Explicit layout demand stays in the app; normal Image modifiers remain untouched.
        let travelWidth = min(8192, Int(ceil(max(320, min(containerWidth, 680) - 40) * scale)))
        let gardenWidth = min(8192, Int(ceil(80 * scale)))
        let next = [
            AssetCatalog.Travel.coast: AssetPixelSize(width: travelWidth, height: max(1, Int(ceil(Double(travelWidth) * 0.75)))),
            AssetCatalog.Travel.ridge: AssetPixelSize(width: travelWidth, height: max(1, Int(ceil(Double(travelWidth) * 0.75)))),
            AssetCatalog.Tasks.garden: AssetPixelSize(width: gardenWidth, height: max(1, Int(ceil(Double(gardenWidth) * 2 / 3))))
        ]
        guard next != targetPixels else { return }
        targetPixels = next
        if images.connected { await refresh() }
    }
    func image(for trip: Trip) -> Image { trip.id == "coast" ? artwork.travel.coast : artwork.travel.ridge }
    func describedArtwork(for trip: Trip, locale: Locale) -> AssetArtwork {
        trip.id == "coast" ? artwork.travel.coastArtwork(locale: locale, requireDescription: true)
            : artwork.travel.ridgeArtwork(locale: locale, requireDescription: true)
    }
    func status(for trip: Trip) -> String {
        let ref = trip.id == "coast" ? AssetCatalog.Travel.coast : AssetCatalog.Travel.ridge
        guard let status = images.results[ref] else { return "Bundled artwork" }
        let format = status.mime == "image/png" ? "PNG" : "WebP"
        let rendition = status.pixelSize.map { " · \(format) \($0.width)×\($0.height)" } ?? ""
        switch status.source {
        case .bundle: return "Bundled artwork"
        case .cache: return "On this device · release \(status.sequence ?? 0)\(rendition)"
        case .remote: return "From your workspace · release \(status.sequence ?? 0)\(rendition)"
        }
    }
}

struct Trip: Identifiable, Hashable {
    let id: String
    let name: String
    let location: String
    let description: String
    let details: [String]
    static let all = [
        Trip(id: "coast", name: "Take the coast road", location: "A WEEKEND BY THE WATER", description: "Slow mornings, a winding coastal walk, and nowhere you need to be. A little space to reset.", details: ["2 nights", "Coastal walks", "A slower pace"]),
        Trip(id: "ridge", name: "Above the everyday", location: "A FEW DAYS IN THE MOUNTAINS", description: "Follow the trail past the last pine tree. Pack a good book, find a quiet spot, and stay a little longer.", details: ["3 nights", "Mountain trails", "Room to wander"])
    ]
}

struct TravelHome: View {
    @Bindable var session: DemoSession
    @Environment(\.displayScale) private var displayScale
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GOOD PLACES. NO RUSH.").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                        Text("A little further from the everyday.").font(.largeTitle.weight(.semibold)).fontDesign(.serif)
                        Text("A small collection of places worth slowing down for.").font(.body).foregroundStyle(.secondary)
                    }
                    Picker("Explore or saved trips", selection: $session.showSaved) {
                        Text("Explore").tag(false)
                        Text("Saved · \(session.saved.count)").tag(true)
                    }.pickerStyle(.segmented)
                    if session.visibleTrips.isEmpty {
                        ContentUnavailableView("Your next escape", systemImage: "bookmark", description: Text("Save a place that catches your eye. It will be waiting here."))
                    }
                    ForEach(session.visibleTrips) { trip in
                        VStack(alignment: .leading, spacing: 0) {
                            Button { session.selection = trip } label: {
                                session.image(for: trip)
                                    .resizable().scaledToFill().frame(height: 240).clipped()
                                    .accessibilityHidden(true)
                            }.buttonStyle(.plain).accessibilityLabel("View \(trip.name)")
                            VStack(alignment: .leading, spacing: 12) {
                                Text(trip.location).font(.caption2.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
                                HStack(alignment: .top) {
                                    Button { session.selection = trip } label: {
                                        Text(trip.name).font(.title2.weight(.semibold)).fontDesign(.serif).foregroundStyle(.primary).multilineTextAlignment(.leading)
                                    }.buttonStyle(.plain)
                                    Spacer(minLength: 8)
                                    SaveButton(trip: trip, session: session)
                                }
                                Text(session.status(for: trip)).font(.caption).foregroundStyle(.secondary)
                            }.padding(20)
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 16) {
                            session.artwork.tasks.garden.resizable().scaledToFit().frame(width: 80, height: 64).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Make room for a slower day.").font(.headline).fontDesign(.serif)
                                Text("This little illustration has its own managed placement too.").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        Divider()
                        Label(session.images.connected ? "Connected to your workspace" : "An Assetlib demo · bundled artwork", systemImage: session.images.connected ? "checkmark.shield" : "shippingbox").font(.footnote)
                        if let error = session.images.lastError {
                            Text(error).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                        Button(session.images.connected ? "Manage connection" : "Try your own artwork") { session.showingConnection = true }
                            .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }.padding(20).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    Text("A fictional travel collection. No reservations or purchases.").font(.caption).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Elsewhere")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { session.showingConnection = true } label: { Image(systemName: "slider.horizontal.3").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Assetlib connection")
                }
            }
            .refreshable { await session.refresh() }
            .sheet(isPresented: $session.showingConnection) { ConnectionSheet(session: session) }
            .sheet(item: $session.selection) { trip in TripDetail(trip: trip, session: session) }
        }.tint(.primary)
            .background {
                GeometryReader { proxy in
                    Color.clear.task(id: proxy.size.width * displayScale) {
                        await session.setDisplay(containerWidth: proxy.size.width, scale: displayScale)
                    }
                }
            }
    }
}

struct SaveButton: View {
    let trip: Trip
    @Bindable var session: DemoSession
    var body: some View {
        Button { session.toggle(trip) } label: {
            Image(systemName: session.saved.contains(trip.id) ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44)
        }.buttonStyle(.plain).accessibilityLabel(session.saved.contains(trip.id) ? "Unsave \(trip.name)" : "Save \(trip.name)")
    }
}

struct TripDetail: View {
    let trip: Trip
    @Bindable var session: DemoSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    var body: some View {
        let artwork = session.describedArtwork(for: trip, locale: locale)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    artwork.image.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 24))
                        .accessibilityElement(children: .ignore)
                        .accessibilityAddTraits(.isImage)
                        .accessibilityLabel(Text(verbatim: artwork.accessibilityDescription ?? ""))
                        .accessibilityHidden(artwork.accessibilityDescription == nil)
                    Text(trip.location).font(.caption.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
                    Text(trip.name).font(.largeTitle.weight(.semibold)).fontDesign(.serif)
                    Text(trip.description).font(.title3).foregroundStyle(.secondary)
                    ForEach(trip.details, id: \.self) { Label($0, systemImage: "checkmark").font(.body) }
                    HStack { Text("Keep it for later").font(.headline); Spacer(); SaveButton(trip: trip, session: session) }
                    Text(artwork.source == .bundle ? "Bundled artwork" : session.status(for: trip)).font(.caption).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }.navigationTitle("A place to pause").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct ConnectionSheet: View {
    @Bindable var session: DemoSession
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Put your own artwork in this app.").font(.title2.weight(.semibold)).fontDesign(.serif)
                    Text("Create an Assetlib workspace, copy its public SDK configuration, and paste it below. The demo already includes the three starter placements.")
                    Link("Create or open a workspace", destination: URL(string: "https://console.assetlib.dev")!)
                }
                Section("Public SDK configuration") {
                    TextEditor(text: $session.configText).font(.system(.caption, design: .monospaced)).frame(minHeight: 180)
                        .autocorrectionDisabled().textInputAutocapitalization(.never).accessibilityLabel("Public SDK configuration JSON")
                    Text("Paste public configuration only. No API secret, editor token, or private signing key is needed.").font(.caption).foregroundStyle(.secondary)
                    if let error = session.connectionError { Text(error).foregroundStyle(.red).font(.footnote) }
                    Button("Use this workspace") { Task { await session.connect() } }.disabled(session.configText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if session.images.connected {
                    Section("This connection") {
                        LabeledContent("Accepted release", value: session.images.release == 0 ? "None yet" : String(session.images.release))
                        Button { Task { await session.refresh() } } label: {
                            HStack { Text("Check for updates"); Spacer(); if session.images.isLoading { ProgressView() } }
                        }.disabled(session.images.isLoading)
                        Button("Disconnect", role: .destructive) { session.disconnect() }
                        Text("Disconnect restores the bundled images. Verified cached files and the highest accepted release remain on this device for safe reconnection.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Try the full loop") {
                    Text("In the console, change the image bound to travel.coast and publish. Check for updates here. Then roll back in the console and check again. Artwork changes; the app's layout stays yours.")
                    Text("The app uses normal SwiftUI Image values. Network loading, verification, caching, and release history live in the SDK.").font(.footnote).foregroundStyle(.secondary)
                    Text("The demo requests physical pixels for its layout and display scale. PNG and WebP renditions decode to native images; SVG artwork uses a prepared raster fallback on iOS.").font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Assetlib").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
