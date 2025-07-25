import Foundation

// MARK: - Model Selection
// Provides easy selection of models for different tasks.

/// Transcription models from OpenAI.
enum TranscriptionModel: String, CaseIterable {
    /// The latest Whisper model, optimized for speech-to-text.
    case whisper1 = "whisper-1"
    // Currently, whisper-1 is the only model available for the Transcription API.
    // New models can be added here as they are released.
}

/// Chat completion models from OpenAI, ordered by capability (most capable first).
enum ChatModel: String, CaseIterable {
    /// Most advanced, multimodal, and cost-effective model. Best for complex tasks.
    case gpt4o = "gpt-4o"
    /// Highly capable model, successor to GPT-4.
    case gpt4Turbo = "gpt-4-turbo"
    /// Fast, affordable, and capable model for a wide range of tasks.
    case gpt35Turbo = "gpt-3.5-turbo"
}

/// Text-to-Speech (TTS) models from OpenAI.
enum TTSModel: String, CaseIterable {
    /// Standard quality, low-latency model.
    case tts1 = "tts-1"
    /// High-definition quality model.
    case tts1HD = "tts-1-hd"
}

/// Represents the available voices for Text-to-Speech.
enum TTSVoice: String, CaseIterable {
    case alloy, echo, fable, onyx, nova, shimmer
}

// MARK: - Protocol for testability
protocol OpenAIServiceProtocol {
    func transcribeAudio(from url: URL, model: TranscriptionModel) async throws -> String
    func processTranscription(_ text: String, model: ChatModel) async throws -> String
    /// This function performs text-to-speech. A full speech-to-speech implementation
    /// would involve chaining transcription, processing, and this speech generation.
    func generateSpeech(from text: String, model: TTSModel, voice: TTSVoice) async throws -> Data
}

// MARK: - OpenAI API Models
struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double = 0.7
    let maxTokens: Int? = 1000
    
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

struct TTSRequest: Codable {
    let model: String
    let input: String
    let voice: String
}

// MARK: - Mock Service for Testing
class MockOpenAIService: OpenAIServiceProtocol {
    var shouldSimulateError = false
    var mockTranscriptionResult = "Hello, this is a mock transcription of your audio recording."
    var mockProcessingResult = "This is a mock AI response based on your transcription."
    
    func transcribeAudio(from url: URL, model: TranscriptionModel) async throws -> String {
        let operationId = UUID().uuidString.prefix(8)
        print("🧪 [\(operationId)] MockOpenAIService: Starting audio transcription simulation")
        print("🧪 [\(operationId)] Model: \(model.rawValue)")
        print("🧪 [\(operationId)] Audio file: \(url.lastPathComponent)")
        
        // Log file info
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            print("🧪 [\(operationId)] Audio file size: \(fileSize) bytes")
        } catch {
            print("⚠️ [\(operationId)] Could not read file attributes: \(error)")
        }
        
        let startTime = Date()
        print("🧪 [\(operationId)] Simulating network delay (1 second)...")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if shouldSimulateError {
            print("❌ [\(operationId)] Simulating transcription error")
            throw OpenAIServiceError.transcriptionFailed("Mock transcription error for testing")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("✅ [\(operationId)] Mock transcription completed in \(String(format: "%.2f", duration))s")
        print("📝 [\(operationId)] Result length: \(mockTranscriptionResult.count) characters")
        print("📝 [\(operationId)] Transcription: \(mockTranscriptionResult)")
        return mockTranscriptionResult
    }
    
    func processTranscription(_ text: String, model: ChatModel) async throws -> String {
        let operationId = UUID().uuidString.prefix(8)
        print("🧪 [\(operationId)] MockOpenAIService: Starting AI processing simulation")
        print("🧪 [\(operationId)] Model: \(model.rawValue)")
        print("🧪 [\(operationId)] Input length: \(text.count) characters")
        print("🧪 [\(operationId)] Input text: \(text.prefix(100))\(text.count > 100 ? "..." : "")")
        
        let startTime = Date()
        print("🧪 [\(operationId)] Simulating network delay (1.5 seconds)...")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        if shouldSimulateError {
            print("❌ [\(operationId)] Simulating processing error")
            throw OpenAIServiceError.processingFailed("Mock processing error for testing")
        }
        
        let result = "Based on your input: '\(text)', here's the mock AI response: \(mockProcessingResult)"
        let duration = Date().timeIntervalSince(startTime)
        
        print("✅ [\(operationId)] Mock processing completed in \(String(format: "%.2f", duration))s")
        print("🤖 [\(operationId)] Response length: \(result.count) characters")
        print("🤖 [\(operationId)] AI Response: \(result)")
        return result
    }

    func generateSpeech(from text: String, model: TTSModel, voice: TTSVoice) async throws -> Data {
        let operationId = UUID().uuidString.prefix(8)
        print("🧪 [\(operationId)] MockOpenAIService: Starting TTS simulation")
        print("🧪 [\(operationId)] Model: \(model.rawValue), Voice: \(voice.rawValue)")
        print("🧪 [\(operationId)] Text length: \(text.count) characters")
        print("🧪 [\(operationId)] Text to synthesize: \(text.prefix(100))\(text.count > 100 ? "..." : "")")
        
        let startTime = Date()
        print("🧪 [\(operationId)] Simulating TTS processing (1 second)...")
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if shouldSimulateError {
            print("❌ [\(operationId)] Simulating TTS error")
            throw OpenAIServiceError.ttsFailed("Mock TTS error for testing")
        }
        
        let mockData = "This is mock audio data for: \(text.prefix(50))".data(using: .utf8)!
        let duration = Date().timeIntervalSince(startTime)
        
        print("✅ [\(operationId)] Mock TTS completed in \(String(format: "%.2f", duration))s")
        print("🔊 [\(operationId)] Generated mock audio data: \(mockData.count) bytes")
        return mockData
    }
}

// MARK: - Real OpenAI Service
class OpenAIService: OpenAIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    
    init() throws {
        // Updated to load API key from the app's Info.plist.
        // Ensure you have `OPENAI_API_KEY = "your-key"` in your `Config.xcconfig`
        // and have linked it to your project's `Info.plist`.
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty, key != "YOUR_API_KEY_PLACEHOLDER" else {
            throw OpenAIServiceError.missingAPIKey("OPENAI_API_KEY not found in Info.plist or is a placeholder. Please check your Config.xcconfig file.")
        }
        self.apiKey = key
        print("✅ OpenAIService initialized with API key")
    }
    
    func transcribeAudio(from url: URL, model: TranscriptionModel) async throws -> String {
        print("🎙️ Starting audio transcription with model \(model.rawValue)...")
        
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
        body.append("\(model.rawValue)\r\n".data(using: .utf8)!)
        
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
    
    func processTranscription(_ text: String, model: ChatModel) async throws -> String {
        print("🤖 Processing transcription with AI model \(model.rawValue)...")
        
        let messages = [
            ChatMessage(role: "system", content: "You are a helpful assistant. You are running inside a native macOS app."),
            ChatMessage(role: "user", content: text)
        ]
        
        let requestBody = ChatCompletionRequest(model: model.rawValue, messages: messages)
        
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

    func generateSpeech(from text: String, model: TTSModel, voice: TTSVoice) async throws -> Data {
        print("🗣️ Generating speech with model \(model.rawValue) and voice \(voice.rawValue)...")
        
        let requestBody = TTSRequest(model: model.rawValue, input: text, voice: voice.rawValue)
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/speech")!)
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
                throw OpenAIServiceError.ttsFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            print("✅ Speech generation completed")
            return data
            
        } catch {
            print("❌ Speech generation failed: \(error)")
            throw OpenAIServiceError.ttsFailed(error.localizedDescription)
        }
    }
}

// MARK: - Error Types
enum OpenAIServiceError: Error, LocalizedError {
    case missingAPIKey(String)
    case transcriptionFailed(String)
    case processingFailed(String)
    case ttsFailed(String)
    case invalidResponse(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let message):
            return "API Key Error: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription Error: \(message)"
        case .processingFailed(let message):
            return "Processing Error: \(message)"
        case .ttsFailed(let message):
            return "Text-to-Speech Error: \(message)"
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
                // In a real app, you might want to handle this more gracefully,
                // perhaps by notifying the user that the service is unavailable.
                return MockOpenAIService()
            }
        }
    }
}