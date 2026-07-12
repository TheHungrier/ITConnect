# ITConnect Chatbot API

Backend FastAPI cho chatbot ITConnect.

---

## 1. Mục tiêu

Cung cấp API chatbot để trả lời nhanh các câu hỏi liên quan đến nghiệp vụ ITConnect:

- hoạt động học thuật/đoàn,
- điểm danh,
- điểm rèn luyện,
- góp ý,
- bản đồ và thông tin liên quan.

---

## 2. Yêu cầu môi trường

- Python 3.11+
- pip
- (Khuyến nghị) `venv`

---

## 3. Cài đặt

Từ thư mục gốc repository:

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

Cài dependencies:

```bash
pip install -r requirements.txt
```

---

## 4. Chạy API local

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

Nếu chạy thành công, endpoint `/health` sẽ trả trạng thái OK.

---

## 5. Cấu hình Firestore thật

Tải Firebase Admin SDK service account JSON từ Firebase Console, sau đó set biến môi trường:

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

> Nếu chưa set service account, API vẫn chạy nhưng các truy vấn cần Firestore có thể trả dữ liệu demo/rỗng.

---

## 6. Train PhoBERT intent classifier

Dataset mẫu nằm ở:

```text
data/intent_dataset.csv
```

Chạy train:

```bash
python scripts/train_intent_phobert.py
```

Model sau train sẽ được lưu tại:

```text
models/phobert_intent
```

API sẽ tự load model này nếu tồn tại. Nếu chưa train, API dùng rule-based intent để chạy trước.

---

## 7. Gợi ý debug nhanh

- Kiểm tra đúng phiên bản Python (`python --version`).
- Kiểm tra virtual environment đã được activate.
- Kiểm tra biến `GOOGLE_APPLICATION_CREDENTIALS` đúng đường dẫn.
- Kiểm tra cổng `8000` chưa bị chiếm bởi tiến trình khác.
