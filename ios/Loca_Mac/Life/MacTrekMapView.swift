import SwiftUI
import MapKit
import AppKit

// MARK: - TrekAnnotation

final class TrekAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let trek: TrekRecord

    init(trek: TrekRecord) {
        self.trek = trek
        self.coordinate = trek.coordinate
        self.title = trek.name
        self.subtitle = "\(trek.formattedElevation) · \(trek.region)"
        super.init()
    }
}

// MARK: - MacTrekMapView (NSViewRepresentable)

/// Native AppKit MKMapView wrapper delivering precision camera controls, custom
/// illuminated summit badges, and smooth fly-to animations for Pluto's Trek Atlas.
struct MacTrekMapView: NSViewRepresentable {

    let treks: [TrekRecord]
    let selectedTrek: TrekRecord?
    let onSelectTrek: (TrekRecord) -> Void

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsPitchControl = true
        mapView.showsZoomControls = true

        // Configure realistic topo terrain on macOS 14+
        let config = MKStandardMapConfiguration(elevationStyle: .realistic, poiFilter: .excludingAll)
        config.showsTraffic = false
        mapView.preferredConfiguration = config

        // Register custom summit annotation view
        mapView.register(TrekAnnotationView.self, forAnnotationViewWithReuseIdentifier: TrekAnnotationView.reuseIdentifier)

        // Set initial camera over world/Alps
        let initialCoord = CLLocationCoordinate2D(latitude: 35.0, longitude: 20.0)
        let camera = MKMapCamera(lookingAtCenter: initialCoord, fromDistance: 18_000_000, pitch: 35, heading: 0)
        mapView.setCamera(camera, animated: false)

        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self

        // Update annotations if trek count or IDs changed
        let currentAnnotations = mapView.annotations.compactMap { $0 as? TrekAnnotation }
        let currentIDs = Set(currentAnnotations.map { $0.trek.id })
        let newIDs = Set(treks.map { $0.id })

        if currentIDs != newIDs || currentAnnotations.count != treks.count {
            mapView.removeAnnotations(currentAnnotations)
            let newAnnotations = treks.map { TrekAnnotation(trek: $0) }
            mapView.addAnnotations(newAnnotations)
        } else {
            // Update visual state of existing annotation views
            for annotation in currentAnnotations {
                if let view = mapView.view(for: annotation) as? TrekAnnotationView {
                    view.updateVisuals(isSelected: annotation.trek.id == selectedTrek?.id)
                }
            }
        }

        // Fly camera to selected trek if changed
        if let selectedTrek, selectedTrek.id != context.coordinator.lastSelectedID {
            context.coordinator.lastSelectedID = selectedTrek.id
            let camera = MKMapCamera(
                lookingAtCenter: selectedTrek.coordinate,
                fromDistance: 120_000,
                pitch: 55,
                heading: 15
            )
            mapView.setCamera(camera, animated: true)

            // Select annotation pin
            if let targetAnnotation = mapView.annotations.first(where: { ($0 as? TrekAnnotation)?.trek.id == selectedTrek.id }) {
                mapView.selectAnnotation(targetAnnotation, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MacTrekMapView
        var lastSelectedID: UUID?

        init(parent: MacTrekMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let trekAnnotation = annotation as? TrekAnnotation else { return nil }

            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: TrekAnnotationView.reuseIdentifier,
                for: annotation
            ) as? TrekAnnotationView ?? TrekAnnotationView(annotation: annotation, reuseIdentifier: TrekAnnotationView.reuseIdentifier)

            view.annotation = trekAnnotation
            let isSelected = trekAnnotation.trek.id == parent.selectedTrek?.id
            view.updateVisuals(isSelected: isSelected)
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let trekAnnotation = view.annotation as? TrekAnnotation else { return }
            parent.onSelectTrek(trekAnnotation.trek)
        }
    }
}

// MARK: - TrekAnnotationView

final class TrekAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "TrekAnnotationView"

    private let badgeLayer = CALayer()
    private let iconImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {
        canShowCallout = false
        frame = NSRect(x: 0, y: 0, width: 44, height: 44)
        wantsLayer = true

        badgeLayer.frame = bounds
        badgeLayer.cornerRadius = 22
        badgeLayer.masksToBounds = false
        badgeLayer.shadowRadius = 8
        badgeLayer.shadowOpacity = 0.6
        badgeLayer.shadowOffset = CGSize(width: 0, height: 3)
        if let layer {
            layer.addSublayer(badgeLayer)
        }

        iconImageView.frame = NSRect(x: 10, y: 10, width: 24, height: 24)
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(iconImageView)
    }

    func updateVisuals(isSelected: Bool) {
        guard let trekAnnotation = annotation as? TrekAnnotation else { return }
        let trek = trekAnnotation.trek
        let isConquered = trek.status == .conquered

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if isConquered {
            // Radiant Cyan / Amber Summit Beacon
            badgeLayer.backgroundColor = NSColor(red: 0.05, green: 0.12, blue: 0.22, alpha: 0.95).cgColor
            badgeLayer.borderColor = NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0).cgColor
            badgeLayer.borderWidth = isSelected ? 3.0 : 2.0
            badgeLayer.shadowColor = NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.8).cgColor

            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
            let img = NSImage(systemSymbolName: "trophy.fill", accessibilityDescription: "Conquered")?.withSymbolConfiguration(config)
            iconImageView.image = img
            iconImageView.contentTintColor = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
        } else {
            // Muted Slate Translucent Wishlist Pin
            badgeLayer.backgroundColor = NSColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 0.85).cgColor
            badgeLayer.borderColor = NSColor(white: 0.5, alpha: 0.4).cgColor
            badgeLayer.borderWidth = isSelected ? 2.5 : 1.0
            badgeLayer.shadowColor = NSColor.black.cgColor

            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let img = NSImage(systemSymbolName: "mappin.and.ellipse", accessibilityDescription: "Wishlist")?.withSymbolConfiguration(config)
            iconImageView.image = img
            iconImageView.contentTintColor = NSColor(white: 0.7, alpha: 1.0)
        }

        transform = isSelected ? CGAffineTransform(scaleX: 1.25, y: 1.25) : .identity
        CATransaction.commit()
    }
}
