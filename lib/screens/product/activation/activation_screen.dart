import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/models/activation_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/screens/product/activation/api/activation_api_service.dart';
import 'package:impact_app/screens/product/activation/model/activation_model.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class ActivationScreen extends StatefulWidget {
  
  const ActivationScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}


class _ActivationScreenState extends State<ActivationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingDropdownData = true; // For loading dropdown options
  final ActivationApiService _apiService = ActivationApiService();
  final Logger _logger = Logger();
  late Store _selectedStore = Store();
  String? _userIdPrinciple;
  
  // List untuk menyimpan multiple activation items
  final List<ActivationItem> _activationItems = [];

  // Data for dropdowns
  List<String> _programList = [];
  List<String> _periodeList = [];
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingDropdownData = true;
    });
    try {
      _selectedStore = (await SessionManager().getStoreData())!;
      final user = await SessionManager().getCurrentUser();
      if (user != null && user.idpriciple != null) {
        _userIdPrinciple = user.idpriciple;
        await _fetchDropdownData();
      } else {
        _logger.e("ActivationScreen", "User or idPrinciple is null.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat data user untuk dropdown.')),
          );
        }
      }
    } catch (e) {
       _logger.e("ActivationScreen", "Error loading initial data: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal memuat data awal: $e')),
         );
       }
    } finally {
      // Tambahkan activation item pertama setelah data dropdown dimuat (atau gagal dimuat)
      if (_activationItems.isEmpty) { // Only add if list is empty
        _addActivationItemInternal();
      }
      if(mounted){
        setState(() {
          _isLoadingDropdownData = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Dispose semua text controllers
    for (var item in _activationItems) {
      // item.programController.dispose(); // No longer TextEditingController
      // item.periodeController.dispose(); // No longer TextEditingController
      item.keteranganController.dispose();
    }
    super.dispose();
  }
    
  void _removeActivationItem(int index) {
    if (_activationItems.length > 1) {
      setState(() {
        // Dispose controllers sebelum remove item
        _activationItems[index].keteranganController.dispose();
        
        _activationItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 item aktivasi')),
      );
    }
  }

  Future<void> _fetchDropdownData() async {
    if (_userIdPrinciple == null) return;
    try {
      final programs = await _apiService.fetchPrograms(_userIdPrinciple!);
      final periods = await _apiService.fetchPeriods(_userIdPrinciple!);
      if (mounted) {
        setState(() {
          _programList = programs;
          _periodeList = periods;
        });
      }
    } catch (e) {
      _logger.e("ActivationScreen", "Error fetching dropdown data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data Pilihan Program/Periode: $e')),
        );
      }
    }
  }

  void _addActivationItemInternal() {
    setState(() {
      _activationItems.add(ActivationItem(
        keteranganController: TextEditingController(),
      ));
    });
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
      
      if (_activationItems[i].selectedProgram == null || _activationItems[i].selectedProgram!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Program untuk item ${i + 1}')),
        );
        return false;
      }
      
      if (_activationItems[i].selectedPeriode == null || _activationItems[i].selectedPeriode!.isEmpty) {
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
    try {
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.idLogin == null || user.idpriciple == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data user tidak lengkap untuk ${isOnline ? "pengiriman online" : "penyimpanan offline"}.')),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }
      final store = await SessionManager().getStoreData();

      if (isOnline) {
        bool hasInternet = await ConnectivityUtils.checkInternetConnection();
        if (!hasInternet) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada koneksi internet. Silakan gunakan mode offline.')),
            );
          }
          setState(() { _isLoading = false; });
          return;
        }
        
        List<ActivationEntryModel> entriesToSubmit = _activationItems.map((item) {
          return ActivationEntryModel(
            idUser: user.idLogin!,
            idPinciple: user.idpriciple!,
            idOutlet: store?.idOutlet ?? '',
            outletName: store?.nama,
            tgl: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            program: item.selectedProgram!,
            rangePeriode: item.selectedPeriode!,
            keterangan: item.keteranganController.text,
            imageFile: item.image,
          );
        }).toList();

        bool success = await _apiService.submitActivationOnline(entriesToSubmit);
                
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil dikirim ke server')),
            );
            Navigator.pop(context); 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal mengirim data ke server')),
            );
          }
          setState(() { _isLoading = false; });
        }
      } else {
        List<ActivationEntryModel> entriesToSave = _activationItems.map((item) {
           return ActivationEntryModel(
            idUser: user.idLogin!,
            idPinciple: user.idpriciple!,
            idOutlet: store?.idOutlet ?? '',
            outletName: store?.nama,
            tgl: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            program: item.selectedProgram!,
            rangePeriode: item.selectedPeriode!,
            keterangan: item.keteranganController.text,
            imagePath: item.image?.path, // Simpan path untuk offline
          );
        }).toList();

        bool success = await _apiService.saveActivationOffline(entriesToSave);
        
        if (success) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
            );
            Navigator.pop(context); 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menyimpan data secara lokal')),
            );
          }
          setState(() { _isLoading = false; });
        }
      }
    } catch (e) {
      _logger.e("ActivationScreen", "Error submitting data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
        setState(() { _isLoading = false; });
      }
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
          ? const Center(child: CircularProgressIndicator(key: Key("submissionLoading")))
          : _isLoadingDropdownData 
            ? const Center(child: CircularProgressIndicator(key: Key("dropdownLoading")))
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
                            _selectedStore.nama ?? 'Memuat nama toko...',
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
                    
                    // Tombol Kirim Data
                    if (_activationItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _showSendDataDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Ganti dengan AppColors.primary jika ada
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
        onPressed: _addActivationItemInternal, // Use internal method that doesn't fetch store again
        heroTag: 'activation_screen_fab', // Unique heroTag
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
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: _programList.isEmpty ? 'Memuat program...' : 'Pilih program',
                    border: UnderlineInputBorder(),
                  ),
                  value: item.selectedProgram,
                  isExpanded: true,
                  items: _programList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _programList.isEmpty ? null : (String? newValue) {
                    setState(() {
                      item.selectedProgram = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Program tidak boleh kosong';
                    return null;
                  },
                )
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
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: _periodeList.isEmpty ? 'Memuat periode...' : 'Pilih periode',
                    border: UnderlineInputBorder(),
                  ),
                  value: item.selectedPeriode,
                  isExpanded: true,
                  items: _periodeList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _periodeList.isEmpty ? null :(String? newValue) {
                    setState(() {
                      item.selectedPeriode = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Periode tidak boleh kosong';
                    return null;
                  },
                )
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
  String? selectedProgram;
  String? selectedPeriode;
  final TextEditingController keteranganController;
  
  ActivationItem({
    this.image,
    this.selectedProgram,
    this.selectedPeriode,
    required this.keteranganController,
  });
}