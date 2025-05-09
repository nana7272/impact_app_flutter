import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../themes/app_colors.dart';
import '../utils/connectivity_utils.dart';
import '../models/store_model.dart';

class ActivationScreen extends StatefulWidget {
  final Store store;
  
  const ActivationScreen({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  // List untuk menyimpan multiple activation items
  final List<ActivationItem> _activationItems = [];
  
  @override
  void initState() {
    super.initState();
    // Tambahkan activation item pertama pada init
    _addNewActivationItem();
  }
  
  @override
  void dispose() {
    // Dispose semua text controllers
    for (var item in _activationItems) {
      item.programController.dispose();
      item.periodeController.dispose();
      item.keteranganController.dispose();
    }
    super.dispose();
  }
  
  void _addNewActivationItem() {
    setState(() {
      _activationItems.add(ActivationItem(
        programController: TextEditingController(),
        periodeController: TextEditingController(),
        keteranganController: TextEditingController(),
      ));
    });
  }
  
  void _removeActivationItem(int index) {
    if (_activationItems.length > 1) {
      setState(() {
        // Dispose controllers sebelum remove item
        _activationItems[index].programController.dispose();
        _activationItems[index].periodeController.dispose();
        _activationItems[index].keteranganController.dispose();
        
        _activationItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 item aktivasi')),
      );
    }
  }
  
  Future<void> _pickImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        setState(() {
          _activationItems[index].image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }
  
  bool _validateData() {
    for (int i = 0; i < _activationItems.length; i++) {
      if (_activationItems[i].image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon ambil foto untuk aktivasi item ${i + 1}')),
        );
        return false;
      }
      
      if (_activationItems[i].programController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Program untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (_activationItems[i].periodeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Periode untuk item ${i + 1}')),
        );
        return false;
      }
    }
    
    return true;
  }
  
  void _showSendDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitData(false); // offline
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text('Offline (Local)'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitData(true); // online
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text('Online (Server)', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitData(bool isOnline) async {
    if (!_validateData()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      if (isOnline) {
        // Verifikasi koneksi internet
        bool hasInternet = await ConnectivityUtils.checkInternetConnection();
        if (!hasInternet) {
          Navigator.pop(context); // tutup dialog loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada koneksi internet. Silakan gunakan mode offline.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Simulasi pengiriman data ke server
        await Future.delayed(const Duration(seconds: 2));
        
        // Close loading dialog
        Navigator.pop(context);
        
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dikirim ke server')),
        );
        
        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      } else {
        // Simulasi penyimpanan data secara lokal
        await Future.delayed(const Duration(seconds: 1));
        
        // Close loading dialog
        Navigator.pop(context);
        
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
        );
        
        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.grey[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Store info header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, color: Colors.blue[700], size: 30),
                        const SizedBox(width: 10),
                        Text(
                          widget.store.name ?? 'TK RINDU JAYA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Activation Items list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activationItems.length,
                    itemBuilder: (context, index) {
                      return _buildActivationItemWidget(index);
                    },
                  ),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewActivationItem,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.blue),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildActivationItemWidget(int index) {
    final item = _activationItems[index];
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with X button
          Stack(
            children: [
              GestureDetector(
                onTap: () => _pickImage(index),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: item.image != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: Image.file(
                            item.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                        ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => _removeActivationItem(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ],
          ),
          
          // Program field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Program'),
                TextField(
                  controller: item.programController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama program',
                    border: UnderlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          
          // Periode field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Periode'),
                TextField(
                  controller: item.periodeController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan periode',
                    border: UnderlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  readOnly: true,
                  onTap: () {
                    // Show date picker
                    showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    ).then((dateRange) {
                      if (dateRange != null) {
                        final start = "${dateRange.start.day}/${dateRange.start.month}/${dateRange.start.year}";
                        final end = "${dateRange.end.day}/${dateRange.end.month}/${dateRange.end.year}";
                        setState(() {
                          item.periodeController.text = "$start - $end";
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Keterangan field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keterangan'),
                TextField(
                  controller: item.keteranganController,
                  decoration: const InputDecoration(
                    hintText: 'Tambahkan keterangan',
                    border: UnderlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model untuk menyimpan item aktivasi beserta controller-nya
class ActivationItem {
  File? image;
  final TextEditingController programController;
  final TextEditingController periodeController;
  final TextEditingController keteranganController;
  
  ActivationItem({
    this.image,
    required this.programController,
    required this.periodeController,
    required this.keteranganController,
  });
}