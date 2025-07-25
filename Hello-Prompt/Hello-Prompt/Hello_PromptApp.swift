//
//  Hello_PromptApp.swift
//  Hello-Prompt
//
//  Created by Jason Y on 25/7/2025.
//

import SwiftUI

@main
struct Hello_PromptApp: App {
    private let hotkeyManager = HotkeyManager()
    
    var body: some Scene {
        MenuBarExtra("Hello Prompt", systemImage: "star") {
            ContentView()
                .onAppear {
                    print("🎉 App launched! Setting up hotkey manager...")
                    hotkeyManager.setupHotkey()
                    print("🎯 Check console for hotkey registration status")
                }
        }
    }
}
