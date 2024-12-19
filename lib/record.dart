import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'classes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with SingleTickerProviderStateMixin {
  String? selectedClass;
  bool isRecording = false;
  List<double> soundBars = List.generate(30, (index) => 0.0);
  final FlutterTts flutterTts = FlutterTts();
  final AudioRecorder audioRecord = AudioRecorder();
  StreamSubscription<Amplitude>? amplitudeSubscription;
  String? recordingPath;
  Timer? soundBarTimer;
  bool isPaused = false;
  Duration recordingDuration = Duration.zero;
  Timer? durationTimer;
  bool isPlaying = false;
  String? transcription;
  String? notes;
  bool isUploading = false;
  bool showNotes = false;
  ScrollController scrollController = ScrollController();
  List<Map<String, String>> classes = [];
  bool isLoadingClasses = true;
  final String? serverUrl = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _checkMicPermission();
    _loadClasses();
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _checkMicPermission() async {
    if (await audioRecord.hasPermission()) {
      // Microphone permission granted
    }
  }

  void _updateSoundBars(double amplitude) {
    setState(() {
      // Create a smooth wave effect
      for (int i = soundBars.length - 1; i > 0; i--) {
        soundBars[i] = soundBars[i - 1];
      }
      // Normalize amplitude to 0-1 range and add some randomness for natural look
      soundBars[0] = math.min(1.0, amplitude * (0.5 + math.Random().nextDouble() * 0.5));
    });
  }

  Future<void> _loadClasses() async {
    try {
      setState(() => isLoadingClasses = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sakhr_assistant')
          .doc("placeholder")
          .collection("classes")
          .get();

      setState(() {
        classes = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'key': doc.id,
            'code': data['code'] as String,
            'name': data['name'] as String,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading classes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoadingClasses = false);
    }
  }

  Future<void> _saveNotes() async {
    if (notes == null || selectedClass == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now();
      
      // Reference to the specific class document
      final classRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sakhr_assistant')
          .doc('placeholder')
          .collection('classes')
          .doc(selectedClass);

      // Create notes subcollection within the class document
      await classRef.collection('notes').add({
        'notes': notes,
        'transcription': transcription,
        'timestamp': timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notes saved successfully',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFF00FF00),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving notes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _toggleRecording() async {
    if (selectedClass == null) return;

    if (!isRecording) {
      try {
        if (await audioRecord.hasPermission()) {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String recordingDir = '${appDir.path}/recordings';
          
          final Directory recordingDirectory = Directory(recordingDir);
          if (!await recordingDirectory.exists()) {
            await recordingDirectory.create(recursive: true);
          }

          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String filePath = '$recordingDir/recording_$timestamp.m4a';

          await audioRecord.start(
            RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: filePath,
          );
          
          durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            setState(() {
              recordingDuration += Duration(seconds: 1);
            });
          });

          setState(() {
            isRecording = true;
            isPaused = false;
            recordingDuration = Duration.zero;
          });
        }
      } catch (e) {
        print('Error starting recording: $e');
      }
    } else {
      try {
        if (isPaused) {
          // Resume recording
          await audioRecord.resume();
          durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            setState(() {
              recordingDuration += Duration(seconds: 1);
            });
          });
          setState(() => isPaused = false);
        } else {
          // Pause recording
          await audioRecord.pause();
          durationTimer?.cancel();
          recordingPath = await audioRecord.stop();  // Stop and save the recording
          setState(() {
            isRecording = false;  // Set recording to false
            isPaused = false;     // Reset pause state
            recordingDuration = Duration.zero;  // Reset duration
          });
        }
      } catch (e) {
        print('Error pausing/resuming recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      recordingPath = await audioRecord.stop();
      amplitudeSubscription?.cancel();
      durationTimer?.cancel();
      setState(() {
        isRecording = false;
        isPaused = false;
        recordingDuration = Duration.zero;
        soundBars = List.generate(30, (index) => 0.0);
      });
      print('Recording saved to: $recordingPath');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<bool> _testServerConnection() async {
    try {
      final uri = Uri.parse(serverUrl!);
      final fullUri = uri.resolve('/api/health');
      final response = await http
          .get(fullUri)
          .timeout(Duration(seconds: 5));
      
      print('Server health check response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Server connection test failed: $e');
      return false;
    }
  }
  Future<void> _generateNotes() async {
    if (!isRecording && recordingPath != null) {
      try {
        // Check if file exists first
        final file = File(recordingPath!);
        print('Checking file...');
        print('File path: ${file.path}');
        print('File exists: ${await file.exists()}');
        print('File size: ${await file.length()} bytes');

        if (!await file.exists()) {
          throw Exception('Recording file not found');
        }

        if (await file.length() == 0) {
          throw Exception('Recording file is empty');
        }

        setState(() {
          isUploading = true;
        });

        print('Testing server connection...');
        final isConnected = await _testServerConnection();
        print('Server connected: $isConnected');

        if (!isConnected) {
          throw Exception('Cannot connect to server. Please check if the server is running.');
        }

        print('Creating multipart request...');
        final uri = Uri.parse(serverUrl!);
        final fullUri = uri.resolve('/api/transcribe');
        final request = http.MultipartRequest('POST', fullUri)
          ..headers.addAll({
            'Content-Type': 'multipart/form-data',
          });
        
        print('Adding file to request...');
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a'
        );
        request.files.add(multipartFile);
        
        print('Sending request...');
        final streamedResponse = await request.send();
        print('Response status code: ${streamedResponse.statusCode}');
        
        final response = await http.Response.fromStream(streamedResponse);
        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          setState(() {
            transcription = responseData['transcription'];
            notes = responseData['notes'];
          });
          await _saveNotes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notes generated successfully',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Color(0xFF00FF00),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Upload failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('Error processing audio: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing audio: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    }
  }
  // Add this function to your _RecordScreenState class

  Future<void> _generateReminders() async {
    if (notes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No notes available to generate reminders from'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => isUploading = true);

      // Make API request to generate reminders
      final response = await http.post(
        Uri.parse(String.fromEnvironment('API_URL')+'api/generate-reminders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'notes': notes}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate reminders: ${response.body}');
      }

      final responseData = json.decode(response.body);
      final reminders = responseData['reminders'] as List;
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Parse and store each reminder
      for (var reminder in reminders) {
        // Convert time_until to actual DateTime
        final timeUntil = reminder['time_until'] as String;
        final now = DateTime.now();
        DateTime dueDate;

        if (timeUntil.contains('week')) {
          final weeks = int.parse(timeUntil.split(' ')[0]);
          dueDate = now.add(Duration(days: weeks * 7));
        } else if (timeUntil.contains('day')) {
          final days = int.parse(timeUntil.split(' ')[0]);
          dueDate = now.add(Duration(days: days));
        } else if (timeUntil.contains('month')) {
          final months = int.parse(timeUntil.split(' ')[0]);
          dueDate = DateTime(now.year, now.month + months, now.day);
        } else {
          // Default to one week if unable to parse
          dueDate = now.add(Duration(days: 7));
        }

        // Store reminder in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .add({
          'title': reminder['title'],
          'description': reminder['description'],
          'dueDate': Timestamp.fromDate(dueDate),
          'type': reminder['type'],
          'priority': reminder['priority'],
          'course': classes.firstWhere((c) => c['key'] == selectedClass)['code'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generated ${reminders.length} reminders',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFF00FF00),
        ),
      );
    } catch (e) {
      print('Error generating reminders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> _generatenotesandreminders() async {
    await _generateNotes();
    await _generateReminders();
  }

  @override
  void dispose() {
    flutterTts.stop();
    audioRecord.dispose();
    amplitudeSubscription?.cancel();
    soundBarTimer?.cancel();
    durationTimer?.cancel();
    super.dispose();
  }

  // Rest of the build method remains the same as before
  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  showNotes ? 'Notes' : 'Record',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedClass != null)
                  GestureDetector(
                    onTap: () => setState(() => showNotes = !showNotes),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showNotes ? Icons.mic : Icons.note_alt,
                            color: Color(0xFF00FF00),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            showNotes ? 'Record' : 'View Notes',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),

            // Main Content
            Expanded(
              child: selectedClass == null
                  ? // Class Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a Class',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 20.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final classInfo = classes[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedClass = classInfo['key'];
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF00FF00)),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Color(0xFF00FF00)),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        classInfo['code']!,
                                        style: TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        classInfo['name']!,
                                        style: TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF00FF00),
                                      size: 16.sp,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : showNotes
                      ? // Notes View
                        Column(
                          children: [
                            // Selected Class Header
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFF00FF00)),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Color(0xFF00FF00)),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          classes.firstWhere((c) => c['key'] == selectedClass)['code']!,
                                          style: TextStyle(
                                            color: Color(0xFF00FF00),
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        classes.firstWhere((c) => c['key'] == selectedClass)['name']!,
                                        style: TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedClass = null;
                                        isRecording = false;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      color: Color(0xFF00FF00),
                                      size: 24.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Notes List
                            Expanded(
                              child: NotesView(classkey: selectedClass!),
                            ),
                          ],
                        )
                      : // Recording Interface
                        Column(
                          children: [
                            // Your existing recording interface content
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFF00FF00)),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Color(0xFF00FF00)),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          classes.firstWhere((c) => c['key'] == selectedClass)['code']!,
                                          style: TextStyle(
                                            color: Color(0xFF00FF00),
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        classes.firstWhere((c) => c['key'] == selectedClass)['name']!,
                                        style: TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedClass = null;
                                        isRecording = false;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      color: Color(0xFF00FF00),
                                      size: 24.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 40.h),
                            Container(
                              height: 100.h,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  soundBars.length,
                                  (index) => Container(
                                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                                    width: 6.w,
                                    height: soundBars[index] * 100.h,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF00FF00),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 40.h),
                            Center(
                              child: Column(
                                children: [
                                  if (isRecording || isPaused)
                                    Text(
                                      _formatDuration(recordingDuration),
                                      style: TextStyle(
                                        color: Color(0xFF00FF00),
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isRecording)
                                        GestureDetector(
                                          onTap: _stopRecording,
                                          child: Container(
                                            width: 60.w,
                                            height: 60.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFFFF0000),
                                                width: 4.w,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.stop,
                                                color: Color(0xFFFF0000),
                                                size: 30.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(width: isRecording ? 40.w : 0),
                                      GestureDetector(
                                        onTap: _toggleRecording,
                                        child: Container(
                                          width: 80.w,
                                          height: 80.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Color(0xFF00FF00),
                                              width: 4.w,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              isRecording
                                                  ? (isPaused ? Icons.play_arrow : Icons.pause)
                                                  : Icons.mic,
                                              color: Color(0xFF00FF00),
                                              size: 40.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24.h),
                                  if (!isRecording)
                                    GestureDetector(
                                      onTap: _generatenotesandreminders,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                          vertical: 12.h,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Color(0xFF00FF00)),
                                          borderRadius: BorderRadius.circular(24.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.note_add_outlined,
                                              color: Color(0xFF00FF00),
                                              size: 20.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Generate Notes',
                                              style: TextStyle(
                                                color: Color(0xFF00FF00),
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class NotesView extends StatelessWidget {
  final String classkey;

  const NotesView({Key? key, required this.classkey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('sakhr_assistant')
          .doc('placeholder')
          .collection('classes')
          .doc(classkey)
          .collection('notes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Color(0xFF00FF00)),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No notes found',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final noteDoc = snapshot.data!.docs[index];
            final noteData = noteDoc.data() as Map<String, dynamic>;
            final timestamp = (noteData['timestamp'] as Timestamp).toDate();

            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF00FF00)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ExpansionTile(
                title: Text(
                  DateFormat('MMM d, y HH:mm').format(timestamp),
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 16.sp,
                  ),
                ),
                iconColor: Color(0xFF00FF00),
                collapsedIconColor: Color(0xFF00FF00),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (noteData['transcription'] != null) ...[
                          Text(
                            'Transcription',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            noteData['transcription'],
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                        Text(
                          'Notes',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        MarkdownBody(
                          data: noteData['notes'],
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: Color(0xFF00FF00), fontSize: 14.sp),
                            h1: TextStyle(color: Color(0xFF00FF00), fontSize: 20.sp, fontWeight: FontWeight.bold),
                            h2: TextStyle(color: Color(0xFF00FF00), fontSize: 18.sp, fontWeight: FontWeight.bold),
                            h3: TextStyle(color: Color(0xFF00FF00), fontSize: 16.sp, fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: Color(0xFF00FF00)),
                            code: TextStyle(color: Color(0xFF00FF00), backgroundColor: Colors.black45),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SingleNoteQuizButton(noteContent: noteData['notes']),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}