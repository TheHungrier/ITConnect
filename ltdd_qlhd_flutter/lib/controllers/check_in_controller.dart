import 'dart:convert';

class CheckInData {
  final String qrRawValue;
  final String activityId;
  final String qrCode;
  final String activityTitle;
  final String activityLocation;
  final String activityTime;
  final String studentName;
  final String studentCode;
  final DateTime checkInTime;

  CheckInData({
    required this.qrRawValue,
    required this.activityId,
    required this.qrCode,
    required this.activityTitle,
    required this.activityLocation,
    required this.activityTime,
    required this.studentName,
    required this.studentCode,
    required this.checkInTime,
  });
}

class CheckInController {
  Map<String, dynamic> parseQrData(String rawValue) {
    final safeRawValue = rawValue.trim();

    if (safeRawValue.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(safeRawValue);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return {};
    }

    return {};
  }

  bool isActivityCheckInQr(String rawValue) {
    final data = parseQrData(rawValue);

    final type = data['type']?.toString().trim() ?? '';
    final activityId = data['activityId']?.toString().trim() ?? '';
    final qrCode = data['qrCode']?.toString().trim() ?? '';

    final isValidType =
        type == 'activity_checkin' || type == 'activity_check_in';

    return isValidType && activityId.isNotEmpty && qrCode.isNotEmpty;
  }

  CheckInData createCheckInData(String rawValue) {
    final data = parseQrData(rawValue);

    final activityId = data['activityId']?.toString().trim() ?? '';
    final qrCode = data['qrCode']?.toString().trim() ?? '';

    return CheckInData(
      qrRawValue: rawValue,
      activityId: activityId,
      qrCode: qrCode,
      activityTitle: data['activityTitle']?.toString().trim().isNotEmpty == true
          ? data['activityTitle'].toString().trim()
          : 'Hoạt động sinh viên',
      activityLocation:
          data['activityLocation']?.toString().trim().isNotEmpty == true
          ? data['activityLocation'].toString().trim()
          : 'Địa điểm hoạt động',
      activityTime: data['activityTime']?.toString().trim() ?? '',
      studentName: data['studentName']?.toString().trim().isNotEmpty == true
          ? data['studentName'].toString().trim()
          : 'Sinh viên',
      studentCode: data['studentCode']?.toString().trim() ?? '',
      checkInTime: DateTime.now(),
    );
  }
}
