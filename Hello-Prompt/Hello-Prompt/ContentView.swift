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
            
            if let url = audioRecorder.recordingURL {
                Text("Recording saved: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
        }
        .padding()
        .onAppear {
            print("🎬 ContentView appeared - checking microphone permissions")
            audioRecorder.requestMicrophonePermission { granted in
                hasPermission = granted
            }
        }
    }
}

#Preview {
    ContentView()
}
