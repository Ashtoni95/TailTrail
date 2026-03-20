//
//  LocationPickerMapView.swift
//  TailTrail
//
//

// Views/LocationPickerMapView.swift
import SwiftUI
import MapKit

struct LocationPickerMapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var locationName: String
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        
        // Set initial region
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: false)
        
        // Add a draggable pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Drag to set location"
        mapView.addAnnotation(annotation)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update existing annotation or add new one
        if let annotation = mapView.annotations.first as? MKPointAnnotation {
            annotation.coordinate = coordinate
        } else {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Drag to set location"
            mapView.addAnnotation(annotation)
        }
        
        reverseGeocode(coordinate: coordinate) { name in
            if let name = name {
                locationName = name
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LocationPickerMapView
        
        init(_ parent: LocationPickerMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "DraggablePin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.isDraggable = true
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange dragState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
            if dragState == .ending, let coordinate = view.annotation?.coordinate {
                parent.coordinate = coordinate
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: location) else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let mapItems = try await request.mapItems
                guard let mapItem = mapItems.first else {
                    completion(nil)
                    return
                }
                
                var locationString = ""
                
                if let address = mapItem.address {
                    locationString = address.fullAddress
                } else if let representations = mapItem.addressRepresentations {
                    var components: [String] = []
                    if let city = representations.cityWithContext { components.append(city) }
                    if let region = representations.regionName { components.append(region) }
                    locationString = components.joined(separator: ", ")
                }
                
                if locationString.isEmpty {
                    locationString = mapItem.name ?? ""
                }
                
                await MainActor.run {
                    completion(locationString.isEmpty ? nil : locationString)
                }
                
            } catch {
                print("Reverse geocoding error: \(error)")
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
}
