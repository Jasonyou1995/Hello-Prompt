import Foundation
import AppKit
import HotKey
import UserNotifications

class HotkeyManager {
    private var hotKey: HotKey?

    func setupHotkey() {
        print("🚀 Starting hotkey setup...")
        print("📱 Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Request notification permissions first
        requestNotificationPermissions()
        
        // Try to register the hotkey - using F12 which has zero conflict chance
        print("🎯 Attempting to register F12...")
        print("🔍 Creating HotKey object...")
        
        do {
            hotKey = HotKey(key: .f12, modifiers: [])
            print("🎉 HotKey object created successfully!")
            
            if hotKey != nil {
                print("🔧 Setting up key handler...")
                hotKey?.keyDownHandler = { [weak self] in
                    print("⚡️⚡️⚡️ HOTKEY HANDLER TRIGGERED! ⚡️⚡️⚡️")
                    print("🕐 Handler called at: \(Date())")
                    self?.handleHotkeyPressed()
                }
                print("✅ SUCCESS: Hotkey registered - F12")
                print("🔧 Handler assigned successfully")
                print("🎯 Test by pressing F12 now!")
                
                // Show success notification
                showNotification(title: "Hotkey Ready", message: "Press F12 to test!")
                
            } else {
                print("❌ CRITICAL: HotKey object is nil after creation")
                tryAlternativeHotkeys()
            }
        } catch {
            print("❌ EXCEPTION during hotkey creation: \(error)")
            tryAlternativeHotkeys()
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("❌ Notification permissions denied")
            }
        }
    }
    
    private func tryAlternativeHotkeys() {
        print("🔄 Trying alternative hotkey combinations...")
        let alternatives: [(Key, NSEvent.ModifierFlags, String)] = [
            (.f11, [], "F11"),
            (.f10, [], "F10"),
            (.f9, [], "F9")
        ]
        
        for (key, modifiers, description) in alternatives {
            print("🎯 Trying: \(description)")
            hotKey = HotKey(key: key, modifiers: modifiers)
            
            if hotKey != nil {
                hotKey?.keyDownHandler = { [weak self] in
                    print("⚡️ ALTERNATIVE HOTKEY TRIGGERED!")
                    self?.handleHotkeyPressed()
                }
                print("✅ SUCCESS: Alternative hotkey registered - \(description)")
                showNotification(title: "Alternative Hotkey", message: "Using \(description)")
                return
            } else {
                print("❌ Failed: \(description)")
            }
        }
        print("💥 CRITICAL: All hotkey alternatives failed!")
        showNotification(title: "Hotkey Error", message: "All hotkey combinations failed!")
    }
    
    private func handleHotkeyPressed() {
        print("🔥🔥🔥 HOTKEY PRESSED! 🔥🔥🔥")
        print("📱 Activating app...")
        
        // Multiple feedback methods
        NSApp.activate(ignoringOtherApps: true)
        NSSound.beep()
        
        showNotification(title: "Hotkey Activated!", message: "Your hotkey is working perfectly!")
        
        // Flash menu bar icon (if possible)
        DispatchQueue.main.async {
            print("✨ App should now be active")
        }
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error)")
            } else {
                print("✅ Notification sent: \(title)")
            }
        }
    }
    
    deinit {
        hotKey = nil
    }
}
