import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'record.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Classes',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF00FF00),
                        size: 32.sp,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddClassScreen(),
                          ),
                        );
                      },
                    )
                  ],
                ),
                SizedBox(height: 20.h),

                // Classes List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('sakhr_assistant')
                      .doc("placeholder")
                      .collection("classes")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong',
                          style: TextStyle(color: Color(0xFF00FF00)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00FF00)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No classes added yet',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final classData = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        final key = snapshot.data!.docs[index].id;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                              MaterialPageRoute(
                                builder: (context) => ClassNotesScreen(className: classData['name'], classCode: classData['code'], teacher: classData['teacher'], classkey: key,),
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF00FF00)),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Color(0xFF00FF00),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              classData['code'] ?? '',
                                              style: TextStyle(
                                                color: Color(0xFF00FF00),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              classData['name'] ?? '',
                                              style: TextStyle(
                                                color: Color(0xFF00FF00),
                                                fontSize: 18.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            color: Color(0xFF00FF00),
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            classData['teacher'] ?? '',
                                            style: TextStyle(
                                              color: Color(0xFF00FF00),
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.note_outlined,
                                            color: Color(0xFF00FF00),
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '0 notes',
                                            style: TextStyle(
                                              color: Color(0xFF00FF00),
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF00FF00),
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({Key? key}) : super(key: key);

  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _teacherController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addClass() async {
    if (_nameController.text.isEmpty ||
        _codeController.text.isEmpty ||
        _teacherController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not found');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sakhr_assistant')
          .doc("placeholder")
          .collection("classes")
          .add({
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'teacher': _teacherController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF00FF00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Class',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                hint: 'Class Name',
                icon: Icons.class_outlined,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _codeController,
                hint: 'Class Code',
                icon: Icons.code,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _teacherController,
                hint: 'Teacher Name',
                icon: Icons.person_outline,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _addClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00FF00),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Add Class',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF00FF00)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Color(0xFF00FF00)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFF00FF00).withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Color(0xFF00FF00)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }
}

class ClassNotesScreen extends StatelessWidget {
  final String classCode;
  final String className;
  final String teacher;
  final String classkey;

  const ClassNotesScreen({
    Key? key,
    required this.classCode,
    required this.className,
    required this.teacher,
    required this.classkey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF00FF00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          className,
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            children: [
              // Class Info Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF00FF00)),
                  ),
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
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        classCode,
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.person_outline,
                      color: Color(0xFF00FF00),
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      teacher,
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Notes List
              Expanded(
                child: NotesView(classkey: classkey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quiz Generation Button Widget
// class QuizButton extends StatelessWidget {
//   final String classKey;

//   const QuizButton({
//     Key? key,
//     required this.classKey,
//   }) : super(key: key);

//   Future<List<String>> _fetchNotes() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) throw Exception('User not found');

//     final notesSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .collection('sakhr_assistant')
//         .doc("placeholder")
//         .collection("classes")
//         .doc(classKey)
//         .collection('notes')
//         .orderBy('timestamp', descending: true)
//         .get();

//     List<String> notes = [];
//     for (var doc in notesSnapshot.docs) {
//       final data = doc.data();
//       print("Note data: $data");
//       if (data['notes'] != null) {
//         notes.add(data['notes'] as String);
//       }
//     }

//     if (notes.isEmpty) {
//       throw Exception('No notes found for this class');
//     }

//     print("Total notes found: ${notes.length}");

//     return notes;
//   }

//   Future<List<QuizQuestion>> _generateQuiz(List<String> notes) async {
//     try {
//       final combinedNotes = notes.join('\n');
//       print("Number of notes: ${notes.length}");
//       print("Total combined notes length: ${combinedNotes.length} characters");
//       print("First 100 characters of notes: ${combinedNotes.substring(0, combinedNotes.length < 100 ? combinedNotes.length : 100)}");
//       print("Last 100 characters of notes: ${combinedNotes.substring(combinedNotes.length < 100 ? 0 : combinedNotes.length - 100)}");
      
//       final requestBody = json.encode({'notes': combinedNotes});
//       print("Request body length: ${requestBody.length} characters");
      
//       final response = await http.post(
//         Uri.parse('String.fromEnvironment('API_URL')'+'/api/generate-quiz'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: requestBody,
//       );

//       print("API response status: ${response.statusCode}");
//       print("API response length: ${response.body.length} characters");
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final llmOutput = data['llm_output'] as String;
//         print("LLM output length: ${llmOutput.length} characters");
        
//         // For debugging, print some metadata from the response
//         if (data.containsKey('debug_info')) {
//           print("Debug info from server: ${data['debug_info']}");
//         }
        
//         final lines = llmOutput.split('\n');
//         print("Number of lines in LLM output: ${lines.length}");
        
//         List<QuizQuestion> questions = [];
        
//         for (int i = 0; i < lines.length; i++) {
//           final line = lines[i];
//           final trimmedLine = line.trim();
          
//           if (trimmedLine.contains('|||')) {
//             print("Processing line $i: ${trimmedLine.substring(0, trimmedLine.length < 50 ? trimmedLine.length : 50)}...");
            
//             final parts = trimmedLine.split('|||');
//             print("Number of parts: ${parts.length}");
            
//             if (parts.length >= 7) {
//               final questionType = parts[0].trim();
//               if (['MULTIPLE_CHOICE', 'TRUE_FALSE', 'ORDER', 'FILL_BLANK'].contains(questionType)) {
//                 questions.add(QuizQuestion(
//                   type: questionType,
//                   question: parts[1].trim(),
//                   correctAnswer: parts[2].trim(),
//                   incorrectAnswers: [
//                     parts[3].trim(),
//                     parts[4].trim(),
//                     parts[5].trim(),
//                   ],
//                   explanation: parts[6].trim(),
//                 ));
//                 print("Added question of type: $questionType");
//               } else {
//                 print("Skipping invalid question type: $questionType");
//               }
//             } else {
//               print("Skipping line with insufficient parts (${parts.length} parts)");
//             }
//           }
//         }

//         if (questions.isEmpty) {
//           print("No valid questions were parsed from the response");
//           throw Exception('No valid questions could be parsed from the response');
//         }
        
//         print("Successfully parsed ${questions.length} questions");
//         return questions;
//       } else {
//         print("Server returned error status: ${response.statusCode}");
//         print("Error response body: ${response.body}");
//         throw Exception('Failed to generate quiz: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       print("Error in _generateQuiz: $e");
//       print("Stack trace: $stackTrace");
//       rethrow;
//     }
//   }

//   Future<void> _handleQuizGeneration(BuildContext context) async {
//     // Store context reference before async operation
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
    
//     try {
//       // Show loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFF00FF00),
//           ),
//         ),
//       );

//       print("Fetching notes");
//       final notes = await _fetchNotes();
//       print("Found ${notes.length} notes");
      
//       print("Generating quiz");
//       final questions = await _generateQuiz(notes);
//       print("Generated ${questions.length} questions");

//       // Check if widget is still mounted
//       if (!context.mounted) return;

//       // Hide loading indicator
//       Navigator.of(context).pop();

//       // Navigate to quiz screen
//       await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => QuizScreen(questions: questions),
//         ),
//       );
//     } catch (e, stackTrace) {
//       print("Error in quiz generation: $e");
//       print("Stack trace: $stackTrace");

//       // Hide loading indicator if showing
//       if (context.mounted && Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }

//       // Show error message
//       scaffoldMessenger.showSnackBar(
//         SnackBar(
//           content: Text(
//             e.toString().contains('No notes found')
//                 ? 'Add some notes to generate a quiz!'
//                 : 'Failed to generate quiz: ${e.toString()}',
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Color(0xFF00FF00),
//           padding: EdgeInsets.symmetric(vertical: 16.h),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//         ),
//         onPressed: () => _handleQuizGeneration(context),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.quiz, color: Colors.black, size: 24.sp),
//             SizedBox(width: 8.w),
//             Text(
//               'Generate Quiz',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Quiz Question Model
// class QuizQuestion {
//   final String type;
//   final String question;
//   final String correctAnswer;
//   final List<String> incorrectAnswers;
//   final String explanation;

//   QuizQuestion({
//     required this.type,
//     required this.question,
//     required this.correctAnswer,
//     required this.incorrectAnswers,
//     required this.explanation,
//   });

//   factory QuizQuestion.fromJson(Map<String, dynamic> json) {
//     return QuizQuestion(
//       type: json['type'],
//       question: json['question'],
//       correctAnswer: json['correct_answer'],
//       incorrectAnswers: List<String>.from(json['incorrect_answers']),
//       explanation: json['explanation'],
//     );
//   }

//   List<String> get allAnswers {
//     // Only shuffle for multiple choice, other types need specific handling
//     if (type == 'MULTIPLE_CHOICE') {
//       final answers = [...incorrectAnswers, correctAnswer];
//       answers.shuffle();
//       return answers;
//     }
//     // For TRUE_FALSE, always show in this order
//     else if (type == 'TRUE_FALSE') {
//       return ['True', 'False'];
//     }
//     // For ORDER and others, return as is
//     return incorrectAnswers;
//   }
//   List<String> get orderedSteps {
//     if (type == 'ORDER') {
//       return correctAnswer.split('|').map((s) => s.trim()).toList();
//     }
//     return [];
//   }
// }

// Quiz Screen
// Quiz Question Model
class QuizQuestion {
  final String type;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  final String explanation;

  QuizQuestion({
    required this.type,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    required this.explanation,
  });

  // Multiple choice: Show all available options
  // True/False: Show only True and False
  // ORDER: Parse steps for ordering
  List<String> get allAnswers {
    if (type == 'MULTIPLE_CHOICE') {
      final answers = [...incorrectAnswers, correctAnswer];
      answers.shuffle();
      return answers;
    } else if (type == '**TRUE_FALSE') {
      return ['True', 'False'];
    }
    return [];
  }

  // Get ordered steps for ORDERing questions
  List<String> get orderedSteps {
    if (type == '**ORDER') {
      return correctAnswer.split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizScreen({Key? key, required this.questions}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late PageController _pageController;
  late int _currentPage;
  dynamic _selectedAnswer;
  late bool _hasAnswered;
  List<String> _selectedOrder = [];
  List<String> _availableSteps = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentPage = 0;
    _hasAnswered = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Check answer and show feedback
  void _checkAnswer(dynamic answer) {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
  }

  // Move to next question
  void _nextQuestion() {
    if (_currentPage >= widget.questions.length - 1) {
      Navigator.pop(context);
      return;
    }

    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      if (mounted) {
        setState(() {
          _currentPage++;
          _selectedAnswer = null;
          _hasAnswered = false;
          _selectedOrder = [];
          _availableSteps = [];
        });
      }
    });
  }

  // Build multiple choice question UI
  Widget _buildMultipleChoiceQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.question,
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),
        ...question.allAnswers.map((answer) {
          final isSelected = _selectedAnswer == answer;
          final isCorrect = answer == question.correctAnswer;
          final showResult = _hasAnswered;

          return GestureDetector(
            onTap: _hasAnswered ? null : () => _checkAnswer(answer),
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showResult 
                    ? (isCorrect ? Colors.green : (isSelected ? Colors.red : Color(0xFF00FF00)))
                    : Color(0xFF00FF00),
                ),
                borderRadius: BorderRadius.circular(8.r),
                color: isSelected ? Color(0xFF00FF00).withOpacity(0.2) : null,
              ),
              child: Text(
                answer,
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 16.sp,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build true/false question UI
  Widget _buildTrueFalseQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.question,
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),
        ...['True', 'False'].map((answer) {
          final isSelected = _selectedAnswer == answer;
          final isCorrect = answer.toLowerCase() == question.correctAnswer.toLowerCase();
          final showResult = _hasAnswered;

          return GestureDetector(
            onTap: _hasAnswered ? null : () => _checkAnswer(answer),
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showResult 
                    ? (isCorrect ? Colors.green : (isSelected ? Colors.red : Color(0xFF00FF00)))
                    : Color(0xFF00FF00),
                ),
                borderRadius: BorderRadius.circular(8.r),
                color: isSelected ? Color(0xFF00FF00).withOpacity(0.2) : null,
              ),
              child: Text(
                answer,
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 16.sp,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build ordering question UI
  Widget _buildOrderingQuestion(QuizQuestion question) {
    // Initialize available steps if empty
    if (_availableSteps.isEmpty) {
      _availableSteps = List.from(question.orderedSteps)..shuffle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.question,
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),

        // Selected order display
        if (_selectedOrder.isNotEmpty) ...[
          Text(
            'Your Order:',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          ..._selectedOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCorrect = _hasAnswered && question.orderedSteps[index] == step;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasAnswered
                      ? (isCorrect ? Colors.green : Colors.red)
                      : Color(0xFF00FF00),
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ListTile(
                leading: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _hasAnswered
                          ? (isCorrect ? Colors.green : Colors.red)
                          : Color(0xFF00FF00),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _hasAnswered
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Color(0xFF00FF00),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  step,
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 16.sp,
                  ),
                ),
                trailing: !_hasAnswered
                    ? IconButton(
                        icon: Icon(Icons.close, color: Color(0xFF00FF00)),
                        onPressed: () {
                          setState(() {
                            _availableSteps.add(step);
                            _selectedOrder.removeAt(index);
                          });
                        },
                      )
                    : null,
              ),
            );
          }).toList(),
        ],

        // Available steps
        if (!_hasAnswered && _availableSteps.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text(
            'Available Steps:',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _availableSteps.map((step) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOrder.add(step);
                    _availableSteps.remove(step);
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF00FF00)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    step,
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Check answer button for ordering
        if (!_hasAnswered && _selectedOrder.length == question.orderedSteps.length) ...[
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              _checkAnswer(_selectedOrder);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00FF00),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Check Order',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        // Show correct order after answering
        if (_hasAnswered) ...[
          SizedBox(height: 24.h),
          Text(
            'Correct Order:',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          ...question.orderedSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ListTile(
                leading: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  step,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.close, color: Color(0xFF00FF00)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Quiz',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 20.sp,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentPage + 1) / widget.questions.length,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    if (mounted) {
                      setState(() {
                        _currentPage = page;
                        _selectedOrder = [];
                        _availableSteps = [];
                      });
                    }
                  },
                  itemCount: widget.questions.length,
                  itemBuilder: (context, index) {
                    final question = widget.questions[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (question.type == 'MULTIPLE_CHOICE')
                              _buildMultipleChoiceQuestion(question)
                            else if (question.type == '**TRUE_FALSE')
                              _buildTrueFalseQuestion(question)
                            else if (question.type == '**ORDER')
                              _buildOrderingQuestion(question),
                              
                            if (_hasAnswered) ...[
                              SizedBox(height: 16.h),
                              Text(
                                question.explanation,
                                style: TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 14.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF00FF00),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                ),onPressed: _nextQuestion,
                                child: Text(
                                  _currentPage < widget.questions.length - 1 ? 'Next' : 'Finish',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleNoteQuizButton extends StatelessWidget {
  final String noteContent;

  const SingleNoteQuizButton({
    Key? key,
    required this.noteContent,
  }) : super(key: key);

  Future<List<QuizQuestion>> _generateQuiz(String note) async {
    try {
      print('\n=== Starting Quiz Generation ===');
      print('Note length: ${note.length} characters');
      
      final requestBody = json.encode({'notes': note});
      
      final baseUrl = dotenv.env['API_URL'];
      // if (!baseUrl) {
      //   throw Exception('API_URL environment variable is not set');
      // }

      // Create the full URL properly using Uri
      final uri = Uri.parse(baseUrl!);
      final fullUri = uri.resolve('/api/generate-quiz');
      print('Sending request to: $fullUri');
      
      final response = await http.post(
        fullUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('\nReceived response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final llmOutput = data['llm_output'] as String;
        print("Raw output: $llmOutput");
        
        List<QuizQuestion> questions = [];
        
        for (final line in llmOutput.split('\n')) {
          final trimmedLine = line.trim();
          
          if (trimmedLine.contains('|||')) {
            final parts = trimmedLine.split('|||').map((p) => p.trim()).toList();
            final questionType = parts[0].trim().toUpperCase();
            
            print('\nProcessing question type: $questionType');

            try {
              if (parts.length >= 3) {
                List<String> incorrectAnswers = [];
                String explanation = 'No explanation provided';

                // Strict question type matching
                switch (questionType) {
                  case '**TRUE_FALSE':
                    print('Processing True/False question');
                    incorrectAnswers = [];  // Will be handled by QuizQuestion class
                    explanation = parts.length > 3 ? parts[parts.length - 1] : explanation;
                    break;

                  case '**ORDER':
                    print('Processing Order question');
                    // For order questions, we don't need incorrect answers
                    incorrectAnswers = [];
                    explanation = parts.length > 3 ? parts[parts.length - 1] : explanation;
                    break;

                  case 'MULTIPLE_CHOICE':
                    print('Processing Multiple Choice question');
                    if (parts.length > 3) {
                      incorrectAnswers = parts.sublist(3, parts.length - 1)
                          .where((ans) => ans.trim().isNotEmpty)
                          .toList();
                      explanation = parts[parts.length - 1];
                    }
                    break;

                  default:
                    print('Invalid question type: $questionType');
                    continue;  // Skip this question
                }

                questions.add(QuizQuestion(
                  type: questionType,
                  question: parts[1],
                  correctAnswer: parts[2],
                  incorrectAnswers: incorrectAnswers,
                  explanation: explanation,
                ));
                print('Successfully added $questionType question');
              }
            } catch (e) {
              print('Error processing question: $e');
              continue;  // Skip this question and continue with the next
            }
          }
        }

        if (questions.isEmpty) {
          throw Exception('No valid questions were generated');
        }
        
        return questions;
      } else {
        throw Exception('Failed to generate quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('\nError in quiz generation: $e');
      rethrow;
    }
  }

  Future<void> _handleQuizGeneration(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00FF00),
          ),
        ),
      );

      final questions = await _generateQuiz(noteContent);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(questions: questions),
        ),
      );
      
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to generate quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00FF00),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      onPressed: () => _handleQuizGeneration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, color: Colors.black, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'Generate Quiz from Note',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}