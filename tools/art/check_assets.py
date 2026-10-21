"""Asset pipeline check (run before every build / in CI).

Verifies for every drawing in assets/catalog.json:
  * the SVG exists, has a viewBox, a <g id="regions"> and a <g id="outline">
  * every region path is closed and its id matches the catalog
  * every region is big enough for a child's finger (visible area)
  * the number label point lies inside its own region (no overlap/leak)
  * colors are valid and numbers map to the palette
Exit code 1 on any problem.
"""
import json, os, re, sys
from shapely.geometry import Polygon, Point
from shapely.ops import unary_union

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MIN_AREA = 900

def parse_d(d):
    polys = []
    for sub in d.split("Z"):
        sub = sub.strip()
        if not sub: continue
        pts = [tuple(map(float, p.strip().lstrip("ML").split())) for p in re.split(r"(?=[ML])", sub) if p.strip()]
        if len(pts) < 3: raise ValueError("ring with < 3 points")
        polys.append(Polygon(pts).buffer(0))
    g = polys[0]
    for p in polys[1:]: g = g.symmetric_difference(p)  # even-odd
    return g

def main():
    cat = json.load(open(os.path.join(ROOT, "assets", "catalog.json")))
    worlds = {w["id"] for w in cat["worlds"]}
    errors = []
    for d in cat["drawings"]:
        did = d["id"]
        if d["world"] not in worlds: errors.append(f"{did}: unknown world {d['world']}")
        path = os.path.join(ROOT, d["svg"])
        if not os.path.exists(path):
            errors.append(f"{did}: missing {d['svg']}"); continue
        svg = open(path).read()
        if 'viewBox="0 0 1000 1000"' not in svg: errors.append(f"{did}: bad viewBox")
        if '<g id="regions">' not in svg or '<g id="outline"' not in svg:
            errors.append(f"{did}: missing regions/outline group"); continue
        reg_src = svg.split('<g id="outline"')[0]
        raw = []
        for m in re.finditer(r'<path id="([\w-]+)"[^>]* d="([^"]+)"', reg_src):
            rid, dd = m.groups()
            if not dd.strip().endswith("Z"): errors.append(f"{did}/{rid}: path not closed")
            try: raw.append((rid, parse_d(dd)))
            except Exception as e: errors.append(f"{did}/{rid}: {e}")
        ids = [r for r, _ in raw]
        meta_ids = [r["id"] for r in d["regions"]]
        if ids != meta_ids: errors.append(f"{did}: region ids differ from catalog")
        if len(set(ids)) != len(ids): errors.append(f"{did}: duplicate region ids")
        # visible geometry, top-down
        vis, above = {}, None
        for rid, g in reversed(raw):
            vis[rid] = g if above is None else g.difference(above)
            above = g if above is None else unary_union([above, g])
        n_colors = len(d["palette"])
        for r in d["regions"]:
            v = vis.get(r["id"])
            if v is None: continue
            if v.area < MIN_AREA: errors.append(f"{did}/{r['id']}: too small ({v.area:.0f} < {MIN_AREA})")
            if not v.buffer(-1).contains(Point(*r["center"])): errors.append(f"{did}/{r['id']}: label point outside region")
            if not re.fullmatch(r"#[0-9A-F]{6}", r["target"]): errors.append(f"{did}/{r['id']}: bad color {r['target']}")
            if not (1 <= r["number"] <= n_colors) or d["palette"][r["number"] - 1] != r["target"]:
                errors.append(f"{did}/{r['id']}: number/palette mismatch")
    per_world = {w: sum(1 for d in cat["drawings"] if d["world"] == w) for w in worlds}
    print(f"{len(cat['drawings'])} drawings checked · per world: {per_world}")
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("all assets OK")

if __name__ == "__main__":
    main()
