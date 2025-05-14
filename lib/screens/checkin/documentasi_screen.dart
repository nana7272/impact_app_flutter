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
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 30);
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
        if (user == null || user.idLogin == null) {
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
          widget.store.idOutlet!,
          widget.store.lat! as double,
          widget.store.lolat! as double,
          images,
          descriptions,
          widget.store.nama!,
          userId: user.idLogin, // Explicitly pass the user ID
        );
        
        // Close loading dialog
        if (context.mounted) Navigator.pop(context);
        
        if (visitData != null) {
          if (context.mounted) {

             SessionManager().saveOutletVisit(widget.store);
             SessionManager().saveVisitId(visitData['id']);

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
          // Updated button styling to match Figma UI
          SizedBox(
            width: 120,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitData(false); // Local
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF81BFE6), // Light blue color from image
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Offline (Local)'),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitData(true); // Online
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF81BFE6), // Light blue color from image
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Online (Server)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(int index, File? image, TextEditingController controller) {
    return Column(
      children: [
        // Updated image picker to match Figma UI
        GestureDetector(
          onTap: () => _pickImage(index),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: image != null
                ? Image.file(image, fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 32, color: Colors.grey),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Updated text field to match Figma UI
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: index == 1 ? 'Desc Gambar 1' : 'Desc Gambar 2',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check in"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero header with store info - updated to match Figma UI
            Container(
              height: 220,
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
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80), // Space for AppBar
                  Text(
                    widget.store.nama ?? 'TK RINDU JAYA',
                    style: const TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.store.typeStore ?? 'GT',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.store.provinsi ?? 'Jawa Barat'} - ${widget.store.area ?? 'BOGOR'}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form content - updated to match Figma UI
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Image 1
                  _buildImagePicker(1, _image1, _desc1),
                  const SizedBox(height: 24),
                  
                  // Image 2
                  _buildImagePicker(2, _image2, _desc2),
                  const SizedBox(height: 32),
                  
                  // Submit button - updated to match Figma UI
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _showKirimDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Kirim Data',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}