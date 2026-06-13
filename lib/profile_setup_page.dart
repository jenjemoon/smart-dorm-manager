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
  bool _isCheckingUserId = false;

  final List<Map<String, String>> _rcOptions = [
    {'rc': '토레이', 'building': '비전관'},
    {'rc': '장기려', 'building': '은혜관'},
    {'rc': '카이퍼', 'building': '하용조관'},
    {'rc': '손양원', 'building': '벧엘관'},
    {'rc': '열송학사', 'building': '로뎀관'},
    {'rc': '카마이클', 'building': '국제관'},
    {'rc': '갈대상자', 'building': '갈대상자'},
  ];

  final List<String> _titles = [
    '이름을 알려주세요',
    '학번을 입력해주세요',
    '사용할 ID를 정해주세요',
    'RC / 관을 선택해주세요',
    '층을 입력해주세요',
    '방 번호를 입력해주세요',
    '냉장고 통 번호를 입력해주세요',
  ];

  final List<String> _subtitles = [
    '앱에서 표시될 이름이에요.',
    '8자리 학번을 입력해주세요.',
    '다른 사용자와 구분할 ID예요.',
    '거주 중인 RC와 건물을 선택해주세요.',
    '현재 거주 중인 층을 입력해주세요.',
    '방 번호를 숫자로 입력해주세요.',
    '냉장고에 배정된 통 번호를 입력해주세요.',
  ];

  bool get _isLastStep => _currentStep == _titles.length - 1;

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
        return _studentNoController.text.trim().length == 8;
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

  Future<void> _nextStep() async {
    if (!_isCurrentStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentStep == 1 ? '학번은 8자리로 입력해주세요.' : '정보를 입력해주세요.',
          ),
        ),
      );
      return;
    }

    if (_currentStep == 2) {
      setState(() {
        _isCheckingUserId = true;
      });

      final available = await _isUserIdAvailable(_userIdController.text.trim());

      if (!mounted) return;

      setState(() {
        _isCheckingUserId = false;
      });

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 사용 중인 유저 ID입니다.')),
        );
        return;
      }
    }

    if (_isLastStep) {
      await _saveUserInfo();
    } else {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep == 0) return;

    setState(() {
      _currentStep--;
    });
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
      const SnackBar(content: Text('회원가입이 완료되었습니다.')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildInput() {
    switch (_currentStep) {
      case 0:
        return _textField(
          controller: _nameController,
          hint: '예: 김한동',
        );
      case 1:
        return _textField(
          controller: _studentNoController,
          hint: '예: 12345678',
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case 2:
        return _textField(
          controller: _userIdController,
          hint: '예: handong',
        );
      case 3:
        return DropdownButtonFormField<Map<String, String>>(
          value: _selectedRc == null
              ? null
              : _rcOptions.firstWhere((item) => item['rc'] == _selectedRc),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'RC / 관',
          ),
          items: _rcOptions.map((item) {
            return DropdownMenuItem<Map<String, String>>(
              value: item,
              child: Text('${item['rc']} (${item['building']})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRc = value?['rc'];
              _selectedBuilding = value?['building'];
            });
          },
        );
      case 4:
        return _textField(
          controller: _floorController,
          hint: '예: 3',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case 5:
        return _textField(
          controller: _roomNoController,
          hint: '예: 301',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case 6:
        return _textField(
          controller: _fridgeContainerController,
          hint: '예: A3',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hint,
        counterText: '',
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentNoController.dispose();
    _userIdController.dispose();
    _floorController.dispose();
    _roomNoController.dispose();
    _fridgeContainerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _titles.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '추가 정보 입력',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: Colors.black,
              ),
              const SizedBox(height: 32),
              Text(
                '${_currentStep + 1} / ${_titles.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey(_currentStep),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[_currentStep],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitles[_currentStep],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInput(),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _prevStep,
                        child: const Text('이전'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (_isSaving || _isCheckingUserId) ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: _isSaving || _isCheckingUserId
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isLastStep ? '가입 완료' : '다음'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
