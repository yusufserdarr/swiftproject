import SwiftUI

struct ChatbotView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Merhaba! Ben Su İzim asistanı. Sana nasıl yardımcı olabilirim?", isUser: false)
    ]
    @State private var inputText: String = ""
    
    struct ChatMessage: Identifiable {
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
                                ForEach(messages) { message in
                                    HStack(alignment: .bottom, spacing: 8) {
                                        if message.isUser { Spacer() }
                                        
                                        if !message.isUser {
                                            Image(systemName: "drop.fill")
                                                .foregroundStyle(.blue)
                                                .padding(8)
                                                .background(.white)
                                                .clipShape(Circle())
                                                .shadow(radius: 1)
                                        }
                                        
                                        Text(message.text)
                                            .padding(12)
                                            .background(message.isUser ? Color.blue : Color.white)
                                            .foregroundStyle(message.isUser ? .white : .primary)
                                            .cornerRadius(20)
                                            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        
                                        if !message.isUser { Spacer() }
                                    }
                                    .padding(.horizontal)
                                    .id(message.id)
                                }
                            }
                            .padding(.vertical)
                        }
                        .onChange(of: messages.count) {
                            if let lastId = messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    VStack {
                        HStack(spacing: 12) {
                            TextField("Bir şeyler sor...", text: $inputText)
                                .padding(12)
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20))
                                    .padding(12)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
                    }
                }
            }
            .navigationTitle("Asistan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func sendMessage() {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        
        withAnimation {
            messages.append(ChatMessage(text: userText, isUser: true))
        }
        inputText = ""
        
        // Simple rule-based response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = generateResponse(for: userText)
            withAnimation {
                messages.append(ChatMessage(text: response, isUser: false))
            }
        }
    }
    
    private func generateResponse(for text: String) -> String {
        let lowerText = text.lowercased()
        
        if lowerText.contains("merhaba") || lowerText.contains("selam") {
            return "Merhaba! Su tasarrufu hakkında konuşmak ister misin?"
        } else if lowerText.contains("tasarruf") || lowerText.contains("öneri") {
            return SuggestionEngine.getRandomTip()
        } else if lowerText.contains("duş") {
            return "Duş süresini 1 dakika kısaltmak yaklaşık 12 litre su tasarrufu sağlar."
        } else if lowerText.contains("bulaşık") {
            return "Bulaşıkları makinede yıkamak, elde yıkamaya göre çok daha az su harcar."
        } else {
            return "Bunu tam anlayamadım ama su tasarrufu için kısa duş almayı ve muslukları kapatmayı unutma!"
        }
    }
}

#Preview {
    ChatbotView()
}
