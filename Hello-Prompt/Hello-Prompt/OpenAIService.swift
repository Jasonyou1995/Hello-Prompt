import Foundation

// MARK: - Protocol for testability
protocol OpenAIServiceProtocol {
    func transcribeAudio(from url: URL) async throws -> String
    func processTranscription(_ text: String) async throws -> String
}

// MARK: - OpenAI API Models
struct TranscriptionRequest: Codable {
    let model: String = "whisper-1"
    let language: String?
    let prompt: String?
    let responseFormat: String = "json"
    let temperature: Double = 0.0
}

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatCompletionRequest: Codable {
    let model: String = "gpt-3.5-turbo"
    let messages: [ChatMessage]
    let temperature: Double = 0.7
    let maxTokens: Int = 500
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

// MARK: - Mock Service for Testing
class MockOpenAIService: OpenAIServiceProtocol {
    var shouldSimulateError = false
    var mockTranscriptionResult = "Hello, this is a mock transcription of your audio recording."
    var mockProcessingResult = "This is a mock AI response based on your transcription."
    
    func transcribeAudio(from url: URL) async throws -> String {
        print("🧪 MockOpenAIService: Simulating audio transcription...")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if shouldSimulateError {
            throw OpenAIServiceError.transcriptionFailed("Mock transcription error")
        }
        
        print("✅ Mock transcription completed: \(mockTranscriptionResult)")
        return mockTranscriptionResult
    }
    
    func processTranscription(_ text: String) async throws -> String {
        print("🧪 MockOpenAIService: Simulating AI processing...")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        if shouldSimulateError {
            throw OpenAIServiceError.processingFailed("Mock processing error")
        }
        
        let result = "Based on your input: '\(text)', here's the mock AI response: \(mockProcessingResult)"
        print("✅ Mock processing completed")
        return result
    }
}

// MARK: - Real OpenAI Service
class OpenAIService: OpenAIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    
    init() throws {
        // Try to get API key from environment variable
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
              !key.isEmpty else {
            throw OpenAIServiceError.missingAPIKey("OPENAI_API_KEY environment variable not set")
        }
        self.apiKey = key
        print("✅ OpenAIService initialized with API key")
    }
    
    func transcribeAudio(from url: URL) async throws -> String {
        print("🎙️ Starting audio transcription...")
        
        // Create multipart form data request
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Read audio file data
        let audioData = try Data(contentsOf: url)
        
        // Create multipart body
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIServiceError.invalidResponse("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw OpenAIServiceError.transcriptionFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            print("✅ Audio transcription completed")
            return transcriptionResponse.text
            
        } catch {
            print("❌ Transcription failed: \(error)")
            throw OpenAIServiceError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    func processTranscription(_ text: String) async throws -> String {
        print("🤖 Processing transcription with AI...")
        
        let messages = [
            ChatMessage(role: "system", content: "You are a helpful assistant that processes voice transcriptions and provides useful responses."),
            ChatMessage(role: "user", content: text)
        ]
        
        let requestBody = ChatCompletionRequest(messages: messages)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIServiceError.invalidResponse("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw OpenAIServiceError.processingFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
            guard let firstChoice = chatResponse.choices.first else {
                throw OpenAIServiceError.processingFailed("No response choices available")
            }
            
            print("✅ AI processing completed")
            return firstChoice.message.content
            
        } catch {
            print("❌ AI processing failed: \(error)")
            throw OpenAIServiceError.processingFailed(error.localizedDescription)
        }
    }
}

// MARK: - Error Types
enum OpenAIServiceError: Error, LocalizedError {
    case missingAPIKey(String)
    case transcriptionFailed(String)
    case processingFailed(String)
    case invalidResponse(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let message):
            return "API Key Error: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription Error: \(message)"
        case .processingFailed(let message):
            return "Processing Error: \(message)"
        case .invalidResponse(let message):
            return "Response Error: \(message)"
        }
    }
}

// MARK: - Service Factory
class OpenAIServiceFactory {
    static var useMockService = true // Set to false for production
    
    static func createService() -> OpenAIServiceProtocol {
        if useMockService {
            print("🧪 Using MockOpenAIService for testing")
            return MockOpenAIService()
        } else {
            do {
                print("🌐 Using real OpenAIService")
                return try OpenAIService()
            } catch {
                print("⚠️ Failed to create OpenAIService, falling back to mock: \(error)")
                return MockOpenAIService()
            }
        }
    }
}