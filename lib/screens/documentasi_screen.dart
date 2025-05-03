import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DocumentasiScreen extends StatefulWidget {
  const DocumentasiScreen({super.key});

  @override
  State<DocumentasiScreen> createState() => _DocumentasiScreenState();
}

class _DocumentasiScreenState extends State<DocumentasiScreen> {
  File? _image1;
  File? _image2;
  final TextEditingController _desc1 = TextEditingController();
  final TextEditingController _desc2 = TextEditingController();

  Future<void> _pickImage(int index) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        if (index == 1) {
          _image1 = File(picked.path);
        } else {
          _image2 = File(picked.path);
        }
      });
    }
  }

  void _showKirimDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kirim Data'),
        content: Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data dikirim offline")));
            },
            child: Text('Offline (Local)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data dikirim online")));
            },
            child: Text('Online (Server)'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(int index, File? image) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[200],
        child: image != null
            ? ClipOval(child: Image.file(image, width: 80, height: 80, fit: BoxFit.cover))
            : Icon(Icons.camera_alt, size: 32, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Check in"),
        backgroundColor: Colors.grey[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/sample_toko.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('TK RINDU JAYA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('GT', style: TextStyle(color: Colors.white)),
                  Text('Jawa Barat - BOGOR', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildImagePicker(1, _image1),
            SizedBox(height: 8),
            TextField(
              controller: _desc1,
              decoration: InputDecoration(hintText: 'Desc Gambar 1'),
            ),
            SizedBox(height: 24),
            _buildImagePicker(2, _image2),
            SizedBox(height: 8),
            TextField(
              controller: _desc2,
              decoration: InputDecoration(hintText: 'Desc Gambar 2'),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showKirimDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Kirim Data'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
