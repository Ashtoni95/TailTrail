//
//  DogMapView.swift
//  TailTrail
//
//

// Views/DogMapView.swift
import SwiftUI
import MapKit

struct DogMapView: UIViewRepresentable {
    let sightings: [Sighting]
    @Binding var selectedSighting: Sighting?
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let currentCenter = mapView.region.center
        let distance = sqrt(
            pow(currentCenter.latitude - region.center.latitude, 2) +
            pow(currentCenter.longitude - region.center.longitude, 2)
        )
        
        if distance > 0.01 {
            mapView.setRegion(region, animated: true)
        }
        
        let wasUserAction = context.coordinator.isUserSelectingAnnotation

        let currentAnnotations = mapView.annotations.compactMap { $0 as? DogAnnotation }
        let currentIds = Set(currentAnnotations.map { $0.sighting.id })
        let newIds = Set(sightings.map { $0.id })

        let toRemove = currentAnnotations.filter { !newIds.contains($0.sighting.id) }
        mapView.removeAnnotations(toRemove)

        let toAdd = sightings.filter { !currentIds.contains($0.id) }
        let newAnnotations = toAdd.map { DogAnnotation(sighting: $0) }
        mapView.addAnnotations(newAnnotations)

        if !wasUserAction && !toAdd.isEmpty {
            if let firstNew = toAdd.first {
                let newRegion = MKCoordinateRegion(
                    center: firstNew.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                mapView.setRegion(newRegion, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: DogMapView
        var isUserSelectingAnnotation = false
        
        init(_ parent: DogMapView) {
            self.parent = parent
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as? MKMapView
            let location = gesture.location(in: mapView)
            let tappedAnnotation = mapView?.annotations.first { annotation in
                guard let view = mapView?.view(for: annotation) else { return false }
                let point = mapView?.convert(location, to: view)
                return view.point(inside: point ?? .zero, with: nil)
            }
            
            // If they didn't tap on any annotation, clear selection
            if tappedAnnotation == nil {
                parent.selectedSighting = nil
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            guard annotation is DogAnnotation else {
                return nil
            }
            
            let identifier = "DogAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                let label = UILabel()
                if let dogAnnotation = annotation as? DogAnnotation {
                    label.text = dogAnnotation.sighting.isLost ? "🆘" : "🐕"
                } else {
                    label.text = "🐕" // fallback
                }
                label.font = .systemFont(ofSize: 30)
                label.sizeToFit()
                
                let renderer = UIGraphicsImageRenderer(size: label.bounds.size)
                let image = renderer.image { _ in
                    label.drawHierarchy(in: label.bounds, afterScreenUpdates: true)
                }
                
                annotationView?.image = image
                annotationView?.centerOffset = CGPoint(x: 0, y: -image.size.height/2)
                
                let detailButton = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = detailButton
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            isUserSelectingAnnotation = true
            if let annotation = view.annotation as? DogAnnotation {
                parent.selectedSighting = annotation.sighting
                print("Selected dog: \(annotation.sighting.type)") // Debug log
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isUserSelectingAnnotation = false
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation as? DogAnnotation {
                print("Detail tapped for: \(annotation.sighting.type)")
            }
        }
    }
}

// Custom annotation class
class DogAnnotation: NSObject, MKAnnotation {
    let sighting: Sighting
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return sighting.type
    }
    
    var subtitle: String? {
        let chippedEmoji = sighting.chipped == "yes" ? "✅" : (sighting.chipped == "no" ? "❌" : "❓")
        let statusEmoji = sighting.isLost ? "🆘" : "🐕"
        return "\(statusEmoji) Age: \(sighting.age) • \(sighting.area) • \(chippedEmoji)"
    }
    
    init(sighting: Sighting) {
        self.sighting = sighting
        self.coordinate = sighting.coordinate
        super.init()
    }
}
