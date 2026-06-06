import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RefrigeratorCameraPage extends StatefulWidget {
  const RefrigeratorCameraPage({Key? key}) : super(key: key);

  @override
  State<RefrigeratorCameraPage> createState() => _RefrigeratorCameraPageState();
}

class _RefrigeratorCameraPageState extends State<RefrigeratorCameraPage> {
  File? _imageFile;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    setState(() {
      _imageFile = File(pickedImage.path);
    });

    // 나중에 여기서 AI API 연결하면 됨
    // 예: 음식 이름 분석, 유통기한 분석
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('제품 등록'),
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
                    : Image.file(_imageFile!),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('사진 촬영'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
