import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_my_page.dart';
import 'admin_my_page.dart'; 

class MyPageWrapper extends StatelessWidget {
  const MyPageWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final String role = userData?['role'] ?? 'STUDENT';

        if (role == 'ADMIN' || role == 'BOTH') {
          return const AdminMyPage();
        } else {
          return const StudentMyPage();
        }
      },
    );
  }
}