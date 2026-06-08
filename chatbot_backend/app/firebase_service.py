import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

try:
    import firebase_admin
    from firebase_admin import auth, credentials, firestore
except Exception:
    firebase_admin = None
    auth = None
    credentials = None
    firestore = None


class FirebaseService:
    def __init__(self) -> None:
        self.enabled = False
        self.db = None
        self._init_firebase()

    def _init_firebase(self) -> None:
        if firebase_admin is None:
            print('[FirebaseService] firebase_admin chưa được cài.')
            return

        try:
            if not firebase_admin._apps:
                service_account = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '')

                if service_account and os.path.exists(service_account):
                    cred = credentials.Certificate(service_account)
                    firebase_admin.initialize_app(cred)
                else:
                    firebase_admin.initialize_app()

            self.db = firestore.client()
            self.enabled = True

        except Exception as e:
            print(f'[FirebaseService] Lỗi khởi tạo Firebase: {e}')
            self.enabled = False
            self.db = None

    def verify_id_token(self, token: str) -> Optional[str]:
        if not self.enabled or auth is None or not token:
            return None

        try:
            decoded = auth.verify_id_token(token)
            return decoded.get('uid')
        except Exception:
            return None

    def get_user(self, user_id: str) -> Dict[str, Any]:
        if not self.enabled or self.db is None or not user_id:
            return {}

        try:
            doc = self.db.collection('users').document(user_id).get()
            return doc.to_dict() or {}
        except Exception:
            return {}

    def get_my_activities(self, user_id: str) -> List[Dict[str, Any]]:
        if not self.enabled or self.db is None or not user_id:
            return []

        try:
            ref = (
                self.db
                .collection('users')
                .document(user_id)
                .collection('myActivities')
            )

            docs = list(ref.stream())
            result: List[Dict[str, Any]] = []

            for doc in docs:
                data = doc.to_dict() or {}
                data['id'] = doc.id

                if data.get('status') == 'cancelled':
                    continue

                result.append(data)

            result.sort(key=lambda item: self._sort_date_value(item.get('startAt')))

            return result

        except Exception:
            return []

    def get_upcoming_activities(self, limit: int = 5) -> List[Dict[str, Any]]:
        if not self.enabled or self.db is None:
            return []

        try:
            now = datetime.now(timezone.utc)

            docs = self.db.collection('activities').stream()
            result: List[Dict[str, Any]] = []

            for doc in docs:
                data = doc.to_dict() or {}
                data['id'] = doc.id

                status = str(data.get('status', '')).strip()

                if status == 'cancelled':
                    continue

                start_at = data.get('startAt')

                try:
                    if hasattr(start_at, 'timestamp') and start_at.timestamp() < now.timestamp():
                        continue
                except Exception:
                    pass

                result.append(data)

            result.sort(key=lambda item: self._sort_date_value(item.get('startAt')))

            return result[:limit]

        except Exception:
            return []

    def _sort_date_value(self, value: Any) -> float:
        try:
            if hasattr(value, 'timestamp'):
                return float(value.timestamp())

            if isinstance(value, datetime):
                return float(value.timestamp())
        except Exception:
            pass

        return 0.0