import json
import os
import unicodedata
from pathlib import Path
from typing import Dict, Tuple

try:
    import torch
    from transformers import AutoModelForSequenceClassification, AutoTokenizer
except Exception:
    torch = None
    AutoTokenizer = None
    AutoModelForSequenceClassification = None


DEFAULT_INTENT_LABELS = [
    "absent_penalty",
    "attendance_status",
    "check_in_guide",
    "feedback_help",
    "greeting",
    "map_help",
    "my_activities",
    "notification_help",
    "training_score",
    "unknown",
    "upcoming_activity",
]


class IntentService:
    def __init__(self) -> None:
        self.model_dir = Path(os.getenv("INTENT_MODEL_DIR", "models/phobert_intent"))
        self.tokenizer = None
        self.model = None
        self.id2label = self._load_labels()
        self._load_model_if_available()

    def predict(self, text: str) -> Tuple[str, float]:
        clean_text = self._normalize_text(text)

        if not clean_text:
            return "unknown", 0.0

        # Ưu tiên rule trước để các câu ngắn / không dấu vẫn nhận đúng
        rule_intent, rule_confidence = self._rule_predict(clean_text)

        if rule_intent != "unknown":
            return rule_intent, rule_confidence

        # Rule không bắt được thì mới dùng model
        if self.model is not None and self.tokenizer is not None and torch is not None:
            try:
                encoded = self.tokenizer(
                    clean_text,
                    truncation=True,
                    padding=True,
                    max_length=128,
                    return_tensors="pt",
                )

                with torch.no_grad():
                    output = self.model(**encoded)
                    probs = torch.softmax(output.logits, dim=-1)[0]

                    index = int(torch.argmax(probs).item())
                    confidence = float(probs[index].item())
                    intent = self.id2label.get(index, "unknown")

                    if confidence < 0.30:
                        return "unknown", confidence

                    return intent, confidence
            except Exception:
                pass

        return "unknown", 0.4

    def _rule_predict(self, text: str) -> Tuple[str, float]:
        no_accent_text = self._remove_vietnamese_accents(text)
        combined = f"{text} {no_accent_text}"

        if self._has_any(
            combined,
            [
                "xin chao",
                "chao",
                "hello",
                "hi",
                "alo",
                "chatbot oi",
                "tro ly",
                "ban la ai",
                "ho tro",
            ],
        ):
            return "greeting", 0.98

        if self._has_any(
            combined,
            [
                "diem ren luyen",
                "diem cua toi",
                "bao nhieu diem",
                "xep loai",
                "diem hien tai",
                "tong diem",
                "dat loai",
                "diem hoat dong",
                "diem cua em",
            ],
        ):
            return "training_score", 0.94

        if self._has_any(
            combined,
            [
                "sap dien ra",
                "sap toi",
                "hoat dong nao",
                "hoat dong gan",
                "hoat dong moi",
                "dang mo dang ky",
                "su kien",
                "workshop",
                "seminar",
                "chuong trinh",
            ],
        ):
            return "upcoming_activity", 0.92

        if self._has_any(
            combined,
            [
                "da dang ky",
                "hoat dong cua toi",
                "toi dang ky",
                "lich hoat dong cua toi",
                "hoat dong ca nhan",
                "danh sach dang ky",
                "hoat dong toi",
                "hoat dong cua em",
            ],
        ):
            return "my_activities", 0.92

        if self._has_any(
            combined,
            [
                "trang thai diem danh",
                "da diem danh chua",
                "minh chung da duyet",
                "cho duyet",
                "ket qua diem danh",
                "da duoc duyet",
                "bi tu choi chua",
                "tinh trang diem danh",
                "da gui minh chung",
            ],
        ):
            return "attendance_status", 0.90

        if self._has_any(
            combined,
            [
                "diem danh",
                "qr",
                "quet ma",
                "check in",
                "check-in",
                "minh chung",
                "chup anh",
                "scanner",
                "quet qr",
            ],
        ):
            return "check_in_guide", 0.88

        if self._has_any(
            combined,
            [
                "vang",
                "tru diem",
                "bi tu choi",
                "minh chung khong hop le",
                "mat diem",
                "diem phat",
                "khong tham gia",
                "quen diem danh",
            ],
        ):
            return "absent_penalty", 0.90

        if self._has_any(
            combined,
            [
                "thong bao",
                "notification",
                "nhac nho",
                "cham do",
                "tin quan trong",
                "da doc",
            ],
        ):
            return "notification_help", 0.88

        if self._has_any(
            combined,
            [
                "ban do",
                "dia diem",
                "hoi truong",
                "map",
                "vi tri",
                "tim duong",
                "phong hoc",
                "campus",
                "khuon vien",
            ],
        ):
            return "map_help", 0.88

        if self._has_any(
            combined,
            [
                "gop y",
                "phan hoi",
                "feedback",
                "bao loi",
                "lien he admin",
                "ho tro tai khoan",
                "phan anh",
                "de xuat",
            ],
        ):
            return "feedback_help", 0.88

        return "unknown", 0.4

    def _load_model_if_available(self) -> None:
        if torch is None or AutoTokenizer is None or AutoModelForSequenceClassification is None:
            return

        if not self.model_dir.exists():
            return

        try:
            self.tokenizer = AutoTokenizer.from_pretrained(
                str(self.model_dir),
                use_fast=False,
            )
            self.model = AutoModelForSequenceClassification.from_pretrained(
                str(self.model_dir),
            )
            self.model.eval()

            config_id2label = getattr(self.model.config, "id2label", None)

            if isinstance(config_id2label, dict) and config_id2label:
                parsed = {}

                for key, value in config_id2label.items():
                    label = str(value)

                    # Bỏ qua LABEL_0, LABEL_1 vì đây không phải intent thật
                    if label.startswith("LABEL_"):
                        continue

                    parsed[int(key)] = label

                if parsed:
                    self.id2label = parsed

        except Exception:
            self.tokenizer = None
            self.model = None

    def _load_labels(self) -> Dict[int, str]:
        possible_files = [
            self.model_dir / "id2label.json",
            self.model_dir / "labels.json",
            self.model_dir / "label_encoder.json",
        ]

        for file_path in possible_files:
            if not file_path.exists():
                continue

            try:
                with file_path.open("r", encoding="utf-8") as file:
                    data = json.load(file)

                if isinstance(data, dict):
                    result = {}

                    for key, value in data.items():
                        if str(key).isdigit():
                            label = str(value)

                            if not label.startswith("LABEL_"):
                                result[int(key)] = label

                        elif str(value).isdigit():
                            result[int(value)] = str(key)

                    if result:
                        return result

                if isinstance(data, list):
                    return {
                        index: str(label)
                        for index, label in enumerate(data)
                        if not str(label).startswith("LABEL_")
                    }
            except Exception:
                pass

        return {index: label for index, label in enumerate(DEFAULT_INTENT_LABELS)}

    def _normalize_text(self, text: str) -> str:
        return " ".join((text or "").strip().lower().split())

    def _remove_vietnamese_accents(self, text: str) -> str:
        text = text.replace("đ", "d").replace("Đ", "D")
        normalized = unicodedata.normalize("NFD", text)

        return "".join(
            char for char in normalized
            if unicodedata.category(char) != "Mn"
        )

    def _has_any(self, text: str, keywords: list[str]) -> bool:
        return any(keyword in text for keyword in keywords)