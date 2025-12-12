import Foundation

enum GeminiError: LocalizedError {
    case invalidURL
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL."
        case .noData: return "Veri alınamadı."
        case .apiError(let message): return message
        }
    }
}

struct GeminiRequest: Codable {
    struct Content: Codable {
        let role: String
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
    
    let contents: [Content]
}

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
    
    let candidates: [Candidate]?
}

class GeminiService {
    private let apiKey = Secrets.googleAIKey
    private let model = "gemini-1.5-flash-latest"
    
    private let systemPrompt = """
    Sen "Su İzim" adında bir uygulamanın yardımcı asistanısın.
    Görevin: Kullanıcılara su tasarrufu, kuraklık, baraj doluluk oranları ve sürdürülebilirlik hakkında bilgi vermektir.
    Tonun: Arkadaş canlısı, bilgilendirici ve motive edici olsun.
    Kısıtlamalar:
    - Su ve çevre konuları dışındaki sorulara nazikçe cevap veremeyeceğini söyle ve konuyu suya getir.
    - Cevapların kısa ve öz olsun (maksimum 3-4 cümle), mobilde okunması kolay olsun.
    - Asla politik veya tartışmalı konulara girme.
    """
    
    func sendMessage(history: [ChatbotView.ChatMessage], newMessage: String) async throws -> String {
        // Build URL
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        // Build request body
        var contents: [GeminiRequest.Content] = []
        
        // System prompt
        contents.append(GeminiRequest.Content(role: "user", parts: [GeminiRequest.Part(text: systemPrompt)]))
        contents.append(GeminiRequest.Content(role: "model", parts: [GeminiRequest.Part(text: "Anlaşıldı. Ben Su İzim asistanıyım.")]))
        
        // Recent history
        for msg in history.suffix(6) {
            let role = msg.isUser ? "user" : "model"
            contents.append(GeminiRequest.Content(role: role, parts: [GeminiRequest.Part(text: msg.text)]))
        }
        
        // Current message
        contents.append(GeminiRequest.Content(role: "user", parts: [GeminiRequest.Part(text: newMessage)]))
        
        let requestBody = GeminiRequest(contents: contents)
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Send request with retry
        var lastError: Error = GeminiError.noData
        
        for attempt in 1...3 {
            do {
                print("Gemini: Attempt \(attempt)/3...")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check HTTP status
                if let httpResponse = response as? HTTPURLResponse {
                    print("Gemini: HTTP Status = \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        if let errorBody = String(data: data, encoding: .utf8) {
                            print("Gemini Error Body: \(errorBody)")
                        }
                        throw GeminiError.apiError("HTTP \(httpResponse.statusCode)")
                    }
                }
                
                // Decode response
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                if let text = geminiResponse.candidates?.first?.content.parts.first?.text {
                    print("Gemini: Success!")
                    return text
                } else {
                    throw GeminiError.noData
                }
                
            } catch {
                print("Gemini: Attempt \(attempt) failed - \(error.localizedDescription)")
                lastError = error
                
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec
                }
            }
        }
        
        throw lastError
    }
}
