//
//  Sighting.swift
//  TailTrail
//
//

// Models/Sighting.swift
import Foundation
import CoreLocation

struct Sighting: Identifiable, Codable {
    let id: Int
    let latitude: Double
    let longitude: Double
    let type: String
    let age: Int
    let chipped: String
    let area: String
    let description: String?
    let created_at: String?
    let userId: Int?
    let isLost: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case type
        case age
        case chipped
        case area
        case description
        case created_at
        case userId = "user_id"
        case isLost = "is_lost"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
