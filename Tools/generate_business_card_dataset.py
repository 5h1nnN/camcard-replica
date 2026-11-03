#!/usr/bin/env python3
"""Generate a deterministic 30-image synthetic business-card OCR dataset."""

from __future__ import annotations

import csv
import hashlib
import html
import json
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "TestData" / "BusinessCardDataset"
IMAGES = OUT / "images"
SOURCES = OUT / "sources"
CANVAS_SIZE = (1400, 1000)
CARD_SIZE = (1050, 600)


NAMES = [
    "林晓", "陈宇", "周宁", "苏然", "王澈", "李安", "赵晨", "何静", "孙悦", "郑航",
    "Avery Stone", "Jordan Lee", "Morgan Reed", "Taylor Quinn", "Casey Park",
    "Riley Chen", "Jamie Lin", "Cameron Wu", "Robin Hale", "Devon Shaw",
    "顾岚 GU LAN", "韩松 HAN SONG", "沈月 SHEN YUE", "陆川 LU CHUAN", "叶青 YE QING",
    "Mia Zhou 周米娅", "Noah Xu 徐诺", "Iris Fang 方艾", "Leo Tan 谭乐", "Nina Guo 郭宁",
]

COMPANIES = [
    "星河示例科技", "远山创意实验室", "蓝桥产品工作室", "晨光数据中心", "云帆设计事务所",
    "松林移动实验室", "白塔交互工作室", "微光咨询", "方舟示例网络", "新叶创新中心",
    "Northstar Example Labs", "Harborline Studio", "Cedar Test Systems", "Blue Orbit Design",
    "Sample Peak Consulting", "Riverbend Product Lab", "Atlas Example Works", "Paper Kite Mobile",
    "Signal Grove Studio", "Placeholder Ventures", "山海 Example Lab", "青石 Sample Studio",
    "光点 Test Works", "北岸 Example Design", "墨云 Sample Systems", "Mosaic 示例研究所",
    "Nimbus 测试工作室", "Pinecone 示例科技", "Lumen 测试中心", "Orbit 中文实验室",
]

TITLES = [
    "产品经理", "iOS 工程师", "视觉设计师", "数据分析师", "客户顾问", "移动端开发工程师",
    "交互设计师", "研究员", "项目主管", "技术总监", "Product Designer", "Engineering Manager",
    "Research Analyst", "Creative Director", "Solutions Consultant", "Mobile Engineer", "UX Researcher",
    "Product Lead", "Account Director", "Technical Advisor", "产品设计师 Product Designer",
    "软件工程师 Software Engineer", "研究顾问 Research Consultant", "创意总监 Creative Director",
    "项目经理 Project Manager", "UX Designer 体验设计师", "Developer 开发工程师",
    "Analyst 数据分析师", "Consultant 解决方案顾问", "Director 技术总监",
]


SCENARIOS = [
    ("clean_light", "easy", {"type": "none"}),
    ("clean_split", "easy", {"type": "none"}),
    ("clean_center", "easy", {"type": "none"}),
    ("clean_missing_fields", "easy", {"type": "none"}),
    ("clean_dark_card", "easy", {"type": "none"}),
    ("clean_bilingual", "easy", {"type": "none"}),
    ("rotate_minus_3", "medium", {"type": "rotation", "degrees": -3}),
    ("rotate_plus_5", "medium", {"type": "rotation", "degrees": 5}),
    ("rotate_minus_8", "medium", {"type": "rotation", "degrees": -8}),
    ("rotate_plus_10", "medium", {"type": "rotation", "degrees": 10}),
    ("rotate_90", "hard", {"type": "rotation", "degrees": 90}),
    ("rotate_180", "hard", {"type": "rotation", "degrees": 180}),
    ("perspective_left", "medium", {"type": "perspective", "preset": "left"}),
    ("perspective_right", "medium", {"type": "perspective", "preset": "right"}),
    ("perspective_top_narrow", "medium", {"type": "perspective", "preset": "top_narrow"}),
    ("perspective_bottom_narrow", "medium", {"type": "perspective", "preset": "bottom_narrow"}),
    ("perspective_keystone", "hard", {"type": "perspective", "preset": "keystone"}),
    ("perspective_strong", "hard", {"type": "perspective", "preset": "strong"}),
    ("soft_shadow", "medium", {"type": "shadow", "radius": 28, "offset": [28, 30]}),
    ("hard_shadow", "medium", {"type": "shadow", "radius": 8, "offset": [38, 42]}),
    ("low_contrast", "hard", {"type": "low_contrast", "contrast": 0.42}),
    ("dark_scene", "medium", {"type": "dark_background"}),
    ("occluded_corner", "hard", {"type": "occlusion", "coverage": "corner"}),
    ("occluded_center", "hard", {"type": "occlusion", "coverage": "small_center"}),
    ("cropped_edge", "hard", {"type": "crop", "edge": "right", "pixels": 120}),
    ("wood_desk", "medium", {"type": "background", "preset": "wood"}),
    ("patterned_desk", "hard", {"type": "background", "preset": "pattern"}),
    ("desk_clutter", "hard", {"type": "background", "preset": "clutter"}),
    ("blur_noise_rotate", "hard", {"type": "combined", "rotation": -6, "blur": 1.1, "noise": 18}),
    ("perspective_shadow_clutter", "hard", {"type": "combined", "perspective": "strong", "shadow": 20, "background": "clutter"}),
]


def synthetic_fields(index: int) -> dict[str, str]:
    language = "zh" if index <= 10 else "en" if index <= 20 else "bilingual"
    chinese_phone = language != "en"
    mobile = f"+86 138 0000 {index:04d}" if chinese_phone else f"+1 415 555 {1000 + index:04d}"
    office = ""
    if index % 3 != 1 or index in {3, 10, 20, 30}:
        office = f"021-5555-{1000 + index:04d}" if chinese_phone else f"+1 212 555 {2000 + index:04d}"
    fax = ""
    if index in {1, 3, 5, 8, 10, 12, 15, 18, 20, 22, 25, 27, 29, 30}:
        fax = f"021-5556-{1000 + index:04d}" if chinese_phone else f"+1 646 555 {3000 + index:04d}"
    email = "" if index in {9, 24} else f"user{index:02d}@example.com"
    website = "" if index % 4 == 0 or index in {9, 30} else f"www.example.com/card-{index:02d}"
    address = "" if index % 5 == 0 else (
        f"示例市创新路 {10 + index} 号" if chinese_phone else f"{100 + index} Example Avenue, Test City"
    )
    return {
        "name": NAMES[index - 1],
        "company": COMPANIES[index - 1] if index not in {4, 19} else "",
        "jobTitle": TITLES[index - 1] if index not in {4, 14} else "",
        "mobilePhone": mobile,
        "officePhone": office,
        "faxPhone": fax,
        "email": email,
        "website": website,
        "address": address,
        "notes": "",
        "language": language,
    }


def display_lines(fields: dict[str, str]) -> list[str]:
    language = fields["language"]
    zh = language != "en"
    labels = {
        "mobilePhone": "手机" if zh else "Mobile",
        "officePhone": "座机" if zh else "Office",
        "faxPhone": "传真" if zh else "Fax",
        "email": "邮箱" if zh else "Email",
        "website": "网站" if zh else "Website",
        "address": "地址" if zh else "Address",
    }
    lines = [fields["name"]]
    if fields["jobTitle"]:
        lines.append(fields["jobTitle"])
    if fields["company"]:
        lines.append(fields["company"])
    for key in ["mobilePhone", "officePhone", "faxPhone", "email", "website", "address"]:
        if fields[key]:
            lines.append(f"{labels[key]}: {fields[key]}")
    return lines


def estimated_text_width(value: str, size: int) -> float:
    """Conservative width estimate for the SVG's mixed CJK/Latin font stack."""
    width = 0.0
    for character in value:
        if character.isspace():
            width += size * 0.32
        elif ord(character) > 0x2FFF:
            width += size
        elif character.isupper():
            width += size * 0.66
        elif character.islower() or character.isdigit():
            width += size * 0.57
        else:
            width += size * 0.4
    return width


def svg_text(
    x: int,
    y: int,
    value: str,
    size: int,
    color: str,
    weight: int = 400,
    anchor: str = "start",
    max_width: int | None = None,
) -> str:
    safe = html.escape(value)
    fit = ""
    if max_width is not None:
        if anchor == "middle":
            assert x - max_width / 2 >= 0 and x + max_width / 2 <= CARD_SIZE[0]
        else:
            assert x >= 0 and x + max_width <= CARD_SIZE[0]
        if estimated_text_width(value, size) > max_width:
            fit = f' textLength="{max_width}" lengthAdjust="spacingAndGlyphs"'
    return (
        f'<text x="{x}" y="{y}" fill="{color}" font-size="{size}" font-weight="{weight}" '
        f'text-anchor="{anchor}" font-family="PingFang SC, Helvetica Neue, Arial, sans-serif"{fit}>{safe}</text>'
    )


def make_svg(fields: dict[str, str], style: int) -> str:
    dark = style == 4
    background = "#10243e" if dark else ["#ffffff", "#f7fbff", "#fffdf8", "#f4f7f8", "#10243e", "#ffffff"][style]
    primary = "#f5f8ff" if dark else "#10243e"
    secondary = "#c8d7ea" if dark else "#526170"
    accent = ["#1877d2", "#e06a43", "#1f9d79", "#7b61b3", "#5bc0eb", "#d39a22"][style]
    parts = [
        # Quick Look rasterizes non-square SVG thumbnails by filling a square and
        # clipping the long edge. A square wrapper preserves the complete card;
        # render_svg crops the 1050x600 artwork back out after rasterization.
        f'<svg xmlns="http://www.w3.org/2000/svg" width="1050" height="1050" viewBox="0 0 1050 1050">',
        '<g transform="translate(0 225)">',
        f'<rect width="1050" height="600" rx="26" fill="{background}"/>',
    ]

    if style == 0:
        parts += [f'<rect width="24" height="600" fill="{accent}"/>', f'<circle cx="920" cy="96" r="54" fill="{accent}" opacity="0.16"/>']
    elif style == 1:
        parts += [f'<rect x="0" y="0" width="390" height="600" fill="{accent}"/>', '<path d="M390 0 L470 0 L390 600 Z" fill="#ffffff" opacity="0.2"/>']
    elif style == 2:
        parts += [f'<circle cx="525" cy="98" r="38" fill="{accent}"/>', f'<rect x="365" y="184" width="320" height="4" fill="{accent}"/>']
    elif style == 3:
        parts += [f'<path d="M0 440 L300 600 L0 600 Z" fill="{accent}" opacity="0.2"/>', f'<path d="M1050 0 L760 0 L1050 180 Z" fill="{accent}" opacity="0.22"/>']
    elif style == 4:
        parts += [f'<rect x="62" y="64" width="10" height="472" fill="{accent}"/>', f'<circle cx="930" cy="490" r="120" fill="{accent}" opacity="0.12"/>']
    else:
        parts += [f'<rect x="0" y="0" width="1050" height="18" fill="{accent}"/>', f'<rect x="505" y="82" width="2" height="430" fill="{accent}" opacity="0.35"/>']

    name = fields["name"]
    job = fields["jobTitle"]
    company = fields["company"]
    contact = []
    labels = {
        "mobilePhone": "手机 / Mobile" if fields["language"] == "bilingual" else ("手机" if fields["language"] == "zh" else "Mobile"),
        "officePhone": "座机 / Office" if fields["language"] == "bilingual" else ("座机" if fields["language"] == "zh" else "Office"),
        "faxPhone": "传真 / Fax" if fields["language"] == "bilingual" else ("传真" if fields["language"] == "zh" else "Fax"),
        "email": "邮箱 / Email" if fields["language"] == "bilingual" else ("邮箱" if fields["language"] == "zh" else "Email"),
        "website": "网站 / Web" if fields["language"] == "bilingual" else ("网站" if fields["language"] == "zh" else "Website"),
        "address": "地址 / Address" if fields["language"] == "bilingual" else ("地址" if fields["language"] == "zh" else "Address"),
    }
    for key in ["mobilePhone", "officePhone", "faxPhone", "email", "website", "address"]:
        if fields[key]:
            contact.append(f'{labels[key]}: {fields[key]}')

    if style == 1:
        parts.append(svg_text(58, 138, name, 48, "#ffffff", 700, max_width=305))
        if job:
            parts.append(svg_text(58, 194, job, 24, "#ffffff", 500, max_width=305))
        if company:
            parts.append(svg_text(58, 242, company, 25, "#ffffff", 600, max_width=305))
        for n, line in enumerate(contact):
            parts.append(svg_text(455, 132 + n * 68, line, 22 if len(line) < 44 else 19, primary, 400, max_width=535))
    elif style == 2:
        parts.append(svg_text(525, 152, name, 48, primary, 700, "middle", max_width=900))
        if job:
            parts.append(svg_text(525, 228, job, 25, secondary, 500, "middle", max_width=900))
        if company:
            parts.append(svg_text(525, 270, company, 26, accent, 600, "middle", max_width=900))
        for n, line in enumerate(contact):
            parts.append(svg_text(525, 342 + n * 38, line, 20 if len(line) < 46 else 17, secondary, 400, "middle", max_width=900))
    elif style == 5:
        parts.append(svg_text(64, 120, name, 46, primary, 700, max_width=400))
        if job:
            parts.append(svg_text(64, 174, job, 24, secondary, 500, max_width=400))
        if company:
            parts.append(svg_text(64, 222, company, 27, accent, 650, max_width=400))
        for n, line in enumerate(contact):
            parts.append(svg_text(550, 112 + n * 70, line, 21 if len(line) < 45 else 18, secondary, 400, max_width=440))
    else:
        text_x = 78 if style != 4 else 110
        text_width = 890 if style != 4 else 850
        parts.append(svg_text(text_x, 112, name, 50, primary, 700, max_width=text_width))
        if job:
            parts.append(svg_text(text_x, 166, job, 25, secondary, 500, max_width=text_width))
        if company:
            parts.append(svg_text(text_x, 218, company, 28, accent, 650, max_width=text_width))
        for n, line in enumerate(contact):
            parts.append(svg_text(text_x, 316 + n * 42, line, 22 if len(line) < 45 else 18, secondary, 400, max_width=text_width))

    parts.extend(['</g>', '</svg>'])
    return "\n".join(parts)


def render_svg(svg_path: Path, png_path: Path) -> None:
    subprocess.run(
        ["/usr/bin/qlmanage", "-t", "-s", str(CARD_SIZE[0]), "-o", str(png_path.parent), str(svg_path)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )
    thumbnail_path = png_path.parent / f"{svg_path.name}.png"
    with Image.open(thumbnail_path) as thumbnail:
        # make_svg places the card inside a square wrapper so Quick Look cannot
        # crop its right edge while producing a square thumbnail.
        thumbnail.crop((0, 225, CARD_SIZE[0], 825)).save(png_path)
    thumbnail_path.unlink()


def background_for(name: str) -> Image.Image:
    w, h = CANVAS_SIZE
    if name == "dark_scene":
        image = Image.new("RGB", CANVAS_SIZE, "#1b2028")
        draw = ImageDraw.Draw(image)
        for y in range(0, h, 28):
            draw.line((0, y, w, y), fill="#202731", width=2)
        return image
    if name in {"wood_desk", "perspective_shadow_clutter"}:
        image = Image.new("RGB", CANVAS_SIZE, "#b88758")
        draw = ImageDraw.Draw(image)
        for y in range(0, h, 45):
            color = "#a9794e" if (y // 45) % 2 else "#c09263"
            draw.rectangle((0, y, w, y + 45), fill=color)
            draw.line((0, y, w, y), fill="#8e6745", width=3)
        return image.filter(ImageFilter.GaussianBlur(0.6))
    if name == "patterned_desk":
        image = Image.new("RGB", CANVAS_SIZE, "#e9e1d2")
        draw = ImageDraw.Draw(image)
        for x in range(-h, w, 70):
            draw.line((x, 0, x + h, h), fill="#c9bda9", width=8)
        for x in range(-h, w, 140):
            draw.line((x, 0, x + h, h), fill="#8db4ba", width=3)
        return image
    if name == "desk_clutter":
        image = Image.new("RGB", CANVAS_SIZE, "#d8d2c6")
        draw = ImageDraw.Draw(image)
        draw.ellipse((70, 90, 410, 430), fill="#97a7b6")
        draw.rectangle((1080, 90, 1320, 530), fill="#556270")
        draw.rounded_rectangle((75, 700, 390, 930), 24, fill="#f2d16b")
        draw.line((1120, 700, 1310, 910), fill="#bd5548", width=34)
        return image.filter(ImageFilter.GaussianBlur(1.2))
    image = Image.new("RGB", CANVAS_SIZE, "#e9edf1")
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, w, 210), fill="#f4f6f8")
    draw.rectangle((0, 780, w, h), fill="#dfe5ea")
    return image


def perspective_coefficients(destination: list[tuple[float, float]], source_size: tuple[int, int]) -> list[float]:
    sw, sh = source_size
    source = [(0, 0), (sw, 0), (sw, sh), (0, sh)]
    matrix = []
    vector = []
    for (x, y), (u, v) in zip(destination, source):
        matrix.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        vector.append(u)
        matrix.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        vector.append(v)
    augmented = [list(map(float, row)) + [float(value)] for row, value in zip(matrix, vector)]
    size = len(vector)
    for column in range(size):
        pivot = max(range(column, size), key=lambda row: abs(augmented[row][column]))
        if abs(augmented[pivot][column]) < 1e-12:
            raise ValueError("Perspective quadrilateral is singular")
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        divisor = augmented[column][column]
        augmented[column] = [value / divisor for value in augmented[column]]
        for row in range(size):
            if row == column:
                continue
            factor = augmented[row][column]
            augmented[row] = [
                current - factor * pivot_value
                for current, pivot_value in zip(augmented[row], augmented[column])
            ]
    return [augmented[row][-1] for row in range(size)]


def shadow_from(layer: Image.Image, radius: int, offset: tuple[int, int]) -> Image.Image:
    alpha = layer.getchannel("A")
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(radius))
    shadow = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    colored = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 145))
    shifted = Image.new("L", CANVAS_SIZE, 0)
    shifted.paste(shadow_alpha, offset)
    colored.putalpha(shifted)
    shadow.alpha_composite(colored)
    return shadow


def centered_layer(card: Image.Image, rotation: float = 0, offset: tuple[int, int] = (0, 0)) -> Image.Image:
    resized = card.resize((980, 560), Image.Resampling.LANCZOS)
    rotated = resized.rotate(rotation, expand=True, resample=Image.Resampling.BICUBIC, fillcolor=(0, 0, 0, 0))
    layer = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - rotated.width) // 2 + offset[0]
    y = (CANVAS_SIZE[1] - rotated.height) // 2 + offset[1]
    layer.alpha_composite(rotated, (x, y))
    return layer


def perspective_layer(card: Image.Image, preset: str) -> Image.Image:
    quads = {
        "left": [(205, 230), (1200, 135), (1160, 790), (250, 740)],
        "right": [(215, 140), (1185, 235), (1140, 745), (250, 825)],
        "top_narrow": [(330, 180), (1080, 180), (1220, 800), (185, 800)],
        "bottom_narrow": [(180, 180), (1220, 180), (1080, 800), (330, 800)],
        "keystone": [(260, 95), (1160, 235), (1080, 850), (170, 720)],
        "strong": [(350, 90), (1220, 270), (1030, 900), (130, 690)],
    }
    resized = card.resize((980, 560), Image.Resampling.LANCZOS)
    coeffs = perspective_coefficients(quads[preset], resized.size)
    return resized.transform(
        CANVAS_SIZE,
        Image.Transform.PERSPECTIVE,
        coeffs,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )


def add_clutter(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((36, 70, 300, 220), 22, fill="#f5d86f", outline="#caaa3f", width=4)
    draw.ellipse((1160, 690, 1360, 890), fill="#60798c")
    draw.line((90, 850, 360, 690), fill="#bd5548", width=30)


def compose(card: Image.Image, scenario_name: str, params: dict) -> Image.Image:
    background_name = params.get("background", scenario_name)
    scene = background_for(background_name).convert("RGBA")
    disturbance = params["type"]

    if disturbance == "rotation":
        layer = centered_layer(card, params["degrees"])
    elif disturbance == "perspective":
        layer = perspective_layer(card, params["preset"])
    elif disturbance == "crop":
        layer = centered_layer(card, 0, (params["pixels"], 0))
    elif disturbance == "combined" and "perspective" in params:
        layer = perspective_layer(card, params["perspective"])
    else:
        rotation = params.get("rotation", 0)
        layer = centered_layer(card, rotation)

    if disturbance == "shadow":
        scene.alpha_composite(shadow_from(layer, params["radius"], tuple(params["offset"])))
    elif disturbance == "combined" and params.get("shadow"):
        scene.alpha_composite(shadow_from(layer, params["shadow"], (30, 34)))
    else:
        scene.alpha_composite(shadow_from(layer, 12, (14, 18)))
    scene.alpha_composite(layer)

    draw = ImageDraw.Draw(scene, "RGBA")
    if scenario_name == "occluded_corner":
        draw.polygon([(965, 650), (1240, 610), (1260, 865), (930, 880)], fill=(244, 207, 92, 255))
        draw.line((965, 650, 1240, 610), fill=(190, 154, 54, 255), width=5)
    elif scenario_name == "occluded_center":
        # Keep the occluder on the card for edge/segmentation testing without
        # hiding any contact field that is part of the expected OCR truth.
        draw.rounded_rectangle((600, 590, 805, 730), 18, fill=(214, 226, 235, 255), outline=(120, 139, 151, 255), width=4)
    elif scenario_name in {"desk_clutter", "perspective_shadow_clutter"}:
        add_clutter(draw)

    result = scene.convert("RGB")
    if disturbance == "low_contrast":
        result = ImageEnhance.Contrast(result).enhance(params["contrast"])
        haze = Image.new("RGB", CANVAS_SIZE, "#e5e9e8")
        result = Image.blend(result, haze, 0.25)
    if scenario_name == "blur_noise_rotate":
        result = result.filter(ImageFilter.GaussianBlur(params["blur"]))
        noise = Image.effect_noise(CANVAS_SIZE, params["noise"]).convert("L")
        noise_rgb = Image.merge("RGB", (noise, noise, noise))
        result = Image.blend(result, noise_rgb, 0.06)
    return result


def write_readme() -> None:
    readme = """# Synthetic Business Card Test Dataset

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
"""
    (OUT / "README.md").write_text(readme, encoding="utf-8")


def write_gallery(records: list[dict]) -> None:
    cards = []
    for record in records:
        field_rows = "".join(
            f"<li><b>{html.escape(key)}</b>: {html.escape(value or '∅')}</li>"
            for key, value in record["fields"].items()
            if key != "notes"
        )
        cards.append(
            f'''<article><img src="{record['image']}" alt="{record['id']}"><h2>{record['id']} · {html.escape(record['scenario'])}</h2>
            <p>{record['language']} · {record['difficulty']} · layout {record['layout']}</p><ul>{field_rows}</ul></article>'''
        )
    document = f"""<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
    <title>Business Card Ground Truth Dataset</title><style>
    body{{margin:0;background:#eef1f4;color:#172433;font-family:-apple-system,BlinkMacSystemFont,'PingFang SC',sans-serif}}
    header{{padding:32px 4vw;background:#10243e;color:white}} main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:24px;padding:28px}}
    article{{background:white;border-radius:16px;padding:16px;box-shadow:0 8px 24px #17243318}} img{{width:100%;border-radius:10px;display:block}}
    h2{{font-size:18px;margin:14px 0 6px}} p{{color:#607080;margin:0 0 10px}} ul{{padding-left:20px;font-size:13px;line-height:1.6;word-break:break-all}}
    </style></head><body><header><h1>30 张合成名片测试集</h1><p>PNG + SVG source + JSON/CSV Ground Truth</p></header><main>{''.join(cards)}</main></body></html>"""
    (OUT / "gallery.html").write_text(document, encoding="utf-8")


def write_contact_sheet(records: list[dict]) -> None:
    thumb_size = (280, 200)
    sheet = Image.new("RGB", (thumb_size[0] * 5, thumb_size[1] * 6), "white")
    draw = ImageDraw.Draw(sheet)
    for index, record in enumerate(records):
        image = Image.open(OUT / record["image"]).convert("RGB")
        image.thumbnail((thumb_size[0], thumb_size[1] - 28), Image.Resampling.LANCZOS)
        x = (index % 5) * thumb_size[0]
        y = (index // 5) * thumb_size[1]
        sheet.paste(image, (x + (thumb_size[0] - image.width) // 2, y + 26))
        draw.rectangle((x, y, x + thumb_size[0], y + 26), fill="#10243e")
        draw.text((x + 8, y + 6), f"{record['id']}  {record['scenario']}", fill="white")
    sheet.save(OUT / "contact_sheet.png", optimize=True)


def main() -> None:
    IMAGES.mkdir(parents=True, exist_ok=True)
    SOURCES.mkdir(parents=True, exist_ok=True)
    records = []

    with tempfile.TemporaryDirectory(prefix="camcard-dataset-") as temp_dir:
        temp = Path(temp_dir)
        for index, (scenario_name, difficulty, params) in enumerate(SCENARIOS, start=1):
            card_id = f"card_{index:03d}"
            fields = synthetic_fields(index)
            style = (index - 1) % 6
            svg = make_svg(fields, style)
            svg_path = SOURCES / f"{card_id}.svg"
            svg_path.write_text(svg, encoding="utf-8")
            canonical_path = temp / f"{card_id}.png"
            render_svg(svg_path, canonical_path)
            canonical = Image.open(canonical_path).convert("RGBA")
            final = compose(canonical, scenario_name, params)
            output_path = IMAGES / f"{card_id}.png"
            final.save(output_path, optimize=True)

            public_fields = {key: value for key, value in fields.items() if key != "language"}
            missing = [key for key, value in public_fields.items() if value == "" and key != "notes"]
            records.append({
                "id": card_id,
                "image": f"images/{card_id}.png",
                "sourceSvg": f"sources/{card_id}.svg",
                "language": fields["language"],
                "layout": f"layout_{style + 1}",
                "difficulty": difficulty,
                "scenario": scenario_name,
                "disturbance": params,
                "fields": public_fields,
                "missingFields": missing,
                "ocrRawText": "\n".join(display_lines(fields)),
            })

    manifest = {
        "dataset": {
            "name": "CamCardReplica Synthetic Business Card Dataset",
            "version": "1.0.0",
            "count": len(records),
            "imageSize": {"width": CANVAS_SIZE[0], "height": CANVAS_SIZE[1]},
            "syntheticOnly": True,
            "reservedEmailDomain": "example.com",
        },
        "records": records,
    }
    (OUT / "ground_truth.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    csv_fields = [
        "id", "image", "sourceSvg", "language", "layout", "difficulty", "scenario", "disturbance",
        "name", "company", "jobTitle", "mobilePhone", "officePhone", "faxPhone", "email", "website", "address", "notes",
        "missingFields", "ocrRawText",
    ]
    with (OUT / "ground_truth.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=csv_fields)
        writer.writeheader()
        for record in records:
            row = {key: record.get(key, "") for key in csv_fields}
            row.update(record["fields"])
            row["disturbance"] = json.dumps(record["disturbance"], ensure_ascii=False, separators=(",", ":"))
            row["missingFields"] = ";".join(record["missingFields"])
            writer.writerow(row)

    write_readme()
    write_gallery(records)
    write_contact_sheet(records)

    checksum_files = sorted(IMAGES.glob("*.png")) + [OUT / "ground_truth.json", OUT / "ground_truth.csv"]
    checksum_lines = []
    for path in checksum_files:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        checksum_lines.append(f"{digest}  {path.relative_to(OUT)}")
    (OUT / "checksums.sha256").write_text("\n".join(checksum_lines) + "\n", encoding="utf-8")

    assert len(list(IMAGES.glob("card_*.png"))) == 30
    assert len(list(SOURCES.glob("card_*.svg"))) == 30
    assert all(Image.open(path).size == CANVAS_SIZE for path in IMAGES.glob("card_*.png"))
    print(f"Generated {len(records)} cards in {OUT}")


if __name__ == "__main__":
    main()
