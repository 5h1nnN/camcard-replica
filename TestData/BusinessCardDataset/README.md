# Synthetic Business Card Test Dataset

This folder contains 30 deterministic, synthetic business-card images for OCR, field-extraction, edge-detection, and perspective-correction testing. No real personal information is used; all emails use `example.com` and all names, companies, addresses, and phone numbers are fictional.

## Contents

- `images/card_001.png` … `card_030.png`: final 1400×1000 test scenes.
- `sources/card_001.svg` … `card_030.svg`: browser-compatible canonical card artwork with exact text.
- `ground_truth.json`: authoritative structured fields, OCR text, missing fields, layout, difficulty, and disturbance parameters.
- `ground_truth.csv`: flattened version for spreadsheets and simple test runners.
- `gallery.html`: visual HTML index of all cases and expected values.
- `contact_sheet.png`: compact visual overview.
- `checksums.sha256`: SHA-256 checksums for reproducibility.

## Coverage

- Simplified Chinese, English, and bilingual cards.
- Missing company, title, email, website, and address fields.
- Mobile, office, and fax classification.
- Rotations from −8° to 180°.
- Left/right/top/bottom and strong perspective distortions.
- Soft/hard shadows, low contrast, dark scenes, partial occlusion, cropped edges, blur/noise, patterned and cluttered desks.

## Ground-truth rules

- Empty strings mean that the field is intentionally absent; the app must not invent a value.
- `ocrRawText` is the canonical reading-order text before visual disturbance.
- `fields` contains the normalized value expected after structured extraction and human verification.
- Disturbances preserve every expected glyph: occluders and cropped edges target non-text regions, so each structured Ground Truth value remains directly recoverable from the image.

Regenerate with:

```bash
python3 Tools/generate_business_card_dataset.py
```
