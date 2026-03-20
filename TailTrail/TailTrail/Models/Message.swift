//
//  Message.swift
//  TailTrail
//
// Models/Message.swift
import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let sightingId: Int
    let userId: Int?
    let message: String
    let createdAt: Date
    let isSystemMessage: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case sightingId = "sighting_id"
        case userId = "user_id"
        case message
        case createdAt = "created_at"
        case isSystemMessage = "is_system_message"
    }
    
    // For UI grouping
    var isFromCurrentUser: Bool {
        // This will be set based on logged in user
        return userId == SupabaseManager.shared.currentUserId
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: createdAt)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}
