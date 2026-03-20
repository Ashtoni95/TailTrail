//
//  LoginView.swift
//  TailTrail
//
//

// Views/LoginView.swift
import SwiftUI
import CryptoKit

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: String?
    var onLoginSuccess: ((SupabaseManager.User) -> Void)?
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("🐕")
                        .font(.system(size: 80))
                    Text("Tail Trail")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Sign in to report sightings")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 40)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Login Button
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                .disabled(isLoading)
                
                // Test User Quick Fill
                VStack(spacing: 5) {
                    Text("Test Account:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        email = "test@example.com"
                        password = "password"
                    }) {
                        Text("Tap to fill test credentials")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Simple footer
                Text("Demo App • Test User Only")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let hashedPassword = hashPassword(password)
                let user = try await SupabaseManager.shared.authenticateUser(
                    email: email,
                    hashedPassword: hashedPassword
                )
                
                await MainActor.run {
                    isLoading = false
                    if let user = user {
                        SupabaseManager.shared.currentUserId = user.id
                        
                        onLoginSuccess?(user)
                        currentUser = user.username
                        isLoggedIn = true
                        dismiss()
                    } else {
                        errorMessage = "Invalid email or password"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Login failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
