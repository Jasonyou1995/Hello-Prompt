import Foundation
import HotKey

// MARK: - HotKey Manager for Global Shortcuts
class KeyboardShortcutsManager: ObservableObject {
    private var hotKey: HotKey?
    private var isListenerActive = false
    
    // Callback for when hotkey is pressed
    var onToggleRecording: (() -> Void)?
    
    init() {
        print("🎹 KeyboardShortcutsManager: Initialized with HotKey package")
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
        
        // Setup the hotkey handler
        hotKey?.keyDownHandler = { [weak self] in
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
        hotKey?.keyDownHandler = nil
        isListenerActive = false
        print("✅ KeyboardShortcutsManager: Stopped listening for shortcuts")
    }
    
    /// Get the current keyboard shortcut as a string
    func getCurrentShortcutDescription() -> String {
        if let hotKey = hotKey {
            let modifierStrings = hotKey.modifiers.map { modifier in
                switch modifier {
                case .command: return "⌘"
                case .option: return "⌥"
                case .control: return "⌃"
                case .shift: return "⇧"
                case .function: return "fn"
                default: return ""
                }
            }
            let keyString = getKeyDisplayName(for: hotKey.key)
            return modifierStrings.joined() + keyString
        }
        return "No shortcut set"
    }
    
    /// Check if a shortcut is currently set
    func hasShortcutSet() -> Bool {
        return hotKey != nil
    }
    
    /// Update the shortcut to a new key combination
    func updateShortcut(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Stop current hotkey
        hotKey?.keyDownHandler = nil
        
        // Create new hotkey
        hotKey = HotKey(key: key, modifiers: modifiers)
        
        // Restart listening if we were listening before
        if isListenerActive {
            startListening()
        }
        
        print("🎹 KeyboardShortcutsManager: Updated shortcut to: \(getCurrentShortcutDescription())")
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultShortcut() {
        // Default: Command+Shift+Space (⌘⇧Space)
        hotKey = HotKey(key: .space, modifiers: [.command, .shift])
        print("🎹 KeyboardShortcutsManager: Set default shortcut: ⌘⇧Space")
    }
    
    private func getKeyDisplayName(for key: Key) -> String {
        switch key {
        case .space: return "Space"
        case .return: return "↩"
        case .tab: return "⇥"
        case .escape: return "⎋"
        case .delete: return "⌫"
        case .forwardDelete: return "⌦"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        default: return key.description
        }
    }
}
