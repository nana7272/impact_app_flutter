// screens/activity/views/common_activity_widgets.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:provider/provider.dart';

class DateSelectorWidget extends StatelessWidget {
  final VoidCallback?
      onDateChanged; // Callback jika diperlukan aksi tambahan setelah tanggal berubah

  const DateSelectorWidget({Key? key, this.onDateChanged}) : super(key: key);

  Future<void> _selectDate(
      BuildContext context, ActivityProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await provider.updateSelectedDate(picked);
      onDateChanged?.call(); // Panggil callback jika ada
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context,
        listen: false); // listen: false karena kita hanya trigger
    // Dengarkan perubahan tanggal dari provider untuk update UI di sini
    final selectedDateForDisplay = context
        .select((ActivityProvider p) => p.formattedSelectedDateForDisplay);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _selectDate(context, provider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedDateForDisplay,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const Icon(Icons.search, color: Colors.blue, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorMessageWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          )
        ],
      ),
    );
  }
}
