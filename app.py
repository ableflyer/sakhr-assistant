from flask import Flask, request, jsonify
from flask_cors import CORS
import whisper
import torch
from langchain_ollama import ChatOllama
import os
import soundfile as sf
from pydub import AudioSegment
import numpy as np
import audioop
import shutil
from werkzeug.utils import secure_filename
import datetime
import logging
from functools import wraps
import tempfile

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={
    r"/api/*": {
        "origins": "*",
        "methods": ["POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})  # Enable CORS for all routes

# Enhanced Configuration
UPLOAD_FOLDER = 'uploads'
PROCESSED_FOLDER = os.path.join(UPLOAD_FOLDER, 'processed')
NOTES_FOLDER = os.path.join(UPLOAD_FOLDER, 'notes')
ALLOWED_EXTENSIONS = {'mp3', 'wav', 'ogg', 'm4a'}
TARGET_SAMPLE_RATE = 16000  # Whisper prefers 16kHz
MAX_AUDIO_LENGTH = 4 * 60 * 60  # 4 hours in seconds

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024  # 1GB max file size

# Create necessary folders
for folder in [UPLOAD_FOLDER, PROCESSED_FOLDER, NOTES_FOLDER]:
    os.makedirs(folder, exist_ok=True)

class AudioValidationError(Exception):
    """Custom exception for audio validation errors"""
    pass

def validate_and_process_audio(input_path):
    """Validate and process audio file to make it compatible with Whisper"""
    try:
        file_ext = input_path.split('.')[-1].lower()
        processed_path = os.path.join(PROCESSED_FOLDER, 
                                    f"processed_{os.path.basename(input_path)}.wav")
        
        # Load audio file based on format
        try:
            if file_ext == 'mp3':
                audio = AudioSegment.from_mp3(input_path)
            elif file_ext == 'wav':
                audio = AudioSegment.from_wav(input_path)
            elif file_ext == 'ogg':
                audio = AudioSegment.from_ogg(input_path)
            elif file_ext == 'm4a':
                audio = AudioSegment.from_file(input_path, format='m4a')
            else:
                raise AudioValidationError(f"Unsupported audio format: {file_ext}")
        except Exception as e:
            raise AudioValidationError(f"Failed to load audio file: {str(e)}")

        # Validate duration
        duration_ms = len(audio)
        if duration_ms < 1000:  # Less than 1 second
            raise AudioValidationError("Audio file too short")
        if duration_ms > MAX_AUDIO_LENGTH * 1000:  # Convert max length to ms
            raise AudioValidationError(f"Audio file too long (max {MAX_AUDIO_LENGTH//60//60} hours)")

        # Convert to mono if stereo
        if audio.channels > 1:
            audio = audio.set_channels(1)

        # Set sample rate to 16kHz
        if audio.frame_rate != TARGET_SAMPLE_RATE:
            audio = audio.set_frame_rate(TARGET_SAMPLE_RATE)

        # Normalize audio volume using pydub's normalize method
        target_dBFS = -20.0
        change_in_dBFS = target_dBFS - audio.dBFS
        audio = audio.apply_gain(change_in_dBFS)

        # Export processed audio
        audio.export(processed_path, format='wav')

        # Verify the processed file
        with sf.SoundFile(processed_path) as audio_file:
            if audio_file.samplerate != TARGET_SAMPLE_RATE:
                raise AudioValidationError("Failed to set correct sample rate")
            if audio_file.channels != 1:
                raise AudioValidationError("Failed to convert to mono")

        logger.info(f"Audio processed successfully: {processed_path}")
        return processed_path

    except Exception as e:
        logger.error(f"Audio validation error: {str(e)}")
        raise AudioValidationError(str(e))

def init_models():
    """Initialize models lazily to avoid loading them if not needed"""
    if not hasattr(init_models, 'whisper_model'):
        logger.info("Initializing Whisper model...")
        init_models.whisper_model = whisper.load_model("base", device="cuda" if torch.cuda.is_available() else "cpu")
    
    if not hasattr(init_models, 'llm'):
        logger.info("Initializing LLM...")
        init_models.llm = ChatOllama(model="llama3.2", temperature=0)
    
    return init_models.whisper_model, init_models.llm

def error_handler(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except AudioValidationError as e:
            logger.error(f"Audio validation error in {f.__name__}: {str(e)}")
            return jsonify({
                'error': str(e),
                'type': 'audio_validation_error',
                'endpoint': f.__name__,
                'timestamp': datetime.datetime.now().isoformat()
            }), 400
        except Exception as e:
            logger.error(f"Error in {f.__name__}: {str(e)}", exc_info=True)
            return jsonify({
                'error': str(e),
                'type': 'general_error',
                'endpoint': f.__name__,
                'timestamp': datetime.datetime.now().isoformat()
            }), 500
    return wrapper

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/transcribe', methods=['POST'])
@error_handler
def transcribe_audio():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    if not file or not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file type. Allowed types: ' + ', '.join(ALLOWED_EXTENSIONS)}), 400
    
    filename = secure_filename(file.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    processed_filepath = None
    
    try:
        logger.info(f"Saving file: {filename}")
        file.save(filepath)
        
        # Validate and process audio
        logger.info("Validating and processing audio")
        processed_filepath = validate_and_process_audio(filepath)
        
        # Initialize models
        whisper_model, llm = init_models()
        
        # Transcribe audio
        logger.info("Starting transcription")
        try:
            result = whisper_model.transcribe(processed_filepath)
            transcription = result["text"]
            logger.info("Transcription complete")
        except Exception as e:
            logger.error(f"Transcription error: {str(e)}")
            raise AudioValidationError("Failed to transcribe audio. Please ensure the file contains clear speech.")
        
        # Generate notes
        logger.info("Generating notes")
        notes_messages = [
            (
                "system",
                "You are a helpful assistant that summarizes transcribed lectures into concise and well-structured notes in Markdown format. "
                "Always use Markdown syntax for headers, bullet points, code blocks, and other relevant formatting. "
                "Make the notes organized, readable, and directly useful for studying."
            ),
            (
                "human",
                f"Here is the transcription of the lecture: \n\n{transcription}"
            )
        ]
        notes_response = llm.invoke(notes_messages)
        notes_content = notes_response.content if hasattr(notes_response, "content") else "Error: No content generated."
        
        # Save notes
        notes_filename = f"notes_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        notes_path = os.path.join(NOTES_FOLDER, notes_filename)
        with open(notes_path, "w", encoding="utf-8") as f:
            f.write(notes_content)
        
        logger.info("Processing complete")
        return jsonify({
            'status': 'success',
            'transcription': transcription,
            'notes': notes_content,
            'notes_file': notes_filename,
            'audio_info': {
                'duration': len(AudioSegment.from_wav(processed_filepath)) / 1000,  # seconds
                'sample_rate': TARGET_SAMPLE_RATE,
                'channels': 1
            }
        })
        
    except AudioValidationError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        raise e
    finally:
        # Clean up files
        if filepath and os.path.exists(filepath):
            os.remove(filepath)
        if processed_filepath and os.path.exists(processed_filepath):
            os.remove(processed_filepath)
        logger.info("Cleaned up temporary files")

@app.route('/api/generate-quiz', methods=['POST'])
@error_handler
def generate_quiz():
    if not request.is_json:
        return jsonify({'error': 'Content-Type must be application/json'}), 400
    
    data = request.get_json()
    if 'notes' not in data:
        return jsonify({'error': 'No notes provided'}), 400
    
    notes = data['notes']
    _, llm = init_models()
    
    logger.info("Generating quiz")
    quiz_messages = [
        (
            "system",
            '''
            Instructions:

            Create a mini-quiz with 10 questions based on the provided notes
            Use the following strict format for EACH question:
            [QUESTION_TYPE]|||[QUESTION_TEXT]|||[CORRECT_ANSWER]|||[INCORRECT_ANSWER1]|||[INCORRECT_ANSWER2]|||[INCORRECT_ANSWER3]|||[EXPLANATION]

            Question Types:

            MULTIPLE_CHOICE: Standard multiple-choice question
            TRUE_FALSE: Yes/No or True/False question
            MATCH: Matching pairs
            FILL_BLANK: Complete the sentence question

            Example Format:
            MULTIPLE_CHOICE|||What is the capital of France?|||Paris|||London|||Berlin|||Rome|||Paris is the official capital and largest city of France, located in the north-central part of the country.
            
            Additional Guidelines:

            Ensure answers are plausible but clearly distinguishable
            Create distractors that are related but incorrect
            Provide a brief, informative explanation for each answer
            Maintain an educational tone similar to Duolingo
            Randomize answer order in the actual quiz presentation
            ignore any notes about reminders like quizes, assignment, tests, or additional resources
            '''
        ),
        (
            "human",
            f"Notes to Convert into Quiz: \n\n{notes}"
        ),
    ]
    
    quiz_response = llm.invoke(quiz_messages)
    quiz_content = quiz_response.content
    
    # Parse quiz content
    questions = []
    for line in quiz_content.strip().split('\n'):
        if '|||' in line:
            parts = line.split('|||')
            if len(parts) >= 7:  # Ensure we have all required parts
                questions.append({
                    'type': parts[0].strip(),
                    'question': parts[1].strip(),
                    'correct_answer': parts[2].strip(),
                    'incorrect_answers': [ans.strip() for ans in parts[3:6]],
                    'explanation': parts[6].strip()
                })
    
    logger.info(f"Generated {len(questions)} questions")
    return jsonify({
        'status': 'success',
        'questions': questions,
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/generate-reminders', methods=['POST'])
@error_handler
def generate_reminders():
    if not request.is_json:
        return jsonify({'error': 'Content-Type must be application/json'}), 400
    
    data = request.get_json()
    if 'notes' not in data:
        return jsonify({'error': 'No notes provided'}), 400
    
    notes = data['notes']
    _, llm = init_models()
    
    logger.info("Generating reminders")
    reminder_messages = [
        (
            "system",
            '''
            Instructions:
            Extract all reminders, deadlines, assignments, and important dates from the provided notes.
            Keep relative time expressions simple (e.g., "2 weeks", "3 days", "1 month").
            
            Use this format for EACH reminder:
            [TIME_UNTIL_DUE]|||[TYPE]|||[TITLE]|||[DESCRIPTION]|||[PRIORITY]
            
            Types: ASSIGNMENT, EXAM, DEADLINE, MEETING
            Priority: HIGH, MEDIUM, LOW
            
            Examples:
            2 weeks|||ASSIGNMENT|||Math Homework|||Complete exercises 1-10|||HIGH
            3 days|||EXAM|||Physics Quiz|||Study chapters 1-3|||HIGH
            1 month|||DEADLINE|||Project Proposal|||Write initial draft|||MEDIUM
            '''
        ),
        (
            "human",
            f"Notes to Extract Reminders From:\n\n{notes}"
        ),
    ]
    
    reminder_response = llm.invoke(reminder_messages)
    reminder_content = reminder_response.content
    
    # Parse reminders
    reminders = []
    for line in reminder_content.strip().split('\n'):
        if '|||' in line:
            parts = line.split('|||')
            if len(parts) >= 5:  # Ensure we have all required parts
                reminders.append({
                    'time_until': parts[0].strip(),
                    'type': parts[1].strip(),
                    'title': parts[2].strip(),
                    'description': parts[3].strip(),
                    'priority': parts[4].strip()
                })
    
    logger.info(f"Generated {len(reminders)} reminders")
    return jsonify({
        'status': 'success',
        'reminders': reminders,
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/health', methods=['GET'])
def health_check():
    """Endpoint to check if the server is running"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'cuda_available': torch.cuda.is_available(),
        'upload_folder_exists': os.path.exists(UPLOAD_FOLDER),
        'processed_folder_exists': os.path.exists(PROCESSED_FOLDER),
        'notes_folder_exists': os.path.exists(NOTES_FOLDER)
    })

@app.route('/api/cleanup', methods=['POST'])
@error_handler
def cleanup_files():
    """Endpoint to clean up old files"""
    try:
        # Remove files older than 24 hours
        cutoff = datetime.datetime.now() - datetime.timedelta(hours=24)
        
        for folder in [UPLOAD_FOLDER, PROCESSED_FOLDER, NOTES_FOLDER]:
            for filename in os.listdir(folder):
                filepath = os.path.join(folder, filename)
                if os.path.getctime(filepath) < cutoff.timestamp():
                    if os.path.isfile(filepath):
                        os.remove(filepath)
                    elif os.path.isdir(filepath):
                        shutil.rmtree(filepath)
        
        return jsonify({
            'status': 'success',
            'message': 'Cleanup completed',
            'timestamp': datetime.datetime.now().isoformat()
        })
    except Exception as e:
        raise Exception(f"Cleanup failed: {str(e)}")

if __name__ == '__main__':
    logger.info("Starting Flask server...")
    logger.info(f"CUDA available: {torch.cuda.is_available()}")
    
    # Check for ffmpeg
    try:
        import subprocess
        subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
        logger.info("ffmpeg found and working")
    except Exception as e:
        logger.warning("ffmpeg not found or not working. Audio conversion may fail.")
        logger.warning(f"Error: {str(e)}")
    
    app.run(debug=True, host='0.0.0.0', port=5000)