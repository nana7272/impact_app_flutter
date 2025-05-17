// screens/activity/model/attendance_report.dart
import 'dart:convert';

AttendanceReport attendanceReportFromJson(String str) => AttendanceReport.fromJson(json.decode(str));

String attendanceReportToJson(AttendanceReport data) => json.encode(data.toJson());

class AttendanceReport {
    AttendanceSummary summary;
    List<AttendanceDetail> details;

    AttendanceReport({
        required this.summary,
        required this.details,
    });

    factory AttendanceReport.fromJson(Map<String, dynamic> json) => AttendanceReport(
        summary: AttendanceSummary.fromJson(json["summary"]),
        details: List<AttendanceDetail>.from(json["details"].map((x) => AttendanceDetail.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "summary": summary.toJson(),
        "details": List<dynamic>.from(details.map((x) => x.toJson())),
    };
}

class AttendanceSummary {
    int plan;
    int dikunjungi;
    int tidakDikunjungi;

    AttendanceSummary({
        required this.plan,
        required this.dikunjungi,
        required this.tidakDikunjungi,
    });

    factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
        plan: json["plan"],
        dikunjungi: json["dikunjungi"],
        tidakDikunjungi: json["tidak_dikunjungi"],
    );

    Map<String, dynamic> toJson() => {
        "plan": plan,
        "dikunjungi": dikunjungi,
        "tidak_dikunjungi": tidakDikunjungi,
    };
}

class AttendanceDetail {
    String outletName;
    String tanggal; // Format "2025-05-17"
    String jamCheckIn; // Format "10:32:53"
    String? jamCheckOut; // Bisa null
    String? durasi; // Bisa null
    String displayDatetime; // Format "17 May, 10:32:53"
    List<VisitImage> visitImages;

    AttendanceDetail({
        required this.outletName,
        required this.tanggal,
        required this.jamCheckIn,
        this.jamCheckOut,
        this.durasi,
        required this.displayDatetime,
        required this.visitImages,
    });

    factory AttendanceDetail.fromJson(Map<String, dynamic> json) => AttendanceDetail(
        outletName: json["outlet_name"],
        tanggal: json["tanggal"],
        jamCheckIn: json["jam_check_in"],
        jamCheckOut: json["jam_check_out"],
        durasi: json["durasi"],
        displayDatetime: json["display_datetime"],
        visitImages: List<VisitImage>.from(json["visit_images"].map((x) => VisitImage.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "tanggal": tanggal,
        "jam_check_in": jamCheckIn,
        "jam_check_out": jamCheckOut,
        "durasi": durasi,
        "display_datetime": displayDatetime,
        "visit_images": List<dynamic>.from(visitImages.map((x) => x.toJson())),
    };
}

class VisitImage {
    String imageType; // "ci" (check-in) atau "co" (check-out)
    String imageUrl;
    String keteranganGambar;
    String timeGambar; // Format "03:33:02"

    VisitImage({
        required this.imageType,
        required this.imageUrl,
        required this.keteranganGambar,
        required this.timeGambar,
    });

    factory VisitImage.fromJson(Map<String, dynamic> json) => VisitImage(
        imageType: json["image_type"],
        imageUrl: json["image_url"],
        keteranganGambar: json["keterangan_gambar"],
        timeGambar: json["time_gambar"],
    );

    Map<String, dynamic> toJson() => {
        "image_type": imageType,
        "image_url": imageUrl,
        "keterangan_gambar": keteranganGambar,
        "time_gambar": timeGambar,
    };
}