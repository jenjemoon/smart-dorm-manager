import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RefrigeratorCameraPage extends StatefulWidget {
  const RefrigeratorCameraPage({Key? key}) : super(key: key);

  @override
  State<RefrigeratorCameraPage> createState() => _RefrigeratorCameraPageState();
}

class _RefrigeratorCameraPageState extends State<RefrigeratorCameraPage> {
  File? _imageFile;
  bool _isAnalyzing = false;
  bool _isSaving = false;

  String? _itemName;
  String? _expireDate;
  String _storageType = 'IN_CONTAINER';

  Future<void> _takePhoto() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    setState(() {
      _imageFile = File(pickedImage.path);
      _itemName = null;
      _expireDate = null;
    });

    await _analyzeFoodImage();
  }

  Future<void> _analyzeFoodImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    // TODO: 나중에 여기를 실제 AI API 결과로 교체
    // 여기 해야함.
    setState(() {
      _itemName = '우유';
      _expireDate = '2026.06.15';
      _isAnalyzing = false;
    });
  }

  Future<void> _registerItem() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (_itemName == null || _itemName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식품 분석 후 등록해주세요.')),
      );
      return;
    }
    //
    setState(() {
      _isSaving = true;
    });

    await FirebaseFirestore.instance.collection('refrigeratorItems').add({
      'userId': user.uid,
      'itemName': _itemName,
      'expireDate': _expireDate ?? '',
      'imageUrl': '',
      'status': 'ACTIVE',
      'storageType': _storageType,
      'registeredDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제품이 등록되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '제품 등록',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _imageFile == null
                    ? const Text(
                        '등록할 식품을 촬영해주세요.',
                        style: TextStyle(fontSize: 18),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imageFile!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  '음식 분석 중...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (_itemName != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.kitchen_outlined, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _itemName!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('유통기한: ${_expireDate ?? '미확인'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_itemName != null)
              Row(
                children: [
                  Expanded(
                    child: _storageButton(
                      title: '내부 보관',
                      value: 'IN_CONTAINER',
                      icon: Icons.kitchen_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _storageButton(
                      title: '외부 보관',
                      value: 'OUTSIDE_CONTAINER',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _imageFile == null ? _takePhoto : _registerItem,
                icon: Icon(
                  _imageFile == null
                      ? Icons.camera_alt_outlined
                      : Icons.add_circle_outline,
                ),
                label: Text(
                  _imageFile == null
                      ? '사진 촬영'
                      : _isSaving
                          ? '등록 중...'
                          : '등록하기',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storageButton({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final selected = _storageType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _storageType = value;
        });
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
