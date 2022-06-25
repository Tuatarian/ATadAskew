import raylib, rayutils, lenientops, sequtils, strutils, sugar, zero_functional, math, strformat, random

randomize()

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
    rect : Rectangle

var
    plr = Player(dead : false)
    worldCenter = screenCenter
    lvnum = 0
    level = readFile(&"lvl{lvnum}.txt").splitLines.filter(x => x != "")
    polys : seq[seq[Vector2]]
    drawnPolys : seq[seq[Vector2]]
    offset : Vector2
    zoom = 1f
    omegas : seq[float]
    pivots : seq[Vector2]
    polysCCW : seq[bool]
    lven : Vector2
    lvenParts : seq[Vector2]
    mpos : Vector2
    mposLast : Vector2
    sPos : Vector2
    started : bool
    deathWaitTimer : int

InitWindow screenWidth, screenHeight, "GAME_NAME"
SetTargetFPS 60

func world2screen(v, o : Vector2, z : float) : Vector2 = (v - o)*z
proc world2screen(v : Vector2) : Vector2 = (v - offset)*zoom
func screen2world(v, o : Vector2, z : float) : Vector2 = v/z + o
proc screen2world(v : Vector2) : Vector2 = v/zoom + offset

proc updateParticles(parts : var seq[Vector2], numParts : int, linspeed, rotspeed, rad, killRange : float) : void =
    var polarPts = parts.map(x => cart2Polar x)
    if polarPts.len - numParts < 0:
        polarPts.add polar2Cart(rand(killRange..rad), rand(2*PI))
    for i in 0..<polarPts.len:
        if polarPts[i].x - linspeed/60 <= killRange:
            polarPts[i] = polar2Cart(rand(killRange..rad), rand(2*PI))
        else:
            polarPts[i].y += rotspeed/60
            polarPts[i].x += -linspeed/60
    parts = polarPts.map(x => polar2Cart x)

proc loadLeveL(lvl : seq[string]) =
    var lvll = lvl
    for i in 0..<lvll.len:
        let disc = lvll[i][0] 
        lvll[i] = lvll[i][1..^1]
        if disc == '&':
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
        elif disc == '/':
            lven = lvll[i].split(' ').filter(x => x != "").map(x => parseFloat x).makevec2
        elif disc == 's':
            sPos = lvll[i].split(' ').filter(x => x != "").map(x => parseFloat x).makevec2

loadLeveL(level)

let
    iPolys = polys
    iDrawnPolys = drawnPolys

proc updatePlr(p : var Player) =
    plr.rect = makerect(plr.pos, 50, 50)

proc resetLevel() =
    plr.pos = sPos
    polys = iPolys
    drawnPolys = iDrawnPolys
    plr.dead = false
    deathWaitTimer = 0
    started = false
    updatePlr plr

resetLevel()

while not WindowShouldClose():

    mposLast = mpos
    mpos = GetMousePosition()

    BeginDrawing()
    ClearBackground C11

    if not plr.dead:

        if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
            started = true
        
        if started:
            plr.pos += (screen2world(mpos) - plr.pos) * 0.9
            updatePlr(plr)
            
            for i in 0..<polys.len:
                polys[i] = polys[i].rotateVecSeq(degToRad omegas[i]/60, pivots[i])
                drawnPolys[i] = polys[i].mapIt(world2screen it)
                if polys[i].len > 2:
                    if plr.rect.checkColRec polys[i]:
                        echo plr.pos, sPos
                        drawPolygon drawnPolys[i], C10, polysCCW[i]
                        plr.dead = true
                    else:
                        drawPolygon drawnPolys[i], C9, polysCCW[i]
                    for inx, v in drawnPolys[i].pairs:
                        DrawCircleV(v, 4, colorArr[inx mod colorArr.len])
        
        else:
          for i in 0..<polys.len:
                drawnPolys[i] = polys[i].mapIt(world2screen it)
                if polys[i].len > 2:
                    if plr.rect.checkColRec polys[i]:
                        drawPolygon drawnPolys[i], C10, polysCCW[i]
                        plr.dead = true
                    else:
                        drawPolygon drawnPolys[i], C9, polysCCW[i]
                    for inx, v in drawnPolys[i].pairs:
                        DrawCircleV(v, 4, colorArr[inx mod colorArr.len])

    else:
        deathWaitTimer += 1
        if deathWaitTimer >= 30:
            resetLevel()
        elif deathWaitTimer == 20:
            resetLevel()
            plr.dead = true
            deathWaitTimer = 20
        for i in 0..<polys.len:
            if polys[i].len > 2:
                if plr.rect.checkColRec polys[i]:
                    drawPolygon drawnPolys[i], C10, polysCCW[i]
                else:
                    drawPolygon drawnPolys[i], C9, polysCCW[i]
                for inx, v in drawnPolys[i].pairs:
                    DrawCircleV(v, 4, colorArr[inx mod colorArr.len])


    updateParticles(lvenParts, numparts = 20, linspeed = 50, rotspeed = 0, rad = 150, killRange = 10)
    DrawRectangleV(world2screen(lven - makevec2(25, 25)), makevec2(50, 50)*zoom, C7)
    for i in 0..<lvenParts.len:
        DrawRectangleV(world2screen(lvenParts[i] + lven), zoom*makevec2(15, 15), C7)

    DrawRectangleV(world2screen(plr.pos - plr.rect.width.int div 2), zoom*makevec2(plr.rect.width, plr.rect.height), C2)
    EndDrawing()


CloseWindow()