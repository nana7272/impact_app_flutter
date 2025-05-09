// lib/screens/promo_audit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/api/promo_audit_api_service.dart';
import 'package:impact_app/models/promo_audit_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';

class PromoAuditScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  final Store store;
  
  const PromoAuditScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
    required this.store,
  }) : super(key: key);

  @override
  State<PromoAuditScreen> createState() => _PromoAuditScreenState();
}

class _PromoAuditScreenState extends State<PromoAuditScreen> {
  final PromoAuditApiService _apiService = PromoAuditApiService();
  final TextEditingController _keteranganController = TextEditingController();
  
  bool _isLoading = true;
  bool _statusPromotion = false;
  bool _extraDisplay = false;
  bool _popPromo = false;
  bool _hargaPromo = false;
  File? _photoFile;
  
  String? _existingPhotoUrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }
  
  // Memuat data promo audit yang sudah ada (jika ada)
  Future<void> _loadExistingData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final existingData = await _apiService.getPromoAuditByStore(
        widget.storeId, 
        widget.visitId
      );
      
      if (existingData != null) {
        setState(() {
          _isEditing = true;
          _statusPromotion = existingData.statusPromotion;
          _extraDisplay = existingData.extraDisplay;
          _popPromo = existingData.popPromo;
          _hargaPromo = existingData.hargaPromo;
          _keteranganController.text = existingData.keterangan ?? '';
          _existingPhotoUrl = existingData.photoUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Mengambil foto dari kamera
  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _photoFile = File(image.path);
      });
    }
  }
  
  // Mempersiapkan data promo audit
  PromoAudit _prepareData() {
    return PromoAudit(
      storeId: widget.storeId,
      visitId: widget.visitId,
      statusPromotion: _statusPromotion,
      extraDisplay: _extraDisplay,
      popPromo: _popPromo,
      hargaPromo: _hargaPromo,
      keterangan: _keteranganController.text.isNotEmpty ? _keteranganController.text : null,
      photoUrl: _existingPhotoUrl,
    );
  }
  
  // Dialog konfirmasi pengiriman data
  void _showSendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitOffline();
            },
            child: const Text('Offline (Local)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitOnline();
            },
            child: const Text('Online (Server)'),
          ),
        ],
      ),
    );
  }
  
  // Submit data secara offline
  Future<void> _submitOffline() async {
    setState(() {
      _isLoading = true;
    });
    
    // Prepare data
    final data = _prepareData();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      bool success = await _apiService.savePromoAuditOffline(data, _photoFile);
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
        );
        
        // Kembali ke layar sebelumnya
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data secara lokal')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menyimpan data: $e')),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Submit data secara online
  Future<void> _submitOnline() async {
    setState(() {
      _isLoading = true;
    });
    
    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan metode offline.')),
      );
      return;
    }
    
    // Prepare data
    final data = _prepareData();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      bool success = await _apiService.submitPromoAudit(data, _photoFile);
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dikirim ke server')),
        );
        
        // Kembali ke layar sebelumnya
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim data ke server')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengirim data: $e')),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Audit'),
        backgroundColor: Colors.grey[700],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Info Card
                  _buildStoreInfoCard(),
                  const SizedBox(height: 16),
                  
                  // Status Promotion
                  const Text(
                    'Status Promotion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Berjalan'),
                              value: true,
                              groupValue: _statusPromotion,
                              onChanged: (value) {
                                setState(() {
                                  _statusPromotion = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Tidak Berjalan'),
                              value: false,
                              groupValue: _statusPromotion,
                              onChanged: (value) {
                                setState(() {
                                  _statusPromotion = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Extra Display
                  const Text(
                    'Extra Display',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Ada'),
                              value: true,
                              groupValue: _extraDisplay,
                              onChanged: (value) {
                                setState(() {
                                  _extraDisplay = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Tidak ada'),
                              value: false,
                              groupValue: _extraDisplay,
                              onChanged: (value) {
                                setState(() {
                                  _extraDisplay = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // POP Promo
                  const Text(
                    'POP Promo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Terpasang'),
                              value: true,
                              groupValue: _popPromo,
                              onChanged: (value) {
                                setState(() {
                                  _popPromo = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Tidak Terpasang'),
                              value: false,
                              groupValue: _popPromo,
                              onChanged: (value) {
                                setState(() {
                                  _popPromo = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Harga Promo
                  const Text(
                    'Harga Promo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Sesuai'),
                              value: true,
                              groupValue: _hargaPromo,
                              onChanged: (value) {
                                setState(() {
                                  _hargaPromo = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Tidak Sesuai'),
                              value: false,
                              groupValue: _hargaPromo,
                              onChanged: (value) {
                                setState(() {
                                  _hargaPromo = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Photo Section
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _photoFile != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _photoFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                            ? _existingPhotoUrl!.startsWith('http')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _existingPhotoUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder(),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_existingPhotoUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder(),
                                  ),
                                )
                            : _buildPhotoPlaceholder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Click to add photo',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  
                  // Keterangan field
                  const SizedBox(height: 16),
                  const Text(
                    'Keterangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _keteranganController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan Keterangan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ),
                  
                  // Submit button
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _showSendDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _isEditing ? 'UPDATE DATA' : 'SIMPAN DATA',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
  
  // Widget placeholder untuk foto
  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          'Tap to take photo',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
  
  // Widget untuk menampilkan info toko
  Widget _buildStoreInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Store icon or image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),
            // Store details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.name ?? 'UNNAMED STORE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.store.address ?? 'No address',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}