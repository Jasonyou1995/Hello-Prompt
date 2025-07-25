//
//  Hello_PromptApp.swift
//  Hello-Prompt
//
//  Created by Jason Y on 25/7/2025.
//

import SwiftUI

@main
struct Hello_PromptApp: App {
    @StateObject private var windowManager = SpotlightWindowManager()
    
    var body: some Scene {
        // Hidden main window - we don't want any visible windows by default
        Settings {
            EmptyView()
        }
    }
}

// MARK: - Spotlight Window Manager
class SpotlightWindowManager: ObservableObject {
    private var window: NSWindow?
    private let hotkeyManager = HotkeyManager()
    
    init() {
        print("🌟 SpotlightWindowManager: Initializing")
        setupSpotlightWindow()
        setupHotkey()
    }
    
    private func setupSpotlightWindow() {
        // Create the main content view
        let contentView = SpotlightContentView()
            .environmentObject(self)
        
        // Create NSWindow with spotlight-like properties
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { return }
        
        // Configure window appearance
        window.contentView = NSHostingView(rootView: contentView)
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Initially hidden
        window.orderOut(nil)
        
        print("✅ SpotlightWindowManager: Window created and configured")
    }
    
    private func setupHotkey() {
        print("🎹 SpotlightWindowManager: Setting up hotkey")
        hotkeyManager.setupHotkey()
        
        // Listen for hotkey events
        NotificationCenter.default.addObserver(
            forName: .hotkeyActivated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.toggleWindow()
        }
    }
    
    func showWindow() {
        guard let window = window else { return }
        
        // Center window on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2 + 100 // Slightly above center like Spotlight
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("🌟 SpotlightWindowManager: Window shown")
    }
    
    func hideWindow() {
        guard let window = window else { return }
        window.orderOut(nil)
        print("🌟 SpotlightWindowManager: Window hidden")
    }
    
    private func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
}

// MARK: - Hotkey Manager
class HotkeyManager {
    func setupHotkey() {
        // This integrates with the existing KeyboardShortcutsManager
        // We'll post a notification when hotkey is activated
        let shortcutsManager = KeyboardShortcutsManager()
        shortcutsManager.onToggleRecording = {
            NotificationCenter.default.post(name: .hotkeyActivated, object: nil)
        }
        shortcutsManager.startListening()
        print("🎹 HotkeyManager: Setup completed")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let hotkeyActivated = Notification.Name("hotkeyActivated")
}
