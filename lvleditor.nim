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
    origin : Vector2
    mode : int
    lvout : string
    polys : seq[seq[Vector2]]
    drawnPolys : seq[seq[Vector2]]
    omegas : seq[float]
    cObj : int
    adjInx = -1
    zoom : float

# lvout = readFile("lvl0.txt")

#[ MODES
 0 : Placing points in polygon
 1 : Moving points
 2 : Adding points inside line
]#

InitWindow screenWidth, screenHeight, "GAME_NAME"
SetTargetFPS 60

while not WindowShouldClose():
    let mpos = GetMousePosition()

    if IsKeyPressed(KEY_UP): cObj = (cObj + 1) mod polys.len
    if IsKeyPressed KEY_DOWN: cObj = (cObj - 1) mod polys.len
    if IsKeyPressed KEY_P: 
        polys.add @[]
        cObj = polys.len - 1
        echo polys.len, polys


    if mode == 0:
        if IsKeyPressed KEY_C:
            if polys[cObj][^1] != polys[cObj][0]:
                polys[cObj].add polys[cObj][0]
        DrawCircleV(mpos, 4, GREEN)
        if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
            polys[cObj].add mpos
    if mode == 1:
        if (not(IsMouseButtonDown(MOUSE_LEFT_BUTTON)) and mpos - polys[cObj][adjInx] <& makevec2(4, 4)):
            for i in 0..<polys[cObj].len:
                if mpos - polys[cObj][i] <& makevec2(4, 4):
                    adjInx = i
        if adjInx != -1:
            if IsMouseButtonDown MOUSE_LEFT_BUTTON:
                polys[cObj][adjInx] = mpos
    for i in 0..<polys.len:
        if i == cObj and polys[cObj].len > 1:
            drawLines(polys[i], RED)
        elif polys[i].len > 1: drawLines(polys[i], WHITEE)

    BeginDrawing()
    ClearBackground BGREY

    EndDrawing()
CloseWindow()