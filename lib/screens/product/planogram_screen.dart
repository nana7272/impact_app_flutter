import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../themes/app_colors.dart';
import '../../utils/connectivity_utils.dart';
import '../../models/store_model.dart';

class PlanogramScreen extends StatefulWidget {
  final Store store;
  
  const PlanogramScreen({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<PlanogramScreen> createState() => _PlanogramScreenState();
}

class _PlanogramScreenState extends State<PlanogramScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  // List untuk menyimpan multiple planogram items
  final List<PlanogramItem> _planogramItems = [];
  
  // List untuk tipe display dan issue
  final List<String> _displayTypes = [
    'Shelf Display',
    'Endcap Display',
    'Counter Display',
    'Floor Display',
    'Window Display',
    'Promotional Display'
  ];
  
  final List<String> _displayIssues = [
    'Tidak Ada Masalah',
    'Stock Tidak Lengkap',
    'Display Berantakan',
    'Price Tag Tidak Ada',
    'Produk Bercampur',
    'Display Rusak'
  ];
  
  @override
  void initState() {
    super.initState();
    // Tambahkan planogram item pertama pada init
    _addNewPlanogramItem();
  }
  
  @override
  void dispose() {
    // Dispose semua text controllers
    for (var item in _planogramItems) {
      item.descBeforeController.dispose();
      item.descAfterController.dispose();
    }
    super.dispose();
  }
  
  void _addNewPlanogramItem() {
    setState(() {
      _planogramItems.add(PlanogramItem(
        descBeforeController: TextEditingController(),
        descAfterController: TextEditingController(),
      ));
    });
  }
  
  void _removePlanogramItem(int index) {
    if (_planogramItems.length > 1) {
      setState(() {
        // Dispose controllers sebelum remove item
        _planogramItems[index].descBeforeController.dispose();
        _planogramItems[index].descAfterController.dispose();
        
        _planogramItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 item planogram')),
      );
    }
  }
  
  Future<void> _pickBeforeImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        setState(() {
          _planogramItems[index].beforeImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }
  
  Future<void> _pickAfterImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        setState(() {
          _planogramItems[index].afterImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }
  
  bool _validateData() {
    for (int i = 0; i < _planogramItems.length; i++) {
      final item = _planogramItems[i];
      
      if (item.displayType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih Display Type untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (item.displayIssue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih Display Issue untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (item.beforeImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon ambil Foto Before untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (item.afterImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon ambil Foto After untuk item ${i + 1}')),
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
        title: const Text('Planogram'),
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
                          widget.store.nama ?? 'TK RINDU JAYA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Planogram Items list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _planogramItems.length,
                    itemBuilder: (context, index) {
                      return _buildPlanogramItemWidget(index);
                    },
                  ),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPlanogramItem,
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
  
  Widget _buildPlanogramItemWidget(int index) {
    final item = _planogramItems[index];
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with X button (same as previous components)
          Stack(
            children: [
              GestureDetector(
                onTap: () => {}, // This image is just for reference
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
                  child: Image.asset(
                    'assets/placeholder_image.png', // Use a placeholder image
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => _removePlanogramItem(index),
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
          
          // Display Type dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Display Type'),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  hint: const Text('Pilih tipe display'),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  value: item.displayType.isNotEmpty ? item.displayType : null,
                  onChanged: (String? newValue) {
                    setState(() {
                      item.displayType = newValue ?? '';
                    });
                  },
                  items: _displayTypes.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Display Issue dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Display issue'),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  hint: const Text('Pilih masalah display'),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  value: item.displayIssue.isNotEmpty ? item.displayIssue : null,
                  onChanged: (String? newValue) {
                    setState(() {
                      item.displayIssue = newValue ?? '';
                    });
                  },
                  items: _displayIssues.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Before and After Photos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Before Photo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto Before'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickBeforeImage(index),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.beforeImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    item.beforeImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Desc Gambar'),
                      TextField(
                        controller: item.descBeforeController,
                        decoration: const InputDecoration(
                          hintText: 'Deskripsi foto sebelum',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // After Photo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto After'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickAfterImage(index),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.afterImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    item.afterImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Desc Gambar'),
                      TextField(
                        controller: item.descAfterController,
                        decoration: const InputDecoration(
                          hintText: 'Deskripsi foto sesudah',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model untuk menyimpan item planogram beserta controller-nya
class PlanogramItem {
  File? beforeImage;
  File? afterImage;
  String displayType = '';
  String displayIssue = '';
  final TextEditingController descBeforeController;
  final TextEditingController descAfterController;
  
  PlanogramItem({
    this.beforeImage,
    this.afterImage,
    this.displayType = '',
    this.displayIssue = '',
    required this.descBeforeController,
    required this.descAfterController,
  });
}