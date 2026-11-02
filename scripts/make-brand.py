"""Generates the Varnixo logo, app icon and favicon (web/public) plus the
Flutter launcher source (assets/brand). Run: python scripts/make-brand.py
Placeholder brand mark until the client supplies final artwork."""
import math
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GREEN, LEAF, MANGO, INK = (25, 98, 52), (58, 150, 72), (242, 122, 26), (10, 32, 18)
FONTS = 'C:/Windows/Fonts'
SS = 4  # supersampling factor for smooth edges


def leaf(draw, cx, cy, length, width, angle, fill, rib):
    """A pointed leaf (two arcs) centred on cx, cy, rotated by angle degrees."""
    pts = []
    for i in range(61):
        t = i / 60
        x = (t - 0.5) * length
        y = math.sin(math.pi * t) ** 0.85 * width / 2
        pts.append((x, y))
    outline = pts + [(x, -y) for x, y in reversed(pts)]
    a = math.radians(angle)
    rot = lambda x, y: (cx + x * math.cos(a) - y * math.sin(a), cy + x * math.sin(a) + y * math.cos(a))
    draw.polygon([rot(x, y) for x, y in outline], fill=fill)
    draw.line([rot(-length * 0.42, 0), rot(length * 0.45, 0)], fill=rib, width=max(2, int(length * 0.035)))


def mark(size, square=False):
    """Green disc (or full-bleed square for iOS/maskable icons), mango 'sun', two leaves."""
    s = size * SS
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if square:
        d.rectangle([0, 0, s, s], fill=GREEN)
    else:
        d.ellipse([0, 0, s - 1, s - 1], fill=GREEN)
    r = s * 0.17
    d.ellipse([s * 0.60 - r, s * 0.30 - r, s * 0.60 + r, s * 0.30 + r], fill=MANGO)
    leaf(d, s * 0.43, s * 0.58, s * 0.62, s * 0.30, -50, LEAF, GREEN)
    leaf(d, s * 0.62, s * 0.66, s * 0.40, s * 0.20, -15, (120, 190, 110), GREEN)
    return im.resize((size, size), Image.LANCZOS)


def foreground(size):
    """Adaptive-icon foreground: the mark on transparent, inside Android's 66% safe zone."""
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = round(size * 0.62)
    im.alpha_composite(mark(inner), ((size - inner) // 2, (size - inner) // 2))
    return im


def splash(w, h):
    """Dark green launch screen with the badge and wordmark centred."""
    im = Image.new('RGB', (w, h), (10, 32, 18))
    side = min(w, h)
    badge = round(side * 0.28)
    word = ImageFont.truetype(f'{FONTS}/seguibl.ttf', max(12, round(side * 0.085)))
    d = ImageDraw.Draw(im)
    tw = d.textlength('Varnixo', font=word)
    gap = round(side * 0.04)
    total = badge + gap + word.size
    top = (h - total) // 2
    im.paste(mark(badge), ((w - badge) // 2, top), mark(badge))
    d.text(((w - tw) / 2, top + badge + gap - word.size * 0.18), 'Varnixo', font=word, fill=(255, 255, 255))
    return im


def logo():
    w, h = 900, 337
    im = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0))
    im.alpha_composite(mark(250 * SS), (20 * SS, 44 * SS))
    d = ImageDraw.Draw(im)
    word = ImageFont.truetype(f'{FONTS}/seguibl.ttf', 150 * SS)
    tag = ImageFont.truetype(f'{FONTS}/seguisb.ttf', 31 * SS)
    d.text((300 * SS, 60 * SS), 'Varnixo', font=word, fill=INK)
    d.text((306 * SS, 248 * SS), 'VEGETABLES · FRUITS · DRY FRUITS', font=tag, fill=MANGO)
    return im.resize((w, h), Image.LANCZOS)


def main():
    pub = os.path.join(ROOT, 'web', 'public')
    logo().save(os.path.join(pub, 'brand', 'logo.png'))
    mark(256).save(os.path.join(pub, 'brand', 'icon.png'))
    mark(64).save(os.path.join(pub, 'favicon.png'))
    # Installable-app (PWA) icons referenced by web/public/manifest.webmanifest.
    os.makedirs(os.path.join(pub, 'icons'), exist_ok=True)
    mark(192).save(os.path.join(pub, 'icons', 'icon-192.png'))
    mark(512).save(os.path.join(pub, 'icons', 'icon-512.png'))
    mark(512, square=True).save(os.path.join(pub, 'icons', 'maskable-512.png'))
    os.makedirs(os.path.join(ROOT, 'assets', 'brand'), exist_ok=True)
    mark(1024).save(os.path.join(ROOT, 'assets', 'brand', 'varnixo-icon-1024.png'))

    # Flutter launcher icons: overwrite each existing file at its own size.
    app = os.path.join(ROOT, 'apps', 'customer_app')
    targets = [(os.path.join(app, 'android', 'app', 'src', 'main', 'res', d, 'ic_launcher.png'), False)
               for d in ('mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi')]
    ios = os.path.join(app, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    targets += [(os.path.join(ios, f), True) for f in os.listdir(ios) if f.endswith('.png')]
    web = os.path.join(app, 'web')
    targets += [(os.path.join(web, 'favicon.png'), False)]
    targets += [(os.path.join(web, 'icons', f), 'maskable' in f) for f in os.listdir(os.path.join(web, 'icons'))]
    for path, square in targets:
        size = Image.open(path).size[0]
        icon = mark(size, square)
        if path.startswith(ios):
            icon = icon.convert('RGB')  # App Store rejects icons with alpha
        icon.save(path)

    # Capacitor Android shell (web/android): launcher icons + splash, if generated.
    res = os.path.join(ROOT, 'web', 'android', 'app', 'src', 'main', 'res')
    if os.path.isdir(res):
        for d in os.listdir(res):
            folder = os.path.join(res, d)
            for f in os.listdir(folder):
                path = os.path.join(folder, f)
                if f in ('ic_launcher.png', 'ic_launcher_round.png'):
                    mark(Image.open(path).size[0]).save(path); targets.append((path, False))
                elif f == 'ic_launcher_foreground.png':
                    foreground(Image.open(path).size[0]).save(path); targets.append((path, False))
                elif f == 'splash.png':
                    splash(*Image.open(path).size).save(path); targets.append((path, False))
        bg = os.path.join(res, 'values', 'ic_launcher_background.xml')
        if os.path.exists(bg):
            with open(bg, 'w', encoding='utf-8') as fh:
                fh.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                         '    <color name="ic_launcher_background">#196234</color>\n</resources>\n')
    print(f'brand assets written ({len(targets)} app icons)')


if __name__ == '__main__':
    main()
