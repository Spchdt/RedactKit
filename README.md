# RedactKit 🔒

<div align="center">
  
![RedactKit Logo](RedactKit/Assets.xcassets/redactKitLogo.imageset/Frame%202.png)

**A powerful, AI-powered PII detection and redaction tool built with SwiftUI**

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-blue.svg)](https://developer.apple.com/swiftui/)
[![CoreML](https://img.shields.io/badge/CoreML-5.0+-green.svg)](https://developer.apple.com/machine-learning/core-ml/)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0+-lightgrey.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

## 🚀 Overview

RedactKit is an intelligent text processing application that automatically detects and redacts Personally Identifiable Information (PII) from text content. Using advanced machine learning models and Natural Language Processing, it identifies sensitive information like emails, phone numbers, addresses, SSNs, credit card numbers, and more.

### ✨ Key Features

- **🧠 AI-Powered Detection**: Uses CoreML and NeuroBERT for accurate PII identification
- **🎨 Beautiful UI**: Modern SwiftUI interface with stunning animations and effects
- **⚡ Real-time Processing**: Instant text analysis and redaction
- **📚 History Management**: Persistent storage of processed content using SwiftData
- **🔄 Animated Redaction**: Smooth animations showing the redaction process
- **📋 Clipboard Integration**: Easy copy/paste functionality
- **🛡️ Content Verification**: Built-in security features for sensitive data handling

## 🔍 Supported PII Types

RedactKit can detect and redact the following types of sensitive information:

| Type | Examples | Description |
|------|----------|-------------|
| **Person Names** | John Doe, Sarah Smith | Individual names and identities |
| **Email Addresses** | user@example.com | Email addresses and contact information |
| **Phone Numbers** | (555) 123-4567, +1-800-555-0199 | Various phone number formats |
| **Physical Addresses** | 123 Main St, Anytown, CA 90210 | Street addresses and locations |
| **Social Security Numbers** | 123-45-6789 | SSNs and similar identifiers |
| **Credit Card Numbers** | 4111-1111-1111-1111 | Payment card information |
| **Dates** | 01/15/1990, Jan 15, 1990 | Birth dates and other sensitive dates |

## 🛠️ Technology Stack

- **Framework**: SwiftUI 5.0+
- **Language**: Swift 5.9+
- **ML Framework**: CoreML 5.0+
- **NLP**: Natural Language Framework
- **Tokenization**: HuggingFace Tokenizers (NeuroBERT-Mini)
- **Data Persistence**: SwiftData
- **Animation**: SwiftUI Animations with Matched Geometry Effects
- **Minimum Target**: macOS 14.0+

## 📦 Installation

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/Spchdt/RedactKit.git
   cd RedactKit
   ```

2. **Open in Xcode**
   ```bash
   open RedactKit.xcodeproj
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Dependencies

The project includes:
- CoreML model (`PIIDetectionModel.mlpackage`)
- NeuroBERT-Mini tokenizer
- Custom UI components and animations

## 🎯 Usage

### Basic Workflow

1. **Launch RedactKit**
   - Beautiful animated splash screen with the RedactKit logo

2. **Input Text**
   - Paste or type text containing potential PII
   - Click "Paste to Start" to begin analysis

3. **AI Analysis**
   - Watch as the AI processes your text
   - Real-time detection of sensitive information

4. **Review Results**
   - See highlighted PII with color-coded categories
   - Review the original and redacted versions

5. **Export & Save**
   - Copy redacted text to clipboard
   - Save to history for future reference

### Advanced Features

#### History Management
- Access previously processed content
- Delete unwanted entries
- Copy historical redactions

#### Content Verification
- Built-in verification system
- Security checks for sensitive data
- Safe handling of PII information

## 🏗️ Architecture

### Core Components

```
RedactKit/
├── 🎨 UI Components/
│   ├── ContentView.swift          # Main application view
│   ├── HistoryView.swift          # History management interface
│   ├── OriginalTextView.swift     # Original text display
│   ├── InjectedTextView.swift     # Redacted text display
│   └── UI Elements/
│       ├── UltraGlossyButton.swift
│       ├── GlossyCircleButton.swift
│       └── PrismaticMeshBackground.swift
├── 🧠 AI & Processing/
│   ├── PIIDetector.swift          # Core ML PII detection
│   ├── TextProcessor.swift       # Text manipulation and animation
│   └── PIIDetectionModel.mlpackage # Trained ML model
├── 💾 Data Management/
│   ├── Content.swift             # SwiftData model
│   └── ViewModel.swift           # App state management
└── 🚀 App/
    └── RedactKitApp.swift        # Main app entry point
```

### ML Pipeline

1. **Tokenization**: Text is tokenized using NeuroBERT-Mini
2. **Feature Extraction**: Tokens are converted to model inputs
3. **Inference**: CoreML model processes the features
4. **Post-processing**: Results are mapped back to original text
5. **Entity Merging**: Adjacent tokens are combined into complete entities

## 🎨 Design Philosophy

RedactKit emphasizes:
- **User Experience**: Intuitive interface with beautiful animations
- **Performance**: Optimized ML inference for real-time processing
- **Security**: Safe handling of sensitive information
- **Accessibility**: Clean, readable design with clear visual feedback

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Contribution Guidelines

- Follow Swift style guidelines
- Add tests for new features
- Update documentation
- Ensure all tests pass
- Maintain code quality

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **NeuroBERT-Mini**: HuggingFace model for tokenization
- **CoreML**: Apple's machine learning framework
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistence and data modeling

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Spchdt/RedactKit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Spchdt/RedactKit/discussions)
- **Email**: [Contact](mailto:your-email@example.com)

## 🔄 Version History

### v1.0.0 (Current)
- Initial release
- Core PII detection functionality
- SwiftUI interface with animations
- History management
- Clipboard integration

---

<div align="center">
  <strong>Built with ❤️ using SwiftUI and CoreML</strong>
  <br>
  <sub>Created by <a href="https://github.com/Spchdt">Supachod Trakansirorut</a></sub>
</div>
