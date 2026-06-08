import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/check_in_repository.dart';
import '../services/cloudinary_service.dart';

class AttendanceDetailResult {
  final bool success;
  final String message;

  AttendanceDetailResult({required this.success, required this.message});
}

class AttendanceDetailController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final CheckInRepository _checkInRepository = CheckInRepository();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  XFile? evidenceFile;
  bool isVideo = false;
  bool isSubmitting = false;

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (file == null) return;

    evidenceFile = file;
    isVideo = false;
    notifyListeners();
  }

  Future<void> recordVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 20),
    );

    if (file == null) return;

    evidenceFile = file;
    isVideo = true;
    notifyListeners();
  }

  Future<void> chooseFromGallery() async {
    final file = await _picker.pickMedia();

    if (file == null) return;

    final lowerPath = file.path.toLowerCase();

    evidenceFile = file;
    isVideo =
        lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mkv');

    notifyListeners();
  }

  void removeEvidence() {
    evidenceFile = null;
    isVideo = false;
    notifyListeners();
  }

  Future<String> _uploadEvidence({required String activityId}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để tải minh chứng');
    }

    final file = evidenceFile;

    if (file == null) {
      throw Exception('Vui lòng thêm ảnh hoặc video minh chứng');
    }

    final localFile = File(file.path);

    if (!await localFile.exists()) {
      throw Exception('Không tìm thấy file minh chứng');
    }

    final result = await CloudinaryService.instance.uploadEvidence(
      file: localFile,
      userId: user.uid,
      activityId: activityId,
      isVideo: isVideo,
    );

    return result.secureUrl;
  }

  Future<AttendanceDetailResult> confirmCheckIn({
    required String activityId,
    required String qrCode,
    required String qrRawValue,
  }) async {
    if (evidenceFile == null) {
      return AttendanceDetailResult(
        success: false,
        message: 'Vui lòng thêm ảnh hoặc video minh chứng',
      );
    }

    try {
      isSubmitting = true;
      notifyListeners();

      final proofUrl = await _uploadEvidence(activityId: activityId);

      await _checkInRepository.confirmCheckIn(
        activityId: activityId,
        qrCode: qrCode,
        qrRawValue: qrRawValue,
        proofUrl: proofUrl,
        proofType: isVideo ? 'video' : 'image',
      );

      return AttendanceDetailResult(
        success: true,
        message: 'Xác nhận điểm danh thành công',
      );
    } catch (e) {
      return AttendanceDetailResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
