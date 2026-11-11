"""Render the native splash assets from the vector masters.

Two images per density, and nothing between them and the SVG:

  launch_logo   frame ① of Launch Concept 3A — the butterfly at 118dp and 0.92
                opacity with the wordmark 16dp beneath it, centred by the
                platform over the flat brand colour.
  launch_icon   the same butterfly alone on a 240dp canvas, for the splash
                Android 12 draws before the window theme applies and masks to a
                circle. A wordmark set beside it there would be cut.

Every size is rasterised from the vector at that size. No PNG is ever scaled up
from another, which is the whole reason the masters were asked for.
"""

import os
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUTTERFLY_SVG = os.path.join(ROOT, 'assets/launch/butterfly_mono_white.svg')
FONT = os.path.join(ROOT, 'assets/fonts/Tajawal/Tajawal-ExtraBold.ttf')
WORDMARK = 'السعودية كوزمتكس'

# Frame ①, in the design's reference viewport of 390 wide.
BUTTERFLY_DP = 118
GAP_DP = 16
WORDMARK_DP = 24
BUTTERFLY_OPACITY = 0.92

# Android 12 draws its icon in a 240dp circle and keeps the inner ~160dp.
ICON_CANVAS_DP = 240
ICON_BUTTERFLY_DP = 150

ANDROID = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0}
IOS = {'LaunchImage.png': 1.0, 'LaunchImage@2x.png': 2.0, 'LaunchImage@3x.png': 3.0}


def butterfly(width_px: int) -> Image.Image:
    """The mark, rasterised from the vector at exactly this width."""
    with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as handle:
        path = handle.name
    subprocess.run(
        ['rsvg-convert', '-w', str(width_px), '-b', 'none', BUTTERFLY_SVG, '-o', path],
        check=True)
    mark = Image.open(path).convert('RGBA')
    os.unlink(path)
    alpha = mark.getchannel('A').point(lambda v: round(v * BUTTERFLY_OPACITY))
    mark.putalpha(alpha)
    return mark


def frame_one(scale: float) -> Image.Image:
    mark = butterfly(round(BUTTERFLY_DP * scale))
    font = ImageFont.truetype(FONT, round(WORDMARK_DP * scale))
    box = ImageDraw.Draw(Image.new('RGBA', (1, 1))).textbbox(
        (0, 0), WORDMARK, font=font, direction='rtl', language='ar', anchor='lt')
    text_w, text_h = box[2] - box[0], box[3] - box[1]

    gap = round(GAP_DP * scale)
    width = max(mark.width, text_w)
    canvas = Image.new('RGBA', (width, mark.height + gap + text_h), (0, 0, 0, 0))
    canvas.alpha_composite(mark, ((width - mark.width) // 2, 0))
    ImageDraw.Draw(canvas).text(
        (width // 2, mark.height + gap - box[1]), WORDMARK, font=font,
        fill=(255, 255, 255, 255), direction='rtl', language='ar', anchor='ma')
    return canvas


def android_icon(scale: float) -> Image.Image:
    side = round(ICON_CANVAS_DP * scale)
    mark = butterfly(round(ICON_BUTTERFLY_DP * scale))
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(mark, ((side - mark.width) // 2, (side - mark.height) // 2))
    return canvas


def write(image: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, optimize=True)
    print(f'{os.path.relpath(path, ROOT)}  {image.width}x{image.height}')


def main() -> None:
    for bucket, scale in ANDROID.items():
        base = os.path.join(ROOT, 'android/app/src/main/res', f'drawable-{bucket}')
        write(frame_one(scale), os.path.join(base, 'launch_logo.png'))
        write(android_icon(scale), os.path.join(base, 'launch_icon.png'))

    ios = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    for name, scale in IOS.items():
        write(frame_one(scale), os.path.join(ios, name))


if __name__ == '__main__':
    main()
