import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/campus_location_model.dart';

class CampusMapController extends ChangeNotifier {
  String keyword = '';
  String selectedArea = 'Tất cả';

  final LatLng campusCenter = const LatLng(10.8067, 106.6286);

  final List<String> areas = const [
    'Tất cả',
    'Khu A',
    'Khu B',
    'Thư viện',
    'Hội trường',
    'Văn phòng',
  ];

  final List<CampusLocationModel> locations = [
    CampusLocationModel(
      id: 'hall',
      name: 'Hội trường',
      area: 'Hội trường',
      building: 'Tòa nhà C',
      floor: 'Tầng 3',
      description:
          'Địa điểm thường tổ chức workshop, seminar, hội thảo và sự kiện lớn.',
      note: 'Nên đến trước 10-15 phút nếu hoạt động có điểm danh QR.',
      position: const LatLng(10.807689733479092, 106.62872561800845),
      icon: Icons.groups_rounded,
    ),
    CampusLocationModel(
      id: 'library',
      name: 'Thư viện',
      area: 'Thư viện',
      building: 'Trung tâm thông tin thư viện',
      floor: 'Tầng 1 - Tầng 3',
      description:
          'Khu vực đọc sách, học nhóm, tra cứu tài liệu và sử dụng máy tính học tập.',
      note: 'Giữ trật tự khi tham gia hoạt động hoặc học nhóm.',
      position: const LatLng(10.806709403781625, 106.62851762699695),
      icon: Icons.local_library_rounded,
    ),
    CampusLocationModel(
      id: 'a_area',
      name: 'Khu A',
      area: 'Khu A',
      building: 'Tòa nhà A',
      floor: 'Tầng 1 - Tầng 4',
      description:
          'Khu phòng học lý thuyết, sinh hoạt lớp và một số hoạt động học thuật.',
      note: 'Kiểm tra mã phòng trong thông tin hoạt động trước khi đến.',
      position: const LatLng(10.806783595310764, 106.62883767183055),
      icon: Icons.apartment_rounded,
    ),
    CampusLocationModel(
      id: 'b_area',
      name: 'Khu B',
      area: 'Khu B',
      building: 'Tòa nhà B',
      floor: 'Tầng 1 - Tầng 4',
      description:
          'Khu phòng học và phòng thực hành, có thể dùng cho workshop hoặc seminar.',
      note: 'Một số phòng có thể cần đăng nhập tài khoản sinh viên.',
      position: const LatLng(10.807243020998026, 106.62884892528847),
      icon: Icons.apartment_rounded,
    ),
    CampusLocationModel(
      id: 'faculty_office',
      name: 'Văn phòng Khoa CNTT',
      area: 'Văn phòng',
      building: 'Tòa nhà B',
      floor: 'Tầng trệt',
      description:
          'Nơi sinh viên có thể liên hệ các vấn đề liên quan đến khoa, hoạt động hoặc hỗ trợ học tập.',
      note: 'Nên liên hệ trong giờ hành chính.',
      position: const LatLng(10.807142999608097, 106.62883580289116),
      icon: Icons.business_center_rounded,
    ),
  ];

  void updateKeyword(String value) {
    keyword = value.trim().toLowerCase();
    notifyListeners();
  }

  void changeArea(String area) {
    selectedArea = area;
    notifyListeners();
  }

  List<CampusLocationModel> filteredLocations() {
    return locations.where((location) {
      final matchArea =
          selectedArea == 'Tất cả' || location.area == selectedArea;

      final searchText = [
        location.name,
        location.area,
        location.building,
        location.floor,
        location.description,
        location.note,
      ].join(' ').toLowerCase();

      final matchKeyword = keyword.isEmpty || searchText.contains(keyword);

      return matchArea && matchKeyword;
    }).toList();
  }
}
