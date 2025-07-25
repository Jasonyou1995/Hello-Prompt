import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
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
        print("🎯 Starting audio recording...")
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording-\(Date().timeIntervalSince1970).m4a")
        
        // macOS-compatible audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            
            // Prepare and start recording
            if audioRecorder?.prepareToRecord() == true {
                audioRecorder?.record()
                
                DispatchQueue.main.async {
                    self.isRecording = true
                    self.recordingURL = audioFilename
                }
                
                print("✅ Recording started successfully")
                print("📁 Recording to: \(audioFilename.lastPathComponent)")
            } else {
                print("❌ Failed to prepare recording")
            }
            
        } catch {
            print("❌ Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        print("🛑 Stopping audio recording...")
        
        audioRecorder?.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        print("✅ Recording stopped")
        if let url = recordingURL {
            print("💾 Recording saved to: \(url.lastPathComponent)")
            // Start processing the audio after recording stops
            Task {
                await processRecording(url: url)
            }
        }
    }
    
    // MARK: - Audio Processing
    @MainActor
    private func processRecording(url: URL) async {
        isProcessing = true
        transcriptionText = ""
        aiResponse = ""
        
        do {
            // Step 1: Transcribe audio
            processingStatus = "Transcribing audio..."
            print("🎯 Starting audio transcription...")
            
            let transcription = try await openAIService.transcribeAudio(from: url)
            transcriptionText = transcription
            
            print("📝 Transcription: \(transcription)")
            
            // Step 2: Process transcription with AI
            processingStatus = "Processing with AI..."
            print("🤖 Processing transcription with AI...")
            
            let response = try await openAIService.processTranscription(transcription)
            aiResponse = response
            
            print("🎉 AI Response: \(response)")
            processingStatus = "Complete!"
            
        } catch {
            print("❌ Processing failed: \(error.localizedDescription)")
            processingStatus = "Error: \(error.localizedDescription)"
            aiResponse = "Processing failed: \(error.localizedDescription)"
        }
        
        // Keep the processing status visible for a moment, then clear it
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isProcessing = false
            self.processingStatus = ""
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