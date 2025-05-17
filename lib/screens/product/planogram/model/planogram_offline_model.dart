// lib/screens/product/planogram/model/planogram_offline_model.dart

class OfflinePlanogramItemDetail {
  final int dbId; // Primary key dari tabel planogram_entries
  final String? displayType;
  final String? displayIssue;
  final String? ketBefore;
  final String? ketAfter;
  final String? imageBeforePath;
  final String? imageAfterPath;

  OfflinePlanogramItemDetail({
    required this.dbId,
    this.displayType,
    this.displayIssue,
    this.ketBefore,
    this.ketAfter,
    this.imageBeforePath,
    this.imageAfterPath,
  });

  factory OfflinePlanogramItemDetail.fromMap(Map<String, dynamic> map) {
    return OfflinePlanogramItemDetail(
      dbId: map['id'] as int,
      displayType: map['display_type'] as String?,
      displayIssue: map['display_issue'] as String?,
      ketBefore: map['ket_before'] as String?,
      ketAfter: map['ket_after'] as String?,
      imageBeforePath: map['image_before_path'] as String?,
      imageAfterPath: map['image_after_path'] as String?,
    );
  }
}

class OfflinePlanogramGroup {
  final String submissionGroupId;
  final String outletId;
  final String outletName;
  final String tglSubmission; // YYYY-MM-DD
  final String userId;
  final List<OfflinePlanogramItemDetail> items;

  OfflinePlanogramGroup({
    required this.submissionGroupId,
    required this.outletId,
    required this.outletName,
    required this.tglSubmission,
    required this.userId,
    required this.items,
  });
}
