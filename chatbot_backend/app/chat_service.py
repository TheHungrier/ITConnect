from datetime import datetime
from typing import Any, Dict, List

from .firebase_service import FirebaseService
from .intent_service import IntentService


class ChatService:
    def __init__(self) -> None:
        self.intent_service = IntentService()
        self.firebase = FirebaseService()

    def reply(self, user_id: str, message: str) -> Dict[str, Any]:
        intent, confidence = self.intent_service.predict(message)

        if intent == 'greeting':
            return self._response('Xin chào! Bạn muốn hỏi về hoạt động, điểm rèn luyện, điểm danh hay bản đồ?', intent, confidence)

        if intent == 'training_score':
            return self._training_score(user_id, intent, confidence)

        if intent == 'upcoming_activity':
            return self._upcoming_activities(intent, confidence)

        if intent == 'my_activities':
            return self._my_activities(user_id, intent, confidence)

        if intent == 'check_in_guide':
            return self._response(
                'Để điểm danh, bạn vào mục Điểm danh ở thanh điều hướng, quét mã QR của hoạt động, thêm ảnh/video minh chứng rồi bấm xác nhận. Sau đó admin sẽ duyệt minh chứng.',
                intent,
                confidence,
            )
        
        if intent == 'attendance_status':
            return self._response(
                'Bạn có thể xem trạng thái điểm danh trong mục Hoạt động của tôi. Nếu minh chứng đang chờ xử lý, trạng thái sẽ là Chờ duyệt. Khi admin duyệt và chốt điểm danh, hoạt động sẽ chuyển sang Hoàn thành. Nếu minh chứng bị từ chối hoặc bạn không điểm danh, hệ thống sẽ ghi nhận Vắng.',
                intent,
                confidence,
            )
        
        if intent == 'absent_penalty':
            return self._response(
                'Nếu bạn vắng hoặc minh chứng điểm danh bị từ chối, hệ thống sẽ đánh dấu Vắng và trừ 6 điểm rèn luyện trong học kỳ đó.',
                intent,
                confidence,
            )

        if intent == 'notification_help':
            return self._response(
                'Bạn có thể xem thông báo trong màn Thông báo. Các thông báo quan trọng gồm hoạt động mới, nhắc điểm danh, tin tức quan trọng và kết quả xử lý điểm danh.',
                intent,
                confidence,
            )

        if intent == 'map_help':
            return self._response(
                'Bạn mở mục Bản đồ ở Home để tìm các địa điểm trong trường. Có thể tìm kiếm theo tên khu vực hoặc chọn bộ lọc địa điểm.',
                intent,
                confidence,
            )

        if intent == 'feedback_help':
            return self._response(
                'Bạn vào mục Góp ý ở Home, chọn loại góp ý và nhập nội dung. Admin sẽ xem và xử lý phản hồi của bạn.',
                intent,
                confidence,
            )

        return self._response(
            'Mình chưa hiểu rõ câu hỏi này. Bạn có thể hỏi ngắn hơn, ví dụ: "Điểm rèn luyện của tôi bao nhiêu?" hoặc "Tôi có hoạt động nào sắp diễn ra?"',
            'unknown',
            confidence,
        )

    def _training_score(self, user_id: str, intent: str, confidence: float) -> Dict[str, Any]:
        activities = self.firebase.get_my_activities(user_id)

        if not activities:
            return self._response(
                'Hiện mình chưa tìm thấy hoạt động của bạn. Điểm rèn luyện mặc định mỗi học kỳ là 70 điểm.',
                intent,
                confidence,
            )

        completed_points = 0
        penalty_points = 0
        completed_count = 0
        absent_count = 0

        for activity in activities:
            status = str(activity.get('status', ''))
            attended = activity.get('attended') is True

            if status == 'completed' and attended:
                completed_points += self._to_int(activity.get('points'))
                completed_count += 1

            if status == 'absent' or self._to_int(activity.get('penaltyPoints')) > 0:
                penalty = self._to_int(activity.get('penaltyPoints')) or 6
                penalty_points += penalty
                absent_count += 1

        total = max(0, min(100, 70 + completed_points - penalty_points))
        rank = self._rank(total)

        return self._response(
            f'Điểm rèn luyện hiện tại của bạn là {total}/100, xếp loại {rank}. Bạn đã hoàn thành {completed_count} hoạt động, cộng {completed_points} điểm và bị trừ {penalty_points} điểm từ {absent_count} hoạt động vắng/từ chối.',
            intent,
            confidence,
        )

    def _upcoming_activities(self, intent: str, confidence: float) -> Dict[str, Any]:
        activities = self.firebase.get_upcoming_activities(limit=5)

        if not activities:
            return self._response(
                'Hiện chưa có hoạt động sắp diễn ra trong hệ thống hoặc backend chưa kết nối được Firestore.',
                intent,
                confidence,
            )

        lines = ['Các hoạt động sắp diễn ra:']
        for index, activity in enumerate(activities, start=1):
            title = activity.get('title') or 'Hoạt động'
            location = activity.get('location') or 'Chưa cập nhật địa điểm'
            start_at = self._format_firestore_date(activity.get('startAt'))
            points = self._to_int(activity.get('points'))
            lines.append(f'{index}. {title} - {start_at} - {location} - +{points} điểm')

        return self._response('\n'.join(lines), intent, confidence)

    def _my_activities(self, user_id: str, intent: str, confidence: float) -> Dict[str, Any]:
        activities = self.firebase.get_my_activities(user_id)

        if not activities:
            return self._response('Bạn chưa có hoạt động nào trong danh sách Hoạt động của tôi.', intent, confidence)

        lines = ['Một số hoạt động của bạn:']
        for index, activity in enumerate(activities[:5], start=1):
            title = activity.get('title') or 'Hoạt động'
            status = activity.get('status') or 'upcoming'
            start_at = self._format_firestore_date(activity.get('startAt'))
            lines.append(f'{index}. {title} - {start_at} - trạng thái: {self._status_text(status)}')

        return self._response('\n'.join(lines), intent, confidence)

    def _response(self, reply: str, intent: str, confidence: float) -> Dict[str, Any]:
        return {
            'reply': reply,
            'intent': intent,
            'confidence': confidence,
        }

    def _to_int(self, value: Any) -> int:
        try:
            return int(value)
        except Exception:
            return 0

    def _format_firestore_date(self, value: Any) -> str:
        try:
            if hasattr(value, 'strftime'):
                return value.strftime('%d/%m/%Y %H:%M')
            if isinstance(value, datetime):
                return value.strftime('%d/%m/%Y %H:%M')
        except Exception:
            pass
        return 'Chưa cập nhật thời gian'

    def _rank(self, points: int) -> str:
        if points >= 90:
            return 'Xuất sắc'
        if points >= 80:
            return 'Tốt'
        if points >= 65:
            return 'Khá'
        if points >= 50:
            return 'Trung bình'
        if points >= 35:
            return 'Yếu'
        return 'Kém'

    def _status_text(self, status: str) -> str:
        mapping = {
            'upcoming': 'Sắp diễn ra',
            'pending_review': 'Chờ duyệt điểm danh',
            'completed': 'Hoàn thành',
            'absent': 'Vắng',
            'cancelled': 'Đã hủy',
        }
        return mapping.get(status, status)
