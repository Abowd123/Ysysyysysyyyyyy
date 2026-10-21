import json, os, sys, io
sys.path.insert(0, os.path.dirname(__file__))
from pages_a import lion, cat, bird, car, plane, train
from pages_b import castle, dragon, unicorn, fish, whale, octopus
from pages_c import rocket, planet, astronaut, flower, butterfly, tree, house, teddy, ball_toys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "drawings")
WORLDS = [
    {"id": "animals", "emoji": "🦁", "title": {"ar": "عالم الحيوانات", "en": "Animals"}, "colors": ["#FFD27A", "#FF9F43"], "stars": 0, "music": "music_meadow"},
    {"id": "vehicles", "emoji": "🚗", "title": {"ar": "عالم المركبات", "en": "Vehicles"}, "colors": ["#8FD3FF", "#4E8DF5"], "stars": 0, "music": "music_meadow"},
    {"id": "fantasy", "emoji": "🏰", "title": {"ar": "عالم الخيال", "en": "Fantasy"}, "colors": ["#D7B8FF", "#9B6BFF"], "stars": 0, "music": "music_dream"},
    {"id": "sea", "emoji": "🌊", "title": {"ar": "عالم البحار", "en": "Under the Sea"}, "colors": ["#8EE8F0", "#2FA6D9"], "stars": 3, "music": "music_dream"},
    {"id": "space", "emoji": "🚀", "title": {"ar": "عالم الفضاء", "en": "Space"}, "colors": ["#6C7BE8", "#2B2D6E"], "stars": 6, "music": "music_dream"},
    {"id": "nature", "emoji": "🌸", "title": {"ar": "عالم الطبيعة", "en": "Nature"}, "colors": ["#B8F0A8", "#5CC46A"], "stars": 9, "music": "music_meadow"},
    {"id": "home", "emoji": "🏠", "title": {"ar": "عالمي الصغير", "en": "My Little World"}, "colors": ["#FFC4D6", "#FF7FA5"], "stars": 12, "music": "music_meadow"},
]
pages = [lion(), cat(), bird(), car(), plane(), train(), castle(), dragon(), unicorn(), fish(), whale(), octopus(),
         rocket(), planet(), astronaut(), flower(), butterfly(), tree(), house(), teddy(), ball_toys()]
metas, errors = [], []
for p in pages:
    try:
        metas.append(p.build(OUT))
    except Exception as e:
        errors.append(f"{p.id}: {e}")
if errors:
    print("\n".join(errors)); sys.exit(1)
json.dump({"version": 1, "worlds": WORLDS, "drawings": metas}, open(os.path.join(ROOT, "assets", "catalog.json"), "w"), ensure_ascii=False, indent=1)
print(len(metas), "drawings,", sum(len(m["regions"]) for m in metas), "regions")
if "--preview" in sys.argv:
    from PIL import Image
    tiles = []
    for p in pages:
        for colored in (False, True):
            png = p.preview(os.path.join(OUT, f"{p.id}.svg"), colored, 300)
            tiles.append(Image.open(io.BytesIO(png)).convert("RGB"))
    cols = 6; rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols*300, rows*300), "white")
    for i, t in enumerate(tiles): sheet.paste(t, ((i % cols)*300, (i // cols)*300))
    sheet.save("/home/user/work/preview/sheet.png")
