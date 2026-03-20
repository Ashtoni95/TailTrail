//
//  SupabaseManager.swift
//  TailTrail
//
//

// Services/SupabaseManager.swift
import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    var currentUserId: Int?
    
    private init() {
        guard let supabaseURL = URL(string: SupabaseSecrets.URL) else {
            fatalError("Invalid Supabase URL")
        }
        
        let options = SupabaseClientOptions(
            auth: .init(
                emitLocalSessionAsInitialSession: true
            )
        )
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: SupabaseSecrets.KEY,
            options: options
        )
    }
    
    // Fetch all sightings
    func fetchSightings() async throws -> [Sighting] {
        do {
            let sightings: [Sighting] = try await client
                .from("sightings")
                .select()
                .order("created_at", ascending: false) // Most recent first
                .execute()
                .value
            
            return sightings
        } catch {
            print("Error fetching sightings: \(error)")
            throw error
        }
    }
    
    // Optional: Fetch sightings within a specific region
    func fetchSightings(
        minLat: Double,
        maxLat: Double,
        minLng: Double,
        maxLng: Double
    ) async throws -> [Sighting] {
        do {
            let sightings: [Sighting] = try await client
                .from("sightings")
                .select()
                .gte("latitude", value: minLat)
                .lte("latitude", value: maxLat)
                .gte("longitude", value: minLng)
                .lte("longitude", value: maxLng)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return sightings
        } catch {
            print("Error fetching sightings in region: \(error)")
            throw error
        }
    }
    
    func createSighting(
        latitude: Double,
        longitude: Double,
        type: String,
        age: Int,
        chipped: String,
        area: String,
        description: String?,
        userId: Int?,
        isLost: Bool
    ) async throws -> Sighting {
        struct NewSighting: Encodable {
            let latitude: Double
            let longitude: Double
            let type: String
            let age: Int
            let chipped: String
            let area: String
            let description: String?
            let user_id: Int?
            let is_lost: Bool
        }
        
        do {
            let newSighting = NewSighting(
                latitude: latitude,
                longitude: longitude,
                type: type,
                age: age,
                chipped: chipped,
                area: area,
                description: description,
                user_id: userId,
                is_lost: isLost
            )
            
            let sighting: Sighting = try await client
                .from("sightings")
                .insert(newSighting)
                .select()
                .single()
                .execute()
                .value
            
            return sighting
        } catch {
            print("Error creating sighting: \(error)")
            throw error
        }
    }
    
    // Optional: Delete a sighting
    func deleteSighting(id: Int) async throws {
        do {
            try await client
                .from("sightings")
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            print("Error deleting sighting: \(error)")
            throw error
        }
    }
    
    // MARK: - Message Methods

    func fetchMessages(for sightingId: Int) async throws -> [Message] {
        do {
            let messages: [Message] = try await client
                .from("dog_messages")
                .select()
                .eq("sighting_id", value: sightingId)
                .order("created_at", ascending: true)  // Oldest first for chat
                .execute()
                .value
            
            return messages
        } catch {
            print("Error fetching messages: \(error)")
            throw error
        }
    }

    func sendMessage(to sightingId: Int, message: String) async throws -> Message {
        struct NewMessage: Encodable {
            let sighting_id: Int
            let user_id: Int?
            let message: String
        }
        
        guard let userId = currentUserId else {
            throw NSError(domain: "MessageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        do {
            let newMessage = NewMessage(
                sighting_id: sightingId,
                user_id: userId,
                message: message
            )
            
            let message: Message = try await client
                .from("dog_messages")
                .insert(newMessage)
                .select()
                .single()
                .execute()
                .value
            
            return message
        } catch {
            print("Error sending message: \(error)")
            throw error
        }
    }

    func subscribeToMessages(for sightingId: Int, onNewMessage: @escaping (Message) -> Void) -> RealtimeChannelV2 {
        let channel = client.realtimeV2.channel("messages-\(sightingId)")
        
        Task {
            // New syntax: filter as a separate parameter
            for await insertAction in channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "dog_messages",
                filter: "sighting_id=eq.\(sightingId)"
            ) {
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                do {
                    let newMessage = try insertAction.decodeRecord(as: Message.self, decoder: decoder)
                    await MainActor.run {
                        onNewMessage(newMessage)
                    }
                } catch {
                    print("Failed to decode real-time message: \(error)")
                }
            }
        }
        
        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                print("Failed to subscribe to channel: \(error)")
            }
        }
        
        return channel
    }
    
    // Add a User model
    struct User: Codable {
        let id: Int
        let email: String
        let username: String
        let firstName: String?
        let lastName: String?
        let created_at: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case username
            case firstName = "first_name"
            case lastName = "last_name"
            case created_at
        }
    }

    func authenticateUser(email: String, hashedPassword: String) async throws -> User? {
        do {
            let users: [User] = try await client
                .from("users")
                .select()
                .eq("email", value: email)
                .eq("password", value: hashedPassword)
                .execute()
                .value
            
            return users.first
        } catch {
            print("Error authenticating user: \(error)")
            throw error
        }
    }

}
