import 'package:flutter/material.dart';

class SendDataDialog extends StatelessWidget {
  final Function(bool) onSendMethod;

  const SendDataDialog({
    Key? key, 
    required this.onSendMethod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kirim Data',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kirim data menggunakan metode?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Offline option
          _buildMethodButton(
            context,
            title: 'Offline (Local)',
            subtitle: 'Simpan data di perangkat',
            iconData: Icons.storage,
            color: Colors.blue[200]!,
            onTap: () {
              Navigator.pop(context);
              onSendMethod(false);
            },
          ),
          
          const SizedBox(height: 12),
          
          // Online option
          _buildMethodButton(
            context,
            title: 'Online (Server)',
            subtitle: 'Kirim langsung ke server',
            iconData: Icons.cloud_upload,
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              onSendMethod(true);
            },
          ),
          
          const SizedBox(height: 8),
          
          // Cancel button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
}