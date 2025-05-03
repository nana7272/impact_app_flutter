import 'package:flutter/material.dart';

class PresentationScreen extends StatelessWidget {
  const PresentationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {
        'date': '25 Februari 2024, 10:20',
        'image': 'https://cdn-icons-png.flaticon.com/512/7007/7007373.png',
        'message': 'Anda belum checkout di toko: TK Rindu Jaya',
        'detail': 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'
      },
      {
        'date': '25 Februari 2024, 10:20',
        'image': 'https://cdn-icons-png.flaticon.com/512/7007/7007373.png',
        'message': 'Anda belum checkout di toko: TK Rindu Jaya',
        'detail': 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text('Presentation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.blue),
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(item['date'], style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['image'], height: 150, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
                Text(item['message'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item['detail']),
                const Divider(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}