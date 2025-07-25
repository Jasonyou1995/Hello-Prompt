import Foundation
import KeyboardShortcuts

// MARK: - Keyboard Shortcut Names
extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording")
}

// MARK: - Keyboard Shortcuts Manager
class KeyboardShortcutsManager: ObservableObject {
    private var isListenerActive = false
    
    // Callback for when hotkey is pressed
    var onToggleRecording: (() -> Void)?
    
    init() {
        print("🎹 KeyboardShortcutsManager: Initialized")
        setupDefaultShortcut()
    }
    
    deinit {
        stopListening()
        print("🎹 KeyboardShortcutsManager: Deinitialized")
    }
    
    // MARK: - Public Methods
    
    /// Start listening for the keyboard shortcut
    func startListening() {
        guard !isListenerActive else {
            print("⚠️ KeyboardShortcutsManager: Already listening")
            return
        }
        
        print("🎹 KeyboardShortcutsManager: Starting to listen for shortcuts")
        
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            print("🎯 KeyboardShortcutsManager: Toggle recording shortcut activated")
            DispatchQueue.main.async {
                self?.onToggleRecording?()
            }
        }
        
        isListenerActive = true
        print("✅ KeyboardShortcutsManager: Now listening for shortcuts")
    }
    
    /// Stop listening for the keyboard shortcut
    func stopListening() {
        guard isListenerActive else {
            print("⚠️ KeyboardShortcutsManager: Not currently listening")
            return
        }
        
        print("🎹 KeyboardShortcutsManager: Stopping shortcut listener")
        KeyboardShortcuts.disable(.toggleRecording)
        isListenerActive = false
        print("✅ KeyboardShortcutsManager: Stopped listening for shortcuts")
    }
    
    /// Get the current keyboard shortcut as a string
    func getCurrentShortcutDescription() -> String {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleRecording) {
            return shortcut.description
        }
        return "No shortcut set"
    }
    
    /// Check if a shortcut is currently set
    func hasShortcutSet() -> Bool {
        return KeyboardShortcuts.getShortcut(for: .toggleRecording) != nil
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultShortcut() {
        // Set a default shortcut if none exists
        if !hasShortcutSet() {
            // Default: Command+Shift+Space
            let defaultShortcut = KeyboardShortcuts.Shortcut(.space, modifiers: [.command, .shift])
            KeyboardShortcuts.setShortcut(defaultShortcut, for: .toggleRecording)
            print("🎹 KeyboardShortcutsManager: Set default shortcut: ⌘⇧Space")
        } else {
            print("🎹 KeyboardShortcutsManager: Using existing shortcut: \(getCurrentShortcutDescription())")
        }
    }
}
