//
//  ChatView.swift
//  TailTrail
//
// Views/ChatView.swift
import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    let sighting: Sighting
    
    @State private var messages: [Message] = []
    @State private var newMessageText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat header with dog info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sighting.type)
                            .font(.headline)
                        HStack {
                            Text(sighting.area)
                                .font(.caption)
                                .foregroundColor(.gray)
                            if sighting.isLost {
                                Text("• LOST")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    Spacer()
                    Text(sighting.isLost ? "🆘" : "🐕")
                        .font(.title)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 2, y: 1)
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Message input area
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        TextField("Type a message...", text: $newMessageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .disabled(isLoading)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .frame(width: 40, height: 40)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(newMessageText.isEmpty ? .gray : .blue)
                                    .frame(width: 40, height: 40)
                            }
                        }
                        .disabled(newMessageText.isEmpty || isLoading)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Conversation")
                        .font(.headline)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        isLoading = true
        Task {
            do {
                let fetchedMessages = try await SupabaseManager.shared.fetchMessages(for: sighting.id)
                await MainActor.run {
                    messages = fetchedMessages
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load messages: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        isLoading = true
        let originalText = newMessageText
        newMessageText = ""
        
        Task {
            do {
                let newMessage = try await SupabaseManager.shared.sendMessage(
                    to: sighting.id,
                    message: messageText
                )
                
                await MainActor.run {
                    messages.append(newMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    newMessageText = originalText
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: Message
    @State private var showTime = false
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Username for others' messages
                if !message.isFromCurrentUser && !message.isSystemMessage {
                    Text("User \(message.userId ?? 0)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
                
                // Message content
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isSystemMessage ?
                        Color.gray.opacity(0.2) :
                        (message.isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    )
                    .foregroundColor(message.isSystemMessage ? .primary : (message.isFromCurrentUser ? .white : .primary))
                    .cornerRadius(16)
                    .onTapGesture {
                        withAnimation {
                            showTime.toggle()
                        }
                    }
                
                // Timestamp (shows on tap)
                if showTime {
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            }
            
            if !message.isFromCurrentUser && !message.isSystemMessage {
                Spacer(minLength: 60)
            }
        }
        .padding(.vertical, 2)
    }
}


