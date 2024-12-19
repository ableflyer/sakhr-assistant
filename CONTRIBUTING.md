# Contributing to Sakhr Assistant

First off, thank you for considering contributing to Sakhr Assistant! It's people like you that help make this student assistant tool better for everyone.

## Prerequisites

Before you begin contributing, ensure you have:
- Flutter development environment set up
- Python 3.8 or higher installed
- ngrok account and authtoken configured
- Firebase project access (ask maintainers)
- Basic understanding of Flask and Flutter

## Setting Up Development Environment

### 1. Fork & Clone
```bash
git clone https://github.com/YOUR-USERNAME/sakhr-assistant.git
cd sakhr-assistant
git remote add upstream https://github.com/ableflyer/sakhr-assistant.git
```

### 2. Backend Setup
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Create your `.env` file:
```bash
cp .env.example .env
# Edit with your configuration
```

### 3. Frontend Setup
```bash
flutter clean
flutter pub get
```

Create your `.env` file:
```bash
echo "API_URL='your-ngrok-url'" > .env
```

### 4. Firebase Setup
For development, you'll need access to the Firebase project. Contact maintainers for:
- `google-services.json` for Android
- `GoogleService-Info.plist` for iOS
- Firebase project access

## Development Workflow

### 1. Choose an Issue
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue you'd like to work on
- Wait for assignment or approval

### 2. Create a Branch
```bash
git checkout -b type/issue-description
# type can be: feature, bugfix, docs, test
```

### 3. Development Guidelines

#### Backend (Flask)
- Follow PEP 8 style guide
- Add type hints to new functions
- Include docstrings
- Add tests for new endpoints
- Handle all error cases

Example endpoint:
```python
from typing import Dict, Any

@app.route('/api/endpoint', methods=['POST'])
def new_endpoint() -> Dict[str, Any]:
    """
    Endpoint description.

    Returns:
        Dict containing response data
    """
    try:
        # Implementation
        return jsonify({'status': 'success'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

#### Frontend (Flutter)
- Use consistent formatting (`flutter format .`)
- Follow Material Design guidelines
- Maintain the existing color scheme (green on black)
- Handle loading and error states
- Add widget tests
- Use responsive design with ScreenUtil

Example widget:
```dart
class CustomWidget extends StatelessWidget {
  final String title;

  const CustomWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF00FF00)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFF00FF00),
          fontSize: 16.sp,
        ),
      ),
    );
  }
}
```

### 4. Testing

#### Backend Tests
```bash
cd backend
pytest
```

#### Frontend Tests
```bash
cd frontend
flutter test
```

### 5. Commit Guidelines

Format:
```
type(scope): brief description

Longer description if needed

Fixes #issue_number
```

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- test: Testing
- refactor: Code refactoring
- style: Formatting, missing semi colons, etc
- chore: Maintenance

Example:
```
feat(quiz): add quiz generation for single notes

- Implement quiz generation endpoint
- Add quiz UI in Flutter
- Include loading states and error handling

Fixes #42
```

### 6. Submit Pull Request

1. Push your changes:
```bash
git push origin your-branch-name
```

2. Create Pull Request on GitHub

3. Include in description:
- What changes you made
- Why you made them
- Testing performed
- Screenshots (for UI changes)
- Issue number referenced

### 7. Review Process

1. Automated checks must pass
2. Code review by maintainers
3. Address any requested changes
4. Maintainers merge PR
5. Delete your branch

## Getting Help

- Check documentation in README files
- Ask in GitHub issues
- Contact maintainers
- Join our Discord server (if available)

## Recognition

Contributors are:
- Listed in README.md
- Mentioned in release notes
- Added to Contributors list

Thank you for contributing to Sakhr Assistant! 🎉
