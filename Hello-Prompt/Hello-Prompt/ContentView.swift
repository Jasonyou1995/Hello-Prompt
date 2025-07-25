//
//  ContentView.swift
//  Hello-Prompt
//
//  Created by Jason Y on 25/7/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Main Spotlight Content View
struct SpotlightContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var windowManager: SpotlightWindowManager
    @FocusState private var isWindowFocused: Bool
    
    var body: some View {
        ZStack {
            // Background with blur effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(20)
            
            // Main content
            VStack(spacing: 20) {
                // Siri-like Globe
                SiriGlobeView(
                    isRecording: audioRecorder.isRecording,
                    isProcessing: audioRecorder.isProcessing,
                    audioLevel: Double(audioRecorder.audioLevel)
                )
                .frame(width: 120, height: 120)
                
                // Status Text
                VStack(spacing: 8) {
                    Text(getStatusText())
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if audioRecorder.isProcessing {
                        Text(audioRecorder.processingStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Transcription Result (if available)
                if !audioRecorder.transcriptionText.isEmpty {
                    ScrollView {
                        Text(audioRecorder.transcriptionText)
                            .font(.body)
                            .padding()
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: 80)
                    .padding(.horizontal)
                }
                
                // AI Response (if available)
                if !audioRecorder.aiResponse.isEmpty {
                    ScrollView {
                        Text(audioRecorder.aiResponse)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: 100)
                    .padding(.horizontal)
                }
            }
            .padding(30)
        }
        .frame(width: 400, height: 300)
        .focused($isWindowFocused)
        .onAppear {
            setupAudioRecorder()
            isWindowFocused = true
        }
        .onKeyPress(.space, .return, .escape) { _ in
            handleKeyPress()
            return .handled
        }
    }
    
    private func getStatusText() -> String {
        if audioRecorder.isProcessing {
            return "Thinking..."
        } else if audioRecorder.isRecording {
            return "Listening..."
        } else if !audioRecorder.aiResponse.isEmpty {
            return "Ready"
        } else {
            return "Press and hold to speak"
        }
    }
    
    private func handleKeyPress() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
        }
        // Close window after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            windowManager.hideWindow()
        }
    }
    
    private func setupAudioRecorder() {
        // Request microphone permission immediately
        audioRecorder.requestMicrophonePermission { granted in
            if granted {
                print("✅ Microphone permission granted")
                // Auto-start recording when window appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    audioRecorder.startRecording()
                }
            } else {
                print("❌ Microphone permission denied")
            }
        }
    }
}

// MARK: - Siri Globe View
struct SiriGlobeView: View {
    let isRecording: Bool
    let isProcessing: Bool
    let audioLevel: Double
    
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .scaleEffect(pulseScale)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Animated waves (when recording)
            if isRecording {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 40 + CGFloat(index) * 20)
                        .scaleEffect(1.0 + audioLevel * 0.3 + CGFloat(index) * 0.1)
                        .opacity(0.7 - Double(index) * 0.2)
                        .animation(
                            Animation.easeInOut(duration: 0.8 + Double(index) * 0.2)
                                .repeatForever(autoreverses: true),
                            value: audioLevel
                        )
                }
            }
            
            // Central icon
            Image(systemName: getIconName())
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(getIconColor())
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isRecording)
        }
        .onAppear {
            pulseScale = isRecording ? 1.1 : 1.0
        }
        .onChange(of: isRecording) { _, newValue in
            pulseScale = newValue ? 1.1 : 1.0
        }
    }
    
    private func getIconName() -> String {
        if isProcessing {
            return "brain.head.profile"
        } else if isRecording {
            return "mic.fill"
        } else {
            return "mic"
        }
    }
    
    private func getIconColor() -> Color {
        if isProcessing {
            return .orange
        } else if isRecording {
            return .red
        } else {
            return .blue
        }
    }
}

// MARK: - Visual Effect View for macOS
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    init(material: NSVisualEffectView.Material = .hudWindow, 
         blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    SpotlightContentView()
        .environmentObject(SpotlightWindowManager())
}
