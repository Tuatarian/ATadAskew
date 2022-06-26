import raylib, rayutils, lenientops, sequtils, strutils, rlgl, math, sugar, strformat, zero_functional, random

randomize()

template C1*() : Color = makecolor("EE5722", 255)
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
    lvn = 2
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
    lven = makevec2(PI, E)
    lvenParts : seq[Vector2]
    lvenOmega : float
    typingLvenOmega : bool
    sPos : Vector2
    closed : seq[bool]

try:
    lvout = readFile(&"lvl{$lvn}.txt")
except IOError:
    discard

proc updateParticles(parts : seq[Vector2], numParts : int, linspeed, rotspeed, rad, killRange : float) : seq[Vector2] =
    var polarPts = parts.map(x => cart2Polar x)
    if polarPts.len - numParts < 0:
        polarPts.add polar2Cart(rand(killRange..rad), rand(2*PI))
    for i in 0..<polarPts.len:
        if polarPts[i].x - linspeed/60 <= killRange:
            polarPts[i] = polar2Cart(rand(killRange..rad), rand(2*PI))
        else:
            polarPts[i].y += rotspeed/60
            polarPts[i].x += -linspeed/60
    return polarPts.map(x => polar2Cart x)
    

proc loadLeveL(lvl : string) =
    var lvll = lvl.splitLines.filter(x => x != "")
    for i in 0..<lvll.len:
        let disc = lvll[i][0] 
        lvll[i] = lvll[i][1..^1]
        if disc == '&':
            polys.add @[]
            drawnPolys.add @[]
            polysCCW.add false
            omegas.add 0
            pivots.add screenCenter
            closed.add true
            
            let terms = toSeq lvll[i].split(',').filterIt(it != "")
            let coords = terms[0].split(' ').filter(x => x != "").map(x => parseFloat x)
            for z in 0..<coords.len div 2:
                polys[i].add makevec2(coords[2*z], coords[2*z + 1])
            polysCCW[i] = isCCW polys[i]
            omegas[i] = terms[1].parseFloat
            let pv = terms[2].split(" ").filter(x => x != "").toSeq.map(x => parseFloat x)
            pivots[i] = makevec2(pv[0], pv[1])
        elif disc == '/':
            # lvenOmega = lvll[i][0].parseInt.float
            lven = lvll[i][1..^1].split(' ').filter(x => x != "").map(x => parseFloat x).makevec2
            echo lven
        elif disc == 's':
            sPos = lvll[i].split(' ').filter(x => x != "").map(x => parseFloat x).makevec2

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
    closed.add false
    cObj = polys.len - 1

while not WindowShouldClose():
    BeginDrawing()
    ClearBackground C11

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
            closed.add false
            omegas.add 0
            polysCCW.add false
            pivots.add screenCenter
            cObj = polys.len - 1
            mode = 0

        if IsKeyDown KEY_LEFT_ALT:
            if IsKeyPressed KEY_BACKSPACE:
                polys.delete cObj
                drawnPolys.delete cObj
                omegas.delete cObj
                pivots.delete cObj
                polysCCW.delete cObj
                cObj = (cObj - 1).sgnmod(0, polys.len)


        elif IsKeyPressed KEY_L:
            if mode == 3:
                mode = 0
            else: mode = 3
        if lven != makevec2(PI, E):
            lvenParts = updateParticles(lvenParts, numparts = 20, linspeed = 50, rotspeed = 0, rad = 150, killRange = 10)

        if IsKeyPressed KEY_S:
            sPos = screen2world(mpos - makevec2(20, 20)*zoom)
        
        if KEY_X.IsKeyPressed and polys[cObj].len > 2:
            if closed[cObj]:
                closed[cObj] = false
            else:
                closed[cObj] = true
                polysCCW[cObj] = isCCW polys[cObj]


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
                let thck = 20
                if min(lines) <= thck:
                    DrawCircleV(mpos, 6, WHITE)
                    DrawCircleV(drawnPolys[cObj][(lines.find(min(lines)) + 1) mod lines.len], 6, WHITE)
                    DrawCircleV(drawnPolys[cObj][lines.find(min(lines))], 6, WHITE)
                    if IsKeyPressed KEY_C:
                        polys[cObj].insert(screen2world mpos, (lines.find(min(lines)) + 1) mod drawnPolys[cObj].len)

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
        elif mode == 2:
            let distArr = drawnPolys[cObj].mapIt(mag(mpos - it))
            let mdst = min distArr
            DrawLineV(drawnPolys[cObj][abs(distArr.find(mdst) - 1) mod distArr.len], drawnPolys[cObj][(distArr.find(mdst) + 1) mod distArr.len], makecolor(WHITED.colHex(), 75))
            DrawCircleV(drawnPolys[cObj][distArr.find(mdst)], 6, PINK)
            if mdst <= 20 and IsKeyPressed KEY_DELETE:
                polys[cObj].delete distArr.find(mdst)
                if polys[cObj].len >= 3 and isCCW polys[cObj]:
                    polysCCW[cObj] = true
                else:
                    polysCCW[cObj] = false
        elif mode == 3:
            if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
                lven = screen2world mpos
            if IsKeyPressed KEY_O:
                typingLvenOmega = not typingLvenOmega
                if typingLvenOmega:
                    if lvenOmega == 0:
                        heldOmega = ""
                    else:
                        heldOmega = $lvenOmega
                else:
                    lvenOmega = parseFloat heldOmega
                    heldOmega = ""
            
            if typingLvenOmega:
                if heldOmega.len > 0 and IsKeyPressed KEY_BACKSPACE: heldOmega = heldOmega[0..^2]
                else:
                    let cPressed = GetCharPressed()
                    if cPressed != 0 and char(cPressed) != 'o':
                        heldOmega &= char cPressed
                if heldOmega != "": lvenOmega = parseFloat heldOmega

        # Adding omegas and pivots to polys

        if typingOmega:
            # USE DEGREES - I DON"T WANT TO DEAL WITH EXPRS IN PI
            if heldOmega.len > 0 and IsKeyPressed KEY_BACKSPACE: heldOmega = heldOmega[0..^2]
            else:
                let cPressed = GetCharPressed()
                if cPressed != 0 and char(cPressed) != 'o':
                    heldOmega &= char cPressed
            if heldOmega != "": omegas[cObj] = parseFloat heldOmega
        if IsKeyPressed(KEY_O) and mode != 3:
            typingOmega = not typingOmega
            if not typingOmega: 
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
            if polys[i].len > 1:
                if closed[i]:
                    drawPolygon drawnPolys[i], C9, polysCCW[i]
                if i == cObj:
                    if heldOmega != "":
                        if omegas[i] != 0: drawTextCenteredX(heldOmega, int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[7])
                    elif omegas[i] != 0:
                        drawTextCenteredX(($omegas[i]).dup removeSuffix ".0", int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[1])                       
                    drawLines(drawnPolys[cObj], C2)
                    for inx, v in drawnPolys[cObj].pairs:
                        DrawCircleV(v, 4, colorArr[inx mod colorArr.len])
                else: 
                    if omegas[i] != 0: drawTextCenteredX(($omegas[i]).dup removeSuffix ".0", int mean(drawnPolys[i]).x, int mean(drawnPolys[i]).y, int(60 * zoom), colorArr[1])

        DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)
        DrawRectanglePro(makerect(heldPivot.x - 4, heldPivot.y - 4, 8, 8), makevec2(0, 0), PI/4, C11)

        if lven != makevec2(E, PI):
            DrawRectangleV(world2screen(lven - makevec2(25, 25)), makevec2(50, 50)*zoom, C7)
            if lvenOmega != 0:
                drawTextCentered(heldOmega, lven.world2screen.x.int, lven.world2screen.y.int, int 60*zoom, RED)
            for i in 0..<lvenParts.len:
                DrawRectangleV(world2screen(lvenParts[i] + lven), zoom*makevec2(15, 15), C7)
        
        if sPos != makevec2(E, PI):
            DrawRectangleV(world2screen sPos, makevec2(40, 40)*zoom, C1)

        # Write Level

        if IsKeyPressed(KEY_ENTER):
            lvout = ""
            for i in 0..<polys.len:
                lvout &= "&" & ($polys[i]).replace(",", "").replace("x:", "").replace("y:", "").replace("(", "").replace(")", "")[3..^2] & &",{$omegas[i]}," & ($pivots[i]).replace("x:", "").replace("y:", "").replace("(", "").replace(")", "").replace(",", "")[1..^1] & "\n" # should have just used regex or some other kind of filtering
            lvout &= $"/" & ($lven).replace(",", "").replace("x:", "").replace("y:", "").replace("(", "").replace(")", "")[1..^1] & &",{$lvenOmega}," & "\n"
            lvout &= "s" & ($sPos).replace(",", "").replace("x:", "").replace("y:", "").replace("(", "").replace(")", "")[1..^1] & "\n"
            writeFile(&"lvl{$lvn}.txt", lvout)
            echo &"wrote to lvl{$lvn}.txt"
    else:
        for i in 0..<polys.len:
            pPolys[i] = pPolys[i].rotateVecSeq(degToRad omegas[i]/60, pivots[i])
            pDrawnPolys[i] = pPolys[i].mapIt(world2screen it)
            rlSetLineWidth 3
            if closed[i]:
                drawPolygon pDrawnPolys[i], C9, polysCCW[i]
            rlSetLineWidth 1
            DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)
    
    if IsKeyPressed(KEY_SPACE):
        playing = not playing
        if playing:
            pPolys = polys
            pDrawnPolys = drawnPolys
        
    # Drawing debug space
    EndDrawing()
CloseWindow()