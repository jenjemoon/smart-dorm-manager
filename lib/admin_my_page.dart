import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMyPage extends StatefulWidget {
  const AdminMyPage({Key? key}) : super(key: key);

  @override
  State<AdminMyPage> createState() => _AdminMyPageState();
}

class _AdminMyPageState extends State<AdminMyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('관리자 마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminProfile(),
            const SizedBox(height: 32),

            const Text('관리자 할 일 (To-Do)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildAdminTodoSection(),
            const SizedBox(height: 32),

            _buildManagementShortcuts(context),
            const SizedBox(height: 32),

            _buildNotificationCenter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final String name = userData?['name'] ?? '관리자';
        final String studentNo = userData?['studentNo'] ?? '-';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$name 님', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('관리자 (ADMIN)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('사번/학번: $studentNo', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminTodoSection() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('machines').where('status', isEqualTo: 'BROKEN').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return _todoCard(
              icon: Icons.warning_amber_rounded,
              title: '기기 고장 신고',
              count: count,
              color: Colors.red.shade100,
              iconColor: Colors.red.shade700,
              onTap: () { /* 고장 관리 리스트 */ },
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usageSessions').where('status', isEqualTo: 'OVERDUE').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return _todoCard(
              icon: Icons.local_laundry_service,
              title: '세탁물 미수거 건',
              count: count,
              color: Colors.orange.shade100,
              iconColor: Colors.orange.shade800,
              onTap: () { /* 미수거 관리 리스트 */ },
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('refrigeratorItems').where('status', isEqualTo: 'EXPIRED').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return _todoCard(
              icon: Icons.kitchen,
              title: '냉장고 유효기간 만료/초과 건',
              count: count,
              color: Colors.yellow.shade100,
              iconColor: Colors.orange.shade900,
              onTap: () { /* 냉장고 음식 관리 페이지 */ },
            );
          },
        ),
      ],
    );
  }

  Widget _todoCard({required IconData icon, required String title, required int count, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: count > 0 ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: count > 0 ? iconColor.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: count > 0 ? Colors.white : Colors.grey.shade300, shape: BoxShape.circle),
              child: Icon(icon, color: count > 0 ? iconColor : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal, color: count > 0 ? Colors.black87 : Colors.grey)),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(12)),
                child: Text('$count건', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              )
            else
              const Text('0건', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementShortcuts(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () { /* 사용자 관리 페이지 */ },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: const [
                  Icon(Icons.people_alt_outlined, color: Colors.white, size: 28),
                  SizedBox(height: 8),
                  Text('사용자 리스트', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () { /* 벌점 관리 페이지 */ },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: const [
                  Icon(Icons.gavel_rounded, color: Colors.black87, size: 28),
                  SizedBox(height: 8),
                  Text('벌점 관리', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. 알림 및 메시지 센터
  Widget _buildNotificationCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('알림 센터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [Tab(text: '관리자 시스템 알림'), Tab(text: '받은 문의/메시지')],
        ),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: _tabController,
            children: [
              const Center(child: Text('새로운 시스템 알림이 없습니다.', style: TextStyle(color: Colors.grey))),
              const Center(child: Text('받은 메시지함이 비어있습니다.', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ],
    );
  }
}