import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MachineHomePage extends StatefulWidget {
  const MachineHomePage({Key? key}) : super(key: key);

  @override
  State<MachineHomePage> createState() => _MachineHomePageState();
}

class _MachineHomePageState extends State<MachineHomePage> {
  String _selectedType = 'WASHER';
  String _selectedFilter = 'ALL';

  String _formatStatus(String status) {
    switch (status) {
      case 'AVAILABLE':
        return '사용 가능';
      case 'USING':
        return '사용 중';
      case 'WAITING':
        return '수거 대기';
      case 'BROKEN':
        return '고장';
      default:
        return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return const Color(0xFF9BC3FF);
      case 'USING':
        return Colors.black;
      case 'WAITING':
        return Colors.orange;
      case 'BROKEN':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _pageTitle() {
    return _selectedType == 'WASHER' ? '세탁' : '건조';
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('machines')
        .where('machineType', isEqualTo: _selectedType);

    if (_selectedFilter == 'AVAILABLE') {
      query = query.where('status', isEqualTo: 'AVAILABLE');
    } else if (_selectedFilter == 'USING') {
      query = query.where('status', isEqualTo: 'USING');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          '홈',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _typeButton('세탁기', 'WASHER'),
                    const SizedBox(width: 12),
                    _typeButton('건조기', 'DRYER'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _filterButton('전체', 'ALL'),
                    const SizedBox(width: 12),
                    _filterButton('사용 가능', 'AVAILABLE'),
                    const SizedBox(width: 12),
                    _filterButton('사용 중', 'USING'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '등록된 기기가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final machines = snapshot.data!.docs;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pageTitle(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 32),
                        width: 60,
                        height: 5,
                        color: Colors.black,
                      ),
                      Column(
                        children: machines.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          final machineNo = data['machineNo'] ?? '';
                          final status = data['status'] ?? 'AVAILABLE';
                          final location = data['location'] ?? '--';
                          final remainingTime =
                              data['remainingTime'] ?? '00:00';

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/machineDetail',
                                arguments: {
                                  'machineId': doc.id,
                                  'machineType': data['machineType'],
                                },
                              );
                            },
                            child: _machineCard(
                              machineNo: machineNo.toString(),
                              status: status,
                              location: location,
                              remainingTime: remainingTime,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(String label, String type) {
    final bool isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedFilter = 'ALL';
          });
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String label, String filter) {
    final bool isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _machineCard({
    required String machineNo,
    required String status,
    required String location,
    required String remainingTime,
  }) {
    final bool isUsing = status == 'USING';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            color: Colors.grey.shade200,
            child: Icon(
              _selectedType == 'WASHER'
                  ? Icons.local_laundry_service_outlined
                  : Icons.dry_cleaning_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(
                      color:
                          status == 'AVAILABLE' ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_selectedType == 'WASHER' ? '세탁기' : '건조기'} $machineNo',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('⌾ $location'),
                if (isUsing) ...[
                  const SizedBox(height: 8),
                  Text('남은 시간 $remainingTime'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
