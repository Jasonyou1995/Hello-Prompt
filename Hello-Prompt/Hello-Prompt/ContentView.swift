//
//  ContentView.swift
//  Hello-Prompt
//
//  Created by Jason Y on 25/7/2025.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var hotkeyManager = NativeHotkeyManager()
    @State private var hasPermission = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: audioRecorder.isRecording ? "mic.fill" : "mic")
                .imageScale(.large)
                .foregroundStyle(audioRecorder.isRecording ? .red : .blue)
                .font(.system(size: 50))
            
            Text(audioRecorder.isRecording ? "Recording..." : "Ready to Record")
                .font(.headline)
                .foregroundColor(audioRecorder.isRecording ? .red : .primary)
            
            if hasPermission {
                Button(action: {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "record.circle")
                        Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                    }
                    .padding()
                    .background(audioRecorder.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                Button("Request Microphone Permission") {
                    audioRecorder.requestMicrophonePermission { granted in
                        hasPermission = granted
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Processing Status
            if audioRecorder.isProcessing {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(audioRecorder.processingStatus)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            
            // Transcription Result
            if !audioRecorder.transcriptionText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        Text(audioRecorder.transcriptionText)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 100)
                }
                .padding(.horizontal)
            }
            
            // AI Response
            if !audioRecorder.aiResponse.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Response:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        Text(audioRecorder.aiResponse)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
                .padding(.horizontal)
            }
            
            if let url = audioRecorder.recordingURL {
                Text("Recording saved: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
            
            // Hotkey Controls
            VStack(spacing: 8) {
                Text("Global Hotkey")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(hotkeyManager.currentHotkey.description)
                    .font(.body)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                
                Text("Status: \(hotkeyManager.registrationStatus)")
                    .font(.caption)
                    .foregroundColor(hotkeyManager.registrationStatus.contains("Active") ? .green : .orange)
                
                HStack {
                    Button(hotkeyManager.registrationStatus.contains("Active") ? "Disable Hotkey" : "Enable Hotkey") {
                        if hotkeyManager.registrationStatus.contains("Active") {
                            hotkeyManager.unregisterHotkey()
                        } else {
                            hotkeyManager.registerHotkey()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(hotkeyManager.registrationStatus.contains("Active") ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Developer Testing Controls
            VStack {
                Text("Testing Controls")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Button("Use Mock Service") {
                        OpenAIServiceFactory.useMockService = true
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(OpenAIServiceFactory.useMockService ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                    
                    Button("Use Real Service") {
                        OpenAIServiceFactory.useMockService = false
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!OpenAIServiceFactory.useMockService ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                }
            }
            .padding(.top)
        }
        .padding()
        .onAppear {
            print("🎬 ContentView appeared - checking microphone permissions")
            audioRecorder.requestMicrophonePermission { granted in
                hasPermission = granted
            }
            
            // Set up hotkey manager
            print("🎹 Setting up hotkey manager delegate")
            hotkeyManager.delegate = audioRecorder
            hotkeyManager.registerHotkey()
        }
    }
}

#Preview {
    ContentView()
}
