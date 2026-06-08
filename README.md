# ITConnect

ITConnect là ứng dụng hỗ trợ quản lý hoạt động sinh viên. Ứng dụng giúp sinh viên xem tin tức, đăng ký hoạt động, điểm danh bằng mã QR, gửi minh chứng, theo dõi điểm rèn luyện và gửi góp ý cho quản trị viên.

Project gồm 2 phần chính:

- `ltdd_qlhd_flutter`: ứng dụng mobile viết bằng Flutter.
- `chatbot_backend`: backend chatbot viết bằng Python FastAPI.

---

## 1. Chức năng chính

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

### Mobile app

- Flutter
- Firebase Authentication
- Cloud Firestore
- Cloudinary hoặc Firebase Storage cho ảnh/minh chứng tùy cấu hình
- Local Notifications
- OpenStreetMap với `flutter_map`

### Chatbot backend

- Python 3.11
- FastAPI
- Uvicorn
- Firebase Admin SDK
- PhoBERT dùng để phân loại ý định câu hỏi
- Dataset intent tự xây dựng theo nghiệp vụ của ITConnect

---

## 3. Cấu trúc thư mục

```text
MuRom_QLHD/
├── ltdd_qlhd_flutter/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── chatbot_backend/
│   ├── app/
│   ├── data/
│   ├── models/
│   ├── scripts/
│   └── requirements.txt
│
├── README.md
└── .gitignore
