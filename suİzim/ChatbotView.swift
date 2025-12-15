/*
import SwiftUI

import SwiftUI

struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @FocusState private var isFocused: Bool
    
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                }
                                
                                if viewModel.isTyping {
                                    HStack {
                                        TypingIndicatorView()
                                            .padding(.leading)
                                        Spacer()
                                    }
                                    .id("TypingIndicator")
                                }
                                
                                // Invisible footer for scrolling
                                Color.clear.frame(height: 1).id("Bottom")
                            }
                            .padding(.vertical)
                        }
                        .onChange(of: viewModel.messages) {
                             scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: viewModel.isTyping) {
                            if viewModel.isTyping {
                                withAnimation {
                                    proxy.scrollTo("TypingIndicator", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            TextField("Su hakkında bir soru sor...", text: $viewModel.inputText)
                                .focused($isFocused)
                                .padding(12)
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .submitLabel(.send)
                                .onSubmit {
                                    viewModel.sendMessage()
                                }
                            
                            Button(action: viewModel.sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20))
                                    .padding(12)
                                    .background(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                }
            }
            .navigationTitle("Asistan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo("Bottom", anchor: .bottom)
        }
    }
}

// MARK: - Subviews
struct MessageBubble: View {
    let message: ChatbotView.ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer() }
            
            if !message.isUser {
                Image(systemName: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
                    .shadow(radius: 1)
            }
            
            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(message.isUser ? .white : .primary)
                .cornerRadius(18)
                // Add tiny tail logic only if needed, for now rounded is modern
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            if message.isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

struct TypingIndicatorView: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(.gray.opacity(0.5))
                    .scaleEffect(offset == CGFloat(index) ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: offset)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(18)
        .onAppear {
            offset = 1 // Start animation trigger
        }
    }
}

#Preview {
    ChatbotView()
}
    





#Preview {
    ChatbotView()
}
*/
