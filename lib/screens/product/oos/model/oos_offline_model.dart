import 'package:impact_app/screens/product/oos/model/oos_item_model.dart';

class OfflineOOSGroup {
  final String outletName;
  final String tgl;
  final List<OOSItem> items; // Menggunakan OOSItem langsung karena sudah punya localId

  OfflineOOSGroup({
    required this.outletName,
    required this.tgl,
    required this.items,
  });
}
