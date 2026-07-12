# ITConnect Flutter App

Ứng dụng mobile Flutter cho hệ thống ITConnect.

---

## 1. Chức năng chính

- Đăng nhập tài khoản sinh viên/quản trị viên.
- Xem tin tức, thông báo, danh sách hoạt động.
- Đăng ký/hủy đăng ký hoạt động.
- Điểm danh bằng mã QR.
- Gửi minh chứng (ảnh/video) khi cần.
- Theo dõi điểm rèn luyện.
- Xem bản đồ địa điểm trong trường.
- Gửi góp ý và sử dụng chatbot hỗ trợ.

---

## 2. Yêu cầu môi trường

- Flutter SDK (khuyến nghị stable mới nhất)
- Dart SDK (đi kèm Flutter)
- Android Studio hoặc VS Code
- Thiết bị/emulator Android hoặc iOS

Kiểm tra môi trường:

```bash
flutter doctor
```

---

## 3. Cài đặt và chạy

Từ thư mục gốc repository:

```bash
cd ltdd_qlhd_flutter
flutter pub get
flutter run
```

Build release (tuỳ chọn):

```bash
flutter build apk
```

---

## 4. Cấu hình Firebase

Project này sử dụng Firebase (Authentication/Firestore/Storage theo cấu hình dự án).

Bạn cần:

1. Tạo/chọn Firebase project.
2. Thêm app Android/iOS tương ứng.
3. Thêm file cấu hình Firebase cho từng nền tảng theo hướng dẫn FlutterFire.

> Lưu ý: Không commit các thông tin nhạy cảm (API keys đặc biệt, service account, secrets) lên repository công khai.

---

## 5. Cấu trúc mã nguồn (mức cơ bản)

```text
ltdd_qlhd_flutter/
├─ lib/
│  ├─ ... (screens, widgets, services, models)
├─ assets/
├─ android/
├─ ios/
└─ pubspec.yaml
```

---

## 6. Gợi ý phát triển

- Tổ chức theo module tính năng (auth, activity, attendance, feedback...).
- Tách rõ `UI` / `state` / `service` để dễ bảo trì.
- Dùng môi trường dev/staging/prod nếu dự án mở rộng.

---

## 7. Liên quan backend chatbot

Backend chatbot nằm ở thư mục:

```text
../chatbot_backend
```

Xem hướng dẫn chạy backend tại `chatbot_backend/README.md`.
