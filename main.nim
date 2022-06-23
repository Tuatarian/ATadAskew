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
    spawn : Vector2

var
    worldCenter = screenCenter
    level = 0
    polys : seq[seq[Vector2]]
    drawnPolys : seq[seq[Vector2]]
    offset : Vector2
    zoom = 1f
    omegas : seq[float]
    pivots : seq[Vector2]
    polysCCW : seq[bool]
    plr : Player
    lven : Vector2
    lvenParts : seq[Vector2]

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

proc loadLeveL(lvl : int) =
    var lvll = (&"lvl{lvl}.txt").readFile.splitLines.filter(x => x != "")
    for i in 0..<lvll.len:
        if lvll[i][0] == '&':
            lvll[i] = lvll[i][1..^1]
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
        elif lvll[i][0] == '/':
            lvll[i] = lvll[i][1..^1]
            lven = lvll[i].split(' ').filter(x => x != "").map(x => parseFloat x).makevec2

let
    iPolys = polys
    iDrawnPolys = drawnPolys

proc resetLevel() =
     polys = iPolys
     drawnPolys = iDrawnPolys

loadLeveL(level)

while not WindowShouldClose():
    ClearBackground C11

    BeginDrawing()

    for i in 0..<polys.len:
        polys[i] = polys[i].rotateVecSeq(degToRad omegas[i]/60, pivots[i])
        drawnPolys[i] = polys[i].mapIt(world2screen it)
        if polys[i].len > 2: 
            drawPolygon drawnPolys[i], C9, polysCCW[i]
            for inx, v in drawnPolys[i].pairs:
                DrawCircleV(v, 4, colorArr[inx mod colorArr.len])

    updateParticles(lvenParts, numparts = 20, linspeed = 50, rotspeed = 0, rad = 150, killRange = 10)
    DrawRectangleV(world2screen(lven - makevec2(25, 25)), makevec2(50, 50)*zoom, C7)
    for i in 0..<lvenParts.len:
        DrawRectangleV(world2screen(lvenParts[i] + lven), zoom*makevec2(12, 15), C7)

    EndDrawing()
CloseWindow()