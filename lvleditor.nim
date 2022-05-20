import raylib, rayutils, lenientops, sequtils, math

template C1*() : Color = makecolor("B51C20", 255)
template C2*() : Color = makecolor("A9400D", 255)
template C3*() : Color = makecolor("ECAF1E", 255)
template C4*() : Color = makecolor("75C996", 255)
template C5*() : Color = makecolor("3BC2C1", 255)

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
    offset : Vector2
    mode : int
    lvout : string
    polys : seq[seq[Vector2]]
    drawnPolys : seq[seq[Vector2]]
    inpoints : seq[Vector2]
    omegas : seq[float]
    cObj : int
    adjInx = 0
    zoom = 1f
    mpos : Vector2
    mposLast : Vector2

# lvout = readFile("lvl0.txt")

#[ MODES
 0 : Adding Mode
 1 : Editing Mode
 2 : Delete Mode
]#

func world2screen(v, o : Vector2, z : float) : Vector2 = (v - o)*z
proc world2screen(v : Vector2) : Vector2 = (v - offset)*zoom
func screen2world(v, o : Vector2, z : float) : Vector2 = v/z + o
proc screen2world(v : Vector2) : Vector2 = v/zoom + offset

InitWindow screenWidth, screenHeight, "GAME_NAME"
SetTargetFPS 60

while not WindowShouldClose():
    mposLast = mpos
    mpos = GetMousePosition()
    let mw = GetMouseWheelMove()

    zoom += mw/15

    if IsMouseButtonDown(MOUSE_BUTTON_MIDDLE):
        offset += (mposLast - mpos)/zoom

    if IsKeyPressed(KEY_UP): cObj = (cObj + 1) mod polys.len
    if IsKeyPressed KEY_DOWN: cObj = (cObj - 1) mod polys.len
    if IsKeyPressed KEY_M: mode = (mode + 1) mod 2
    if IsKeyPressed KEY_P: 
        polys.add @[]
        drawnPolys.add @[]
        cObj = polys.len - 1

    if mode == 0:
        # if IsKeyPressed KEY_C:
        #     if polys[cObj][^1] != polys[cObj][0]:
        #         polys[cObj].add polys[cObj][0]
        DrawCircleV(mpos, 4, GREEN)
        if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
            polys[cObj].add screen2world(mpos, offset, zoom)
        if drawnPolys.len > 0 and drawnPolys[cObj].len > 1: #IsKeyPressed(KEY_C):
            var lines : seq[float]

            for i in 0..<drawnPolys[cObj].len:
                lines.add abs(drawnPolys[cObj][i].y + ((drawnPolys[cObj][(i + 1) mod drawnPolys[cObj].len].y - drawnPolys[cObj][i].y)/(drawnPolys[cObj][(i + 1) mod drawnPolys[cObj].len].x - drawnPolys[cObj][i].x))*(mpos.x - drawnPolys[cObj][i].x) - mpos.y)
            let th = 20
            drawTextCenteredY($(lines.mapIt(it.roundToInt)), 100, 100, 40, WHITEE)
            if min(lines) <= th:
                DrawCircleV(mpos, 6, WHITE)
                DrawCircleV(drawnPolys[cObj][(lines.find(min(lines)) + 1) mod lines.len], 6, WHITE)
                DrawCircleV(drawnPolys[cObj][lines.find(min(lines))], 6, WHITE)
                if IsKeyPressed KEY_C:
                    polys[cObj].insert(screen2world mpos, (lines.find(min(lines)) + 1) mod drawnPolys[cObj].len)
            # y = p0y + (dy/dx)
            # if endpts[0].y + (endpts[0].y - endpts[1].y)/(endpts[0].x - endpts[1].x)*(mpos.x - endpts[0].x) - mpos.y <= th:
            #     polys[cObj].insert(screen2world mpos, drawnPolys[cObj].find(endpts[0]) + 1)
    if mode == 1:
        if (not(IsMouseButtonDown(MOUSE_LEFT_BUTTON))):
            for i in 0..<polys[cObj].len:
                if abs(mpos - drawnPolys[cObj][i]) <& makevec2(20, 20):
                    adjInx = i
        if adjInx != -1:
            DrawCircleV(drawnPolys[cObj][adjInx], 6, BLUE)
            if IsMouseButtonDown(MOUSE_LEFT_BUTTON) and abs(mpos - drawnPolys[cObj][adjInx]) <& max(makevec2(20, 20), abs(mposLast - mpos) + makevec2(4, 4)):
                polys[cObj][adjInx] = screen2World(mpos, offset, zoom)

    drawnPolys = polys.mapIt(it.mapIt(it.world2screen(offset, zoom)))
    for i in 0..<polys.len:
        if i == cObj and polys[cObj].len > 1:
            drawLines(drawnPolys[cObj], C1)
            for i in drawnPolys[cObj]:
                DrawCircleV(i, 4, C1)
        elif polys[i].len > 1: 
            drawLines(drawnPolys[i], WHITEE)

    BeginDrawing()
    ClearBackground BGREY
    DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)

    EndDrawing()
CloseWindow()