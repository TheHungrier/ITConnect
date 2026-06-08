import json
import os
from pathlib import Path

import pandas as pd
import torch
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from torch.utils.data import Dataset
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    Trainer,
    TrainingArguments,
)

DATA_PATH = Path(os.getenv('DATA_PATH', 'data/intent_dataset.csv'))
OUTPUT_DIR = Path(os.getenv('OUTPUT_DIR', 'models/phobert_intent'))
MODEL_NAME = os.getenv('MODEL_NAME', 'vinai/phobert-base')


class IntentDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, index):
        encoded = self.tokenizer(
            str(self.texts[index]),
            truncation=True,
            padding='max_length',
            max_length=self.max_length,
            return_tensors='pt',
        )

        item = {key: value.squeeze(0) for key, value in encoded.items()}
        item['labels'] = torch.tensor(int(self.labels[index]), dtype=torch.long)

        return item


def main():
    if not DATA_PATH.exists():
        raise FileNotFoundError(f'Không tìm thấy dataset: {DATA_PATH}')

    df = pd.read_csv(DATA_PATH)
    df = df.dropna(subset=['text', 'intent'])

    df['text'] = df['text'].astype(str).str.strip()
    df['intent'] = df['intent'].astype(str).str.strip()

    df = df[(df['text'] != '') & (df['intent'] != '')]
    df = df.drop_duplicates(subset=['text', 'intent'])

    label_encoder = LabelEncoder()
    labels = label_encoder.fit_transform(df['intent'])

    id2label = {
        index: label
        for index, label in enumerate(label_encoder.classes_)
    }

    label2id = {
        label: index
        for index, label in id2label.items()
    }

    print('Dataset:', DATA_PATH)
    print('Total samples:', len(df))
    print('Intents:', id2label)

    train_texts, val_texts, train_labels, val_labels = train_test_split(
        df['text'].tolist(),
        labels.tolist(),
        test_size=0.2,
        random_state=42,
        stratify=labels,
    )

    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, use_fast=False)

    model = AutoModelForSequenceClassification.from_pretrained(
        MODEL_NAME,
        num_labels=len(label_encoder.classes_),
        id2label=id2label,
        label2id=label2id,
    )

    train_dataset = IntentDataset(train_texts, train_labels, tokenizer)
    val_dataset = IntentDataset(val_texts, val_labels, tokenizer)

    args = TrainingArguments(
        output_dir=str(OUTPUT_DIR),
        eval_strategy='epoch',
        save_strategy='epoch',
        learning_rate=2e-5,
        per_device_train_batch_size=4,
        per_device_eval_batch_size=4,
        num_train_epochs=3,
        weight_decay=0.01,
        logging_steps=20,
        load_best_model_at_end=True,
        metric_for_best_model='eval_loss',
        save_total_limit=2,
    )

    trainer = Trainer(
        model=model,
        args=args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
    )

    trainer.train()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    trainer.save_model(str(OUTPUT_DIR))
    tokenizer.save_pretrained(str(OUTPUT_DIR))

    with (OUTPUT_DIR / 'id2label.json').open('w', encoding='utf-8') as file:
        json.dump(id2label, file, ensure_ascii=False, indent=2)

    with (OUTPUT_DIR / 'label2id.json').open('w', encoding='utf-8') as file:
        json.dump(label2id, file, ensure_ascii=False, indent=2)

    with (OUTPUT_DIR / 'labels.txt').open('w', encoding='utf-8') as file:
        for label in label_encoder.classes_:
            file.write(f'{label}\n')

    print(f'Saved model to {OUTPUT_DIR}')
    print('Saved id2label.json, label2id.json, labels.txt')


if __name__ == '__main__':
    main()