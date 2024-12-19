import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClassSchedule {
  final String id;
  final String className;
  final String courseCode;
  final String time;
  final List<String> daysOfWeek;
  final String professor;
  final String room;
  final DateTime startTime;
  final DateTime endTime;

  ClassSchedule({
    required this.id,
    required this.className,
    required this.courseCode,
    required this.time,
    required this.daysOfWeek,
    required this.professor,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  factory ClassSchedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassSchedule(
      id: doc.id,
      className: data['className'] ?? '',
      courseCode: data['courseCode'] ?? '',
      time: data['time'] ?? '',
      daysOfWeek: List<String>.from(data['daysOfWeek'] ?? []),
      professor: data['professor'] ?? '',
      room: data['room'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'courseCode': courseCode,
      'time': time,
      'daysOfWeek': daysOfWeek,
      'professor': professor,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class ScheduleScreen extends StatelessWidget {
  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  List<ClassSchedule> sortSchedulesByTime(List<ClassSchedule> schedules) {
    schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    return schedules;
  }

  List<ClassSchedule> getClassesForDay(List<ClassSchedule> schedules, String day) {
    return sortSchedulesByTime(
      schedules.where((schedule) => schedule.daysOfWeek.contains(day)).toList(),
    );
  }

  Future<void> _deleteSchedule(BuildContext context, String scheduleId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sakhr_assistant')
          .doc("placeholder")
          .collection("schedules")
          .doc(scheduleId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class removed from schedule')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing class: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('sakhr_assistant')
              .doc("placeholder")
              .collection("schedules")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(color: Color(0xFF00FF00)),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF00)),
              );
            }

            final schedules = snapshot.data?.docs
                .map((doc) => ClassSchedule.fromFirestore(doc))
                .toList() ?? [];

            return SingleChildScrollView(
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
                          'Schedule',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF00FF00),
                            size: 32.sp,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddScheduleScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Week View
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        children: weekDays.map((day) {
                          final dayClasses = getClassesForDay(schedules, day);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day Header
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF00FF00),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: Color(0xFF00FF00),
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      day,
                                      style: TextStyle(
                                        color: Color(0xFF00FF00),
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (dayClasses.isEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: Text(
                                    'No classes scheduled',
                                    style: TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontSize: 14.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...dayClasses.map((schedule) => Dismissible(
                                  key: Key(schedule.id),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(right: 16.w),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) =>
                                      _deleteSchedule(context, schedule.id),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditScheduleScreen(
                                            schedule: schedule,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(vertical: 8.h),
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF00FF00).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    color: Color(0xFF00FF00),
                                                    size: 16.sp,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    schedule.time,
                                                    style: TextStyle(
                                                      color: Color(0xFF00FF00),
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                                                  schedule.courseCode,
                                                  style: TextStyle(
                                                    color: Color(0xFF00FF00),
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            schedule.className,
                                            style: TextStyle(
                                              color: Color(0xFF00FF00),
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    color: Color(0xFF00FF00),
                                                    size: 16.sp,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    schedule.professor,
                                                    style: TextStyle(
                                                      color: Color(0xFF00FF00),
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.room_outlined,
                                                    color: Color(0xFF00FF00),
                                                    size: 16.sp,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    schedule.room,
                                                    style: TextStyle(
                                                      color: Color(0xFF00FF00),
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                              if (day != weekDays.last) SizedBox(height: 16.h),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({Key? key}) : super(key: key);

  @override
  _AddScheduleScreenState createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  String? _selectedClassId;
  Map<String, dynamic>? _selectedClassData;
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 30);
  final List<String> _selectedDays = [];
  final _roomController = TextEditingController();
  bool _isLoading = false;

  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF00FF00),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Color(0xFF00FF00),
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _addSchedule() async {
    if (_selectedClassData == null ||
        _roomController.text.isEmpty ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields and select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not found');

      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        _endTime.hour,
        _endTime.minute,
      );

      final timeString = '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sakhr_assistant')
          .doc("placeholder")
          .collection("schedules")
          .add({
        'className': _selectedClassData!['name'],
        'courseCode': _selectedClassData!['code'],
        'professor': _selectedClassData!['teacher'],
        'room': _roomController.text.trim(),
        'time': timeString,
        'daysOfWeek': _selectedDays,
        'startTime': startTime,
        'endTime': endTime,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding schedule: $e'),
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
          'Add Class Schedule',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Class Selection
            Text(
              'Select Class',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
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
                  return Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Color(0xFF00FF00)));
                }

                if (!snapshot.hasData) {
                  return CircularProgressIndicator(color: Color(0xFF00FF00));
                }

                final classes = snapshot.data!.docs;

                if (classes.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF00FF00)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'No classes added yet. Please add classes first.',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 14.sp,
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF00FF00)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClassId,
                      hint: Text(
                        'Select a class',
                        style: TextStyle(
                          color: Color(0xFF00FF00).withOpacity(0.5),
                        ),
                      ),
                      dropdownColor: Colors.black,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
                      items: classes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            '${data['code']} - ${data['name']}',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 16.sp,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          final selectedDoc = classes.firstWhere((doc) => doc.id == value);
                          setState(() {
                            _selectedClassId = value;
                            _selectedClassData = selectedDoc.data() as Map<String, dynamic>;
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
            
            // Room Number
            _buildTextField(
              controller: _roomController,
              hint: 'Room Number',
              icon: Icons.room_outlined,
            ),
            SizedBox(height: 24.h),

            // Time Selection
            Text(
              'Class Time',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    label: 'Start Time',
                    time: _startTime,
                    onPressed: () => _selectTime(true),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTimeButton(
                    label: 'End Time',
                    time: _endTime,
                    onPressed: () => _selectTime(false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Days Selection
            Text(
              'Class Days',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: weekDays.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Color(0xFF00FF00),
                      fontSize: 14.sp,
                    ),
                  ),
                  selectedColor: Color(0xFF00FF00),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    side: BorderSide(
                      color: Color(0xFF00FF00),
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 32.h),

            // Add Button
            ElevatedButton(
              onPressed: _isLoading ? null : _addSchedule,
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

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
          side: BorderSide(color: Color(0xFF00FF00)),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTimeOfDay(time),
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class EditScheduleScreen extends StatefulWidget {
  final ClassSchedule schedule;

  const EditScheduleScreen({
    Key? key,
    required this.schedule,
  }) : super(key: key);

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late TextEditingController _classNameController;
  late TextEditingController _courseCodeController;
  late TextEditingController _professorController;
  late TextEditingController _roomController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<String> _selectedDays;
  bool _isLoading = false;

  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    _classNameController = TextEditingController(text: widget.schedule.className);
    _courseCodeController = TextEditingController(text: widget.schedule.courseCode);
    _professorController = TextEditingController(text: widget.schedule.professor);
    _roomController = TextEditingController(text: widget.schedule.room);
    _startTime = TimeOfDay.fromDateTime(widget.schedule.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.schedule.endTime);
    _selectedDays = List.from(widget.schedule.daysOfWeek);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF00FF00),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Color(0xFF00FF00),
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _updateSchedule() async {
    if (_classNameController.text.isEmpty ||
        _courseCodeController.text.isEmpty ||
        _professorController.text.isEmpty ||
        _roomController.text.isEmpty ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields and select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not found');

      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        _endTime.hour,
        _endTime.minute,
      );

      final timeString = '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sakhr_assistant')
          .doc("placeholder")
          .collection("schedules")
          .doc(widget.schedule.id)
          .update({
        'className': _classNameController.text.trim(),
        'courseCode': _courseCodeController.text.trim(),
        'professor': _professorController.text.trim(),
        'room': _roomController.text.trim(),
        'time': timeString,
        'daysOfWeek': _selectedDays,
        'startTime': startTime,
        'endTime': endTime,'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating schedule: $e'),
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
    _classNameController.dispose();
    _courseCodeController.dispose();
    _professorController.dispose();
    _roomController.dispose();
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
          'Edit Class Schedule',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Color(0xFF00FF00)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: Text(
                    'Delete Class',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 20.sp,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to delete this class from your schedule?',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 16.sp,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          final userId = FirebaseAuth.instance.currentUser?.uid;
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('sakhr_assistant')
                              .doc("placeholder")
                              .collection("schedules")
                              .doc(widget.schedule.id)
                              .delete();
                          if (!mounted) return;
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Return to schedule screen
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting class: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _classNameController,
              hint: 'Class Name',
              icon: Icons.class_outlined,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _courseCodeController,
              hint: 'Course Code',
              icon: Icons.code,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _professorController,
              hint: 'Professor Name',
              icon: Icons.person_outline,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _roomController,
              hint: 'Room Number',
              icon: Icons.room_outlined,
            ),
            SizedBox(height: 24.h),

            // Time Selection
            Text(
              'Class Time',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    label: 'Start Time',
                    time: _startTime,
                    onPressed: () => _selectTime(true),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTimeButton(
                    label: 'End Time',
                    time: _endTime,
                    onPressed: () => _selectTime(false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Days Selection
            Text(
              'Class Days',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: weekDays.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Color(0xFF00FF00),
                      fontSize: 14.sp,
                    ),
                  ),
                  selectedColor: Color(0xFF00FF00),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    side: BorderSide(
                      color: Color(0xFF00FF00),
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 32.h),

            // Update Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateSchedule,
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
                      'Update Class',
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

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
          side: BorderSide(color: Color(0xFF00FF00)),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTimeOfDay(time),
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}