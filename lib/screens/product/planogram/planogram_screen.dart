import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/utils/session_manager.dart';
import '../../../themes/app_colors.dart';
import '../../../utils/connectivity_utils.dart';
import '../../../models/store_model.dart';
import 'api/planogram_api_service.dart';
import 'model/api_display_type_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:intl/intl.dart';

class PlanogramScreen extends StatefulWidget {
  
  const PlanogramScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<PlanogramScreen> createState() => _PlanogramScreenState();
}

class _PlanogramScreenState extends State<PlanogramScreen> {
  final ImagePicker _picker = ImagePicker();
  final PlanogramApiService _apiService = PlanogramApiService();
  final Logger _logger = Logger();
  final String _tag = "PlanogramScreen";

  bool _isLoading = false;
  bool _isLoadingDropdown = true;
  Store? _selectedStore;

  
  // List untuk menyimpan multiple planogram items
  final List<PlanogramItem> _planogramItems = [];
  
  // Data untuk dropdown dari API
  List<ApiDisplayType> _apiDisplayTypes = [];
  List<String> _apiDisplayIssues = [];
  String? _userIdPrinciple;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoadingDropdown = true; });
    try {
      _selectedStore = await SessionManager().getStoreData();
      final user = await SessionManager().getCurrentUser();
      if (user != null && user.idpriciple != null) {
        _userIdPrinciple = user.idpriciple;
        await _fetchDropdownData();
      } else {
        _logger.e(_tag, "User or idPrinciple is null.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat data user untuk dropdown.')),
          );
        }
      }
    } catch (e) {
      _logger.e(_tag, "Error loading initial data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data awal: $e')),
        );
      }
    } finally {
      if (_planogramItems.isEmpty) {
         _addNewPlanogramItemInternal(); // Add first item after loading attempt
      }
      if (mounted) setState(() { _isLoadingDropdown = false; });
    }
  }

  Future<void> _fetchDropdownData() async {
    if (_userIdPrinciple == null) return;
    try {
      final displayTypes = await _apiService.fetchDisplayTypes(_userIdPrinciple!);
      final displayIssues = await _apiService.fetchDisplayIssues(_userIdPrinciple!);
      if (mounted) {
        setState(() {
          _apiDisplayTypes = displayTypes;
          _apiDisplayIssues = displayIssues;
        });
      }
    } catch (e) {
      _logger.e(_tag, "Error fetching dropdown data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data dropdown: $e')));
    }
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
  
  void _addNewPlanogramItemInternal() {
    setState(()  {
      _planogramItems.add(PlanogramItem(
        descBeforeController: TextEditingController(),
        descAfterController: TextEditingController(),
        selectedApiDisplayType: _apiDisplayTypes.isNotEmpty ? _apiDisplayTypes.first : null, // Default to first or null
        displayIssue: _apiDisplayIssues.isNotEmpty ? _apiDisplayIssues.first : '',
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
      _logger.e(_tag, "Error picking before image: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengambil gambar: $e')));
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
      _logger.e(_tag, "Error picking after image: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengambil gambar: $e')));
    }
  }
  
  bool _validateData() {
    for (int i = 0; i < _planogramItems.length; i++) {
      final item = _planogramItems[i];

      if (item.selectedApiDisplayType == null || item.selectedApiDisplayType!.nama.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih Display Type untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (item.displayIssue.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih Display Issue untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (item.beforeImage == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon ambil Foto Before untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (item.afterImage == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
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
    
    setState(() { _isLoading = true; });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text(isOnline ? "Mengirim data..." : "Menyimpan data...")])),
      );
    }
    
    try {
      final user = await SessionManager().getCurrentUser();
      final store = _selectedStore; // Already fetched in initState

      if (user == null || user.idLogin == null || store == null || store.idOutlet == null) {
        throw Exception("Data user atau toko tidak lengkap.");
      }

      String submissionGroupId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String tglSubmission = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (isOnline) {
        bool hasInternet = await ConnectivityUtils.checkInternetConnection();
        if (!hasInternet) {
          if(mounted) Navigator.pop(context); // Close loading
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan mode offline.')));
          setState(() { _isLoading = false; });
          return;
        }
        
        List<Map<String, dynamic>> dokumentasiItemsData = [];
        List<File?> beforeImages = [];
        List<File?> afterImages = [];

        for (var item in _planogramItems) {
          dokumentasiItemsData.add({
            'id_user': user.idLogin,
            'id_outlet': store.idOutlet,
            'outlet': store.nama,
            'ket': item.descBeforeController.text,
            'tgl': tglSubmission,
            'type': item.selectedApiDisplayType?.nama ?? '',
            'complain': item.displayIssue,
            'ket2': item.descAfterController.text,
          });
          beforeImages.add(item.beforeImage);
          afterImages.add(item.afterImage);
        }

        bool success = await _apiService.submitPlanogramDataOnline(dokumentasiItemsData, beforeImages, afterImages);
        if(mounted) Navigator.pop(context); // Close loading

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dikirim ke server')));
            Navigator.pop(context); // Go back
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim data ke server')));
        }

      } else {
        List<Map<String, dynamic>> itemsToSave = [];
        for (var item in _planogramItems) {
          itemsToSave.add({
            'id_user': user.idLogin,
            'id_outlet': store.idOutlet,
            'outlet_name': store.nama,
            'ket_before': item.descBeforeController.text,
            'tgl_submission': tglSubmission,
            'display_type': item.selectedApiDisplayType?.nama ?? '',
            'display_issue': item.displayIssue,
            'ket_after': item.descAfterController.text,
            'image_before_path': item.beforeImage?.path,
            'image_after_path': item.afterImage?.path,
            'submission_group_id': submissionGroupId,
          });
        }

        bool success = await _apiService.savePlanogramDataOffline(itemsToSave);
        if(mounted) Navigator.pop(context); // Close loading

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan secara lokal')));
            Navigator.pop(context); // Go back
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan data secara lokal')));
        }
      }
    } catch (e) {
      _logger.e(_tag, "Error submitting data: $e");
      if(mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumentasi Gambar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.grey[700],
      ),
      body: _isLoading && !_isLoadingDropdown // Show main loading only if not dropdown loading
          ? const Center(child: CircularProgressIndicator(key: Key("mainLoadingPlanogram")))
          : _isLoadingDropdown
            ? const Center(child: CircularProgressIndicator(key: Key("dropdownLoadingPlanogram")))
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
                          _selectedStore?.nama ?? 'Memuat toko...',
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
                  if (_planogramItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _showSendDataDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('KIRIM DATA', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoadingDropdown ? null : _addNewPlanogramItemInternal,
        heroTag: 'planogram_screen_fab', // Unique heroTag
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.blue),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildPlanogramItemWidget(int index) {
    final item = _planogramItems[index];
    
    return Card(
      shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
      child: Container(
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
              alignment: Alignment.topCenter,
              children: [
                GestureDetector(
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: item.selectedApiDisplayType != null && item.selectedApiDisplayType!.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                            child: Image.network(
                              item.selectedApiDisplayType!.image,
                              fit: BoxFit.contain, // Contain to see the whole image
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          )
                        : const Center(child: Text("Pilih Tipe Display", style: TextStyle(color: Colors.grey))),
                    ), // Closes Container
                  ), // Closes GestureDetector
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
                ), // Closes Positioned
              ], // This now correctly closes the Stack's children list
            ), // This now correctly closes the Stack
            
            // Display Type dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Display Type'),
                  DropdownButtonFormField<ApiDisplayType>(
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      hintText: 'Pilih tipe display',
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    value: item.selectedApiDisplayType,
                    onChanged: _apiDisplayTypes.isEmpty ? null : (ApiDisplayType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          item.selectedApiDisplayType = newValue;
                        });
                      }
                    },
                    items: _apiDisplayTypes.map<DropdownMenuItem<ApiDisplayType>>((ApiDisplayType value) {
                      return DropdownMenuItem<ApiDisplayType>(
                        value: value,
                        child: Text(value.nama, overflow: TextOverflow.ellipsis),
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
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      hintText: _apiDisplayIssues.isEmpty ? 'Memuat issue...' : 'Pilih masalah display',
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    value: item.displayIssue.isNotEmpty && _apiDisplayIssues.contains(item.displayIssue) ? item.displayIssue : null,
                    onChanged: _apiDisplayIssues.isEmpty ? null : (String? newValue) {
                      setState(() {
                        item.displayIssue = newValue ?? '';
                      });
                    },
                    items: _apiDisplayIssues.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, overflow: TextOverflow.ellipsis),
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
           
          ]
        )
          ),
    );
  }
}

// Model untuk menyimpan item planogram beserta controller-nya
class PlanogramItem {
  File? beforeImage;
  File? afterImage;
  ApiDisplayType? selectedApiDisplayType;
  String displayIssue = '';
  final TextEditingController descBeforeController;
  final TextEditingController descAfterController;
  
  PlanogramItem({
    this.beforeImage,
    this.afterImage,
    this.selectedApiDisplayType,
    this.displayIssue = '',
    required this.descBeforeController,
    required this.descAfterController,
  });
}