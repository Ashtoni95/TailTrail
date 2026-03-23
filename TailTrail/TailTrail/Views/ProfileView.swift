//
//  ProfileView.swift
//  TailTrail
//
//

// Views/ProfileView.swift
import SwiftUI
import Supabase
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: String?
    let user: SupabaseManager.User?
    
    @State private var showLogoutAlert = false
    @State private var sightingCount = 0
    
    // Avatar state
    @State private var avatarURL: String? // remote fallback (unused for saving)
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var localAvatarImage: UIImage?
    
    // Hover state for the "Change Photo" button
    @State private var isHoveringChangePhoto = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Profile Avatar
                            ZStack {
                                if let image = localAvatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                } else if let avatarURL, let url = URL(string: avatarURL) {
                                    // Fallback to remote if you still want to show it when no local image yet.
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 110, height: 110)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                        case .failure:
                                            defaultAvatar
                                        @unknown default:
                                            defaultAvatar
                                        }
                                    }
                                } else {
                                    defaultAvatar
                                }
                                
                                if isUploading {
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: 110, height: 110)
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            
                            // Change photo button with hover effect
                            if user != nil {
                                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                        Text("Change Photo")
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isHoveringChangePhoto ? Color.blue.opacity(0.12) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isHoveringChangePhoto ? Color.blue.opacity(0.6) : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(isHoveringChangePhoto ? .blue : .primary)
                                    .scaleEffect(isHoveringChangePhoto ? 1.03 : 1.0)
                                    .animation(.easeInOut(duration: 0.12), value: isHoveringChangePhoto)
                                }
                                .disabled(isUploading)
                                .onHover { hovering in
                                    #if os(macOS) || targetEnvironment(macCatalyst)
                                    withAnimation(.easeInOut(duration: 0.12)) {
                                        isHoveringChangePhoto = hovering
                                    }
                                    #endif
                                }
                                .onChange(of: photoItem) { _ in
                                    Task { await pickAndSaveLocally() }
                                }
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
                            
                            if let uploadError {
                                Text(uploadError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
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
                avatarURL = user?.avatarURL // fallback only
                loadLocalAvatar()
                fetchSightingCount()
            }
        }
    }
    
    // MARK: - Views
    
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 110, height: 110)
            Image(systemName: "person.fill")
                .font(.system(size: 50, weight: .semibold))
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Helpers
    
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
    
    // MARK: - Local avatar handling (no database, no storage)
    
    private func pickAndSaveLocally() async {
        uploadError = nil
        guard user != nil else { return }
        guard let item = photoItem else { return }
        
        isUploading = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Convert to JPEG for consistent storage and smaller size
                let jpegData = dataToJPEG(data: data) ?? data
                try saveLocalAvatar(data: jpegData)
                await MainActor.run {
                    self.localAvatarImage = UIImage(data: jpegData)
                    self.isUploading = false
                }
            } else {
                await MainActor.run {
                    self.isUploading = false
                    self.uploadError = "Couldn't read selected image."
                }
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.uploadError = "Save failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadLocalAvatar() {
        let url = localAvatarURL()
        guard let data = try? Data(contentsOf: url) else {
            self.localAvatarImage = nil
            return
        }
        self.localAvatarImage = UIImage(data: data)
    }
    
    private func saveLocalAvatar(data: Data) throws {
        let url = localAvatarURL()
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
    
    private func localAvatarURL() -> URL {
        // Use a per-user filename to avoid collisions when multiple users log in on same device
        let filename = "avatar_user_\(user?.id ?? 0).jpg"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("Avatars").appendingPathComponent(filename)
    }
    
    // Best-effort conversion to JPEG at reasonable quality.
    private func dataToJPEG(data: Data) -> Data? {
        #if canImport(UIKit)
        if let image = UIImage(data: data),
           let jpeg = image.jpegData(compressionQuality: 0.85) {
            return jpeg
        }
        #endif
        return nil
    }
}

