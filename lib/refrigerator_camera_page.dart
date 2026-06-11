import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RefrigeratorCameraPage extends StatefulWidget {
  const RefrigeratorCameraPage({Key? key}) : super(key: key);

  @override
  State<RefrigeratorCameraPage> createState() => _RefrigeratorCameraPageState();
}

class _RefrigeratorCameraPageState extends State<RefrigeratorCameraPage> {
  CameraController? _cameraController;
  File? _imageFile;

  bool _isCameraReady = false;
  bool _isTakingPicture = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;

  String? _itemName;
  String? _expireDate;
  String _storageType = 'IN_CONTAINER';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      return;
    }

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() {
      _isCameraReady = true;
    });
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    final picture = await _cameraController!.takePicture();

    setState(() {
      _imageFile = File(picture.path);
      _itemName = null;
      _expireDate = null;
      _isTakingPicture = false;
    });

    await _analyzeFoodImage();
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _imageFile = null;
      _itemName = null;
      _expireDate = null;
      _storageType = 'IN_CONTAINER';
    });
  }

  Future<void> _analyzeFoodImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    const apiKey = 'AQ.Ab8RN6LB6bXGJpC6sfeHIua0AhyrOnuKb_2Iw9QDRIIMyarWKA';

    final bytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''
이 이미지를 보고 냉장고에 등록할 식품 정보를 JSON으로만 반환해줘.

형식:
{
  "itemName": "음식명",
  "expireDate": "YYYY.MM.DD 또는 미확인",
  "storageType": "IN_CONTAINER",
  "recommendedStorageDays": 7
}
'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 분석 실패: ${response.body}')),
      );
      return;
    }

    final decoded = jsonDecode(response.body);
    final text =
        decoded['candidates'][0]['content']['parts'][0]['text'] as String;

    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    final result = jsonDecode(cleaned);

    setState(() {
      _itemName = result['itemName'] ?? '알 수 없음';
      _expireDate = result['expireDate'] ?? '미확인';
      _storageType = result['storageType'] ?? 'IN_CONTAINER';
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

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제품이 등록되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageFile != null;

    return Scaffold(
      backgroundColor: hasImage ? Colors.white : Colors.black,
      appBar: AppBar(
        title: const Text(
          '제품 등록',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: hasImage ? Colors.white : Colors.black,
        foregroundColor: hasImage ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: !_isCameraReady || _cameraController == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(hasImage ? 24 : 0),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CameraPreview(_cameraController!),
                    ),
                  ),
                  if (_isAnalyzing)
                    const Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 20),
                      child: Text(
                        '음식 분석 중...',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (_itemName != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20, bottom: 20),
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
                  Padding(
                    padding: EdgeInsets.all(hasImage ? 0 : 24),
                    child: Row(
                      children: [
                        if (hasImage)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _retakePhoto,
                              icon: const Icon(Icons.refresh),
                              label: const Text('다시 촬영'),
                            ),
                          ),
                        if (hasImage) const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: hasImage ? _registerItem : _takePhoto,
                              icon: Icon(
                                hasImage
                                    ? Icons.add_circle_outline
                                    : Icons.camera_alt_outlined,
                              ),
                              label: Text(
                                hasImage
                                    ? _isSaving
                                        ? '등록 중...'
                                        : '등록하기'
                                    : _isTakingPicture
                                        ? '촬영 중...'
                                        : '촬영하기',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
