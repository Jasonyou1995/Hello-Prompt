import Foundation
import Carbon
import AppKit

// MARK: - Native macOS Hotkey Manager
// This implementation uses Carbon Event Manager for global hotkeys without third-party dependencies

/// Protocol for hotkey action handling
protocol HotkeyActionProtocol {
    func handleHotkeyPressed()
}

/// Represents a hotkey combination
struct HotkeyDefinition {
    let key: UInt32         // Virtual key code
    let modifiers: UInt32   // Modifier flags
    let identifier: String  // Unique identifier
    let description: String // Human-readable description
}

/// Native hotkey manager using Carbon Event Manager
class NativeHotkeyManager: ObservableObject {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var isRegistered = false
    
    weak var delegate: HotkeyActionProtocol?
    
    // Default hotkey: Cmd+Shift+Space
    private let defaultHotkey = HotkeyDefinition(
        key: 49, // Space key
        modifiers: UInt32(cmdKey | shiftKey),
        identifier: "record_audio",
        description: "⌘⇧Space - Toggle Audio Recording"
    )
    
    @Published var currentHotkey: HotkeyDefinition
    @Published var registrationStatus: String = "Not registered"
    
    private let hotkeyId: EventHotKeyID = EventHotKeyID(signature: OSType(kEventClassKeyboard), id: 1)
    
    init() {
        self.currentHotkey = defaultHotkey
        print("🎹 NativeHotkeyManager: Initialized with default hotkey: \(defaultHotkey.description)")
    }
    
    deinit {
        unregisterHotkey()
        print("🎹 NativeHotkeyManager: Deinitialized")
    }
    
    // MARK: - Public Methods
    
    /// Register the hotkey with the system
    func registerHotkey() {
        print("🎹 NativeHotkeyManager: Attempting to register hotkey")
        
        guard !isRegistered else {
            print("⚠️ NativeHotkeyManager: Hotkey already registered")
            return
        }
        
        // Check for accessibility permissions first
        guard checkAccessibilityPermissions() else {
            registrationStatus = "Accessibility permissions required"
            print("❌ NativeHotkeyManager: Accessibility permissions not granted")
            return
        }
        
        let result = registerGlobalHotkey()
        
        if result == noErr {
            isRegistered = true
            registrationStatus = "Active: \(currentHotkey.description)"
            print("✅ NativeHotkeyManager: Hotkey registered successfully")
        } else {
            registrationStatus = "Registration failed (error: \(result))"
            print("❌ NativeHotkeyManager: Failed to register hotkey, error code: \(result)")
        }
    }
    
    /// Unregister the hotkey
    func unregisterHotkey() {
        print("🎹 NativeHotkeyManager: Unregistering hotkey")
        
        guard isRegistered else {
            print("⚠️ NativeHotkeyManager: No hotkey to unregister")
            return
        }
        
        if let hotKeyRef = hotKeyRef {
            let result = UnregisterEventHotKey(hotKeyRef)
            if result == noErr {
                print("✅ NativeHotkeyManager: Hotkey unregistered successfully")
            } else {
                print("⚠️ NativeHotkeyManager: Failed to unregister hotkey, error code: \(result)")
            }
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
            print("✅ NativeHotkeyManager: Event handler removed")
        }
        
        isRegistered = false
        registrationStatus = "Not registered"
    }
    
    /// Change the hotkey combination
    func updateHotkey(key: UInt32, modifiers: UInt32, description: String) {
        print("🎹 NativeHotkeyManager: Updating hotkey to: \(description)")\n        \n        // Unregister current hotkey\n        unregisterHotkey()\n        \n        // Update hotkey definition\n        currentHotkey = HotkeyDefinition(\n            key: key,\n            modifiers: modifiers,\n            identifier: \"record_audio\",\n            description: description\n        )\n        \n        // Re-register with new combination\n        registerHotkey()\n    }\n    \n    // MARK: - Private Methods\n    \n    private func checkAccessibilityPermissions() -> Bool {\n        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]\n        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)\n        \n        print(\"🔐 NativeHotkeyManager: Accessibility permissions granted: \\(accessEnabled)\")\n        return accessEnabled\n    }\n    \n    private func registerGlobalHotkey() -> OSStatus {\n        print(\"🔧 NativeHotkeyManager: Registering global hotkey with Carbon\")\n        print(\"🔧 Key code: \\(currentHotkey.key), Modifiers: \\(currentHotkey.modifiers)\")\n        \n        // Install event handler\n        let eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]\n        \n        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())\n        \n        let status = InstallEventHandler(\n            GetApplicationEventTarget(),\n            { (nextHandler, theEvent, userData) -> OSStatus in\n                guard let userData = userData else { return eventNotHandledErr }\n                let manager = Unmanaged<NativeHotkeyManager>.fromOpaque(userData).takeUnretainedValue()\n                return manager.handleHotkeyEvent(nextHandler, theEvent)\n            },\n            1,\n            eventTypes,\n            selfPointer,\n            &eventHandler\n        )\n        \n        guard status == noErr else {\n            print(\"❌ NativeHotkeyManager: Failed to install event handler, error: \\(status)\")\n            return status\n        }\n        \n        print(\"✅ NativeHotkeyManager: Event handler installed\")\n        \n        // Register the hotkey\n        let registerStatus = RegisterEventHotKey(\n            currentHotkey.key,\n            currentHotkey.modifiers,\n            hotkeyId,\n            GetApplicationEventTarget(),\n            0,\n            &hotKeyRef\n        )\n        \n        if registerStatus == noErr {\n            print(\"✅ NativeHotkeyManager: Hotkey registered with Carbon\")\n        } else {\n            print(\"❌ NativeHotkeyManager: Failed to register hotkey with Carbon, error: \\(registerStatus)\")\n        }\n        \n        return registerStatus\n    }\n    \n    private func handleHotkeyEvent(_ nextHandler: EventHandlerCallRef?, _ theEvent: EventRef?) -> OSStatus {\n        guard let theEvent = theEvent else {\n            print(\"⚠️ NativeHotkeyManager: Received nil event\")\n            return eventNotHandledErr\n        }\n        \n        var hotKeyID = EventHotKeyID()\n        let status = GetEventParameter(\n            theEvent,\n            EventParamName(kEventParamDirectObject),\n            EventParamType(typeEventHotKeyID),\n            nil,\n            MemoryLayout<EventHotKeyID>.size,\n            nil,\n            &hotKeyID\n        )\n        \n        guard status == noErr else {\n            print(\"⚠️ NativeHotkeyManager: Failed to get hotkey ID from event, error: \\(status)\")\n            return eventNotHandledErr\n        }\n        \n        if hotKeyID.signature == hotkeyId.signature && hotKeyID.id == hotkeyId.id {\n            print(\"🎯 NativeHotkeyManager: Hotkey activated! \\(currentHotkey.description)\")\n            \n            DispatchQueue.main.async {\n                self.delegate?.handleHotkeyPressed()\n            }\n            \n            return noErr\n        }\n        \n        return eventNotHandledErr\n    }\n}\n\n// MARK: - Key Code Constants\n// Common virtual key codes for macOS\nextension NativeHotkeyManager {\n    static let keyCodes: [String: UInt32] = [\n        \"Space\": 49,\n        \"Return\": 36,\n        \"Tab\": 48,\n        \"Delete\": 51,\n        \"Escape\": 53,\n        \"F1\": 122, \"F2\": 120, \"F3\": 99, \"F4\": 118,\n        \"F5\": 96, \"F6\": 97, \"F7\": 98, \"F8\": 100,\n        \"F9\": 101, \"F10\": 109, \"F11\": 103, \"F12\": 111,\n        \"A\": 0, \"B\": 11, \"C\": 8, \"D\": 2, \"E\": 14,\n        \"F\": 3, \"G\": 5, \"H\": 4, \"I\": 34, \"J\": 38,\n        \"K\": 40, \"L\": 37, \"M\": 46, \"N\": 45, \"O\": 31,\n        \"P\": 35, \"Q\": 12, \"R\": 15, \"S\": 1, \"T\": 17,\n        \"U\": 32, \"V\": 9, \"W\": 13, \"X\": 7, \"Y\": 16, \"Z\": 6,\n        \"0\": 29, \"1\": 18, \"2\": 19, \"3\": 20, \"4\": 21,\n        \"5\": 23, \"6\": 22, \"7\": 26, \"8\": 28, \"9\": 25\n    ]\n    \n    static let modifierFlags: [String: UInt32] = [\n        \"Command\": UInt32(cmdKey),\n        \"Shift\": UInt32(shiftKey),\n        \"Option\": UInt32(optionKey),\n        \"Control\": UInt32(controlKey)\n    ]\n    \n    /// Get a user-friendly description of modifier flags\n    static func modifierDescription(for flags: UInt32) -> String {\n        var parts: [String] = []\n        \n        if flags & UInt32(controlKey) != 0 { parts.append(\"⌃\") }\n        if flags & UInt32(optionKey) != 0 { parts.append(\"⌥\") }\n        if flags & UInt32(shiftKey) != 0 { parts.append(\"⇧\") }\n        if flags & UInt32(cmdKey) != 0 { parts.append(\"⌘\") }\n        \n        return parts.joined()\n    }\n    \n    /// Get key name from virtual key code\n    static func keyName(for keyCode: UInt32) -> String {\n        for (name, code) in keyCodes {\n            if code == keyCode {\n                return name\n            }\n        }\n        return \"Key(\\(keyCode))\"\n    }\n    \n    /// Create a hotkey definition from components\n    static func createHotkey(key: String, modifiers: [String]) -> HotkeyDefinition? {\n        guard let keyCode = keyCodes[key] else {\n            print(\"❌ Unknown key: \\(key)\")\n            return nil\n        }\n        \n        var modifierFlags: UInt32 = 0\n        var modifierSymbols: [String] = []\n        \n        for modifier in modifiers {\n            guard let flag = self.modifierFlags[modifier] else {\n                print(\"❌ Unknown modifier: \\(modifier)\")\n                return nil\n            }\n            modifierFlags |= flag\n            \n            switch modifier {\n            case \"Command\": modifierSymbols.append(\"⌘\")\n            case \"Shift\": modifierSymbols.append(\"⇧\")\n            case \"Option\": modifierSymbols.append(\"⌥\")\n            case \"Control\": modifierSymbols.append(\"⌃\")\n            default: break\n            }\n        }\n        \n        let description = \"\\(modifierSymbols.joined())\\(key) - Toggle Audio Recording\"\n        \n        return HotkeyDefinition(\n            key: keyCode,\n            modifiers: modifierFlags,\n            identifier: \"record_audio\",\n            description: description\n        )\n    }\n}\n\n// MARK: - Preset Hotkey Combinations\nextension NativeHotkeyManager {\n    static let presetHotkeys: [HotkeyDefinition] = [\n        // Default\n        HotkeyDefinition(\n            key: keyCodes[\"Space\"]!,\n            modifiers: UInt32(cmdKey | shiftKey),\n            identifier: \"cmd_shift_space\",\n            description: \"⌘⇧Space - Toggle Audio Recording\"\n        ),\n        // Alternative combinations\n        HotkeyDefinition(\n            key: keyCodes[\"R\"]!,\n            modifiers: UInt32(cmdKey | optionKey),\n            identifier: \"cmd_opt_r\",\n            description: \"⌘⌥R - Toggle Audio Recording\"\n        ),\n        HotkeyDefinition(\n            key: keyCodes[\"F12\"]!,\n            modifiers: 0,\n            identifier: \"f12\",\n            description: \"F12 - Toggle Audio Recording\"\n        ),\n        HotkeyDefinition(\n            key: keyCodes[\"Space\"]!,\n            modifiers: UInt32(controlKey | optionKey),\n            identifier: \"ctrl_opt_space\",\n            description: \"⌃⌥Space - Toggle Audio Recording\"\n        )\n    ]\n}