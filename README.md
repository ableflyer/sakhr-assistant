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

before you start with the setup, please create an ngrok account and add your authtoken to your system
1. sign up to ngrok
2. go to the setup and installation page
3. Install ngrok:
```
# For macOS (using Homebrew)
brew install ngrok

# For Windows (using Chocolatey)
choco install ngrok

# For Linux
sudo snap install ngrok
```
Alternatively, download directly from ngrok's website
4. add your authtoken, it should be something like this
```
ngrok config add-authtoken [your_auth_token_here]
```
and now you can start the setup

### Backend Setup

1. Set up Python environment:
```
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. Configure environment:
```
cp .env.example .env
# Edit .env with your configuration
```

3. Run the server:
```
flask run
# or
python app.py
```

4. create your own static domain in ngrok and run this in a separate cmd like this
```
ngrok http --url=your-ngrok-url.ngrok-free.app 80
```
Your session should look like this
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
```
flutter clean
flutter pub get
```

2. Copy the forwarding URL and Configure the environment like this:
```
echo "API_URL='https://your-ngrok-url.ngrok-free.app'" > .env
```

3. Run the app:
```
flutter run
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
