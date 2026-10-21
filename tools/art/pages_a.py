from kit import *

SKY = "#CFEFFF"; GRASS = "#7BC86C"; SUN = "#FFD23F"; WHITE = "#FFFFFF"; PINK = "#F59AA8"

def ground(p, y0=860, y1=845, col=GRASS, rid="ground"):
    g = Polygon([(0, 1000)] + bez((0, y0), (250, y0 - 40), (700, y1 + 55), (1000, y1), 60) + [(1000, 1000)])
    p.add(rid, g, col, part="scene", stroke=False)

def sun(p, x=150, y=150, r=72):
    p.add("sun", circle(x, y, r), SUN, part="sun")
    for i in range(10):
        a = i * 2 * math.pi / 10
        p.line([(x + (r + 22)*math.cos(a), y + (r + 22)*math.sin(a)), (x + (r + 50)*math.cos(a), y + (r + 50)*math.sin(a))], part="sun")
    p.animate("sun", "spin", (x, y), amp=1, speed=0.15)

# ------------------------------------------------------------------ animals
def lion():
    p = Page("lion_01", "animals", "الأسد الصغير", "Little Lion", sound="roar")
    sun(p); p.add("cloud", cloud(820, 165, 1.05), WHITE, part="cloud"); ground(p)
    p.add("tail", tube(bez((650, 790), (790, 800), (860, 700), (812, 590), 40), 17), "#F2B544", part="tail")
    p.add("tail_tip", smooth(union(circle(806, 560, 36), ellipse(800, 528, 22, 34, -15), ellipse(830, 545, 20, 30, 30), ellipse(780, 545, 20, 30, -40)), 5), "#B8672E", part="tail")
    p.add("foot_l", ellipse(345, 845, 80, 52, 8), "#F2B544"); p.add("foot_r", ellipse(655, 845, 80, 52, -8), "#F2B544")
    p.add("body", smooth(union(ellipse(500, 690, 185, 175), ellipse(500, 790, 200, 80)), 10), "#F7C548")
    p.add("belly", ellipse(500, 735, 100, 108), "#FDE8A9")
    p.add("paw_l", ellipse(435, 862, 58, 40), "#FDE8A9"); p.add("paw_r", ellipse(565, 862, 58, 40), "#FDE8A9")
    mane = smooth(union(circle(500, 395, 205), *[circle(500 + 212*math.cos(a), 395 + 212*math.sin(a), 62) for a in [i*2*math.pi/14 for i in range(14)]]), 8)
    p.add("mane", mane, "#D9822B", part="head")
    for s, x in (("l", 368), ("r", 632)):
        p.add(f"ear_{s}", circle(x, 262, 56), "#F7C548", part="head")
        p.add(f"inner_ear_{s}", circle(x + (4 if s == "l" else -4), 268, 30), PINK, part="head")
    p.add("face", ellipse(500, 418, 168, 158), "#F7C548", part="head")
    p.add("cheek_l", circle(392, 472, 27), PINK, part="head"); p.add("cheek_r", circle(608, 472, 27), PINK, part="head")
    p.add("eye_l", ellipse(438, 388, 34, 40), WHITE, part="eyes"); p.add("eye_r", ellipse(562, 388, 34, 40), WHITE, part="eyes")
    p.add("muzzle", smooth(union(ellipse(466, 478, 56, 44), ellipse(534, 478, 56, 44)), 6), "#FDF1D2", part="head")
    p.add("nose", Polygon([(470, 436), (530, 436), (500, 470)]).buffer(11, resolution=RES), "#7A3E1D", part="head")
    p.eyes([(438, 388), (562, 388)], look=(6, 8))
    p.line([(500, 470), (500, 492)], "head")
    p.line(bez((500, 492), (488, 512), (462, 512), (452, 496), 20), "head"); p.line(bez((500, 492), (512, 512), (538, 512), (548, 496), 20), "head")
    p.line(bez((410, 338), (425, 328), (448, 328), (462, 336), 16), "head"); p.line(bez((538, 336), (552, 328), (575, 328), (590, 338), 16), "head")
    for x in (420, 450, 550, 580): p.line([(x, 850), (x, 880)])
    p.line(bez((470, 640), (485, 655), (515, 655), (530, 640), 16))
    for (x, y) in [(455, 485), (440, 475), (545, 485), (560, 475)]: p.dot(x, y, 4.5, "head")
    for a, b in [((90, 900), (100, 870)), ((110, 905), (112, 875)), ((880, 905), (890, 875)), ((905, 900), (902, 872))]: p.line([a, b], "scene")
    p.animate("head", "tilt", (500, 560), amp=5, speed=0.7)
    p.animate("eyes", "blink", (500, 388))
    p.animate("tail", "swing", (650, 790), amp=12, speed=1.3)
    p.animate("cloud", "drift", amp=18, speed=0.3)
    return p

def cat():
    p = Page("cat_01", "animals", "القطة اللطيفة", "Sweet Kitty", bg="#FFE3EC", sound="meow")
    p.add("rug", ellipse(500, 905, 400, 70), "#A66CFF", part="scene")
    p.add("yarn", circle(820, 830, 62), "#FF8FB1", part="yarn")
    p.add("tail", tube(bez((640, 820), (800, 830), (770, 640), (850, 600), 40), 26), "#9E9E9E", part="tail")
    p.add("body", smooth(union(ellipse(500, 730, 170, 170), ellipse(500, 845, 190, 60)), 10), "#BDBDBD")
    p.add("belly", ellipse(500, 760, 92, 110), WHITE)
    p.add("paw_l", ellipse(430, 880, 60, 38), WHITE); p.add("paw_r", ellipse(570, 880, 60, 38), WHITE)
    for s, sx in (("l", -1), ("r", 1)):
        ear = rounded_poly([(500 + sx*95, 300), (500 + sx*205, 205), (500 + sx*200, 360)], 14)
        p.add(f"ear_{s}", ear, "#9E9E9E", part="head")
        p.add(f"inner_ear_{s}", rounded_poly([(500 + sx*125, 300), (500 + sx*190, 245), (500 + sx*185, 335)], 10), PINK, part="head")
    p.add("head", ellipse(500, 430, 200, 165), "#BDBDBD", part="head")
    p.add("patch", ellipse(560, 345, 70, 48, 20), "#9E9E9E", part="head")
    p.add("eye_l", ellipse(430, 420, 40, 46), "#9BE15D", part="eyes"); p.add("eye_r", ellipse(570, 420, 40, 46), "#9BE15D", part="eyes")
    p.add("cheek_l", circle(390, 495, 28), PINK, part="head"); p.add("cheek_r", circle(610, 495, 28), PINK, part="head")
    p.add("nose", heart(500, 474, 26), "#F06292", part="head")
    p.eyes([(430, 420), (570, 420)], r=22, look=(3, 5))
    p.line([(500, 497), (500, 512)], "head"); p.smile(477, 512, 23, "head"); p.smile(523, 512, 23, "head")
    for dy in (-12, 12):
        p.line([(380, 478 + dy), (300, 470 + dy*2)], "head", 6); p.line([(620, 478 + dy), (700, 470 + dy*2)], "head", 6)
    for x in (410, 450, 550, 590): p.line([(x, 868), (x, 900)])
    p.line(bez((775, 800), (820, 770), (870, 820), (840, 870), 16), "yarn", 6)
    p.line(bez((770, 845), (810, 860), (850, 840), (875, 810), 16), "yarn", 6)
    p.line(bez((760, 870), (700, 905), (640, 900), (620, 930), 20), "yarn", 6)
    p.animate("head", "tilt", (500, 590), amp=7, speed=0.6); p.animate("eyes", "blink", (500, 420))
    p.animate("tail", "swing", (640, 820), amp=16, speed=1.0); p.animate("yarn", "roll", (820, 830), amp=8, speed=0.8)
    return p

def bird():
    p = Page("bird_01", "animals", "العصفور المغرّد", "Singing Bird", bg="#D8F6FF", sound="chirp")
    p.add("cloud", cloud(200, 170, 1.0), WHITE, part="cloud")
    p.add("branch", tube([(40, 760), (960, 700)], 30), "#8D6E63", part="scene")
    p.add("leaf_1", rot(ellipse(150, 690, 70, 32), -30, (150, 690)), "#7BC86C", part="scene")
    p.add("leaf_2", rot(ellipse(860, 640, 70, 32), 25, (860, 640)), "#43A047", part="scene")
    p.add("leaf_3", rot(ellipse(780, 790, 60, 28), -20, (780, 790)), "#7BC86C", part="scene")
    p.add("tail", rounded_poly([(330, 560), (150, 470), (175, 620)], 16), "#1E88E5", part="tail")
    p.add("body", ellipse(480, 540, 210, 180), "#4FC3F7")
    p.add("belly", ellipse(530, 600, 120, 110), "#FFF3B0")
    p.add("wing", rounded_poly([(330, 500), (560, 470), (470, 640)], 30), "#1E88E5", part="wing")
    p.add("crest", smooth(union(ellipse(560, 345, 22, 52, -20), ellipse(600, 350, 20, 46, 15)), 4), "#FF7043", part="head")
    p.add("beak_top", rounded_poly([(660, 450), (760, 480), (660, 500)], 8), "#FF9F1C", part="head")
    p.add("cheek", circle(600, 500, 26), PINK, part="head")
    p.add("eye", ellipse(600, 430, 34, 38), WHITE, part="eyes")
    p.add("foot_l", rrect(430, 705, 30, 60, 12), "#FF9F1C"); p.add("foot_r", rrect(510, 700, 30, 60, 12), "#FF9F1C")
    p.eyes([(600, 430)], r=18, look=(6, 4))
    for i, x in enumerate((250, 290, 330)):
        p.line(bez((x, 140 + i*10), (x + 20, 120 + i*10), (x + 40, 160 + i*10), (x + 60, 140 + i*10), 12), "notes", 6)
    p.ink(ellipse(760, 330, 20, 15, -20), "notes"); p.line([(778, 325), (778, 250), (810, 262)], "notes", 7)
    p.ink(ellipse(840, 380, 18, 14, -20), "notes"); p.line([(856, 376), (856, 310)], "notes", 7)
    p.animate("wing", "flap", (450, 500), amp=14, speed=2.2); p.animate("eyes", "blink", (600, 430))
    p.animate("head", "tilt", (520, 520), amp=6, speed=1.2); p.animate("tail", "swing", (330, 560), amp=10, speed=1.6)
    p.animate("notes", "float", amp=14, speed=1.0); p.animate("cloud", "drift", amp=20, speed=0.3)
    return p

# ------------------------------------------------------------------ vehicles
def car():
    p = Page("car_01", "vehicles", "السيارة السريعة", "Speedy Car", bg="#E3F2FD", sound="beep")
    sun(p, 830, 150, 64)
    p.add("road", rrect(-20, 800, 1040, 240, 0), "#78909C", part="scene", stroke=False)
    for x in (60, 300, 540, 780): p.add(f"stripe_{x}", rrect(x, 880, 150, 26, 13), WHITE, part="scene")
    p.add("body", smooth(union(rrect(130, 520, 740, 200, 70), rrect(270, 380, 420, 220, 110)), 10), "#E53935", part="car")
    p.add("window_l", rounded_poly([(320, 520), (330, 430), (470, 425), (470, 520)], 26), "#B3E5FC", part="car")
    p.add("window_r", rounded_poly([(510, 520), (510, 425), (640, 430), (660, 520)], 26), "#B3E5FC", part="car")
    p.add("door_handle", rrect(520, 560, 70, 22, 11), "#FFD23F", part="car")
    p.add("light_f", ellipse(840, 590, 30, 36), "#FFF3B0", part="car")
    p.add("light_b", rrect(130, 560, 34, 60, 15), "#FF9F1C", part="car")
    p.add("bumper", rrect(110, 680, 780, 56, 28), "#9E9E9E", part="car")
    for s, x in (("l", 300), ("r", 700)):
        p.add(f"wheel_{s}", circle(x, 735, 92), "#37474F", part=f"wheel_{s}")
        p.add(f"hub_{s}", circle(x, 735, 44), "#BDBDBD", part=f"wheel_{s}")
        for a in range(0, 360, 90):
            r = math.radians(a)
            p.line([(x + 14*math.cos(r), 735 + 14*math.sin(r)), (x + 36*math.cos(r), 735 + 36*math.sin(r))], f"wheel_{s}", 7)
        p.animate(f"wheel_{s}", "spin", (x, 735), amp=1, speed=1.2)
    p.ink(star(430, 615, 30, round_=3), "car", WHITE)
    for i in range(3): p.line([(40, 470 + i*55), (100 - i*15, 470 + i*55)], "speed", 9)
    p.animate("car", "bounce", amp=6, speed=2.2); p.animate("speed", "float", amp=6, speed=2.0)
    return p

def plane():
    p = Page("plane_01", "vehicles", "الطائرة المرحة", "Happy Plane", bg="#C9ECFF", sound="whoosh")
    p.add("cloud_a", cloud(190, 790, 1.2), WHITE, part="cloud"); p.add("cloud_b", cloud(820, 840, 1.0), WHITE, part="cloud")
    p.add("cloud_c", cloud(790, 180, 0.8), WHITE, part="cloud")
    p.add("tail_fin", rounded_poly([(170, 470), (215, 280), (330, 470)], 20), "#FF7043", part="plane")
    p.add("wing_back", rounded_poly([(420, 470), (520, 300), (600, 300), (560, 470)], 20), "#1E88E5", part="plane")
    p.add("body", smooth(union(ellipse(500, 520, 340, 100), circle(800, 510, 90)), 10), "#FFD23F", part="plane")
    p.add("wing", rounded_poly([(420, 540), (600, 540), (560, 720), (470, 720)], 22), "#1E88E5", part="plane")
    p.add("stripe", rrect(230, 545, 420, 36, 18), "#E53935", part="plane")
    for i, x in enumerate((330, 420, 510)): p.add(f"window_{i}", circle(x, 495, 26), "#B3E5FC", part="plane")
    p.add("cockpit", rounded_poly([(700, 445), (790, 430), (850, 470), (720, 500)], 18), "#4FC3F7", part="plane")
    p.add("nose", ellipse(888, 515, 22, 44), "#E53935", part="plane")
    p.add("propeller", union(ellipse(905, 430, 14, 70), ellipse(905, 600, 14, 70)), "#9E9E9E", part="prop")
    p.ink(circle(905, 515, 14), "prop")
    p.animate("prop", "flutter", (905, 515), amp=60, speed=6.0)
    p.animate("plane", "fly", amp=14, speed=0.9); p.animate("cloud", "drift", amp=30, speed=0.4)
    return p

def train():
    p = Page("train_01", "vehicles", "القطار الصغير", "Little Train", bg="#FFF3E0", sound="toot")
    ground(p, 870, 860, "#9BE15D")
    p.add("rail", rrect(-20, 865, 1040, 30, 0), "#8D6E63", part="scene")
    p.add("smoke_a", cloud(300, 210, 0.7), WHITE, part="smoke"); p.add("smoke_b", cloud(180, 120, 0.55), WHITE, part="smoke")
    p.add("chimney", rounded_poly([(270, 300), (370, 300), (350, 440), (290, 440)], 12), "#37474F", part="train")
    p.add("cabin", rrect(560, 300, 330, 400, 40), "#E53935", part="train")
    p.add("roof", rrect(530, 260, 390, 70, 30), "#5E35B1", part="train")
    p.add("window", rrect(620, 360, 210, 150, 30), "#B3E5FC", part="train")
    p.add("boiler", rrect(160, 430, 430, 270, 120), "#1E88E5", part="train")
    p.add("band", rrect(330, 430, 50, 270, 10), "#FFD23F", part="train")
    p.add("front", ellipse(160, 565, 50, 120), "#FFD23F", part="train")
    p.add("light", circle(150, 520, 30), "#FFF3B0", part="train")
    for i, x in enumerate((260, 450, 700)):
        r = 85 if i < 2 else 105
        p.add(f"wheel_{i}", circle(x, 800 - (r - 85), r), "#37474F", part=f"wheel_{i}")
        p.add(f"hub_{i}", circle(x, 800 - (r - 85), r*0.45), "#FF9F1C", part=f"wheel_{i}")
        p.animate(f"wheel_{i}", "spin", (x, 800 - (r - 85)), amp=1, speed=1.0)
    p.line([(260, 800), (700, 780)], "rod", 14)
    p.ink(star(725, 600, 34, round_=3), "train", WHITE)
    p.animate("train", "bounce", amp=5, speed=2.4); p.animate("smoke", "float", amp=24, speed=0.8)
    p.animate("rod", "bounce", amp=8, speed=2.4)
    return p
