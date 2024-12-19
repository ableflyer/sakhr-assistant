import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum ReminderType { ASSIGNMENT, EXAM, DEADLINE, MEETING }
enum Priority { HIGH, MEDIUM, LOW }

class ReminderItem {
  final String title;
  final String description;
  final DateTime dueDate;
  final ReminderType type;
  final Priority priority;
  final String course;

  ReminderItem({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.type,
    required this.priority,
    required this.course,
  });
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  Color getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.HIGH:
        return const Color(0xFFFF0000);
      case Priority.MEDIUM:
        return const Color(0xFFFFAA00);
      case Priority.LOW:
        return const Color(0xFF00FF00);
    }
  }

  String getTimeUntil(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }

  Icon getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.ASSIGNMENT:
        return Icon(Icons.assignment_outlined, color: Color(0xFF00FF00), size: 20.sp);
      case ReminderType.EXAM:
        return Icon(Icons.quiz_outlined, color: Color(0xFF00FF00), size: 20.sp);
      case ReminderType.DEADLINE:
        return Icon(Icons.timer_outlined, color: Color(0xFF00FF00), size: 20.sp);
      case ReminderType.MEETING:
        return Icon(Icons.people_outline, color: Color(0xFF00FF00), size: 20.sp);
    }
  }

  Priority stringToPriority(String str) {
    return Priority.values.firstWhere(
      (e) => e.toString() == str,
      orElse: () => Priority.MEDIUM,
    );
  }

  ReminderType stringToType(String str) {
    return ReminderType.values.firstWhere(
      (e) => e.toString() == str,
      orElse: () => ReminderType.ASSIGNMENT,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

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
                      'Reminders',
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
                            builder: (context) => AddReminderScreen(),
                          ),
                        );
                      },
                    )
                  ],
                ),
                SizedBox(height: 20.h),

                // Reminders List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('reminders')
                      .orderBy('dueDate')
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
                          'No reminders yet',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data!.docs[index].data() 
                            as Map<String, dynamic>;
                        final reminder = ReminderItem(
                          title: data['title'] ?? '',
                          description: data['description'] ?? '',
                          dueDate: (data['dueDate'] as Timestamp).toDate(),
                          type: stringToType(data['type']),
                          priority: stringToPriority(data['priority']),
                          course: data['course'] ?? '',
                        );
                        
                        return Dismissible(
                          key: Key(snapshot.data!.docs[index].id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            // Show confirmation dialog
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    side: BorderSide(color: Color(0xFF00FF00)),
                                  ),
                                  title: Text(
                                    'Delete Reminder',
                                    style: TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete this reminder?',
                                    style: TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
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
                                );
                              },
                            );
                          },
                          onDismissed: (direction) async {
                            // Delete the reminder
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('reminders')
                                .doc(snapshot.data!.docs[index].id)
                                .delete();
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditReminderScreen(
                                    reminderId: snapshot.data!.docs[index].id,
                                    reminder: reminder,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                border: Border.all(color: getPriorityColor(reminder.priority)),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                children: [
                                  // Header with type and time
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: getPriorityColor(reminder.priority).withOpacity(0.1),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8.r),
                                        topRight: Radius.circular(8.r),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            getTypeIcon(reminder.type),
                                            SizedBox(width: 8.w),
                                            Text(
                                              reminder.type.toString().split('.').last,
                                              style: TextStyle(
                                                color: getPriorityColor(reminder.priority),
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Due in ${getTimeUntil(reminder.dueDate)}',
                                              style: TextStyle(
                                                color: getPriorityColor(reminder.priority),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Icon(
                                              Icons.edit_outlined,
                                              color: getPriorityColor(reminder.priority),
                                              size: 20.sp,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Content
                                  Container(
                                    padding: EdgeInsets.all(16.w),
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
                                                  color: getPriorityColor(reminder.priority),
                                                ),
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                reminder.course,
                                                style: TextStyle(
                                                  color: getPriorityColor(reminder.priority),
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                reminder.title,
                                                style: TextStyle(
                                                  color: getPriorityColor(reminder.priority),
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          reminder.description,
                                          style: TextStyle(
                                            color: getPriorityColor(reminder.priority),
                                            fontSize: 16.sp,
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

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({Key? key}) : super(key: key);

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  ReminderType _selectedType = ReminderType.ASSIGNMENT;
  Priority _selectedPriority = Priority.MEDIUM;
  String? _selectedClass;
  bool _isLoading = false;

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
          'Add Reminder',
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
            _buildTextField(
              controller: _titleController,
              hint: 'Title',
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Description',
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            
            // Class Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('sakhr_assistant')
                  .doc("placeholder")
                  .collection("classes")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator(color: Color(0xFF00FF00));
                }

                List<String> classes = snapshot.data!.docs
                    .map((doc) => doc['code'] as String)
                    .toList();

                return _buildDropdown(
                  value: _selectedClass,
                  items: classes,
                  hint: 'Select Class',
                );
              },
            ),
            SizedBox(height: 16.h),

            // Type Dropdown
            _buildDropdown(
              value: _selectedType.toString(),
              items: ReminderType.values.map((e) => e.toString()).toList(),
              hint: 'Reminder Type',
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = ReminderType.values
                        .firstWhere((e) => e.toString() == value);
                  });
                }
              },
            ),
            SizedBox(height: 16.h),

            // Priority Dropdown
            _buildDropdown(
              value: _selectedPriority.toString(),
              items: Priority.values.map((e) => e.toString()).toList(),
              hint: 'Priority Level',
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = Priority.values
                        .firstWhere((e) => e.toString() == value);
                  });
                }
              },
            ),
            SizedBox(height: 16.h),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
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
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Color(0xFF00FF00),
                                surface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: Text(
                      _selectedTime.format(context),
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Add Button
            ElevatedButton(
              onPressed: _isLoading ? null : _addReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00FF00),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                disabledBackgroundColor: Color(0xFF00FF00).withOpacity(0.5),
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
                      'Add Reminder',
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
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF00FF00)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Color(0xFF00FF00)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFF00FF00).withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF00FF00)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Color(0xFF00FF00).withOpacity(0.5),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item.split('.').last,
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 16.sp,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged ?? (String? value) {
            if (value != null) {
              setState(() => _selectedClass = value);
            }
          },
          dropdownColor: Colors.black,
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
          isExpanded: true,
        ),
      ),
    );
  }

  Future<void> _addReminder() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedClass == null) {
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

      final DateTime dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': Timestamp.fromDate(dueDateTime),
        'type': _selectedType.toString(),
        'priority': _selectedPriority.toString(),
        'course': _selectedClass,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding reminder: $e'),
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class EditReminderScreen extends StatefulWidget {
  final String reminderId;
  final ReminderItem reminder;

  const EditReminderScreen({
    Key? key,
    required this.reminderId,
    required this.reminder,
  }) : super(key: key);

  @override
  _EditReminderScreenState createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderType _selectedType;
  late Priority _selectedPriority;
  late String? _selectedClass;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(text: widget.reminder.description);
    _selectedDate = widget.reminder.dueDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.reminder.dueDate);
    _selectedType = widget.reminder.type;
    _selectedPriority = widget.reminder.priority;
    _selectedClass = widget.reminder.course;
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
        'Edit Reminder',
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
          _buildTextField(
            controller: _titleController,
            hint: 'Title',
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _descriptionController,
            hint: 'Description',
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          
          // Class Dropdown
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('sakhr_assistant')
                .doc("placeholder")
                .collection("classes")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator(color: Color(0xFF00FF00));
              }

              List<String> classes = snapshot.data!.docs
                  .map((doc) => doc['code'] as String)
                  .toList();

              return _buildDropdown(
                value: _selectedClass,
                items: classes,
                hint: 'Select Class',
              );
            },
          ),
          SizedBox(height: 16.h),

          // Type Dropdown
          _buildDropdown(
            value: _selectedType.toString(),
            items: ReminderType.values.map((e) => e.toString()).toList(),
            hint: 'Reminder Type',
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = ReminderType.values
                      .firstWhere((e) => e.toString() == value);
                });
              }
            },
          ),
          SizedBox(height: 16.h),

          // Priority Dropdown
          _buildDropdown(
            value: _selectedPriority.toString(),
            items: Priority.values.map((e) => e.toString()).toList(),
            hint: 'Priority Level',
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPriority = Priority.values
                      .firstWhere((e) => e.toString() == value);
                });
              }
            },
          ),
          SizedBox(height: 16.h),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate.isBefore(DateTime.now()) ? DateTime.now() : _selectedDate,
                      firstDate: DateTime.now().subtract(Duration(days: 365)), // Allow dates from past year
                      lastDate: DateTime.now().add(Duration(days: 365)),  // Allow dates up to next year
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
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
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
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                  child: Text(
                    _selectedTime.format(context),
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Update Button
          ElevatedButton(
            onPressed: _isLoading ? null : _updateReminder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00FF00),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              disabledBackgroundColor: Color(0xFF00FF00).withOpacity(0.5),
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
                    'Update Reminder',
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

// Add these helper methods from AddReminderScreen
Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFF00FF00)),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Color(0xFF00FF00)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Color(0xFF00FF00).withOpacity(0.5)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
      ),
    ),
  );
}

Widget _buildDropdown({
  required String? value,
  required List<String> items,
  required String hint,
  Function(String?)? onChanged,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFF00FF00)),
      borderRadius: BorderRadius.circular(8.r),
    ),
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: Color(0xFF00FF00).withOpacity(0.5),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item.split('.').last,
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 16.sp,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged ?? (String? value) {
          if (value != null) {
            setState(() => _selectedClass = value);
          }
        },
        dropdownColor: Colors.black,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
        isExpanded: true,
      ),
    ),
  );
}

  Future<void> _updateReminder() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedClass == null) {
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

      final DateTime dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .doc(widget.reminderId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': Timestamp.fromDate(dueDateTime),
        'type': _selectedType.toString(),
        'priority': _selectedPriority.toString(),
        'course': _selectedClass,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating reminder: $e'),
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}