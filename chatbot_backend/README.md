# ITConnect Chatbot API

Backend FastAPI cho chatbot ITConnect.

## 1. Cài đặt

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
```

## 2. Chạy API

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Test:

```bash
curl http://localhost:8000/health
```

## 3. Kết nối Firestore thật

Tải Firebase Admin SDK service account JSON từ Firebase Console, rồi set biến môi trường:

```bash
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
```

Nếu chưa set service account, API vẫn chạy nhưng các câu hỏi cần Firestore sẽ trả lời dạng demo/không có dữ liệu.

## 4. Train PhoBERT intent classifier

Dataset mẫu nằm ở `data/intent_dataset.csv`.

```bash
python scripts/train_intent_phobert.py
```

Sau khi train, model lưu ở:

```text
models/phobert_intent
```

API sẽ tự load model này nếu tồn tại. Nếu chưa train, API dùng rule-based intent để chạy trước.
