# Hello Prompt - Spotlight Voice Assistant Setup Guide

## Overview

Hello Prompt is an elegant macOS voice assistant that appears like Spotlight when called with a keyboard shortcut. It features:

- 🎙️ Voice-only input (no text required)
- 🌟 Beautiful Siri-like globe interface
- ⚡ Automatic silence detection (stops after 5 seconds)
- 🔗 OpenAI Whisper + GPT-4 integration
- ⌨️ Global keyboard shortcuts (default: ⌘⇧Space)

## Step-by-Step Setup

### Step 1: Configure OpenAI API Key

1. **Get an OpenAI API Key**:

   - Visit https://platform.openai.com/api-keys
   - Create a new API key
   - Copy the key (starts with `sk-...`)

2. **Set up the configuration**:

   ```bash
   cd Hello-Prompt/Hello-Prompt
   cp Config-Template.xcconfig Config.xcconfig
   ```

3. **Edit Config.xcconfig**:
   - Open `Config.xcconfig` in a text editor
   - Replace `YOUR_API_KEY_PLACEHOLDER` with your actual API key:
   ```
   OPENAI_API_KEY = sk-your-actual-api-key-here
   ```

### Step 2: Build and Run in Xcode

1. **Open the project**:

   ```bash
   open Hello-Prompt.xcodeproj
   ```

2. **Configure signing** (in Xcode):

   - Select your project in navigator
   - Go to "Signing & Capabilities"
   - Select your development team
   - Ensure "Automatically manage signing" is checked

3. **Build and run**:
   - Press ⌘R or click the Run button
   - The app will launch but remain hidden (no dock icon)

### Step 3: Set Up Permissions

When you first use the app, macOS will request permissions:

1. **Microphone Permission**:

   - Grant access when prompted
   - If denied, go to System Preferences → Security & Privacy → Microphone

2. **Accessibility Permission** (for global hotkeys):
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Add and enable "Hello Prompt"

### Step 4: Test the Application

#### Basic Testing:

1. **Activate the app**: Press ⌘⇧Space (or your custom shortcut)
2. **Speak**: The globe will animate while listening
3. **Stop recording**: Either wait 5 seconds of silence, or press Enter/Space/Escape
4. **View results**: Transcription and AI response will appear in the window

#### Testing Modes:

The app has two modes for testing:

**Mock Mode** (Default - No API key required):

- Uses simulated responses for testing
- Perfect for development and debugging

**Real Mode** (Requires OpenAI API key):

- Uses actual OpenAI Whisper and GPT-4
- Set your API key in Config.xcconfig

## Troubleshooting Guide

### Common Issues & Solutions

#### ❌ **"API Key Error: OPENAI_API_KEY not found"**

**Solution**:

1. Ensure Config.xcconfig exists and contains your API key
2. Check that the key starts with `sk-`
3. Rebuild the project (⌘⇧K then ⌘R)

#### ❌ **"Microphone permission denied"**

**Solution**:

1. System Preferences → Security & Privacy → Microphone
2. Enable "Hello Prompt"
3. Restart the app

#### ❌ **Global shortcut not working**

**Solution**:

1. System Preferences → Security & Privacy → Accessibility
2. Add "Hello Prompt" to the list
3. Ensure it's checked/enabled
4. Try a different shortcut combination

#### ❌ **App doesn't appear when shortcut is pressed**

**Solution**:

1. Check Console.app for error messages
2. Ensure app is running (check Activity Monitor)
3. Try different shortcut combination
4. Check accessibility permissions

#### ❌ **Recording doesn't start automatically**

**Solution**:

1. Grant microphone permissions
2. Check Console.app for AudioRecorder errors
3. Try manually triggering with Enter key when window appears

#### ❌ **Audio level not showing on globe**

**Solution**:

1. Ensure microphone permissions are granted
2. Check if another app is using the microphone
3. Try speaking louder or closer to the microphone

#### ❌ **"Network client" error**

**Solution**:

1. Check internet connection
2. Verify firewall isn't blocking the app
3. Ensure OpenAI API key is valid and has credits

### Debug Console Output

The app provides detailed logging. To view:

1. Open Console.app
2. Filter for "Hello Prompt"
3. Look for messages starting with 🎤, 🌟, 🎯, etc.

### Advanced Configuration

#### Changing the Keyboard Shortcut:

The default shortcut is ⌘⇧Space. To change it:

1. Launch the app
2. Press the current shortcut to open
3. Use the HotKey system (this will be shown in a future settings panel)

#### Adjusting Silence Detection:

In `AudioRecorder.swift`, modify these constants:

```swift
private let silenceThreshold: Float = 0.02    // Sensitivity (lower = more sensitive)
private let maxSilenceDuration: TimeInterval = 5.0  // Seconds of silence
```

#### Window Appearance:

In `SpotlightWindowManager`, adjust:

- Window size: `NSRect(x: 0, y: 0, width: 400, height: 300)`
- Position offset: `let y = screenRect.midY - windowRect.height / 2 + 100`

## Development Notes

### Architecture:

- **Hello_PromptApp.swift**: Main app with SpotlightWindowManager
- **ContentView.swift**: SpotlightContentView with SiriGlobeView
- **AudioRecorder.swift**: Voice recording with auto-stop and AI processing
- **OpenAIService.swift**: Whisper transcription + GPT-4 chat completion
- **KeyboardShortcutsManager.swift**: Global hotkey handling using HotKey package

### Key Features:

- ✅ Borderless floating window
- ✅ Real-time audio level visualization
- ✅ 5-second silence auto-stop
- ✅ Enter/Space/Escape manual stop
- ✅ Beautiful Siri-like animated globe
- ✅ Mock service for testing without API costs
- ✅ Comprehensive error handling and logging

### Next Steps for Enhancement:

1. Add settings panel for customizing shortcuts and thresholds
2. Implement voice activation ("Hey Hello")
3. Add speech synthesis for AI responses
4. Support for multiple languages
5. Integration with system clipboard for responses

## Getting Help

If you encounter issues not covered here:

1. Check Console.app for detailed error messages
2. Ensure all permissions are granted
3. Try the mock service first to isolate API issues
4. Review the debug output for specific error codes

Your elegant voice assistant is now ready to serve! 🎭✨
