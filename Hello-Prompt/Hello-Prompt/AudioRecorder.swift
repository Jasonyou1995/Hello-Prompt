import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, HotkeyActionProtocol {
    private var audioRecorder: AVAudioRecorder?
    private let openAIService: OpenAIServiceProtocol
    
    @Published var isRecording = false
    @Published var recordingURL: URL?
    @Published var transcriptionText: String = ""
    @Published var aiResponse: String = ""
    @Published var isProcessing = false
    @Published var processingStatus: String = ""
    
    override init() {
        self.openAIService = OpenAIServiceFactory.createService()
        super.init()
        print("🎤 AudioRecorder initialized for macOS")
    }
    
    // Initializer for dependency injection (useful for testing)
    init(openAIService: OpenAIServiceProtocol) {
        self.openAIService = openAIService
        super.init()
        print("🎤 AudioRecorder initialized with custom OpenAI service")
    }
    
    // MARK: - HotkeyActionProtocol
    func handleHotkeyPressed() {
        let hotkeyId = UUID().uuidString.prefix(8)
        print("⌨️ [\(hotkeyId)] Hotkey activated - toggling recording state")
        print("⌨️ [\(hotkeyId)] Current recording state: \(isRecording)")
        
        DispatchQueue.main.async {
            if self.isRecording {
                print("⌨️ [\(hotkeyId)] Stopping recording via hotkey")
                self.stopRecording()
            } else {
                print("⌨️ [\(hotkeyId)] Starting recording via hotkey")
                self.startRecording()
            }
        }
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("✅ Microphone permission already granted")
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Microphone permission granted")
                    } else {
                        print("❌ Microphone permission denied")
                    }
                    completion(granted)
                }
            }
        case .denied, .restricted:
            print("❌ Microphone permission denied or restricted")
            completion(false)
        @unknown default:
            print("❌ Unknown microphone permission status")
            completion(false)
        }
    }
    
    func startRecording() {
        let sessionId = UUID().uuidString.prefix(8)
        print("🎯 [\(sessionId)] Starting audio recording session")
        print("🎯 [\(sessionId)] Current recording state: \(isRecording)")
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let audioFilename = documentsPath.appendingPathComponent("recording-\(timestamp).m4a")
        
        print("📁 [\(sessionId)] Documents path: \(documentsPath.path)")
        print("📁 [\(sessionId)] Audio filename: \(audioFilename.lastPathComponent)")
        print("📁 [\(sessionId)] Full path: \(audioFilename.path)")
        
        // macOS-compatible audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        print("🎧 [\(sessionId)] Audio settings: \(settings)")
        
        do {
            let startTime = Date()
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            
            print("🎧 [\(sessionId)] AVAudioRecorder created successfully")
            print("🎧 [\(sessionId)] Delegate set to self")
            
            // Prepare and start recording
            let prepareTime = Date()
            if audioRecorder?.prepareToRecord() == true {
                let prepareDuration = Date().timeIntervalSince(prepareTime)
                print("✅ [\(sessionId)] Audio recorder prepared in \(String(format: "%.3f", prepareDuration))s")
                
                let recordTime = Date()
                audioRecorder?.record()
                let recordDuration = Date().timeIntervalSince(recordTime)
                
                DispatchQueue.main.async {
                    self.isRecording = true
                    self.recordingURL = audioFilename
                }
                
                let totalStartupTime = Date().timeIntervalSince(startTime)
                print("✅ [\(sessionId)] Recording started successfully in \(String(format: "%.3f", totalStartupTime))s")
                print("📁 [\(sessionId)] Recording to: \(audioFilename.lastPathComponent)")
                print("🗓 [\(sessionId)] Session timestamp: \(timestamp)")
            } else {
                print("❌ [\(sessionId)] Failed to prepare recording")
                print("❌ [\(sessionId)] Audio recorder state: \(audioRecorder?.isRecording ?? false)")
            }
            
        } catch {
            print("❌ [\(sessionId)] Failed to start recording: \(error.localizedDescription)")
            print("❌ [\(sessionId)] Error domain: \((error as NSError).domain)")
            print("❌ [\(sessionId)] Error code: \((error as NSError).code)")
        }
    }
    
    func stopRecording() {
        let sessionId = UUID().uuidString.prefix(8)
        let stopTime = Date()
        
        print("🛑 [\(sessionId)] Stopping audio recording session")
        print("🛑 [\(sessionId)] Current recording state: \(isRecording)")
        
        guard let recorder = audioRecorder else {
            print("⚠️ [\(sessionId)] No audio recorder instance found")
            return
        }
        
        print("🛑 [\(sessionId)] Recorder is currently recording: \(recorder.isRecording)")
        
        if recorder.isRecording {
            recorder.stop()
            let stopDuration = Date().timeIntervalSince(stopTime)
            print("✅ [\(sessionId)] Audio recorder stopped in \(String(format: "%.3f", stopDuration))s")
        } else {
            print("⚠️ [\(sessionId)] Recorder was not in recording state")
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        print("✅ [\(sessionId)] Recording session completed")
        if let url = recordingURL {
            // Check if file was actually created
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            print("💾 [\(sessionId)] Recording file exists: \(fileExists)")
            
            if fileExists {
                do {
                    let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
                    print("💾 [\(sessionId)] Recording file size: \(fileSize) bytes")
                    print("💾 [\(sessionId)] Recording saved to: \(url.lastPathComponent)")
                    
                    // Start processing the audio after recording stops
                    Task {
                        await processRecording(url: url)
                    }
                } catch {
                    print("⚠️ [\(sessionId)] Could not read file attributes: \(error.localizedDescription)")
                }
            } else {
                print("❌ [\(sessionId)] Recording file was not created at expected path")
            }
        } else {
            print("⚠️ [\(sessionId)] No recording URL available")
        }
    }
    
    // MARK: - Audio Processing
    @MainActor
    private func processRecording(url: URL) async {
        let processingId = UUID().uuidString.prefix(8)
        let startTime = Date()
        
        print("🚀 [\(processingId)] Starting audio processing pipeline")
        print("🚀 [\(processingId)] Processing file: \(url.lastPathComponent)")
        
        isProcessing = true
        transcriptionText = ""
        aiResponse = ""
        
        do {
            // Step 1: Transcribe audio
            processingStatus = "Transcribing audio..."
            let transcriptionStartTime = Date()
            print("🎯 [\(processingId)] Step 1: Starting audio transcription")
            
            let transcription = try await openAIService.transcribeAudio(from: url, model: .whisper1)
            transcriptionText = transcription
            
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStartTime)
            print("📝 [\(processingId)] Transcription completed in \(String(format: "%.2f", transcriptionDuration))s")
            print("📝 [\(processingId)] Transcription length: \(transcription.count) characters")
            print("📝 [\(processingId)] Transcription: \(transcription)")
            
            // Step 2: Process transcription with AI
            processingStatus = "Processing with AI..."
            let aiStartTime = Date()
            print("🤖 [\(processingId)] Step 2: Starting AI processing")
            
            let response = try await openAIService.processTranscription(transcription, model: .gpt4o)
            aiResponse = response
            
            let aiDuration = Date().timeIntervalSince(aiStartTime)
            let totalDuration = Date().timeIntervalSince(startTime)
            
            print("🤖 [\(processingId)] AI processing completed in \(String(format: "%.2f", aiDuration))s")
            print("🎉 [\(processingId)] Total processing time: \(String(format: "%.2f", totalDuration))s")
            print("🎉 [\(processingId)] AI Response length: \(response.count) characters")
            print("🎉 [\(processingId)] AI Response: \(response)")
            processingStatus = "Complete!"
            
        } catch {
            let totalDuration = Date().timeIntervalSince(startTime)
            print("❌ [\(processingId)] Processing failed after \(String(format: "%.2f", totalDuration))s")
            print("❌ [\(processingId)] Error: \(error.localizedDescription)")
            
            if let openAIError = error as? OpenAIServiceError {
                print("❌ [\(processingId)] OpenAI Error Type: \(openAIError)")
            }
            
            processingStatus = "Error: \(error.localizedDescription)"
            aiResponse = "Processing failed: \(error.localizedDescription)"
        }
        
        // Keep the processing status visible for a moment, then clear it
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isProcessing = false
            self.processingStatus = ""
            print("🏁 [\(processingId)] Processing pipeline completed")
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("✅ Audio recording finished successfully")
            // Process the recording if it was successful
            if let url = recordingURL {
                Task {
                    await processRecording(url: url)
                }
            }
        } else {
            print("❌ Audio recording failed")
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Audio recording error: \(error?.localizedDescription ?? "Unknown error")")
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}