import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ltdd_qlhd_flutter/services/cloudinary_service.dart';

import '../../repositories/notification_repository.dart';

class AdminActivityFormScreen extends StatefulWidget {
  final String? activityId;
  final Map<String, dynamic>? initialData;

  const AdminActivityFormScreen({super.key, this.activityId, this.initialData});

  bool get isEdit => activityId != null;

  @override
  State<AdminActivityFormScreen> createState() =>
      _AdminActivityFormScreenState();
}

class _AdminActivityFormScreenState extends State<AdminActivityFormScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _pointsController;

  final List<String> _categories = [
    'Đoàn',
    'Workshop',
    'Seminar',
    'CLB',
    'Học thuật',
    'Khác',
  ];

  final List<String> _locations = [
    'Hội trường C',
    'Sân trường',
    'Thư viện',
    'Online',
  ];

  String _selectedCategory = 'Workshop';
  String _selectedLocation = 'Hội trường C';

  String _currentImageUrl = '';
  File? _selectedImageFile;

  DateTime _startAt = DateTime.now().add(const Duration(days: 1));
  DateTime _endAt = DateTime.now().add(const Duration(days: 1, hours: 2));

  bool _registrationOpen = true;
  bool _isCheckInOpen = false;
  bool _isSaving = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF0F172A) : lightBackground;

  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);

  Color get _subTextColor =>
      _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  String get _autoSemester {
    if (_startAt.month >= 8 && _startAt.month <= 12) {
      return 'Học kỳ 1';
    }
    return 'Học kỳ 2';
  }

  @override
  void initState() {
    super.initState();

    final data = widget.initialData ?? {};

    _titleController = TextEditingController(
      text: data['title']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );

    _maxParticipantsController = TextEditingController(
      text: _toInt(data['maxParticipants'], fallback: 100).toString(),
    );

    _pointsController = TextEditingController(
      text: _toInt(data['points'], fallback: 5).toString(),
    );

    final category = data['category']?.toString();
    if (category != null && category.trim().isNotEmpty) {
      if (!_categories.contains(category)) {
        _categories.add(category);
      }

      _selectedCategory = category;
    }

    final location = data['location']?.toString();
    if (location != null && location.trim().isNotEmpty) {
      if (!_locations.contains(location)) {
        _locations.add(location);
      }

      _selectedLocation = location;
    }

    _currentImageUrl = data['imageUrl']?.toString().trim() ?? '';

    _startAt = _toDate(
      data['startAt'],
      fallback: DateTime.now().add(const Duration(days: 1)),
    );

    _endAt = _toDate(
      data['endAt'],
      fallback: _startAt.add(const Duration(hours: 2)),
    );

    _registrationOpen = data['registrationOpen'] != false;
    _isCheckInOpen = data['isCheckInOpen'] == true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _pointsController.dispose();

    super.dispose();
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _toDate(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return fallback;
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatAcademicYear(DateTime startAt) {
    final year = startAt.year;

    if (startAt.month >= 8) {
      return '$year - ${year + 1}';
    }

    return '${year - 1} - $year';
  }

  String _buildTermId() {
    final academicYear = _formatAcademicYear(
      _startAt,
    ).replaceAll(' ', '').replaceAll('-', '_');

    final semesterCode = _autoSemester == 'Học kỳ 1' ? 'HK1' : 'HK2';

    return '${academicYear}_$semesterCode';
  }

  String _buildQrRawValue({
    required String activityId,
    required String qrCode,
  }) {
    return '{"type":"activity_checkin","activityId":"$activityId","qrCode":"$qrCode"}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildMainCard(),
                    const SizedBox(height: 14),
                    _buildImageCard(),
                    const SizedBox(height: 14),
                    _buildTimeCard(),
                    const SizedBox(height: 14),
                    _buildTermCard(),
                    const SizedBox(height: 14),
                    _buildSettingCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          _BackButtonCard(onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'Sửa hoạt động' : 'Thêm hoạt động',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.event_note_rounded,
            title: 'Thông tin hoạt động',
          ),
          const SizedBox(height: 14),
          _input(
            controller: _titleController,
            label: 'Tên hoạt động',
            icon: Icons.event_note_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên hoạt động';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Danh mục',
            icon: Icons.category_rounded,
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Địa điểm',
            icon: Icons.location_on_rounded,
            value: _selectedLocation,
            items: _locations,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedLocation = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _input(
            controller: _descriptionController,
            label: 'Mô tả hoạt động',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _input(
                  controller: _maxParticipantsController,
                  label: 'Số lượng',
                  icon: Icons.people_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');

                    if (number == null || number <= 0) {
                      return 'Không hợp lệ';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  controller: _pointsController,
                  label: 'Điểm',
                  icon: Icons.star_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');

                    if (number == null || number < 0) {
                      return 'Không hợp lệ';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    final hasImage = _selectedImageFile != null || _currentImageUrl.isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.image_rounded, title: 'Ảnh hoạt động'),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 170,
              width: double.infinity,
              color: _isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFEAF4FF),
              child: _buildImagePreview(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: hasImage ? 2 : 1,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(
                      hasImage ? 'Đổi ảnh' : 'Chọn ảnh từ thư viện',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _clearSelectedImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.55)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageFile != null) {
      return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    }

    if (_currentImageUrl.isNotEmpty) {
      return Image.network(
        _currentImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _emptyImagePreview();
        },
      );
    }

    return _emptyImagePreview();
  }

  Widget _emptyImagePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, color: _subTextColor, size: 42),
        const SizedBox(height: 8),
        Text(
          'Chưa chọn ảnh',
          style: TextStyle(color: _subTextColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (picked == null) return;

    setState(() {
      _selectedImageFile = File(picked.path);
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _currentImageUrl = '';
    });
  }

  Widget _buildTimeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.schedule_rounded, title: 'Thời gian'),
          const SizedBox(height: 14),
          _dateTile(
            title: 'Bắt đầu',
            value: _formatDateTime(_startAt),
            onTap: () async {
              final picked = await _pickDateTime(_startAt);

              if (picked == null) return;

              setState(() {
                _startAt = picked;

                if (!_endAt.isAfter(_startAt)) {
                  _endAt = _startAt.add(const Duration(hours: 2));
                }
              });
            },
          ),
          const SizedBox(height: 10),
          _dateTile(
            title: 'Kết thúc',
            value: _formatDateTime(_endAt),
            onTap: () async {
              final picked = await _pickDateTime(_endAt);

              if (picked == null) return;

              setState(() {
                _endAt = picked;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.school_rounded, title: 'Học kỳ'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_formatAcademicYear(_startAt)} • $_autoSemester',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.tune_rounded, title: 'Cài đặt'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryBlue,
            title: Text(
              'Mở đăng ký',
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Sinh viên có thể đăng ký hoạt động',
              style: TextStyle(
                color: _subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: _registrationOpen,
            onChanged: (value) {
              setState(() {
                _registrationOpen = value;
              });
            },
          ),
          Divider(
            color: _isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryBlue,
            title: Text(
              'Mở điểm danh',
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Cho phép sinh viên quét QR check-in',
              style: TextStyle(
                color: _subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: _isCheckInOpen,
            onChanged: (value) {
              setState(() {
                _isCheckInOpen = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.3 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Text(
                  widget.isEdit ? 'Cập nhật hoạt động' : 'Thêm hoạt động',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _cardTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryBlue, size: 21),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: _textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _subTextColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: _cardColor,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _subTextColor),
      style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _subTextColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded, color: primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<String> _uploadImage(String activityId) async {
    if (_selectedImageFile == null) {
      return _currentImageUrl;
    }

    return CloudinaryService.instance.uploadActivityImage(
      imageFile: _selectedImageFile!,
      activityId: activityId,
    );
  }

  Future<void> _syncMyActivitiesAfterActivityUpdate({
    required String activityId,
    required Map<String, dynamic> data,
  }) async {
    final registrations = await _db
        .collectionGroup('myActivities')
        .where('activityId', isEqualTo: activityId)
        .get();

    if (registrations.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    int count = 0;

    for (final doc in registrations.docs) {
      final status = doc.data()['status']?.toString() ?? '';

      if (status == 'cancelled') continue;

      batch.set(doc.reference, {
        'title': data['title'],
        'category': data['category'],
        'description': data['description'],
        'startAt': data['startAt'],
        'endAt': data['endAt'],
        'location': data['location'],
        'imageUrl': data['imageUrl'],
        'points': data['points'],
        'academicYear': data['academicYear'],
        'semester': data['semester'],
        'termId': data['termId'],
        'qrCode': data['qrCode'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      count++;

      if (count == 450) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endAt.isAfter(_startAt)) {
      _showMessage('Thời gian kết thúc phải sau thời gian bắt đầu');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final docRef = widget.activityId == null
          ? _db.collection('activities').doc()
          : _db.collection('activities').doc(widget.activityId);

      final activityId = docRef.id;

      final oldQrCode = widget.initialData?['qrCode']?.toString().trim();

      final qrCode = oldQrCode == null || oldQrCode.isEmpty
          ? activityId
          : oldQrCode;

      final imageUrl = await _uploadImage(activityId);

      final academicYear = _formatAcademicYear(_startAt);
      final termId = _buildTermId();
      final qrRawValue = _buildQrRawValue(
        activityId: activityId,
        qrCode: qrCode,
      );

      final title = _titleController.text.trim();

      final data = {
        'title': title,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'startAt': Timestamp.fromDate(_startAt),
        'endAt': Timestamp.fromDate(_endAt),
        'location': _selectedLocation,
        'imageUrl': imageUrl,
        'maxParticipants': int.parse(_maxParticipantsController.text.trim()),
        'points': int.parse(_pointsController.text.trim()),
        'academicYear': academicYear,
        'semester': _autoSemester,
        'termId': termId,
        'qrCode': qrCode,
        'qrRawValue': qrRawValue,
        'registrationOpen': _registrationOpen,
        'isCheckInOpen': _isCheckInOpen,
        'status': _getStatus(_startAt, _endAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.activityId == null) {
        await docRef.set({
          ...data,
          'currentParticipants': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (_registrationOpen) {
          await NotificationRepository().createActivityNotification(
            activityId: activityId,
            activityTitle: title,
            activityCategory: _selectedCategory,
            activityDate: _startAt,
            activityTime: _formatDateTime(_startAt),
          );
        }
      } else {
        await docRef.set(data, SetOptions(merge: true));

        await _syncMyActivitiesAfterActivityUpdate(
          activityId: activityId,
          data: data,
        );
      }

      if (!mounted) return;

      _showMessage(
        widget.isEdit ? 'Đã cập nhật hoạt động' : 'Đã thêm hoạt động',
      );

      Navigator.pop(context);
    } catch (e) {
      _showMessage('Lỗi lưu hoạt động: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getStatus(DateTime startAt, DateTime endAt) {
    final now = DateTime.now();

    if (now.isBefore(startAt)) return 'upcoming';

    if (now.isAfter(endAt)) return 'finished';

    return 'ongoing';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryBlue,
      ),
    );
  }
}

class _BackButtonCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.32)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
