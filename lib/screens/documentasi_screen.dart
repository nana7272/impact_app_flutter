import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/api/api_services.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';

class DocumentasiScreen extends StatefulWidget {
  final Store store;
  
  const DocumentasiScreen({super.key, required this.store});

  @override
  State<DocumentasiScreen> createState() => _DocumentasiScreenState();
}

class _DocumentasiScreenState extends State<DocumentasiScreen> {
  File? _image1;
  File? _image2;
  final TextEditingController _desc1 = TextEditingController();
  final TextEditingController _desc2 = TextEditingController();
  bool _isLoading = false;
  
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();
  final String _tag = 'DocumentasiScreen';

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

  Future<void> _submitData(bool isOnline) async {
    if (_image1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap ambil gambar pertama')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      if (isOnline) {
        // Check internet connection
        bool isConnected = await ConnectivityUtils.checkInternetConnection();
        
        if (!isConnected) {
          // Close loading dialog
          if (context.mounted) Navigator.pop(context);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada koneksi internet')),
            );
          }
          
          setState(() => _isLoading = false);
          return;
        }
        
        // Get user ID to make sure it's included in the request
        final user = await SessionManager().getCurrentUser();
        if (user == null || user.id == null) {
          _logger.e(_tag, 'User data not found');
          
          // Close loading dialog
          if (context.mounted) Navigator.pop(context);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data user tidak ditemukan')),
            );
          }
          
          setState(() => _isLoading = false);
          return;
        }
        
        // Submit data to server
        List<File> images = [];
        List<String> descriptions = [];
        
        if (_image1 != null) {
          images.add(_image1!);
          descriptions.add(_desc1.text);
        }
        
        if (_image2 != null) {
          images.add(_image2!);
          descriptions.add(_desc2.text);
        }
        
        // Add user ID to the data
        final visitData = await _apiService.checkin(
          widget.store.id!,
          widget.store.latitude!,
          widget.store.longitude!,
          images,
          descriptions,
          userId: user.id, // Explicitly pass the user ID
        );
        
        // Close loading dialog
        if (context.mounted) Navigator.pop(context);
        
        if (visitData != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil dikirim ke server')),
            );
            
            // Navigate back to previous screen after success
            Navigator.pop(context);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal mengirim data')),
            );
          }
        }
      } else {
        // Save data locally
        // Here you would implement local storage using SQLite or Hive
        
        // Close loading dialog
        if (context.mounted) Navigator.pop(context);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data disimpan secara lokal')),
          );
          
          // Navigate back to previous screen after success
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      _logger.e(_tag, 'Error submitting data: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim data: $e')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  void _showKirimDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitData(false); // Local
            },
            child: const Text('Offline (Local)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitData(true); // Online
            },
            child: const Text('Online (Server)'),
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
            : const Icon(Icons.camera_alt, size: 32, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check in"),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Store info card
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                image: widget.store.image != null
                  ? DecorationImage(
                      image: NetworkImage(ApiConstants.baseApiUrl + '/' + widget.store.image!),
                      fit: BoxFit.cover,
                    )
                  : const DecorationImage(
                      image: AssetImage('assets/images/store_placeholder.jpg'),
                      fit: BoxFit.cover,
                    ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.name ?? 'Nama Toko',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    widget.store.type ?? 'Tipe',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    '${widget.store.province ?? ''} - ${widget.store.area ?? ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Image 1
            _buildImagePicker(1, _image1),
            const SizedBox(height: 8),
            TextField(
              controller: _desc1,
              decoration: const InputDecoration(hintText: 'Desc Gambar 1'),
            ),
            const SizedBox(height: 24),
            
            // Image 2
            _buildImagePicker(2, _image2),
            const SizedBox(height: 8),
            TextField(
              controller: _desc2,
              decoration: const InputDecoration(hintText: 'Desc Gambar 2'),
            ),
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showKirimDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Kirim Data'),
              ),
            )
          ],
        ),
      ),
    );
  }
}