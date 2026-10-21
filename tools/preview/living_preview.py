"""Renders the bring-to-life animation exactly like lib/engine/living.dart,
so motion quality can be reviewed as a video without building the app.

python3 tools/preview/living_preview.py lion_01 out.mp4 [--seconds 4] [--shade]
"""
import json, math, os, re, sys, subprocess, tempfile
import cairosvg

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AMBIENT = {'scene', 'sun', 'cloud', 'stars', 'moon', 'smoke', 'bubbles', 'notes', 'puff', 'weed', 'speed'}
INK = "#2B1B12"

def mat_mul(a, b):
    # 2D affine as (a,b,c,d,e,f) meaning x' = a*x + c*y + e ; y' = b*x + d*y + f
    a1, b1, c1, d1, e1, f1 = a; a2, b2, c2, d2, e2, f2 = b
    return (a1*a2 + c1*b2, b1*a2 + d1*b2, a1*c2 + c1*d2, b1*c2 + d1*d2, a1*e2 + c1*f2 + e1, b1*e2 + d1*f2 + f1)
I = (1, 0, 0, 1, 0, 0)
def T(x, y): return (1, 0, 0, 1, x, y)
def S(x, y): return (x, 0, 0, y, 0, 0)
def R(rad): c, s = math.cos(rad), math.sin(rad); return (c, s, -s, c, 0, 0)
def around(p, m): return mat_mul(mat_mul(T(*p), m), T(-p[0], -p[1]))

class Living:
    def __init__(self, meta, svg):
        self.meta, self.svg = meta, svg
        reg = svg.split('<g id="outline"')[0]
        self.regions = re.findall(r'<path id="([\w-]+)" data-part="(\w+)" data-stroke="(\d)" d="([^"]+)"', reg)
        outl = svg.split('<g id="outline"')[1]
        self.details = re.findall(r'<path data-kind="(?:detail|alive)" data-part="(\w+)" d="([^"]+)"( stroke="[^"]+" stroke-width="[\d.]+"| fill="[^"]+")', outl)
        self.bounds = {}
        for rid, part, st, d in self.regions:
            nums = list(map(float, re.findall(r'-?\d+\.?\d*', d)))
            xs, ys = nums[0::2], nums[1::2]
            b = self.bounds.get(part)
            nb = (min(xs), min(ys), max(xs), max(ys))
            self.bounds[part] = nb if b is None else (min(b[0], nb[0]), min(b[1], nb[1]), max(b[2], nb[2]), max(b[3], nb[3]))

        cb = None
        for rid, part, st, d in self.regions:
            if part in AMBIENT: continue
            b = self.bounds_of(d)
            cb = b if cb is None else (min(cb[0], b[0]), min(cb[1], b[1]), max(cb[2], b[2]), max(cb[3], b[3]))
        self.char = cb or (300, 300, 700, 900)
        # Contact shadow only for characters standing on the ground.
        self.grounded = self.char[3] > 820 and meta["world"] != "space"

    @staticmethod
    def bounds_of(d):
        nums = list(map(float, re.findall(r'-?\d+\.?\d*', d)))
        xs, ys = nums[0::2], nums[1::2]
        return (min(xs), min(ys), max(xs), max(ys))

    def entrance(self, t):
        """Anticipation -> jump with stretch -> landing squash -> settle, then breathing.
        Returns (sx, sy, dy, lift) where lift 0..1 is the jump height."""
        if t < 0.16:
            k = math.sin(math.pi / 2 * t / 0.16)
            return (1 + 0.08 * k, 1 - 0.12 * k, 0, 0)
        if t < 0.56:
            u = (t - 0.16) / 0.40; j = math.sin(math.pi * u)
            return (1 - 0.05 * j, 1 + 0.09 * j, -95 * j, j)
        v = t - 0.56
        wob = math.sin(math.pi * 3 * v / 0.84) * math.exp(-4 * v) if v < 1.6 else 0
        br = math.sin(2 * math.pi * 0.45 * t)
        return (1 + 0.10 * wob - 0.008 * br, 1 - 0.10 * wob + 0.012 * br, 0, 0)

    def part_matrix(self, part, t, depth=0):
        spec = self.meta["anim"].get(part)
        if not spec or depth > 3: return I
        m = I
        f = spec.get("follow")
        if f and f != part: m = self.part_matrix(f, t, depth + 1)
        b = self.bounds.get(part, (0, 0, 1000, 1000))
        pv = tuple(spec["pivot"]) if spec.get("pivot") else ((b[0] + b[2]) / 2, (b[1] + b[3]) / 2)
        phase = spec.get("phase", 0)
        if phase == 0 and part.startswith("tail"): phase = -0.9   # follow-through lag
        w = 2 * math.pi * spec["speed"] * t + phase; a = spec["amp"]; ty = spec["type"]
        org = (math.sin(w) + 0.22 * math.sin(2 * w + 0.8)) / 1.1   # organic, less robotic
        rot = lambda deg: around(pv, R(math.radians(deg)))
        sc = lambda sx, sy: around(pv, S(sx, sy))
        if ty in ('tilt', 'swing', 'wave', 'nod', 'sway_top', 'orbit', 'roll'): x = rot(a * org)
        elif ty == 'flap': x = rot(a * math.sin(w) * (0.75 + 0.25 * math.sin(w)))
        elif ty == 'spin': x = rot(360 * spec["speed"] * t * (1 if a >= 0 else -1))
        elif ty == 'blink':
            cyc = (t + spec.get("phase", 0)) % 3.4
            bb = math.sin(math.pi * (cyc - 3.24) / 0.16) if cyc > 3.24 else 0
            x = sc(1, 1 - 0.9 * bb)
        elif ty in ('bounce', 'bounce_big'): x = T(0, -a * abs(math.sin(w)))
        elif ty in ('fly', 'float'): x = T(0, a * math.sin(w))
        elif ty == 'swim': x = T(a * 0.7 * math.cos(w * 0.5), a * math.sin(w))
        elif ty in ('drift', 'sway'): x = T(a * math.sin(w), 0)
        elif ty == 'shake': x = T(a * math.sin(w * 1.7), a * 0.5 * math.cos(w * 2.3))
        elif ty == 'buzz': x = T(a * math.sin(w), a * 0.5 * math.sin(2 * w))
        elif ty == 'rise': x = T(math.sin(w * 2) * 6, -((t * spec["speed"]) % 1) * a * 2)
        elif ty in ('pulse', 'flicker', 'twinkle', 'breathe'):
            s = 1 + a * math.sin(w * 1.7 if ty == 'flicker' else w); x = sc(s, s)
        elif ty == 'flutter': x = sc(1, max(0.15, abs(math.cos(w))))
        elif ty == 'flap_x': x = sc(1 - a * (0.5 + 0.5 * math.sin(w)), 1)
        else: x = I
        return mat_mul(m, x)

    def frame_svg(self, t, shade=False):
        hop = self.entrance(t)
        cx = (self.char[0] + self.char[2]) / 2; base = (cx, self.char[3])
        hopm = around(base, S(hop[0], hop[1])); hopm = mat_mul(T(0, hop[2]), hopm)
        colors = {r["id"]: r["target"] for r in self.meta["regions"]}
        out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"><defs>'
               '<radialGradient id="hl" cx="0.3" cy="0.25" r="0.85"><stop offset="0" stop-color="#fff" stop-opacity=".38"/>'
               '<stop offset=".55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".16"/></radialGradient>'
               f'</defs><rect width="1000" height="1000" fill="{self.meta["bg"]}"/>']
        def tr_for(part, ambient):
            m = I if ambient else hopm
            return 'matrix(%.4f %.4f %.4f %.4f %.2f %.2f)' % mat_mul(m, self.part_matrix(part, t))
        for amb in (True, False):
            for rid, part, st, d in self.regions:
                if (part in AMBIENT) != amb: continue
                tr = tr_for(part, amb)
                stroke = f' stroke="{INK}" stroke-width="9" stroke-linejoin="round"' if st == '1' else ''
                out.append(f'<path transform="{tr}" fill-rule="evenodd" d="{d}" fill="{colors[rid]}"{stroke}/>')
                if shade and st == '1':
                    out.append(f'<path transform="{tr}" fill-rule="evenodd" d="{d}" fill="url(#hl)"/>')
            for part, d, style in self.details:
                if (part in AMBIENT) != amb: continue
                st = style.strip()
                extra = ' fill="none" stroke-linecap="round" stroke-linejoin="round"' if st.startswith('stroke') else ''
                out.append(f'<path transform="{tr_for(part, amb)}" d="{d}" {st}{extra}/>')
            if amb and self.grounded:
                wdt = (self.char[2] - self.char[0]) * 0.42 * (1 - 0.45 * hop[3]) * hop[0]
                out.append(f'<ellipse cx="{cx:.1f}" cy="{self.char[3] - 4:.1f}" rx="{wdt:.1f}" ry="{wdt * 0.13:.1f}" '
                           f'fill="#000" fill-opacity="{0.16 * (1 - 0.6 * hop[3]):.3f}"/>')
        out.append('</svg>')
        return "".join(out)

def main():
    did, outp = sys.argv[1], sys.argv[2]
    secs = float(sys.argv[sys.argv.index('--seconds') + 1]) if '--seconds' in sys.argv else 4
    shade = '--shade' in sys.argv
    px = int(sys.argv[sys.argv.index('--px') + 1]) if '--px' in sys.argv else 480
    cat = json.load(open(os.path.join(ROOT, "assets", "catalog.json")))
    meta = next(d for d in cat["drawings"] if d["id"] == did)
    lv = Living(meta, open(os.path.join(ROOT, meta["svg"])).read())
    fps = 30
    with tempfile.TemporaryDirectory() as tmp:
        for i in range(int(secs * fps)):
            cairosvg.svg2png(bytestring=lv.frame_svg(i / fps, shade).encode(), write_to=f"{tmp}/f{i:04d}.png", output_width=px)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", str(fps), "-i", f"{tmp}/f%04d.png",
                        "-pix_fmt", "yuv420p", "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2", outp], check=True)

if __name__ == "__main__":
    main()
