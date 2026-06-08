import 'package:cloud_firestore/cloud_firestore.dart';

class TermModel {
  final String id;
  final String name;
  final String schoolYear;
  final int semester;
  final int order;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;

  TermModel({
    required this.id,
    required this.name,
    required this.schoolYear,
    required this.semester,
    required this.order,
    required this.isActive,
    required this.startAt,
    required this.endAt,
  });

  factory TermModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final schoolYear = _safeString(data['schoolYear'] ?? data['academicYear']);

    final semester = _toSemesterNumber(data['semester']);

    return TermModel(
      id: doc.id,
      name: _safeString(data['name'], fallback: _buildName(doc.id)),
      schoolYear: schoolYear.isEmpty
          ? _schoolYearFromTermId(doc.id)
          : schoolYear,
      semester: semester == 0 ? _semesterFromTermId(doc.id) : semester,
      order: _toInt(data['order'], fallback: _orderFromTermId(doc.id)),
      isActive: data['isActive'] != false,
      startAt: _toDateTimeNullable(data['startAt']),
      endAt: _toDateTimeNullable(data['endAt']),
    );
  }

  factory TermModel.fromTermId({
    required String termId,
    String? name,
    String? schoolYear,
    dynamic semester,
    dynamic order,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    final safeTermId = termId.trim();
    final parsedSchoolYear = _schoolYearFromTermId(safeTermId);
    final parsedSemester = _semesterFromTermId(safeTermId);

    return TermModel(
      id: safeTermId,
      name: _safeString(name, fallback: _buildName(safeTermId)),
      schoolYear: _safeString(schoolYear, fallback: parsedSchoolYear),
      semester: _toSemesterNumber(semester, fallback: parsedSemester),
      order: _toInt(order, fallback: _orderFromTermId(safeTermId)),
      isActive: true,
      startAt: startAt,
      endAt: endAt,
    );
  }

  static String _safeString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _toSemesterNumber(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    final text = value?.toString().trim().toLowerCase() ?? '';

    if (text.contains('2') || text.contains('hk2')) {
      return 2;
    }

    if (text.contains('1') || text.contains('hk1')) {
      return 1;
    }

    return fallback;
  }

  static DateTime? _toDateTimeNullable(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String _schoolYearFromTermId(String termId) {
    final text = termId.trim();

    final match = RegExp(r'(\d{4})[_-](\d{4})').firstMatch(text);

    if (match == null) return '';

    final startYear = match.group(1) ?? '';
    final endYear = match.group(2) ?? '';

    if (startYear.isEmpty || endYear.isEmpty) return '';

    return '$startYear - $endYear';
  }

  static int _semesterFromTermId(String termId) {
    final upper = termId.toUpperCase();

    if (upper.contains('HK2')) return 2;
    if (upper.contains('HK1')) return 1;

    return 0;
  }

  static int _orderFromTermId(String termId) {
    final schoolYear = _schoolYearFromTermId(termId);
    final semester = _semesterFromTermId(termId);

    final yearMatch = RegExp(r'(\d{4})').firstMatch(schoolYear);

    if (yearMatch == null) return semester;

    final year = int.tryParse(yearMatch.group(1) ?? '') ?? 0;

    return (year * 10) + semester;
  }

  static String _buildName(String termId) {
    final schoolYear = _schoolYearFromTermId(termId);
    final semester = _semesterFromTermId(termId);

    if (schoolYear.isEmpty || semester == 0) {
      return termId;
    }

    return 'HK$semester $schoolYear';
  }
}
