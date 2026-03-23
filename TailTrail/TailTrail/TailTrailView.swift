//
//  TailTrailView.swift
//  TailTrail
//
//

// TailTrailView.swift
import SwiftUI
import MapKit
import Supabase

struct TailTrailView: View {
    @State private var sightings: [Sighting] = []
    @State private var selectedSighting: Sighting?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSighting = false
    @State private var searchText = ""
    @State private var filteredSightings: [Sighting] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.888056, longitude: -119.495556),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isLoggedIn = false
    @State private var currentUser: String?
    @State private var showLogin = false
    @State private var showChat = false
    
    @State private var showProfile = false
    @State var currentUserData: SupabaseManager.User?
    
    var body: some View {
        ZStack {
            DogMapView(
                sightings: displayedSightings,
                selectedSighting: $selectedSighting,
                region: $region
            )
            .edgesIgnoringSafeArea(.all)
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Loading sightings...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.bottom, 80)
                }
            }
            
            // Success message  - optional
            if  selectedSighting != nil && showSuccessMessage {
                VStack {
                    Text("✓ Sighting added!")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            }
            
            // Top bar with refresh and search
            VStack {
                HStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Filter by breed...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 3)
                    .padding(.leading)
                    
                    // Refresh button
                    Button(action: loadSightings) {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Bottom Navigation Bar
            VStack {
                Spacer()
                
                HStack {
                    // Left - Profile Icon
                    Button(action: {
                        if isLoggedIn {
                            Task {
                                do {
                                    let users: [SupabaseManager.User] = try await SupabaseManager.shared.client
                                        .from("users")
                                        .select()
                                        .eq("username", value: currentUser ?? "")
                                        .execute()
                                        .value
                                    
                                    await MainActor.run {
                                        if let userData = users.first {
                                            currentUserData = userData
                                            print("User data loaded: \(userData.username)") // Debug
                                        } else {
                                            print("No user found with username: \(currentUser ?? "nil")")
                                        }
                                        showProfile = true
                                    }
                                } catch {
                                    print("Error fetching user data: \(error)")
                                    showProfile = true
                                }
                            }
                        }
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Middle - Plus in Circle
                    Button(action: {
                        showAddSighting = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Right - Messaging Icon
                    Button(action: {
                        if selectedSighting != nil {
                            showChat = true  // We'll add this state
                        }
                    }) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(selectedSighting != nil ? .blue : .gray.opacity(0.3))
                    }
                    .disabled(selectedSighting == nil)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 5, x: 0, y: -2))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showAddSighting) {
            AddSightingView(
                onAdd: { latitude, longitude, type, age, chipped, area, description, userId, isLost in
                    addNewSighting(
                        latitude: latitude,
                        longitude: longitude,
                        type: type,
                        age: age,
                        chipped: chipped,
                        area: area,
                        description: description,
                        userId: userId,
                        isLost: isLost
                    )
                },
                currentUserId: currentUserData?.id
            )
        }
        
        .sheet(isPresented: $showLogin) {
            LoginView(
                isLoggedIn: $isLoggedIn,
                currentUser: $currentUser,
                onLoginSuccess: { user in
                    currentUserData = user
                    print("Login success: \(user.username)") // Debug
                }
            )
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(
                isLoggedIn: $isLoggedIn,
                currentUser: $currentUser,
                user: currentUserData
            )
        }
        .sheet(isPresented: $showChat) {
            if let sighting = selectedSighting {
                ChatView(sighting: sighting)
            }
        }
        .onAppear {
            if !isLoggedIn {
                showLogin = true
            }
            loadSightings()
        }
        .onChange(of: isLoggedIn) {
            if !isLoggedIn {
                showLogin = true  // Show login when logged out
            }
        }
    }
    
    
    @State private var showSuccessMessage = false
    
    private var displayedSightings: [Sighting] {
        if searchText.isEmpty {
            return sightings
        } else {
            // Check if searching for "lost" or "found"
            let lowercasedSearch = searchText.lowercased()
            if lowercasedSearch == "lost" {
                return sightings.filter { $0.isLost }
            } else if lowercasedSearch == "found" || lowercasedSearch == "spotted" {
                return sightings.filter { !$0.isLost }
            } else {
                return sightings.filter { $0.type.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func addNewSighting(
        latitude: Double,
        longitude: Double,
        type: String,
        age: Int,
        chipped: String,
        area: String,
        description: String?,
        userId: Int?,
        isLost: Bool
    ) {
        isLoading = true
        
        Task {
            do {
                let newSighting = try await SupabaseManager.shared.createSighting(
                    latitude: latitude,
                    longitude: longitude,
                    type: type,
                    age: age,
                    chipped: chipped,
                    area: area,
                    description: description,
                    userId: userId,
                    isLost: isLost
                )
                
                await MainActor.run {
                    withAnimation {
                        sightings.insert(newSighting, at: 0)
                    }
                    showSuccessMessage = true
                    region = MKCoordinateRegion(
                        center: newSighting.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add sighting: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func loadSightings() {
        searchText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedSightings = try await SupabaseManager.shared.fetchSightings()
                await MainActor.run {
                    self.sightings = fetchedSightings
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load sightings: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}


#Preview {
    TailTrailView()
}
