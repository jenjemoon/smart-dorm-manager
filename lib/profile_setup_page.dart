import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _scrollController = ScrollController();

  final _nameController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _userIdController = TextEditingController();
  final _floorController = TextEditingController();
  final _roomNoController = TextEditingController();
  final _fridgeContainerController = TextEditingController();

  String? _selectedRc;
  String? _selectedBuilding;

  int _currentStep = 0;
  bool _isSaving = false;

  final List<Map<String, String>> _rcOptions = [
    {'rc': '토레이', 'building': '비전관'},
    {'rc': '장기려', 'building': '은혜관'},
    {'rc': '카이퍼', 'building': '하용조관'},
    {'rc': '손양원', 'building': '벧엘관'},
    {'rc': '열송학사', 'building': '로뎀관'},
    {'rc': '카마이클', 'building': '국제관'},
    {'rc': '갈대상자', 'building': '갈대상자'},
  ];

  final List<String> _questions = [
    '이름을 입력해주세요',
    '학번을 입력해주세요',
    '사용할 유저 ID를 입력해주세요',
    'RC / 관을 선택해주세요',
    '층을 입력해주세요',
    '방 번호를 입력해주세요',
    '냉장고 통 번호를 입력해주세요',
  ];

  Future<void> _nextStep() async {
    if (!_isCurrentStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정보를 입력해주세요')),
      );
      return;
    }

    if (_currentStep < _questions.length - 1) {
      setState(() {
        _currentStep++;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      _scrollController.animateTo(
        _currentStep * 120,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _saveUserInfo();
    }
  }

  Future<bool> _isUserIdAvailable(String userId) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .get();

    return result.docs.isEmpty;
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _studentNoController.text.trim().isNotEmpty;
      case 2:
        return _userIdController.text.trim().isNotEmpty;
      case 3:
        return _selectedRc != null && _selectedBuilding != null;
      case 4:
        return _floorController.text.trim().isNotEmpty;
      case 5:
        return _roomNoController.text.trim().isNotEmpty;
      case 6:
        return _fridgeContainerController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _saveUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': _nameController.text.trim(),
      'studentNo': _studentNoController.text.trim(),
      'userId': _userIdController.text.trim(),
      'rcName': _selectedRc,
      'buildingName': _selectedBuilding,
      'floor': int.parse(_floorController.text.trim()),
      'roomNo': int.parse(_roomNoController.text.trim()),
      'fridgeContainerNo': _fridgeContainerController.text.trim().toUpperCase(),
      'role': 'STUDENT',
      'penaltyScore': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입이 완료되었습니다. 환영합니다!'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _studentNoController.dispose();
    _userIdController.dispose();
    _floorController.dispose();
    _roomNoController.dispose();
    _fridgeContainerController.dispose();
    super.dispose();
  }

  Widget _buildQuestion(int index) {
    final bool isCurrent = index == _currentStep;
    final bool isDone = index < _currentStep;

    return AnimatedOpacity(
      opacity: isCurrent ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: index == 3
            ? _buildRcDropdown(isCurrent, isDone)
            : _buildTextField(index, isCurrent, isDone),
      ),
    );
  }

  Widget _buildTextField(int index, bool isCurrent, bool isDone) {
    final controllers = [
      _nameController,
      _studentNoController,
      _userIdController,
      _floorController,
      _roomNoController,
      _fridgeContainerController,
    ];

    final controllerIndex = index > 3 ? index - 1 : index;

    final controller = controllers[controllerIndex];

    TextInputType keyboardType = TextInputType.text;
    List<TextInputFormatter>? inputFormatters;
    int? maxLength;

    // 학번
    if (index == 1) {
      keyboardType = TextInputType.number;
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
      ];
      maxLength = 8;
    }

    // 층
    if (index == 4) {
      keyboardType = TextInputType.number;
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }

    // 방 번호
    if (index == 5) {
      keyboardType = TextInputType.number;
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }

    return TextField(
      controller: controller,
      enabled: isCurrent || isDone,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: _questions[index],
        border: const OutlineInputBorder(),
        suffixIcon: isDone ? const Icon(Icons.check) : null,
      ),
      onChanged: (value) async {
        // 학번 8자리 자동 다음
        if (index == 1 && value.length == 8) {
          await Future.delayed(const Duration(milliseconds: 300));
          _nextStep();
        }

        // userId 중복 체크
        if (index == 2 && value.isNotEmpty) {
          final available = await _isUserIdAvailable(value.trim());

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                available ? '사용 가능한 유저 ID입니다' : '이미 사용 중인 유저 ID입니다',
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildRcDropdown(bool isCurrent, bool isDone) {
    return DropdownButtonFormField<Map<String, String>>(
      value: _selectedRc == null
          ? null
          : _rcOptions.firstWhere(
              (item) => item['rc'] == _selectedRc,
            ),
      decoration: InputDecoration(
        labelText: _questions[3],
        border: const OutlineInputBorder(),
        suffixIcon: isDone ? const Icon(Icons.check) : null,
      ),
      items: _rcOptions.map((item) {
        return DropdownMenuItem<Map<String, String>>(
          value: item,
          child: Text('${item['rc']} (${item['building']})'),
        );
      }).toList(),
      onChanged: isCurrent || isDone
          ? (value) async {
              setState(() {
                _selectedRc = value?['rc'];
                _selectedBuilding = value?['building'];
              });

              await Future.delayed(const Duration(milliseconds: 300));

              if (_currentStep == 3) {
                _nextStep();
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastStep = _currentStep == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추가 정보 입력'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '서비스 이용을 위해 기본 정보를 입력해주세요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: List.generate(
                      _questions.length,
                      (index) => _buildQuestion(index),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _nextStep,
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : Text(isLastStep ? '가입 완료' : '다음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
