//
//  NotificationsView.swift
//  TailTrail
//
//  Created by Ashton Irwin
//

import SwiftUI

struct NotificationsView: View {
    let userId: Int
    var onSelect: (Notification) -> Void
    
    @State private var notifications: [Notification] = []
    
    var body: some View {
        NavigationView {
            
            List(notifications) { notification in
                Button(action: {
                    onSelect(notification)
                }) {
                    HStack {
                        Image(systemName: notification.type == "match" ? "pawprint.fill" : "message.fill")
                            .foregroundColor(.blue)
                        
                        Text(notification.message)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Notifications")
            .task {
                print("NotificationsView task running")
                await loadNotificationsAsync()
            }
        }
    }
    
    private func loadNotificationsAsync() async {
        do {
            let fetched = try await SupabaseManager.shared.fetchNotifications(for: userId)
            
            print("Fetched notifications count:", fetched.count)
            
            await MainActor.run {
                notifications = fetched
            }
        } catch {
            print("Error loading notifications:", error)
        }
    }
}
