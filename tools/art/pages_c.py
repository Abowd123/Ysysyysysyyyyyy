from kit import *
from pages_a import ground, sun, WHITE, PINK

# ------------------------------------------------------------------ space
def rocket():
    p = Page("rocket_01", "space", "الصاروخ الشجاع", "Brave Rocket", bg="#2B2D6E", sound="launch")
    p.add("planet", circle(150, 820, 120), "#FF8FB1", part="scene"); p.add("crater", circle(110, 790, 28), "#F06292", part="scene")
    for i, (x, y, r) in enumerate(((150, 150, 34), (850, 220, 28), (800, 700, 36), (220, 470, 34))):
        p.add(f"star_{i}", star(x, y, r), "#FFD23F", part="stars")
    p.add("flame_out", smooth(union(ellipse(500, 860, 80, 110), Polygon([(420, 830), (500, 1000), (580, 830)])), 10), "#FF7043", part="flame")
    p.add("flame_in", ellipse(500, 860, 42, 70), "#FFD23F", part="flame")
    p.add("fin_l", rounded_poly([(400, 600), (290, 790), (420, 770)], 20), "#E53935", part="rocket")
    p.add("fin_r", rounded_poly([(600, 600), (710, 790), (580, 770)], 20), "#E53935", part="rocket")
    p.add("body", smooth(union(ellipse(500, 500, 130, 290), rrect(390, 600, 220, 200, 40)), 10), "#ECEFF1", part="rocket")
    p.add("nose", ellipse(500, 500, 130, 290).intersection(box(0, 0, 1000, 330)), "#E53935", part="rocket")
    p.add("window", circle(500, 470, 78), "#4FC3F7", part="rocket")
    p.add("band", rrect(380, 640, 240, 48, 20).intersection(smooth(union(ellipse(500, 500, 130, 290), rrect(390, 600, 220, 200, 40)), 10)), "#FFD23F", part="rocket")
    p.add("nozzle", rrect(440, 790, 120, 50, 14), "#78909C", part="rocket")
    p.eyes([(475, 465), (530, 465)], r=13, part="rocket", look=(0, 2)); p.smile(502, 500, 26, "rocket", 14)
    p.animate("rocket", "shake", amp=4, speed=6.0); p.animate("flame", "flicker", (500, 820), amp=0.15, speed=8.0)
    p.animate("stars", "twinkle", amp=0.2, speed=1.4)
    return p

def planet():
    p = Page("planet_01", "space", "الكوكب ذو الحلقات", "Ringed Planet", bg="#3B2A7A", sound="twinkle")
    for i, (x, y, r) in enumerate(((140, 160, 36), (860, 140, 36), (820, 860, 38), (130, 820, 36))):
        p.add(f"star_{i}", star(x, y, r), "#FFF3B0", part="stars")
    p.add("moon", circle(830, 250, 60), "#BDBDBD", part="moon"); p.add("moon_crater", circle(810, 232, 24), "#9E9E9E", part="moon")
    ring_outer = ellipse(480, 520, 400, 110, -12); ring_inner = ellipse(480, 520, 300, 66, -12)
    ring = ring_outer.difference(ring_inner)
    cut = rot(box(0, 0, 1000, 520), -12, (480, 520))
    p.add("ring_back", ring.intersection(cut), "#FFD23F", part="planet")
    p.add("planet", circle(480, 520, 230), "#FF9F1C", part="planet")
    p.add("band_1", circle(480, 520, 230).intersection(rot(box(200, 430, 760, 480), -12, (480, 520))), "#FF7043", part="planet")
    p.add("band_2", circle(480, 520, 230).intersection(rot(box(200, 560, 760, 610), -12, (480, 520))), "#FFD23F", part="planet")
    p.add("ring_front", ring.difference(cut), "#FFD23F", part="planet")
    p.add("cheek_l", circle(390, 540, 26), PINK, part="planet"); p.add("cheek_r", circle(570, 540, 26), PINK, part="planet")
    p.eyes([(420, 490), (540, 490)], r=20, part="eyes", look=(0, 4))
    p.smile(480, 545, 36, "planet", 20)
    p.animate("planet", "float", amp=10, speed=0.6); p.animate("stars", "twinkle", amp=0.2, speed=1.4)
    p.animate("moon", "orbit", (480, 520), amp=6, speed=0.4); p.animate("eyes", "blink", (480, 490))
    return p

def astronaut():
    p = Page("astronaut_01", "space", "رائد الفضاء", "Little Astronaut", bg="#24305E", sound="beep")
    for i, (x, y, r) in enumerate(((130, 150, 30), (870, 170, 36), (880, 800, 36), (120, 760, 30))):
        p.add(f"star_{i}", star(x, y, r), "#FFD23F", part="stars")
    p.add("pack", rrect(300, 480, 400, 300, 50), "#9E9E9E", part="astro")
    p.add("leg_l", rrect(380, 740, 100, 150, 40), WHITE, part="astro"); p.add("leg_r", rrect(520, 740, 100, 150, 40), WHITE, part="astro")
    p.add("boot_l", rrect(360, 850, 130, 70, 32), "#5E35B1", part="astro"); p.add("boot_r", rrect(510, 850, 130, 70, 32), "#5E35B1", part="astro")
    p.add("arm_l", rot(rrect(200, 520, 190, 90, 45), -25, (350, 560)), WHITE, part="arm_l")
    p.add("glove_l", circle(225, 470, 48), "#5E35B1", part="arm_l")
    p.add("arm_r", rot(rrect(610, 540, 190, 90, 45), 20, (650, 580)), WHITE, part="astro")
    p.add("glove_r", circle(790, 650, 48), "#5E35B1", part="astro")
    p.add("suit", rrect(350, 500, 300, 300, 90), WHITE, part="astro")
    p.add("panel", rrect(430, 580, 140, 100, 20), "#4FC3F7", part="astro")
    p.add("button_a", circle(470, 630, 18), "#E53935", part="astro"); p.add("button_b", circle(530, 630, 18), "#FFD23F", part="astro")
    p.add("helmet", circle(500, 330, 200), WHITE, part="head")
    p.add("visor", ellipse(500, 340, 145, 120), "#B3E5FC", part="head")
    p.add("antenna", circle(500, 105, 26), "#E53935", part="head"); p.line([(500, 130), (500, 160)], "head")
    p.add("cheek_l", circle(420, 380, 24), PINK, part="head"); p.add("cheek_r", circle(580, 380, 24), PINK, part="head")
    p.eyes([(450, 320), (550, 320)], r=20, look=(0, 6))
    p.smile(500, 385, 32, "head", 20)
    p.ink(ellipse(410, 270, 30, 14, -35), "head", WHITE)
    p.animate("astro", "float", amp=14, speed=0.6); p.animate("head", "float", amp=14, speed=0.6)
    p.animate("arm_l", "wave", (350, 560), amp=14, speed=1.6); p.animate("stars", "twinkle", amp=0.2, speed=1.4)
    p.animate("eyes", "blink", (500, 320))
    return p

# ------------------------------------------------------------------ nature
def flower():
    p = Page("flower_01", "nature", "الوردة الجميلة", "Pretty Flower", bg="#E8F8E0", sound="chime")
    sun(p, 860, 140, 60); ground(p, 870, 860)
    p.add("pot", rounded_poly([(330, 760), (670, 760), (620, 960), (380, 960)], 24), "#FF7043", part="scene")
    p.add("pot_rim", rrect(310, 720, 380, 70, 30), "#FF9F1C", part="scene")
    p.add("stem", tube([(500, 720), (500, 470)], 18), "#43A047", part="flower")
    p.add("leaf_l", rot(ellipse(420, 620, 90, 38), -30, (420, 620)), "#7BC86C", part="flower")
    p.add("leaf_r", rot(ellipse(580, 580, 90, 38), 30, (580, 580)), "#7BC86C", part="flower")
    for i in range(6):
        a = math.radians(i*60 - 90)
        p.add(f"petal_{i}", ellipse(500 + 125*math.cos(a), 340 + 125*math.sin(a), 82, 82), "#FF8FB1" if i % 2 == 0 else "#F06292", part="bloom")
    p.add("center", circle(500, 340, 100), "#FFD23F", part="bloom")
    p.add("cheek_l", circle(445, 370, 20), "#FF9F1C", part="bloom"); p.add("cheek_r", circle(555, 370, 20), "#FF9F1C", part="bloom")
    p.eyes([(465, 320), (535, 320)], r=16, part="bloom", look=(0, 4)); p.smile(500, 370, 30, "bloom", 18)
    p.add("bee_body", ellipse(180, 380, 55, 40), "#FFD23F", part="bee")
    p.add("bee_wing", union(ellipse(170, 330, 30, 22, -20), ellipse(205, 330, 26, 20, 20)), WHITE, part="bee")
    p.line([(170, 345), (170, 415)], "bee", 9); p.line([(195, 342), (195, 418)], "bee", 9); p.dot(222, 372, 7, "bee")
    p.animate("bloom", "sway_top", (500, 720), amp=5, speed=0.8); p.animate("flower", "sway_top", (500, 720), amp=3, speed=0.8)
    p.animate("bee", "buzz", amp=22, speed=1.2)
    return p

def butterfly():
    p = Page("butterfly_01", "nature", "الفراشة الطائرة", "Fluttering Butterfly", bg="#FFF6D6", sound="chime")
    p.add("flower_a", union(*[circle(150 + 40*math.cos(math.radians(a)), 850 + 40*math.sin(math.radians(a)), 34) for a in range(0, 360, 72)]), "#FF8FB1", part="scene")
    p.add("flower_a_c", circle(150, 850, 30), "#FFD23F", part="scene")
    p.add("flower_b", union(*[circle(860 + 36*math.cos(math.radians(a)), 880 + 36*math.sin(math.radians(a)), 30) for a in range(0, 360, 72)]), "#A66CFF", part="scene")
    p.add("flower_b_c", circle(860, 880, 26), "#FFD23F", part="scene")
    for s, sx in (("l", -1), ("r", 1)):
        top = rot(ellipse(500 + sx*215, 380, 200, 150), sx*-25, (500 + sx*215, 380))
        bot = rot(ellipse(500 + sx*170, 650, 140, 110), sx*30, (500 + sx*170, 650))
        p.add(f"wing_top_{s}", top, "#4FC3F7", part=f"wing_{s}")
        p.add(f"wing_bot_{s}", bot, "#A66CFF", part=f"wing_{s}")
        p.add(f"spot_top_{s}", circle(500 + sx*250, 370, 50), "#FFD23F", part=f"wing_{s}")
        p.add(f"spot_bot_{s}", circle(500 + sx*190, 660, 38), "#FF8FB1", part=f"wing_{s}")
        p.add(f"dot_{s}", circle(500 + sx*140, 430, 26), WHITE, part=f"wing_{s}")
        p.animate(f"wing_{s}", "flap_x", (500, 520), amp=0.3, speed=2.4, phase=0)
    p.add("body", ellipse(500, 560, 42, 190), "#8D6E63", part="butterfly")
    p.add("head", circle(500, 360, 62), "#8D6E63", part="butterfly")
    p.line(bez((480, 305), (460, 240), (420, 220), (400, 230), 16), "butterfly"); p.line(bez((520, 305), (540, 240), (580, 220), (600, 230), 16), "butterfly")
    p.dot(400, 230, 14, "butterfly"); p.dot(600, 230, 14, "butterfly")
    p.ink(circle(468, 385, 12), "butterfly", PINK); p.ink(circle(532, 385, 12), "butterfly", PINK)
    p.eyes([(478, 350), (522, 350)], r=12, part="butterfly", look=(0, 2)); p.smile(500, 385, 18, "butterfly", 10)
    p.animate("butterfly", "float", amp=16, speed=0.9)
    for s in ("l", "r"): p.anim[f"wing_{s}"]["follow"] = "butterfly"
    return p

def tree():
    p = Page("tree_01", "nature", "الشجرة المثمرة", "Apple Tree", bg="#DDF5FF", sound="chime")
    sun(p, 150, 140, 62); p.add("cloud", cloud(820, 160, 0.9), WHITE, part="cloud"); ground(p, 860, 850)
    p.add("trunk", rounded_poly([(440, 880), (460, 560), (540, 560), (560, 880)], 16), "#8D6E63", part="scene")
    p.add("hole", ellipse(500, 700, 26, 34), "#5D4037", part="scene")
    crown = smooth(union(circle(500, 400, 200), circle(330, 470, 130), circle(670, 470, 130), circle(400, 300, 120), circle(600, 300, 120)), 8)
    p.add("leaves", crown, "#43A047", part="crown")
    for i, (x, y) in enumerate(((380, 420), (560, 360), (640, 520), (440, 560), (520, 470), (300, 520))):
        p.add(f"apple_{i}", circle(x, y, 36), "#E53935", part="crown")
        p.line([(x, y - 34), (x + 6, y - 52)], "crown", 6)
    p.add("bush_l", smooth(union(circle(150, 860, 70), circle(230, 850, 60)), 6), "#7BC86C", part="scene")
    p.add("bush_r", smooth(union(circle(820, 860, 66), circle(890, 870, 56)), 6), "#7BC86C", part="scene")
    p.animate("crown", "sway_top", (500, 880), amp=2, speed=0.6); p.animate("cloud", "drift", amp=20, speed=0.3)
    return p

# ------------------------------------------------------------------ home
def house():
    p = Page("house_01", "home", "بيتي الجميل", "My Sweet Home", bg="#E0F4FF", sound="ding")
    sun(p, 150, 140, 60); p.add("cloud", cloud(830, 150, 0.9), WHITE, part="cloud"); ground(p, 880, 870)
    p.add("chimney", rrect(640, 220, 80, 160, 10), "#8D6E63", part="house")
    p.add("smoke", cloud(700, 140, 0.45), "#ECEFF1", part="smoke")
    p.add("wall", rrect(220, 450, 560, 430, 16), "#FFF3B0", part="house")
    p.add("roof", rounded_poly([(170, 470), (500, 200), (830, 470)], 26), "#E53935", part="house")
    p.add("attic", circle(500, 360, 48), "#B3E5FC", part="house")
    p.add("door", rrect(430, 650, 140, 230, 60), "#8D6E63", part="house")
    p.dot(545, 770, 13, "house")
    for s, x in (("l", 280), ("r", 620)):
        p.add(f"window_{s}", rrect(x, 540, 110, 110, 18), "#B3E5FC", part="house")
        p.line([(x + 55, 545), (x + 55, 645)], "house", 7); p.line([(x + 5, 595), (x + 105, 595)], "house", 7)
        p.add(f"box_{s}", rrect(x - 10, 650, 130, 36, 14), "#7BC86C", part="house")
    p.add("path", Polygon([(430, 880), (570, 880), (640, 1000), (360, 1000)]), "#FFE0A3", part="scene")
    for i, x in enumerate((140, 860)):
        p.add(f"flower_{i}", union(*[circle(x + 26*math.cos(math.radians(a)), 830 + 26*math.sin(math.radians(a)), 22) for a in range(0, 360, 72)]), "#FF8FB1", part="scene")
        p.add(f"flower_c_{i}", circle(x, 830, 18), "#FFD23F", part="scene")
    p.animate("smoke", "float", amp=20, speed=0.8); p.animate("house", "breathe", (500, 880), amp=0.015, speed=1.0)
    p.animate("cloud", "drift", amp=20, speed=0.3)
    return p

def teddy():
    p = Page("teddy_01", "home", "الدب المحبوب", "Teddy Bear", bg="#FFEFE0", sound="squeak")
    p.add("blanket", ellipse(500, 920, 420, 70), "#4FC3F7", part="scene")
    p.add("ear_l", circle(330, 210, 70), "#C68B59", part="head"); p.add("ear_r", circle(670, 210, 70), "#C68B59", part="head")
    p.add("in_ear_l", circle(335, 215, 38), "#FFCC9A", part="head"); p.add("in_ear_r", circle(665, 215, 38), "#FFCC9A", part="head")
    p.add("arm_l", rot(ellipse(290, 600, 60, 110), 30, (290, 600)), "#C68B59", part="arm_l")
    p.add("arm_r", rot(ellipse(710, 600, 60, 110), -30, (710, 600)), "#C68B59", part="arm_r")
    p.add("leg_l", ellipse(370, 830, 90, 75), "#C68B59"); p.add("leg_r", ellipse(630, 830, 90, 75), "#C68B59")
    p.add("pad_l", ellipse(370, 840, 50, 42), "#FFCC9A"); p.add("pad_r", ellipse(630, 840, 50, 42), "#FFCC9A")
    p.add("body", ellipse(500, 650, 190, 200), "#C68B59")
    p.add("belly", ellipse(500, 680, 110, 120), "#FFCC9A")
    p.add("heart", heart(500, 660, 40), "#F06292")
    p.add("bow_l", rounded_poly([(500, 470), (400, 420), (400, 520)], 16), "#E53935", part="head")
    p.add("bow_r", rounded_poly([(500, 470), (600, 420), (600, 520)], 16), "#E53935", part="head")
    p.add("bow_c", circle(500, 470, 28), "#FF7043", part="head")
    p.add("head", circle(500, 320, 190).difference(box(0, 445, 1000, 1000)).union(ellipse(500, 360, 190, 90).intersection(box(0, 0, 1000, 440))), "#C68B59", part="head")
    p.add("muzzle", ellipse(500, 360, 80, 62), "#FFCC9A", part="head")
    p.add("nose", ellipse(500, 340, 30, 22), "#5D4037", part="head")
    p.add("cheek_l", circle(390, 380, 26), PINK, part="head"); p.add("cheek_r", circle(610, 380, 26), PINK, part="head")
    p.eyes([(430, 280), (570, 280)], r=18, look=(0, 4))
    p.line([(500, 362), (500, 380)], "head"); p.smile(480, 380, 20, "head", 14); p.smile(520, 380, 20, "head", 14)
    p.animate("head", "tilt", (500, 470), amp=6, speed=0.8); p.animate("arm_r", "wave", (690, 520), amp=16, speed=1.5)
    p.animate("arm_l", "wave", (310, 520), amp=-6, speed=1.0); p.animate("eyes", "blink", (500, 280))
    return p

def ball_toys():
    p = Page("toys_01", "home", "ألعابي", "My Toys", bg="#F3E8FF", sound="boing")
    p.add("floor", rrect(-20, 780, 1040, 260, 0), "#FFE0A3", part="scene", stroke=False)
    p.add("block_a", rrect(100, 620, 170, 170, 20), "#E53935", part="blocks")
    p.add("block_b", rrect(270, 620, 170, 170, 20), "#1E88E5", part="blocks")
    p.add("block_c", rrect(185, 450, 170, 170, 20), "#FFD23F", part="blocks")
    p.ink(star(185, 705, 40, round_=3), "blocks", WHITE); p.ink(heart(355, 700, 34), "blocks", WHITE)
    p.ink(circle(270, 535, 38), "blocks", WHITE)
    ball = circle(720, 620, 170)
    p.add("ball", ball, "#FF9F1C", part="ball")
    p.add("ball_s1", ball.intersection(rot(box(540, 560, 900, 620), -25, (720, 620))), "#FFFFFF", part="ball")
    p.add("ball_s2", ball.intersection(rot(box(540, 660, 900, 720), -25, (720, 620))), "#7BC86C", part="ball")
    p.add("kite", rounded_poly([(470, 80), (560, 200), (470, 330), (380, 200)], 14), "#A66CFF", part="kite")
    p.line([(470, 85), (470, 325)], "kite", 6); p.line([(385, 200), (555, 200)], "kite", 6)
    p.line(bez((470, 330), (520, 390), (420, 430), (480, 480), 20), "kite", 6)
    p.add("bow_a", heart(500, 420, 22), "#FF8FB1", part="kite")
    p.animate("ball", "bounce_big", amp=60, speed=1.6); p.animate("kite", "sway", amp=8, speed=0.8)
    p.animate("blocks", "breathe", (270, 790), amp=0.02, speed=1.4)
    return p
