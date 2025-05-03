import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade700,
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            const Text('Tap to change Photo'),
            const SizedBox(height: 20),
            _buildInputRow('Username:', 'adiraoctviani_123'),
            _buildInputRow('First Name:', 'Adira', 'Last Name:', 'Octaviani'),
            _buildInputField('Email:', 'adiraoctviani@gmail.com'),
            _buildDropdown('Provinsi:', ['Jawa Barat']),
            _buildDropdown('Area:', ['Bandung']),
            _buildDropdown('Team Leader:', ['Irvan Pradana']),
            _buildDropdown('PIC:', ['REGION 1']),
            _buildInputField('No KTP:', '32101234567891011'),
            _buildInputField('No Jamsostek:', '32101234567891011'),
            _buildInputField('No NPWP:', '32101234567891011'),
            _buildDropdown('Jenis Kelamin:', ['Perempuan']),
            _buildInputField('Tgl lahir:', '2024-02-16'),
            _buildInputField('Tgl Masuk:', '2024-02-16'),
            _buildInputField('Nama Ibu Kandung:', 'Dira'),
            _buildDropdown('Agama:', ['Islam']),
            _buildDropdown('Pendidikan Terakhir:', ['SMA/SMK']),
            _buildInputField('Alamat:', 'Jln.Bren No.10'),
            _buildInputField('No HP:', '08123456789102'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('SIMPAN'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(label),
        TextField(
          controller: TextEditingController(text: value),
        ),
      ],
    );
  }

  Widget _buildInputRow(String label1, String value1, [String? label2, String? value2]) {
    return Row(
      children: [
        Expanded(child: _buildInputField(label1, value1)),
        const SizedBox(width: 8),
        if (label2 != null && value2 != null) Expanded(child: _buildInputField(label2, value2)),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(label),
        DropdownButtonFormField<String>(
          value: options[0],
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
      ],
    );
  }
}