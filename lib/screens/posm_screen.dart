import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../themes/app_colors.dart';
import '../utils/connectivity_utils.dart';
import '../models/store_model.dart';

class PosmScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const PosmScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<PosmScreen> createState() => _PosmScreenState();
}

class _PosmScreenState extends State<PosmScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String store = "";
  
  // List untuk menyimpan multiple POSM items
  final List<POSMItem> _posmItems = [];
  
  @override
  void initState() {
    super.initState();
    // Tambahkan POSM item pertama pada init
    _addNewPOSMItem();
  }
  
  void _addNewPOSMItem() {
    setState(() {
      _posmItems.add(POSMItem());
    });
  }
  
  void _removePOSMItem(int index) {
    if (_posmItems.length > 1) {
      setState(() {
        _posmItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 item POSM')),
      );
    }
  }
  
  Future<void> _pickImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        setState(() {
          _posmItems[index].image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }
  
  bool _validateData() {
    for (int i = 0; i < _posmItems.length; i++) {
      if (_posmItems[i].image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon ambil foto untuk POSM item ${i + 1}')),
        );
        return false;
      }
      
      if (_posmItems[i].type.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih POSM Type untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (_posmItems[i].status.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih POSM Status untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (_posmItems[i].installed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi POSM Terpasang untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (_posmItems[i].note.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi POSM Keterangan untuk item ${i + 1}')),
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
        title: const Text('POSM'),
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
                          store ?? 'TK RINDU JAYA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // POSM Items list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posmItems.length,
                    itemBuilder: (context, index) {
                      return _buildPOSMItemWidget(index);
                    },
                  ),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPOSMItem,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.blue),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                // Navigate to home
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                // Navigate to activity
              },
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.location_on, color: Colors.white),
                onPressed: () {
                  // Navigate to location/map
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Navigate to notifications
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildPOSMItemWidget(int index) {
    final item = _posmItems[index];
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
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
                  onTap: () => _removePOSMItem(index),
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
          
          // POSM Type dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('POSM TYPE'),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: item.type.isNotEmpty ? item.type : null,
                      hint: const Text('Faktur'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: const [
                        DropdownMenuItem(value: 'Faktur', child: Text('Faktur')),
                        DropdownMenuItem(value: 'Banner', child: Text('Banner')),
                        DropdownMenuItem(value: 'Poster', child: Text('Poster')),
                        DropdownMenuItem(value: 'Wobbler', child: Text('Wobbler')),
                        DropdownMenuItem(value: 'Shelf', child: Text('Shelf')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          item.type = value ?? '';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // POSM Status dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('POSM Status'),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: item.status.isNotEmpty ? item.status : null,
                      hint: const Text('POSM Sudah Terpasang'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: const [
                        DropdownMenuItem(value: 'POSM Sudah Terpasang', child: Text('POSM Sudah Terpasang')),
                        DropdownMenuItem(value: 'POSM Belum Terpasang', child: Text('POSM Belum Terpasang')),
                        DropdownMenuItem(value: 'POSM Rusak', child: Text('POSM Rusak')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          item.status = value ?? '';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // POSM Terpasang field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('POSM Terpasang'),
                const SizedBox(height: 4),
                TextField(
                  decoration: const InputDecoration(
                    hintText: '1',
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      item.installed = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // POSM Keterangan field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('POSM Keterangan'),
                const SizedBox(height: 4),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Berhasil',
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      item.note = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model class untuk POSM Item
class POSMItem {
  File? image;
  String type = '';
  String status = '';
  String installed = '';
  String note = '';
  
  POSMItem({
    this.image,
    this.type = '',
    this.status = '',
    this.installed = '',
    this.note = '',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'installed': installed,
      'note': note,
      'image_path': image?.path,
    };
  }
}