# ITConnect

ITConnect là hệ thống hỗ trợ quản lý đăng ký tham gia hoạt động học thuật và hoạt động đoàn cho sinh viên.

Ứng dụng gồm 2 thành phần chính:

- `ltdd_qlhd_flutter`: Ứng dụng mobile viết bằng Flutter cho sinh viên và quản trị viên.
- `chatbot_backend`: API chatbot viết bằng FastAPI, hỗ trợ trả lời nhanh các câu hỏi nghiệp vụ.

---

## Mục lục

- [1. Tính năng chính](#1-tính-năng-chính)
- [2. Công nghệ sử dụng](#2-công-nghệ-sử-dụng)
- [3. Cấu trúc thư mục](#3-cấu-trúc-thư-mục)
- [4. Yêu cầu môi trường](#4-yêu-cầu-môi-trường)
- [5. Hướng dẫn chạy nhanh](#5-hướng-dẫn-chạy-nhanh)
- [6. Cấu hình Firebase và biến môi trường](#6-cấu-hình-firebase-và-biến-môi-trường)

---

## 1. Tính năng chính

### Sinh viên

- Đăng nhập bằng mã đăng nhập hoặc mã sinh viên.
- Xem tin tức và thông báo.
- Xem danh sách hoạt động.
- Đăng ký hoặc hủy đăng ký hoạt động.
- Xem “Hoạt động của tôi”.
- Điểm danh hoạt động bằng mã QR.
- Gửi ảnh hoặc video minh chứng điểm danh.
- Theo dõi điểm rèn luyện theo học kỳ.
- Xem bản đồ các địa điểm trong trường.
- Gửi góp ý hoặc phản hồi cho quản trị viên.
- Sử dụng chatbot để hỏi nhanh về hoạt động, điểm rèn luyện, điểm danh, bản đồ và góp ý.

### Quản trị viên

- Xem dashboard thống kê.
- Quản lý hoạt động.
- Quản lý tin tức.
- Quản lý danh sách điểm danh.
- Duyệt hoặc từ chối minh chứng điểm danh.
- Chốt điểm danh sau khi hoạt động kết thúc.
- Xem và xử lý góp ý của sinh viên.
- Xem thông báo dành cho admin.

---

## 2. Công nghệ sử dụng

### Mobile app (`ltdd_qlhd_flutter`)

- Flutter
- Firebase Authentication
- Cloud Firestore
- Cloudinary hoặc Firebase Storage
- Local Notifications
- OpenStreetMap với `flutter_map`

### Chatbot backend (`chatbot_backend`)

- Python 3.11+
- FastAPI
- Uvicorn
- Firebase Admin SDK
- PhoBERT cho phân loại intent
- Dataset intent tự xây dựng theo nghiệp vụ ITConnect

---

## 3. Cấu trúc thư mục

```text
ITConnect/
├─ ltdd_qlhd_flutter/        # Ứng dụng mobile Flutter
├─ chatbot_backend/          # API chatbot FastAPI
└─ README.md                 # Tài liệu tổng quan dự án
```

---

## 4. Yêu cầu môi trường

### Chung

- Git

### Cho Flutter app

- Flutter SDK (khuyến nghị bản stable mới nhất)
- Dart SDK (đi kèm Flutter)
- Android Studio/Xcode (tuỳ nền tảng chạy)

### Cho chatbot backend

- Python 3.11+
- pip
- (Khuyến nghị) virtualenv hoặc venv

---

## 5. Hướng dẫn chạy nhanh

## 5.1 Clone repository

```bash
git clone https://github.com/TheHungrier/ITConnect.git
cd ITConnect
```

## 5.2 Chạy chatbot backend

Xem chi tiết tại [`chatbot_backend/README.md`](chatbot_backend/README.md).

```bash
cd chatbot_backend
python -m venv .venv
```

### Windows

```bash
.venv\Scripts\activate
```

### macOS/Linux

```bash
source .venv/bin/activate
```

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

## 5.3 Chạy Flutter app

Xem chi tiết tại [`ltdd_qlhd_flutter/README.md`](ltdd_qlhd_flutter/README.md).

```bash
cd ltdd_qlhd_flutter
flutter pub get
flutter run
```

---

## 6. Cấu hình Firebase và biến môi trường

### Backend FastAPI

Để truy cập Firestore thật, cần set biến môi trường `GOOGLE_APPLICATION_CREDENTIALS` trỏ đến file service account JSON.

### Windows (PowerShell)

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\service-account.json"
```

### Windows (CMD)

```bat
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
```

### macOS/Linux

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/service-account.json"
```

> Nếu chưa cấu hình service account, backend vẫn có thể chạy nhưng các chức năng cần dữ liệu Firestore có thể trả về dữ liệu demo/rỗng.

### Flutter app

- Cần cấu hình Firebase project tương ứng (Android/iOS).
- Đảm bảo các file cấu hình nền tảng đã được thêm đúng theo tài liệu Firebase cho Flutter.
