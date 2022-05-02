import raylib, rayutils, lenientops, sequtils, strutils

const
    screenWidth = 1920
    screenHeight = 1080
    screenCenter = makevec2(1920, 1080) / 2

type Player = object
    pos : Vector2
    dead : bool
    won : bool
    spawn : Vector2

type Wall = object
    poly : seq[Vector2]
    hitbox : seq[Vector2]
    omega : float
    pivot : Vector2

var
    worldCenter = screenCenter
    level = 1
    walls : seq[Wall]

InitWindow screenWidth, screenHeight, "GAME_NAME"
SetTargetFPS 60

proc LoadLevel(l : int, w : var seq[Wall]) =
    let level = readFile("lvl" & $l).split("---")
    let prew = level[0].split("\n")
    for i in 0..<prew.len:
        let terms = prew[0].split(", ")
        let prepoly = terms[0][0..prew[0].find("@")].split(" ").mapIt(parseFloat it)
        for j in 0..<prepoly.len div 2:
            w[i].poly[j] = makevec2(prepoly[2*j], prepoly[2*j + 1])
        w[i].poly.add w[i].poly 
        w[i].omega = (parseFloat terms[1]) / 60

proc updateGame(w : var seq[Wall]) =
    for i in 0..<w.len:
        for j in 0..<w[i].poly.len:
            w[i].poly[j] = w[i].poly[j].rotateVecAbout(w[i].omega, w[i].pivot)

LoadLevel(level, walls)

while not WindowShouldClose():
    ClearBackground BGREY
        
    BeginDrawing()

    EndDrawing()
CloseWindow()