import raylib, rayutils, lenientops, sequtils, strutils, rlgl, math, sugar

template C1*() : Color = makecolor("ECAF1E", 255)
template C2*() : Color = makecolor("F57F29", 255)
template C3*() : Color = makecolor("FABE2B", 255)
template C4*() : Color = makecolor("46B09D", 255)
template C5*() : Color = makecolor("004AA6", 255)
template C6*() : Color = makecolor("4711AA", 255)
template C7*() : Color = makecolor("FCF8E6", 255)
template C8*() : Color = makecolor("EFD8CF", 255)
template C9*() : Color = makecolor("93CFCF", 255)
template C9*() : Color = makecolor("624D40", 255)
template C9*() : Color = makecolor("182534", 255)

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
    polysCCW : seq[bool]
    drawnPolys : seq[seq[Vector2]]
    omegas : seq[float]
    typingOmega : bool
    heldOmega : string
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
    BeginDrawing()
    ClearBackground C4


    mposLast = mpos
    mpos = GetMousePosition()
    let mw = GetMouseWheelMove()

    zoom += mw/15

    if IsMouseButtonDown(MOUSE_BUTTON_MIDDLE):
        offset += (mposLast - mpos)/zoom

    if IsKeyPressed(KEY_UP): cObj = (cObj + 1) mod polys.len
    if IsKeyPressed KEY_DOWN: cObj = (cObj - 1) mod polys.len
    if IsKeyPressed KEY_M: mode = (mode + 1) mod 3
    if IsKeyPressed KEY_P: 
        polys.add @[]
        drawnPolys.add @[]
        omegas.add 0
        polysCCW.add false
        cObj = polys.len - 1

    if mode == 0:
        # if IsKeyPressed KEY_C:
        #     if polys[cObj][^1] != polys[cObj][0]:
        #         polys[cObj].add polys[cObj][0]
        DrawCircleV(mpos, 4, GREEN)
        if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
            polys[cObj].add screen2world(mpos, offset, zoom)
            if polys[cObj].len >= 3 and isCCW polys[cObj]:
                polysCCW[cObj] = true
        if drawnPolys.len > 0 and drawnPolys[cObj].len > 1: #IsKeyPressed(KEY_C):
            var lines : seq[float]
            for i in 0..<drawnPolys[cObj].len:
                lines.add abs(drawnPolys[cObj][i].y + ((drawnPolys[cObj][(i + 1) mod drawnPolys[cObj].len].y - drawnPolys[cObj][i].y)/(drawnPolys[cObj][(i + 1) mod drawnPolys[cObj].len].x - drawnPolys[cObj][i].x))*(mpos.x - drawnPolys[cObj][i].x) - mpos.y)
            let th = 20
            if min(lines) <= th:
                DrawCircleV(mpos, 6, WHITE)
                DrawCircleV(drawnPolys[cObj][(lines.find(min(lines)) + 1) mod lines.len], 6, WHITE)
                DrawCircleV(drawnPolys[cObj][lines.find(min(lines))], 6, WHITE)
                if IsKeyPressed KEY_C:
                    polys[cObj].insert(screen2world mpos, (lines.find(min(lines)) + 1) mod drawnPolys[cObj].len)
            # y = p0y + (dy/dx)
            # if endpts[0].y + (endpts[0].y - endpts[1].y)/(endpts[0].x - endpts[1].x)*(mpos.x - endpts[0].x) - mpos.y <= th:
            #     polys[cObj].insert(screen2world mpos, drawnPolys[cObj].find(endpts[0]) + 1)
    elif mode == 1:
        if (not(IsMouseButtonDown(MOUSE_LEFT_BUTTON))):
            for i in 0..<polys[cObj].len:
                if abs(mpos - drawnPolys[cObj][i]) <& makevec2(20, 20):
                    adjInx = i
        if adjInx != -1:
            DrawCircleV(drawnPolys[cObj][adjInx], 6, BLUE)
            if IsMouseButtonDown(MOUSE_LEFT_BUTTON) and abs(mpos - drawnPolys[cObj][adjInx]) <& max(makevec2(20, 20), abs(mposLast - mpos) + makevec2(4, 4)):
                polys[cObj][adjInx] = screen2World(mpos, offset, zoom)
                if polys[cObj].len >= 3 and isCCW polys[cObj]:
                    polysCCW[cObj] = true
    elif mode == 2:
        let distArr = drawnPolys[cObj].mapIt(mag(mpos - it))
        let mdst = min distArr
        DrawLineV(drawnPolys[cObj][abs(distArr.find(mdst) - 1) mod distArr.len], drawnPolys[cObj][(distArr.find(mdst) + 1) mod distArr.len], makecolor(WHITED.colHex(), 75))
        DrawCircleV(drawnPolys[cObj][distArr.find(mdst)], 6, PINK)
        if mdst <= 20 and IsKeyPressed KEY_DELETE:
            polys[cObj].delete distArr.find(mdst)
            if polys[cObj].len >= 3 and isCCW polys[cObj]:
                polysCCW[cObj] = true

    # Adding omegas and pivots to polys

    if typingOmega:
        # USE DEGREES - I DON"T WANT TO DEAL WITH EXPRS WITH PI
        if heldOmega.len > 0 and IsKeyPressed KEY_BACKSPACE: heldOmega = heldOmega[0..^2]
        else:
            let cPressed = GetCharPressed()
            if cPressed != 0:
                heldOmega &= char cPressed
        if heldOmega != "": omegas[cObj] = parseFloat heldOmega
    if IsKeyPressed(KEY_O): 
        typingOmega = not typingOmega
        if typingOmega == false: 
            if heldOmega != "":
                omegas[cObj] = parseFloat heldOmega
        else:
            if omegas[cObj] == 0:
                heldOmega = ""
            else:
                heldOmega = $omegas[cObj]

    # Draw

    drawnPolys = polys.mapIt(it.mapIt(it.world2screen(offset, zoom)))
    for i in 0..<polys.len:
        rlSetLineWidth 3
        if polys[i].len > 1:
            if polys[i].len > 2: 
                drawPolygon drawnPolys[i], C3, polysCCW[i]
                if omegas[i] != 0: drawTextCenteredX(($omegas[i]).dup removeSuffix ".0", int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[i + int typingOmega])
            if i == cObj:
                drawLines(drawnPolys[cObj], C2)
                for inx, i in drawnPolys[cObj].pairs:
                    DrawCircleV(i, 4, colorArr[inx mod colorArr.len])
            else: 
                drawLines(drawnPolys[i], WHITEE)
        rlSetLineWidth 1
    

    DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)

    EndDrawing()
CloseWindow()