import SwiftUI

@MainActor
class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatbotView.ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var errorMessage: String?
    
    private let geminiService = GeminiService()
    
    init() {
        // Initial Greeting
        messages.append(ChatbotView.ChatMessage(text: "Merhaba! Ben Su İzim asistanı. Su tasarrufu, barajlar veya sürdürülebilirlik hakkında bana her şeyi sorabilirsin. 🌱💧", isUser: false))
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // 1. Add user message immediately
        let userMsg = ChatbotView.ChatMessage(text: text, isUser: true)
        withAnimation {
            messages.append(userMsg)
        }
        inputText = ""
        isTyping = true
        errorMessage = nil
        
        // 2. Call API asynchronously
        Task {
            do {
                // Pass current history for context (excluding the just added user msg if we handle it inside service,
                // but service expects history. Let's pass all distinct messages)
                let responseText = try await geminiService.sendMessage(history: messages, newMessage: text)
                
                withAnimation {
                    isTyping = false
                    messages.append(ChatbotView.ChatMessage(text: responseText, isUser: false))
                }
            } catch {
                print("Gemini API Error Detail: \(error)") // DEBUG: Hatanın gerçek sebebini konsola yaz
                withAnimation {
                    isTyping = false
                    errorMessage = "Bir hata oluştu: \(error.localizedDescription)"
                    messages.append(ChatbotView.ChatMessage(text: "Hata Detayı: \(error.localizedDescription)", isUser: false))
                }
            }
        }
    }
}
