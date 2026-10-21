"""ColorLand art kit: one consistent visual language for every coloring page.

Rules (house style):
  * 1000x1000 canvas, ink #2B1B12, region edges 9u, details 8u, round caps.
  * Big friendly shapes, min region ~24dp on a phone (area >= 900u^2).
  * Every colorable area is its own closed shape (raw, may overlap: the app
    makes them disjoint top-down).
  * Moving parts carry a `part` name used by the bring-to-life animator.
"""
import math, json, os
from shapely.geometry import Point, Polygon, LineString, box, MultiPolygon, GeometryCollection
from shapely.ops import unary_union
from shapely.affinity import scale as _scale, rotate as _rotate, translate as _translate
from shapely.geometry.polygon import orient

RES = 32
INK = "#2B1B12"
W = H = 1000
CANVAS = box(0, 0, W, H)

# ---------------------------------------------------------------- shapes
def circle(x, y, r): return Point(x, y).buffer(r, resolution=RES)
def ellipse(x, y, rx, ry, angle=0):
    e = _scale(Point(0, 0).buffer(1, resolution=RES), rx, ry)
    if angle: e = _rotate(e, angle, origin=(0, 0))
    return _translate(e, x, y)
def rrect(x, y, w, h, r):
    """Rounded rect, (x,y) = top-left."""
    r = min(r, w / 2 - 0.5, h / 2 - 0.5)
    return box(x + r, y + r, x + w - r, y + h - r).buffer(r, resolution=RES)
def poly(pts, round_=0):
    p = Polygon(pts)
    return p.buffer(round_, resolution=RES).buffer(-round_, resolution=RES) if round_ else p
def rounded_poly(pts, r):
    """Polygon with all corners rounded by r."""
    return Polygon(pts).buffer(-r, resolution=RES).buffer(r, resolution=RES)
def smooth(g, r=6): return g.buffer(r, resolution=RES).buffer(-r, resolution=RES)
def union(*gs): return unary_union(list(gs))
def bez(p0, p1, p2, p3, n=36):
    out = []
    for i in range(n + 1):
        t = i / n; u = 1 - t
        out.append((u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0],
                    u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1]))
    return out
def tube(pts, r): return LineString(pts).buffer(r, resolution=RES)
def star(x, y, r, inner=0.48, n=5, rot=-90, round_=4):
    pts = []
    for i in range(n * 2):
        rr = r if i % 2 == 0 else r * inner
        a = math.radians(rot + i * 180 / n)
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    return rounded_poly(pts, round_)
def heart(x, y, s):
    return smooth(union(circle(x - s*0.5, y - s*0.25, s*0.55), circle(x + s*0.5, y - s*0.25, s*0.55),
                        poly([(x - s*1.02, y - s*0.1), (x + s*1.02, y - s*0.1), (x, y + s*1.15)])), 4)
def rot(g, deg, origin): return _rotate(g, deg, origin=origin)
def move(g, dx, dy): return _translate(g, dx, dy)
def mirror_x(g, cx=500): return _scale(g, -1, 1, origin=(cx, 0))
def cloud(x, y, s=1.0):
    return smooth(union(circle(x - 55*s, y + 8*s, 40*s), circle(x, y - 12*s, 55*s),
                        circle(x + 55*s, y + 8*s, 38*s), ellipse(x, y + 26*s, 100*s, 30*s)), 4)
def arc_line(cx, cy, r, a0, a1, n=24):
    return [(cx + r*math.cos(math.radians(a0 + (a1 - a0)*i/n)),
             cy + r*math.sin(math.radians(a0 + (a1 - a0)*i/n))) for i in range(n + 1)]

# ---------------------------------------------------------------- page
class Page:
    def __init__(self, pid, world, title_ar, title_en, bg="#CFEFFF", sound="magic", difficulty=1):
        self.id, self.world = pid, world
        self.title = {"ar": title_ar, "en": title_en}
        self.bg, self.sound, self.difficulty = bg, sound, difficulty
        self.regions = []   # (id, geom, color, part, stroke)
        self.details = []   # (kind, data, part, width)  kind: line | fill
        self.anim = {}

    def add(self, rid, geom, color, part="body", stroke=True):
        assert rid not in [r[0] for r in self.regions], rid
        self.regions.append((rid, geom.intersection(CANVAS), color, part, stroke))
        return self
    def line(self, pts, part="body", width=8):
        self.details.append(("line", list(pts), part, width)); return self
    def dot(self, x, y, r, part="body", color=INK):
        self.details.append(("fill", (circle(x, y, r), color), part, 0)); return self
    def ink(self, geom, part="body", color=INK):
        self.details.append(("fill", (geom, color), part, 0)); return self
    def eyes(self, pts, r=19, part="eyes", look=(4, 6)):
        """Pupils + double shine. pts = eye centers."""
        for (x, y) in pts:
            px, py = x + look[0], y + look[1]
            self.ink(ellipse(px, py, r, r * 1.18), part)
            self.ink(circle(px + r*0.38, py - r*0.45, r*0.36), part, "#FFFFFF")
            self.ink(circle(px - r*0.3, py + r*0.45, r*0.18), part, "#FFFFFF")
        return self
    def smile(self, x, y, w, part="body", depth=None):
        d = depth or w * 0.55
        return self.line(bez((x - w, y), (x - w*0.6, y + d), (x + w*0.6, y + d), (x + w, y), 20), part)
    def animate(self, part, kind, pivot=None, amp=10, speed=1.0, phase=0.0):
        self.anim[part] = {"type": kind, "pivot": list(pivot) if pivot else None,
                           "amp": amp, "speed": speed, "phase": phase}
        return self

    # ------------------------------------------------------------ export
    def build(self, out_dir):
        # visible (disjoint) geometry for meta + static outline
        vis, above = [], None
        for rid, g, col, part, stroke in reversed(self.regions):
            v = g if above is None else g.difference(above)
            above = g if above is None else unary_union([above, g])
            vis.append(v)
        vis.reverse()

        L = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
             '  <g id="regions">']
        # data-vis = the visible (already disjoint) shape, precomputed here so
        # the app never runs path boolean ops at load time.
        for (rid, g, col, part, stroke), v in zip(self.regions, vis):
            L.append(f'    <path id="{rid}" data-part="{part}" data-stroke="{1 if stroke else 0}" d="{geom_d(g)}" data-vis="{geom_d(v)}" fill="#FFFFFF"/>')
        L.append('  </g>')
        bg = CANVAS.difference(unary_union([r[1] for r in self.regions]))
        L.append(f'  <g id="background"><path data-vis="{geom_d(bg)}" d="{geom_d(bg)}"/></g>')
        L.append('  <g id="outline" fill="none" stroke-linecap="round" stroke-linejoin="round">')
        edge = CANVAS.exterior.buffer(2)
        for (rid, g, col, part, stroke), v in zip(self.regions, vis):
            if v.is_empty: continue
            # edge: visible borders, static page only (the alive view strokes raw shapes).
            for ln in lines_of(v.boundary.difference(edge)):
                if ln.length < 6: continue
                L.append(f'    <path data-kind="edge" data-part="{part}" d="{line_d(ln.simplify(0.3).coords)}" stroke="{INK}" stroke-width="9"/>')
            if not stroke:
                # Unstroked scenery (ground, sea): its full raw border, alive view only,
                # so no character-shaped cut-out stays behind when characters move.
                for ln in lines_of(g.boundary.difference(edge)):
                    if ln.length < 6: continue
                    L.append(f'    <path data-kind="alive" data-part="{part}" d="{line_d(ln.simplify(0.3).coords)}" stroke="{INK}" stroke-width="9"/>')
        for kind, data, part, width in self.details:
            if kind == "line":
                L.append(f'    <path data-kind="detail" data-part="{part}" d="{line_d(data)}" stroke="{INK}" stroke-width="{width}"/>')
            else:
                g, color = data
                L.append(f'    <path data-kind="detail" data-part="{part}" d="{geom_d(g)}" fill="{color}"/>')
        L.append('  </g>\n</svg>')
        svg = "\n".join(L)
        os.makedirs(out_dir, exist_ok=True)
        open(os.path.join(out_dir, f"{self.id}.svg"), "w").write(svg)

        colors = []
        for _, _, c, _, _ in self.regions:
            if c.upper() not in colors: colors.append(c.upper())
        regions_meta = []
        for (rid, g, col, part, stroke), v in zip(self.regions, vis):
            if v.is_empty or v.area < 50:
                raise ValueError(f"{self.id}:{rid} is hidden/too small ({v.area:.0f})")
            c = label_point(v)
            regions_meta.append({"id": rid, "number": colors.index(col.upper()) + 1, "target": col.upper(),
                                 "center": [round(c[0]), round(c[1])], "area": round(v.area)})
        small = [r["id"] for r in regions_meta if r["area"] < 900]
        if small:
            raise ValueError(f"{self.id}: regions too small for kids: {small}")
        return {"id": self.id, "world": self.world, "title": self.title, "svg": f"assets/drawings/{self.id}.svg",
                "bg": self.bg.upper(), "sound": self.sound, "difficulty": self.difficulty,
                "palette": colors, "regions": regions_meta, "anim": self.anim}

    def preview(self, path, colored=True, px=500):
        import cairosvg
        import re as _re
        svg = _re.sub(r'\s*<path data-kind="alive"[^>]*/>', '', open(path).read())
        bg = self.bg if colored else "#FFFDF7"
        svg = svg.replace('<g id="regions">', f'<rect width="1000" height="1000" fill="{bg}"/><g id="regions">', 1)
        if colored:
            for rid, g, col, part, stroke in self.regions:
                svg = svg.replace(f'<path id="{rid}" ', f'<path id="{rid}" data-c="{col}" ', 1)
            import re
            svg = re.sub(r'data-c="(#\w+)" (data-part="\w+" data-stroke="\d" d="[^"]*") fill="#FFFFFF"', r'\2 fill="\1"', svg)
        return cairosvg.svg2png(bytestring=svg.encode(), output_width=px)

# ---------------------------------------------------------------- helpers
def polys_of(g):
    if g.is_empty: return []
    if isinstance(g, Polygon): return [g]
    if hasattr(g, "geoms"):
        out = []
        for x in g.geoms: out += polys_of(x)
        return out
    return []
def lines_of(g):
    if g.is_empty: return []
    if g.geom_type == "LineString": return [g]
    if g.geom_type == "LinearRing": return [LineString(g.coords)]
    if hasattr(g, "geoms"):
        out = []
        for x in g.geoms: out += lines_of(x)
        return out
    return []
def ring_d(coords):
    c = list(coords)[:-1]
    return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in c) + " Z"
def geom_d(g):
    parts = []
    for p in polys_of(g):
        if p.area < 4: continue
        p = orient(p.simplify(0.3), 1.0)
        parts.append(ring_d(p.exterior.coords))
        parts += [ring_d(i.coords) for i in p.interiors]
    return " ".join(parts)
def line_d(pts):
    pts = list(pts)
    return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
def label_point(g):
    """Point deepest inside the largest piece (pole of inaccessibility approx)."""
    ps = polys_of(g)
    p = max(ps, key=lambda q: q.area)
    try:
        from shapely.ops import polylabel
        c = polylabel(p, tolerance=2)
        return (c.x, c.y)
    except Exception:
        c = p.representative_point(); return (c.x, c.y)
