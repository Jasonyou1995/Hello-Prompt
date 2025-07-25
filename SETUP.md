# Hello-Prompt Setup Instructions

## Overview
Hello-Prompt is a macOS app that records audio, transcribes it using OpenAI's Whisper API, and processes the transcription with ChatGPT.

## Features
- 🎤 Audio recording with permission handling
- 🎯 Speech-to-text transcription via OpenAI Whisper
- 🤖 AI processing with ChatGPT
- 🧪 Mock service for testing without API calls
- 🔒 Secure API key management
- 📱 Native macOS SwiftUI interface

## Quick Start (Testing Mode)

1. **Open the Project**
   ```bash
   cd Hello-Prompt
   open Hello-Prompt.xcodeproj
   ```

2. **Run in Mock Mode**
   - The app starts in mock mode by default
   - Click "Start Recording" → speak → "Stop Recording"
   - You'll see mock transcription and AI response
   - No API key required for testing!

## Production Setup (Real OpenAI API)

### 1. Get OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign up/Login to your OpenAI account
3. Create a new API key
4. Copy the key (starts with `sk-`)

### 2. Configure API Key

**Option A: Environment Variable (Recommended)**
```bash
export OPENAI_API_KEY="sk-your-api-key-here"
```

**Option B: Xcode Configuration File**
1. Copy `Config-Template.xcconfig` to `Config.xcconfig`
2. Edit `Config.xcconfig` and set your API key:
   ```
   OPENAI_API_KEY = sk-your-api-key-here
   ```
3. In Xcode project settings, add Config.xcconfig to your target

**Option C: Xcode Scheme Environment Variables**
1. Edit Scheme → Run → Environment Variables
2. Add: `OPENAI_API_KEY` = `sk-your-api-key-here`

### 3. Switch to Production Mode
In the app, click "Use Real Service" button to switch from mock to real API.

## Testing the Integration

### Mock Mode Testing
1. Start with mock mode (default)
2. Test recording functionality
3. Verify UI updates and mock responses
4. Check console logs for detailed flow

### Real API Testing
1. Set up API key (see above)
2. Switch to "Use Real Service"
3. Record a short audio clip
4. Verify transcription accuracy
5. Check AI response quality

## Project Structure

```
Hello-Prompt/
├── Hello-Prompt/
│   ├── OpenAIService.swift       # API service with mock support
│   ├── AudioRecorder.swift       # Audio recording + AI integration
│   ├── ContentView.swift         # Main UI
│   ├── Config.xcconfig           # Your API key (create from template)
│   └── Config-Template.xcconfig  # Template for API configuration
├── .gitignore                    # Protects sensitive data
└── SETUP.md                      # This file
```

## Key Components

### OpenAIService.swift
- `MockOpenAIService`: Simulates API calls for testing
- `OpenAIService`: Real OpenAI API integration
- `OpenAIServiceFactory`: Switches between mock/real service
- Protocol-based design for easy testing

### AudioRecorder.swift
- Audio recording with AVFoundation
- Automatic processing after recording
- Published properties for UI updates
- Error handling and status reporting

### ContentView.swift
- SwiftUI interface
- Real-time status updates
- Service switching controls
- Scrollable results display

## Security Features

The `.gitignore` file protects:
- API keys and credentials
- Xcode user data
- Build artifacts
- System files
- Provisioning profiles

## Troubleshooting

### Common Issues

**"Missing API Key" Error**
- Verify API key is set in environment variables
- Check API key format (should start with `sk-`)
- Restart Xcode after setting environment variables

**Recording Permission Denied**
- Grant microphone permission in System Preferences
- Restart the app after granting permission

**API Request Fails**
- Check internet connection
- Verify API key is valid and has credits
- Check OpenAI service status

**Mock Service Not Working**
- Ensure "Use Mock Service" button is highlighted in green
- Check console logs for mock service messages

### Debug Tips

1. **Check Console Logs**
   - Look for 🎤, 🧪, 🎯, 🤖 emoji prefixed messages
   - Error messages will show ❌ prefix

2. **Test Components Individually**
   - Test recording first (check file creation)
   - Test mock service (should work without API key)
   - Test real service (requires valid API key)

3. **Verify API Key**
   ```bash
   echo $OPENAI_API_KEY
   ```

## Development Notes

### Testing Strategy
1. Always start with mock service
2. Test UI responsiveness
3. Verify error handling
4. Test with real API last

### Extending the App
- Add new AI models by extending `OpenAIService`
- Customize transcription by modifying request parameters
- Add new UI features by updating `ContentView`
- Create new mock scenarios in `MockOpenAIService`

## API Usage & Costs

- Whisper API: ~$0.006 per minute of audio
- ChatGPT API: ~$0.002 per 1K tokens
- Typical 30-second recording: ~$0.01 total cost

## Support

For issues:
1. Check this setup guide
2. Review console logs
3. Test in mock mode first
4. Verify API key configuration