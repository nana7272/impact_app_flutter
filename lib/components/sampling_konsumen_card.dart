
import 'package:flutter/material.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:intl/intl.dart';

class SamplingKonsumenCard extends StatelessWidget {
  final SamplingKonsumen data;
  final bool isPending;
  final VoidCallback? onTap;
  final VoidCallback? onSync;
  
  const SamplingKonsumenCard({
    Key? key,
    required this.data,
    this.isPending = false,
    this.onTap,
    this.onSync,
  }) : super(key: key);
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPending ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? const BorderSide(color: AppColors.warning, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (isPending && onSync != null)
                    IconButton(
                      icon: const Icon(Icons.sync, color: AppColors.warning),
                      onPressed: onSync,
                      tooltip: 'Sinkronisasi',
                    )
                  else
                    const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
              const Divider(),
              _buildInfoRow(Icons.phone, 'No HP', data.noHp),
              _buildInfoRow(Icons.person, 'Umur', '${data.umur} tahun'),
              _buildInfoRow(Icons.email, 'Email', data.email),
              _buildInfoRow(Icons.shopping_cart, 'Kuantitas', data.kuantitas.toString()),
              _buildInfoRow(Icons.access_time, 'Tanggal', _formatDate(data.createdAt)),
              
              if (isPending)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending, size: 16, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'Belum tersinkronisasi',
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}