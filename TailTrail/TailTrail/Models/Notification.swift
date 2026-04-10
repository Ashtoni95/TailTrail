//
//  Notification.swift
//  TailTrail
//
//  Created by Ashton Irwin
//
import Foundation
struct Notification: Identifiable, Codable {
    let id: Int
    let userId: Int
    let sightingId: Int
    let matchedSightingId: Int
    let message: String
    let createdAt: Date
    let isRead: Bool
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sightingId = "sighting_id"
        case matchedSightingId = "matched_sighting_id"
        case message
        case type
        case createdAt = "created_at"
        case isRead = "is_read"
    }
}
