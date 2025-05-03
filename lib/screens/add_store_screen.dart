import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class AddStoreScreen extends StatefulWidget {
  const AddStoreScreen({Key? key}) : super(key: key);

  @override
  State<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;

  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  String? _selectedDistributor;
  String? _selectedSegment;
  String? _selectedProvinsi;
  String? _selectedArea;
  String? _selectedKecamatan;
  String? _selectedKelurahan;
  String? _selectedAccount;
  String? _selectedType;

  List<Map<String, dynamic>> _distributorList = [];
  List<Map<String, dynamic>> _segmentList = [];
  List<Map<String, dynamic>> _provinsiList = [];
  List<Map<String, dynamic>> _areaList = [];
  List<Map<String, dynamic>> _kecamatanList = [];
  List<Map<String, dynamic>> _kelurahanList = [];
  List<Map<String, dynamic>> _accountList = [];
  List<Map<String, dynamic>> _typeList = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final response = await http.get(Uri.parse('https://api.impactdigitalreport.com/public/users/masterdata'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dropdownData = data['data'];
        setState(() {
          _distributorList = List<Map<String, dynamic>>.from(dropdownData['distributor'] ?? []);
          _segmentList = List<Map<String, dynamic>>.from(dropdownData['segment'] ?? []);
          _provinsiList = List<Map<String, dynamic>>.from(dropdownData['provinsi'] ?? []);
          _areaList = List<Map<String, dynamic>>.from(dropdownData['area'] ?? []);
          _kecamatanList = List<Map<String, dynamic>>.from(dropdownData['kecamatan'] ?? []);
          _kelurahanList = List<Map<String, dynamic>>.from(dropdownData['kelurahan'] ?? []);
          _accountList = List<Map<String, dynamic>>.from(dropdownData['account'] ?? []);
          _typeList = List<Map<String, dynamic>>.from(dropdownData['type'] ?? []);
        });
      } else {
        throw Exception('Failed to load dropdown data');
      }
    } catch (e) {
      print('Dropdown fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data dropdown')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih foto terlebih dahulu')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.example.com/addstore'),
        );

        request.fields['kode_outlet'] = _kodeController.text;
        request.fields['nama_outlet'] = _namaController.text;
        request.fields['alamat'] = _alamatController.text;
        request.fields['keterangan'] = _keteranganController.text;
        request.fields['distributor_center'] = _selectedDistributor ?? '';
        request.fields['segment'] = _selectedSegment ?? '';
        request.fields['provinsi'] = _selectedProvinsi ?? '';
        request.fields['area'] = _selectedArea ?? '';
        request.fields['kecamatan'] = _selectedKecamatan ?? '';
        request.fields['kelurahan'] = _selectedKelurahan ?? '';
        request.fields['account'] = _selectedAccount ?? '';
        request.fields['type'] = _selectedType ?? '';

        request.files.add(await http.MultipartFile.fromPath('foto', _pickedImage!.path));

        var response = await request.send();
        Navigator.of(context).pop();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store berhasil disimpan!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan data (${response.statusCode})')),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: selectedValue,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['id'].toString(),
            child: Text(item['nama']),
          );
        }).toList(),
        validator: (value) => value == null || value.isEmpty ? 'Wajib dipilih' : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Store'),
        backgroundColor: Colors.grey.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _pickedImage != null ? FileImage(File(_pickedImage!.path)) : null,
                  child: _pickedImage == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_kodeController, 'Kode Outlet'),
              _buildTextField(_namaController, 'Nama Outlet'),
              _buildDropdown('Distributor Center', _distributorList, _selectedDistributor, (val) => setState(() => _selectedDistributor = val)),
              _buildDropdown('Segment', _segmentList, _selectedSegment, (val) => setState(() => _selectedSegment = val)),
              _buildTextField(_alamatController, 'Alamat Outlet'),
              _buildTextField(_keteranganController, 'Keterangan'),
              _buildDropdown('Provinsi', _provinsiList, _selectedProvinsi, (val) => setState(() => _selectedProvinsi = val)),
              _buildDropdown('Area', _areaList, _selectedArea, (val) => setState(() => _selectedArea = val)),
              _buildDropdown('Kecamatan', _kecamatanList, _selectedKecamatan, (val) => setState(() => _selectedKecamatan = val)),
              _buildDropdown('Kelurahan', _kelurahanList, _selectedKelurahan, (val) => setState(() => _selectedKelurahan = val)),
              _buildDropdown('Account', _accountList, _selectedAccount, (val) => setState(() => _selectedAccount = val)),
              _buildDropdown('Type', _typeList, _selectedType, (val) => setState(() => _selectedType = val)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('SIMPAN'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
