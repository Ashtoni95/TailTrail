//
//  ProfileView.swift
//  TailTrail
//
//

// Views/ProfileView.swift
import SwiftUI
import Supabase

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: String?
    let user: SupabaseManager.User?
    
    @State private var showLogoutAlert = false
    @State private var sightingCount = 0
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Profile Icon
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Text("📊")
                                    .font(.system(size: 50))
                            }
                            
                            // User Name
                            if let firstName = user?.firstName, let lastName = user?.lastName {
                                Text("\(firstName) \(lastName)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            } else {
                                Text(user?.username ?? "Unknown User")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            // Member Since
                            if let createdDate = user?.created_at {
                                Text("Member since \(formatDate(createdDate))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                // Account Details
                Section(header: Text("ACCOUNT INFORMATION")) {
                    // Email
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Email")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(user?.email ?? "")
                            .foregroundColor(.primary)
                    }
                    
                    // Username
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Username")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(user?.username ?? "")
                            .foregroundColor(.primary)
                    }
                    
                    // First Name (if available)
                    if let firstName = user?.firstName {
                        HStack {
                            Image(systemName: "person.text.rectangle")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("First Name")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(firstName)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Last Name (if available)
                    if let lastName = user?.lastName {
                        HStack {
                            Image(systemName: "person.text.rectangle")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Last Name")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(lastName)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Stats Section
                Section(header: Text("ACTIVITY")) {
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Sightings Reported")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(sightingCount)")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                    }
                }
                
                // Logout Section
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .onAppear {
                fetchSightingCount()
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func fetchSightingCount() {
        guard let userId = user?.id else { return }
        
        Task {
            do {
                let count = try await SupabaseManager.shared.client
                    .from("sightings")
                    .select("id", head: true, count: .exact)
                    .eq("user_id", value: userId)
                    .execute()
                    .count
                
                await MainActor.run {
                    sightingCount = count ?? 0
                }
            } catch {
                print("Error fetching count: \(error)")
            }
        }
    }


    private func logout() {
        isLoggedIn = false
        currentUser = nil
        dismiss()
    }
}
