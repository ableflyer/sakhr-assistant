import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Add this function in the HomeScreen class
  void _showProfileDialog(BuildContext context, Map<String, dynamic>? userData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Color(0xFF00FF00)),
          ),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF00FF00), width: 2),
                  ),
                  child: userData?['profilePictureLink'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40.r),
                          child: Image.network(
                            userData!['profilePictureLink'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFF00FF00),
                          size: 48.sp,
                        ),
                ),
                SizedBox(height: 16.h),
                
                // Name
                Text(
                  userData?['name'] ?? 'User',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Profile Button
                InkWell(
                  onTap: () {
                    // Will be implemented later
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF00FF00)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Logout Button
                InkWell(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacementNamed(context, '/'); // Navigate to landing page
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Color(0xFF00FF00),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getRecentNotes() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('sakhr_assistant')
    .doc('placeholder')
    .collection('classes')
    .snapshots()
    .asyncMap((classesSnapshot) async {
      List<Map<String, dynamic>> allNotes = [];
      
      for (var classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final notesSnapshot = await classDoc.reference
            .collection('notes')
            .orderBy('timestamp', descending: true)
            .get();
            
        allNotes.addAll(notesSnapshot.docs.map((doc) => {
          ...doc.data(),
          'classCode': classData['code'],
          'className': classData['name']
        }));
      }
      
      allNotes.sort((a, b) => (b['timestamp'] as Timestamp)
          .compareTo(a['timestamp'] as Timestamp));
          
      return allNotes.take(3).toList();
    });
  }

  String getOrdinalDate(DateTime date) {
    final day = date.day;
    String ordinal = 'th';
    
    if (day % 10 == 1 && day != 11) {
      ordinal = 'st';
    } else if (day % 10 == 2 && day != 12) {
      ordinal = 'nd';
    } else if (day % 10 == 3 && day != 13) {
      ordinal = 'rd';
    }

    return DateFormat("MMMM d'$ordinal' y").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();
    final dateFormat = getOrdinalDate(currentDate);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Profile
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final firstName = userData?['name'].split(" ")[0] ?? 'User';
                    final profilePicture = userData?['profilePictureLink'];

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hey ${firstName}!',
                                style: TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: Color(0xFF00FF00),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    dateFormat,
                                    style: TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showProfileDialog(context, userData),
                            child: Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFF00FF00)),
                              ),
                              child: profilePicture != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24.r),
                                      child: Image.network(
                                        profilePicture,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.account_circle_outlined,
                                      color: Color(0xFF00FF00),
                                      size: 32.sp,
                                    ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),

                // Recent Notes Section
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Notes',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Color(0xFF00FF00), size: 16.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'Add Note',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getRecentNotes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}',
                        style: TextStyle(color: Color(0xFF00FF00)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: Color(0xFF00FF00)));
                  }

                  final notes = snapshot.data ?? [];

                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        'No notes yet',
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
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final noteData = notes[index];
                      final timestamp = noteData['timestamp'] as Timestamp;
                      final date = DateFormat('MMMM d\'th\' y').format(timestamp.toDate());

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF00FF00)),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
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
                                      border: Border.all(color: Color(0xFF00FF00)),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      noteData['classCode'] ?? '',
                                      style: TextStyle(
                                        color: Color(0xFF00FF00),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Lecture Notes',
                                      style: TextStyle(
                                        color: Color(0xFF00FF00),
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                noteData['className'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    color: Color(0xFF00FF00),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // Important Stuff Section
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Important Stuff',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Color(0xFF00FF00), size: 16.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'Add Reminder',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('reminders')
                      .where('priority', isEqualTo: 'Priority.HIGH')
                      .orderBy('dueDate', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Color(0xFF00FF00)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child:
                              CircularProgressIndicator(color: Color(0xFF00FF00)));
                    }

                    final reminders = snapshot.data?.docs ?? [];

                    if (reminders.isEmpty) {
                      return Center(
                        child: Text(
                          'No important reminders',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 170.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final reminderData =
                              reminders[index].data() as Map<String, dynamic>;
                          final dueDate = reminderData['dueDate'] as Timestamp;
                          final difference =
                              dueDate.toDate().difference(DateTime.now());
                          final dueText = difference.inDays > 7
                              ? '${(difference.inDays / 7).floor()} weeks'
                              : '${difference.inDays} days';

                          return Container(
                            margin: EdgeInsets.only(right: 12.w),
                            width: 160.w,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFFF0000)),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFFF0000)),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    reminderData['course'] ?? '',
                                    style: TextStyle(
                                      color: Color(0xFFFF0000),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  reminderData['title'] ?? '',
                                  style: TextStyle(
                                    color: Color(0xFFFF0000),
                                    fontSize: 16.sp,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_outlined,
                                      color: Color(0xFFFF0000),
                                      size: 14.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Due: $dueText',
                                      style: TextStyle(
                                        color: Color(0xFFFF0000),
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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