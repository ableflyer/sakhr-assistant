# Sakhr Assistant
A Student assistant app that takes notes for your lectures, gives you quizzes to test your knowledge, and generates study reminders.

## Features
- **Lecture Recording**: Record your lectures with real-time audio visualization
- **Automated Note-Taking**: Transcribes lectures and generates structured notes
- **Quiz Generation**: Creates quizzes from your lecture notes
- **Study Reminders**: Generates smart reminders based on lecture content
- **Class Organization**: Manage different classes and their associated notes

## Project Structure
The project is divided into two main components:
- Flutter mobile application
- Flask Python server

## Quick Start

Before you start with the setup, please create an ngrok account and add your authtoken to your system.

### Ngrok Setup
1. Sign up to ngrok
2. Go to the setup and installation page
3. Install ngrok:
```bash
# For macOS (using Homebrew)
brew install ngrok
# For Windows (using Chocolatey)
choco install ngrok
# For Linux
sudo snap install ngrok
```
Alternatively, download directly from ngrok's website

4. Add your authtoken, it should be something like this:
```bash
ngrok config add-authtoken [your_auth_token_here]
```

### Firebase Setup

1. Create a Firebase Project:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add Project"
   - Enter project name "Sakhr Assistant"
   - Enable Google Analytics if desired
   - Click "Create Project"

2. Configure Authentication:
   - In Firebase Console, go to Authentication
   - Click "Get Started"
   - Enable Google Sign-in method:
     - Click "Google" in Sign-in providers
     - Enable it and configure
     - Add your support email
     - Save

3. Set up Firestore:
   - Go to Firestore Database
   - Click "Create Database"
   - Choose "Start in production mode"
   - Select your preferred region
   - Click "Enable"

4. Add Android App:
   - In Project Overview, click Android icon
   - Enter package name (e.g., "com.example.sakhr_assistant")
   - Download `google-services.json`
   - Place it in `android/app/`

5. Add iOS App (if needed):
   - In Project Overview, click iOS icon
   - Enter bundle ID from your Xcode project
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/`
   - Add to Xcode project

6. Configure Flutter Project:

Add Firebase dependencies to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^latest_version
  firebase_auth: ^latest_version
  cloud_firestore: ^latest_version
  google_sign_in: ^latest_version
```

Update Android configuration (`android/app/build.gradle`):
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        multiDexEnabled true
    }
}
```

Update iOS configuration (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your reversed client ID -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

7. Initialize Firebase in your app (`lib/main.dart`):
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### Backend Setup
1. Set up Python environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Run the server:
```bash
flask run
# or
python app.py
```

4. Create your own static domain in ngrok and run this in a separate cmd:
```bash
ngrok http --url=your-ngrok-url.ngrok-free.app 80
```

Your session should look like this:
```
Session Status                online
Account                       your_email@example.com
Version                       3.4.0
Region                       United States (us)
Latency                      21ms
Web Interface                http://127.0.0.1:4040
Forwarding                   https://your-ngrok-url.ngrok-free.app -> http://localhost:5000
```

### Frontend Setup
1. Install dependencies:
```bash
flutter clean
flutter pub get
```

2. Copy the forwarding URL and Configure the environment:
```bash
echo "API_URL='https://your-ngrok-url.ngrok-free.app'" > .env
```

3. Run the app:
```bash
flutter run
```

### Firestore Security Rules
Add these basic security rules in Firebase Console:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /sakhr_assistant/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Contributing
Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on how to submit pull requests.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- OpenAI for Whisper integration
- Meta for Llama 3.2 integration
- Firebase for backend services
- Flutter team for the framework
- All contributors who have helped this project grow
