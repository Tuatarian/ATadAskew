import raylib, rayutils, lenientops, sequtils, strutils, rlgl, math, sugar, strformat, zero_functional

template C1*() : Color = makecolor("ECAF1E", 255)
template C2*() : Color = makecolor("F57F29", 255)
template C3*() : Color = makecolor("FABE2B", 255)
template C4*() : Color = makecolor("46B09D", 255)
template C5*() : Color = makecolor("004AA6", 255)
template C6*() : Color = makecolor("4711AA", 255)
template C7*() : Color = makecolor("FCF8E6", 255)
template C8*() : Color = makecolor("EFD8CF", 255)
template C9*() : Color = makecolor("93CFCF", 255)
template C10*() : Color = makecolor("624D40", 255)
template C11*() : Color = makecolor("182534", 255)

const
    screenWidth = 1920
    screenHeight = 1080
    screenCenter = makevec2(1920, 1080) / 2

type Player = object
    pos : Vector2
    dead : bool
    won : bool
    spawn : Vector2

var
    offset : Vector2
    mode : int
    lvout : string
    polys : seq[seq[Vector2]]
    polysCCW : seq[bool]
    drawnPolys : seq[seq[Vector2]]
    omegas : seq[float]
    pivots : seq[Vector2]
    typingOmega : bool
    heldOmega : string
    adjPivot : bool
    heldPivot : Vector2
    cObj : int
    adjInx = 0
    zoom = 1f
    mpos : Vector2
    mposLast : Vector2
    playing : bool
    pPolys : seq[seq[Vector2]]
    pDrawnPolys : seq[seq[Vector2]]

try:
    lvout = readFile("lvl0.txt")
except IOError:
    discard

proc loadLeveL(lvl : string) =
    let lvll = lvl.splitLines.filter(x => x != "")
    for i in 0..<lvll.len:
        polys.add @[]
        drawnPolys.add @[]
        polysCCW.add false
        omegas.add 0
        pivots.add screenCenter
        
        let terms = toSeq lvll[i].split(',').filterIt(it != "")
        let coords = terms[0].split(' ').filter(x => x != "").map(x => parseFloat x)
        for z in 0..<coords.len div 2:
            polys[i].add makevec2(coords[2*z], coords[2*z + 1])
            if z == 2:
                polysCCW[i] = isCCW polys[i]
        omegas[i] = terms[1].parseFloat
        let pv = terms[2].split(" ").filter(x => x != "").toSeq.map(x => parseFloat x)
        pivots[i] = makevec2(pv[0], pv[1])
    if polys.len > 0:
        if omegas[cObj] == 0:
            heldOmega = ""
        else:
            heldOmega = $omegas[cObj]

loadLeveL lvout

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

if polys.len == 0:
    polys.add @[]
    drawnPolys.add @[]
    omegas.add 0
    polysCCW.add false
    pivots.add screenCenter
    cObj = polys.len - 1

while not WindowShouldClose():
    BeginDrawing()
    ClearBackground C4

    mposLast = mpos
    mpos = GetMousePosition()
    let mw = GetMouseWheelMove()

    zoom += mw/15

    if IsMouseButtonDown(MOUSE_BUTTON_MIDDLE):
        offset += (mposLast - mpos)/zoom

    if not playing:
        if IsKeyPressed(KEY_UP): cObj = (cObj + 1) mod polys.len
        if IsKeyPressed KEY_DOWN: 
            cObj = (cObj - 1).sgnmod(0, polys.len)
        if IsKeyPressed KEY_M: mode = (mode + 1) mod 3
        if IsKeyPressed KEY_N: 
            polys.add @[]
            drawnPolys.add @[]
            omegas.add 0
            polysCCW.add false
            pivots.add screenCenter
            cObj = polys.len - 1
            mode = 0
        if IsKeyPressed(KEY_BACKSPACE) and IsKeyDown(KEY_LEFT_ALT):
            polys.delete cObj
            drawnPolys.delete cObj
            omegas.delete cObj
            pivots.delete cObj
            polysCCW.delete cObj
            cObj = (cObj - 1).sgnmod(0, polys.len)
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
            if not IsMouseButtonDown MOUSE_LEFT_BUTTON:
                adjInx = -1
                for i in 0..<polys[cObj].len:
                    if abs(mpos - drawnPolys[cObj][i]) <& makevec2(20, 20):
                        adjInx = i
                        break
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
            # USE DEGREES - I DON"T WANT TO DEAL WITH EXPRS IN PI
            if heldOmega.len > 0 and IsKeyPressed KEY_BACKSPACE: heldOmega = heldOmega[0..^2]
            else:
                let cPressed = GetCharPressed()
                if cPressed != 0 and char(cPressed) != 'o':
                    heldOmega &= char cPressed
            if heldOmega != "": omegas[cObj] = parseFloat heldOmega
        if IsKeyPressed(KEY_O):
            typingOmega = not typingOmega
            if typingOmega == false: 
                if heldOmega != "":
                    omegas[cObj] = parseFloat heldOmega
                    heldOmega = ""
            else:
                if omegas[cObj] == 0:
                    heldOmega = ""
                else:
                    heldOmega = $omegas[cObj]

        if adjPivot:
            if IsKeyPressed(KEY_R):
                adjPivot = false
                heldPivot = makevec2(0, 0)
            else:
                heldPivot = mpos # screenspace - convert at the end
        if IsKeyPressed(KEY_P):
            adjPivot = not adjPivot
            if adjPivot:
                heldPivot = world2screen pivots[cObj]
                SetMousePosition(heldPivot.x.int, heldPivot.y.int)
            else:
                pivots[cObj] = heldPivot.screen2world()
                heldPivot = makevec2(0, 0)

        # Draw

        drawnPolys = polys.map(x => x.map(y => world2screen y))
        for i in 0..<polys.len:
            rlSetLineWidth 3
            if polys[i].len > 1:
                if polys[i].len > 2: 
                    drawPolygon drawnPolys[i], C3, polysCCW[i]
                if i == cObj:
                    if heldOmega != "":
                        if omegas[i] != 0: drawTextCenteredX(heldOmega, int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[1])
                    elif omegas[i] != 0:
                        drawTextCenteredX(($omegas[i]).dup removeSuffix ".0", int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[0])                       
                    drawLines(drawnPolys[cObj], C2)
                    for inx, v in drawnPolys[cObj].pairs:
                        DrawCircleV(v, 4, colorArr[inx mod colorArr.len])
                else: 
                    if omegas[i] != 0: drawTextCenteredX(($omegas[i]).dup removeSuffix ".0", int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[0])
                    drawLines(drawnPolys[i], WHITEE)
            rlSetLineWidth 1
        

        DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)
        DrawRectanglePro(makerect(heldPivot.x - 4, heldPivot.y - 4, 8, 8), makevec2(0, 0), PI/4, C11)

        # Write Level

        if IsKeyPressed(KEY_ENTER):
            lvout = ""
            for i in 0..<polys.len:
                lvout &= ($polys[i]).replace(",", "").replace("x:", "").replace("y:", "").replace("(", "").replace(")", "")[3..^2] & &",{$omegas[i]}," & ($pivots[i]).replace("x:", "").replace("y:", "").replace("(", "").replace(")", "").replace(",", "")[1..^1] & "\n" # should have just used regex or some other kind of filtering
            writeFile("lvl0.txt", lvout)
            echo "wrote to lvl0.txt"
    else:
        for i in 0..<polys.len:
            pPolys[i] = pPolys[i].rotateVecSeq(degToRad omegas[i]/60, pivots[i])
            pDrawnPolys[i] = pPolys[i].mapIt(world2screen it)
            rlSetLineWidth 3
            if polys[i].len > 2:
                drawPolygon pDrawnPolys[i], C3, polysCCW[i]
            rlSetLineWidth 1
            DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)
    
    if IsKeyPressed(KEY_SPACE):
        playing = not playing
        if playing:
            pPolys = polys
            pDrawnPolys = drawnPolys
    EndDrawing()
CloseWindow()