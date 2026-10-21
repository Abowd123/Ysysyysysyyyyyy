from kit import *
from pages_a import ground, sun, WHITE, PINK

# ------------------------------------------------------------------ fantasy
def castle():
    p = Page("castle_01", "fantasy", "قلعة الأحلام", "Dream Castle", bg="#EADCFF", sound="twinkle")
    p.add("moon", Point(820, 160).buffer(70, resolution=RES).difference(circle(850, 135, 60)), "#FFD23F", part="moon")
    p.add("star_a", star(150, 140, 38), "#FFD23F", part="stars"); p.add("star_b", star(300, 230, 36), "#FFF3B0", part="stars")
    ground(p, 880, 870, "#9BE15D")
    for s, x in (("l", 150), ("r", 730)):
        p.add(f"tower_{s}", rrect(x, 390, 120, 500, 14), "#FFCDD2")
        p.add(f"roof_{s}", rounded_poly([(x - 30, 400), (x + 60, 220), (x + 150, 400)], 10), "#5E35B1")
        p.add(f"flag_{s}", rounded_poly([(x + 60, 175), (x + 140, 195), (x + 60, 215)], 6), "#FF7043", part=f"flag_{s}")
        p.line([(x + 60, 222), (x + 60, 170)], f"flag_{s}", 7)
        p.add(f"win_{s}", union(rrect(x + 35, 470, 50, 70, 25)), "#FFF3B0")
        p.animate(f"flag_{s}", "wave", (x + 60, 195), amp=12, speed=1.6)
    p.add("keep", rrect(270, 470, 460, 420, 16), "#F8BBD0")
    for i in (0, 1, 3, 4): p.add(f"merlon_{i}", rrect(270 + i*100, 430, 60, 60, 10), "#F8BBD0")
    p.add("tower_c", rrect(420, 260, 160, 230, 14), "#FFCDD2")
    p.add("roof_c", rounded_poly([(390, 270), (500, 90), (610, 270)], 10), "#A66CFF")
    p.add("win_c", heart(500, 360, 30), "#FF8FB1")
    p.add("door", Polygon(list(arc_line(500, 760, 90, 180, 360)) + [(590, 892), (410, 892)]), "#8D6E63")
    p.add("win_kl", rrect(320, 560, 70, 90, 35), "#FFF3B0"); p.add("win_kr", rrect(610, 560, 70, 90, 35), "#FFF3B0")
    p.line([(500, 680), (500, 890)]); p.dot(470, 810, 8); p.dot(530, 810, 8)
    p.animate("stars", "twinkle", amp=0.15, speed=1.4); p.animate("moon", "float", amp=8, speed=0.5)
    return p

def dragon():
    p = Page("dragon_01", "fantasy", "التنين الودود", "Friendly Dragon", bg="#D9F7E8", sound="roar")
    ground(p, 880, 870, "#9BE15D")
    p.add("tail", tube(bez((620, 800), (820, 840), (900, 740), (880, 640), 40), 30), "#43A047", part="tail")
    p.add("tail_tip", rounded_poly([(840, 650), (880, 540), (930, 660)], 14), "#FF7043", part="tail")
    p.add("wing_l", rounded_poly([(330, 560), (130, 380), (200, 600), (300, 660)], 24), "#A66CFF", part="wing_l")
    p.add("wing_r", rounded_poly([(650, 560), (860, 380), (790, 600), (690, 660)], 24), "#A66CFF", part="wing_r")
    p.add("body", smooth(union(ellipse(490, 700, 175, 175), ellipse(490, 820, 190, 70)), 10), "#7BC86C")
    p.add("belly", ellipse(490, 730, 95, 125), "#FFF3B0")
    for i in range(4): p.line([(410, 640 + i*45), (570, 640 + i*45)], "body", 6)
    p.add("foot_l", ellipse(380, 860, 70, 42), "#43A047"); p.add("foot_r", ellipse(600, 860, 70, 42), "#43A047")
    for s, x in (("l", 390), ("r", 590)):
        p.add(f"horn_{s}", rounded_poly([(x - 30, 260), (x + (-40 if s == "l" else 40), 150), (x + 30, 250)], 14), "#FFD23F", part="head")
    p.add("head", ellipse(490, 380, 175, 145), "#7BC86C", part="head")
    p.add("spike", union(*[rounded_poly([(430 + i*60, 245), (460 + i*60, 195), (490 + i*60, 245)], 8) for i in range(2)]), "#FF7043", part="head")
    p.add("snout", ellipse(490, 450, 110, 70), "#9BE15D", part="head")
    p.add("eye_l", ellipse(425, 355, 38, 44), WHITE, part="eyes"); p.add("eye_r", ellipse(555, 355, 38, 44), WHITE, part="eyes")
    p.add("cheek_l", circle(355, 430, 26), PINK, part="head"); p.add("cheek_r", circle(625, 430, 26), PINK, part="head")
    p.eyes([(425, 355), (555, 355)], r=20, look=(4, 6))
    p.dot(455, 440, 9, "head"); p.dot(525, 440, 9, "head"); p.smile(490, 480, 50, "head", 26)
    p.add("puff_a", cloud(760, 330, 0.45), "#ECEFF1", part="puff"); p.add("puff_b", cloud(860, 280, 0.35), "#ECEFF1", part="puff")
    p.animate("wing_l", "flap", (330, 600), amp=12, speed=1.5); p.animate("wing_r", "flap", (650, 600), amp=-12, speed=1.5)
    p.animate("head", "tilt", (490, 520), amp=5, speed=0.8); p.animate("eyes", "blink", (490, 355))
    p.animate("tail", "swing", (620, 800), amp=10, speed=1.1); p.animate("puff", "float", amp=20, speed=0.9)
    return p

def unicorn():
    p = Page("unicorn_01", "fantasy", "المهر السحري", "Magic Unicorn", bg="#FFE8F7", sound="twinkle")
    p.add("rainbow_r", Point(500, 1000).buffer(470, resolution=64).difference(circle(500, 1000, 420)), "#E53935", part="scene")
    p.add("rainbow_y", Point(500, 1000).buffer(420, resolution=64).difference(circle(500, 1000, 370)), "#FFD23F", part="scene")
    p.add("rainbow_b", Point(500, 1000).buffer(370, resolution=64).difference(circle(500, 1000, 320)), "#4FC3F7", part="scene")
    p.add("cloud_l", cloud(150, 940, 1.2), WHITE, part="scene"); p.add("cloud_r", cloud(850, 940, 1.2), WHITE, part="scene")
    p.add("mane_back", smooth(union(circle(330, 330, 70), circle(300, 440, 70), circle(320, 550, 66)), 8), "#A66CFF", part="mane")
    p.add("neck", rounded_poly([(360, 360), (560, 380), (540, 700), (380, 700)], 40), WHITE)
    p.add("ear", rounded_poly([(430, 250), (460, 160), (510, 260)], 12), WHITE, part="head")
    p.add("head", smooth(union(ellipse(500, 360, 140, 115), ellipse(620, 420, 95, 80)), 10), WHITE, part="head")
    p.add("horn", rounded_poly([(500, 255), (560, 90), (580, 270)], 10), "#FFD23F", part="head")
    for i in range(3): p.line([(512 + i*12, 240 - i*45), (566 + i*2, 228 - i*45)], "head", 6)
    p.add("mane_front", smooth(union(circle(400, 280, 55), circle(360, 360, 52)), 6), "#FF8FB1", part="mane")
    p.add("snout", ellipse(650, 440, 70, 55), "#FFE0EC", part="head")
    p.add("eye", ellipse(520, 360, 38, 44), WHITE, part="eyes")
    p.add("cheek", circle(560, 440, 26), PINK, part="head")
    p.eyes([(520, 360)], r=21, look=(6, 6))
    for i in range(3): p.line([(500 + i*20, 312 - (i == 1)*6), (490 + i*22, 296 - (i == 1)*8)], "eyes", 6)
    p.dot(660, 430, 8, "head"); p.smile(650, 470, 32, "head", 16)
    for x, y, r in ((160, 200, 34), (820, 160, 40), (860, 380, 26)): p.ink(star(x, y, r, round_=3), "stars", "#FFD23F")
    p.animate("head", "nod", (460, 520), amp=6, speed=0.9); p.animate("mane", "swing", (360, 400), amp=5, speed=1.1)
    p.animate("eyes", "blink", (520, 360)); p.animate("stars", "twinkle", amp=0.2, speed=1.6)
    return p

# ------------------------------------------------------------------ sea
def fish():
    p = Page("fish_01", "sea", "السمكة الملونة", "Rainbow Fish", bg="#B9EBFF", sound="bubble")
    p.add("sand", Polygon([(0, 1000)] + bez((0, 880), (300, 850), (700, 900), (1000, 870), 50) + [(1000, 1000)]), "#FFE0A3", part="scene", stroke=False)
    p.add("weed_l", tube(bez((120, 900), (60, 780), (180, 700), (110, 560), 40), 24), "#43A047", part="weed")
    p.add("weed_r", tube(bez((880, 900), (950, 790), (830, 720), (900, 600), 40), 22), "#7BC86C", part="weed")
    p.add("shell", rounded_poly([(760, 900), (820, 820), (880, 900)], 16), "#FF8FB1", part="scene")
    p.add("tail", rounded_poly([(300, 480), (130, 340), (160, 480), (130, 620)], 30), "#FF7043", part="tail")
    p.add("fin_top", rounded_poly([(400, 330), (520, 200), (600, 340)], 26), "#FF9F1C", part="fish")
    p.add("fin_bottom", rounded_poly([(440, 630), (500, 720), (560, 630)], 18), "#FF9F1C", part="fish")
    p.add("body", ellipse(520, 480, 260, 175), "#FFD23F", part="fish")
    p.add("stripe_1", Polygon(bez((420, 310), (380, 420), (380, 540), (420, 650), 20)[::-1] + bez((470, 310), (430, 420), (430, 540), (470, 650), 20)).buffer(0).intersection(ellipse(520, 480, 260, 175)), "#4FC3F7", part="fish")
    p.add("stripe_2", Polygon(bez((540, 305), (500, 420), (500, 540), (540, 655), 20)[::-1] + bez((590, 310), (550, 420), (550, 540), (590, 650), 20)).buffer(0).intersection(ellipse(520, 480, 260, 175)), "#A66CFF", part="fish")
    p.add("fin_side", rounded_poly([(520, 500), (610, 470), (600, 570)], 18), "#FF7043", part="fin")
    p.add("eye", circle(680, 430, 46), WHITE, part="eyes")
    p.add("cheek", circle(700, 520, 24), PINK, part="fish")
    p.eyes([(680, 430)], r=24, look=(6, 4))
    p.smile(735, 505, 24, "fish", 14)
    p.add("bubble_a", circle(830, 300, 34), WHITE, part="bubbles"); p.add("bubble_b", circle(880, 200, 22), WHITE, part="bubbles")
    p.add("bubble_c", circle(820, 120, 28), WHITE, part="bubbles")
    p.animate("fish", "swim", amp=16, speed=0.9); p.animate("tail", "swing", (300, 480), amp=14, speed=2.0)
    p.animate("fin", "flap", (520, 500), amp=12, speed=2.0); p.animate("eyes", "blink", (680, 430))
    p.animate("weed", "sway", amp=4, speed=0.7); p.animate("bubbles", "rise", amp=40, speed=0.6)
    return p

def whale():
    p = Page("whale_01", "sea", "الحوت السعيد", "Happy Whale", bg="#C8F0FF", sound="splash")
    p.add("sea", Polygon([(0, 1000)] + bez((0, 700), (250, 660), (750, 740), (1000, 690), 60) + [(1000, 1000)]), "#1E88E5", part="scene", stroke=False)
    p.add("spout_l", tube(bez((440, 260), (420, 180), (360, 150), (320, 170), 20), 20), "#B3E5FC", part="spout")
    p.add("spout_r", tube(bez((470, 260), (490, 180), (550, 150), (590, 170), 20), 20), "#B3E5FC", part="spout")
    p.add("spout_drop", heart(455, 140, 30), "#B3E5FC", part="spout")
    p.add("tail", smooth(union(ellipse(860, 470, 50, 80, 30), ellipse(900, 380, 70, 34, -30), ellipse(800, 360, 70, 34, 30)), 10), "#5E35B1", part="tail")
    p.add("body", smooth(union(ellipse(470, 520, 330, 220), ellipse(760, 520, 150, 80)), 16), "#5E35B1", part="whale")
    p.add("belly", Polygon(bez((170, 560), (300, 760), (650, 760), (780, 560), 40)).buffer(0).intersection(ellipse(470, 520, 330, 220)), "#B3E5FC", part="whale")
    for i in range(4): p.line(bez((230 + i*20, 610 + i*25), (350, 640 + i*28), (550, 640 + i*28), (690 - i*20, 600 + i*25), 20), "whale", 6)
    p.add("fin", rounded_poly([(420, 600), (560, 650), (470, 730)], 26), "#7E57C2", part="fin")
    p.add("eye", ellipse(330, 470, 34, 38), WHITE, part="eyes")
    p.add("cheek", circle(290, 540, 30), PINK, part="whale")
    p.eyes([(330, 470)], r=18, look=(-4, 6))
    p.smile(240, 560, 40, "whale", 24)
    p.animate("whale", "swim", amp=12, speed=0.6); p.animate("tail", "swing", (760, 520), amp=10, speed=1.4)
    p.animate("spout", "pulse", (455, 260), amp=0.12, speed=1.8); p.animate("eyes", "blink", (330, 470))
    p.animate("fin", "flap", (420, 600), amp=10, speed=1.4)
    return p

def octopus():
    p = Page("octopus_01", "sea", "الأخطبوط المرح", "Silly Octopus", bg="#BDEBFF", sound="bubble")
    p.add("sand", Polygon([(0, 1000)] + bez((0, 890), (300, 860), (700, 910), (1000, 880), 50) + [(1000, 1000)]), "#FFE0A3", part="scene", stroke=False)
    p.add("coral", smooth(union(tube([(850, 900), (850, 700)], 22), tube([(850, 790), (920, 720)], 18), tube([(850, 760), (790, 690)], 18)), 6), "#FF7043", part="weed")
    p.add("starfish", star(150, 900, 60, inner=0.5, round_=10), "#FFD23F", part="scene")
    for i in range(6):
        x0 = 300 + i*80
        dx = (-1 if i < 3 else 1) * (60 + abs(i - 2.5)*25)
        p.add(f"arm_{i}", tube(bez((x0, 600), (x0 + dx*0.2, 720), (x0 + dx, 760), (x0 + dx*1.1, 860), 30), 30), "#A66CFF", part=f"arm_{i}")
        p.animate(f"arm_{i}", "swing", (x0, 600), amp=7 if i % 2 else -7, speed=1.3, phase=i*0.5)
    p.add("head", smooth(union(ellipse(500, 440, 220, 220), ellipse(500, 590, 210, 70)), 10), "#BA68C8", part="head")
    for i, (x, y, r) in enumerate(((400, 290, 30), (590, 270, 22), (640, 360, 18))):
        p.add(f"spot_{i}", circle(x, y, r), "#E1BEE7", part="head")
    p.add("eye_l", ellipse(430, 470, 46, 52), WHITE, part="eyes"); p.add("eye_r", ellipse(570, 470, 46, 52), WHITE, part="eyes")
    p.add("cheek_l", circle(370, 550, 28), PINK, part="head"); p.add("cheek_r", circle(630, 550, 28), PINK, part="head")
    p.eyes([(430, 470), (570, 470)], r=24, look=(0, 6)); p.smile(500, 555, 46, "head", 28)
    p.add("bubble_a", circle(760, 300, 32), WHITE, part="bubbles"); p.add("bubble_b", circle(820, 200, 22), WHITE, part="bubbles")
    p.animate("head", "float", amp=12, speed=0.7); p.animate("eyes", "blink", (500, 470))
    for i in range(6): p.anim[f"arm_{i}"]["follow"] = "head"
    p.anim["eyes"]["follow"] = "head"
    p.animate("bubbles", "rise", amp=40, speed=0.6); p.animate("weed", "sway", amp=4, speed=0.7)
    return p
