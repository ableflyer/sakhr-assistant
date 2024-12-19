import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createUserDocument(User user, {String? name}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    await userDoc.set({
      'name': name ?? user.displayName ?? 'User',
      'email': user.email,
      'profilePictureLink': user.photoURL ?? '',
    });

    // Create the sakhr_assistant subcollection
    await userDoc.collection('sakhr_assistant').doc('placeholder').set({
      'created': FieldValue.serverTimestamp(),
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create the user document in Firestore
      await _createUserDocument(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      print('Error signing up with email: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController controller;

  const CustomTextField({
    Key? key,
    required this.hint,
    this.isPassword = false,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              CustomTextField(
                hint: 'Email',
                controller: _emailController,
              ),
              CustomTextField(
                hint: 'Password',
                isPassword: true,
                controller: _passwordController,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () async {
                  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields')),
                    );
                    return;
                  }
                  
                  try {
                    setState(() => _isLoading = true); // Add _isLoading bool to your state
                    final user = await _authService.signUpWithEmail(
                      _emailController.text.trim(),
                      _passwordController.text,
                    );
                    if (user != null) {
                      if (!mounted) return; // Check if widget is still mounted
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign up failed. Please try again.')),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String message = 'An error occurred';
                    if (e.code == 'weak-password') {
                      message = 'The password provided is too weak.';
                    } else if (e.code == 'email-already-in-use') {
                      message = 'An account already exists for that email.';
                    } else if (e.code == 'invalid-email') {
                      message = 'Please enter a valid email address.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16.sp),
                    ),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: () async {
                  final user = await _authService.signInWithGoogle();
                  if (user != null) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');  // Use named route
                },
                child: Text(
                  'Already have an account? Log in',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              CustomTextField(
                hint: 'Email',
                controller: _emailController,
              ),
              CustomTextField(
                hint: 'Password',
                isPassword: true,
                controller: _passwordController,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () async {
                  final user = await _authService.signInWithEmail(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (user != null) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Log In',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: () async {
                  final user = await _authService.signInWithGoogle();
                  if (user != null) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');  // Use named route
                },
                child: Text(
                  'Need an account? Sign up',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}