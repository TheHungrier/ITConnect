import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../controllers/check_in_controller.dart';
import '../../repositories/check_in_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import 'attendance_detail_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final CheckInController _checkInController = CheckInController();
  final CheckInRepository _checkInRepository = CheckInRepository();
  final ImagePicker _imagePicker = ImagePicker();

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _openDetail(CheckInData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceDetailScreen(
          qrRawValue: data.qrRawValue,
          activityId: data.activityId,
          qrCode: data.qrCode,
          activityTitle: data.activityTitle,
          activityLocation: data.activityLocation,
          activityTime: data.activityTime,
          studentName: data.studentName,
          studentCode: data.studentCode,
          checkInTime: data.checkInTime,
        ),
      ),
    ).then((_) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
    });
  }

  Future<void> _handleQrCode(String rawValue) async {
    if (_isProcessing) return;

    if (!_checkInController.isActivityCheckInQr(rawValue)) {
      _showError('Mã QR không hợp lệ');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final parsedData = _checkInController.createCheckInData(rawValue);

      if (parsedData.activityId.trim().isEmpty) {
        throw Exception('Không tìm thấy mã hoạt động trong QR');
      }

      if (parsedData.qrCode.trim().isEmpty) {
        throw Exception('Không tìm thấy mã QR trong dữ liệu');
      }

      final previewData = await _checkInRepository.validateQrBeforeOpenDetail(
        activityId: parsedData.activityId,
        qrCode: parsedData.qrCode,
      );

      if (!mounted) return;

      final data = CheckInData(
        qrRawValue: rawValue,
        activityId: previewData.activityId,
        qrCode: previewData.qrCode,
        activityTitle: previewData.activityTitle,
        activityLocation: previewData.activityLocation,
        activityTime: previewData.activityTime,
        studentName: previewData.studentName,
        studentCode: previewData.studentCode,
        checkInTime: DateTime.now(),
      );

      _openDetail(data);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickQrFromGallery() async {
    if (_isProcessing) return;

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedImage == null) return;

      setState(() {
        _isProcessing = true;
      });

      final capture = await _scannerController.analyzeImage(pickedImage.path);
      final barcodes = capture?.barcodes ?? [];

      if (barcodes.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        _showError('Không tìm thấy mã QR trong ảnh');
        return;
      }

      final rawValue = barcodes.first.rawValue;

      if (rawValue == null || rawValue.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        _showError('Không đọc được nội dung mã QR');
        return;
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await _handleQrCode(rawValue.trim());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showError('Lỗi chọn ảnh QR: $e');
    }
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();

    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  _buildScannerCard(),
                  const SizedBox(height: 18),
                  _buildGuideCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Điểm danh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 340,
              width: double.infinity,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;

                      if (barcodes.isEmpty) return;

                      final value = barcodes.first.rawValue;

                      if (value == null || value.trim().isEmpty) return;

                      _handleQrCode(value.trim());
                    },
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 190,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.50),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Đưa mã QR vào giữa khung để quét',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _scannerAction(
                  icon: Icons.cameraswitch_rounded,
                  title: 'Đổi camera',
                  onTap: () {
                    _scannerController.switchCamera();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _scannerAction(
                  icon: _isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  title: _isTorchOn ? 'Tắt đèn' : 'Bật đèn',
                  onTap: _toggleTorch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _galleryButton(),
        ],
      ),
    );
  }

  Widget _galleryButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickQrFromGallery,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.iconBox(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_rounded,
              color: AppColors.primary(context),
              size: 20,
            ),
            const SizedBox(width: 7),
            Text(
              'Chọn ảnh QR từ thư viện',
              style: TextStyle(
                color: AppColors.primary(context),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scannerAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.iconBox(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary(context), size: 20),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: AppColors.primary(context),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary(context),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bạn có thể quét trực tiếp bằng camera hoặc chọn ảnh QR đã lưu trong thư viện. Sau khi đọc QR thành công, hệ thống sẽ kiểm tra hoạt động trước khi chuyển sang trang xác nhận và gửi minh chứng.',
              style: TextStyle(
                color: AppColors.subtitle(context),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
