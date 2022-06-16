import raylib, rayutils, lenientops, sequtils, strutils, sugar, zero_functional, math

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

InitWindow screenWidth, screenHeight, "GAME_NAME"
SetTargetFPS 60

func world2screen(v, o : Vector2, z : float) : Vector2 = (v - o)*z
proc world2screen(v : Vector2) : Vector2 = (v - offset)*zoom
func screen2world(v, o : Vector2, z : float) : Vector2 = v/z + o
proc screen2world(v : Vector2) : Vector2 = v/zoom + offset

proc loadLeveL(lvl : int) =
    let lvll = readFile("lvl" & $lvl & ".txt").splitLines.filter(x => x != "")
    echo lvll
    for i in 0..<lvll.len:
        polys.add @[]
        drawnPolys.add @[]
        polysCCW.add false
        omegas.add 0
        pivots.add screenCenter
        
        let terms = toSeq lvll[i].split(',').filterIt(it != "")
        echo terms
        let coords = terms[0].split(' ').filter(x => x != "").map(x => parseFloat x)
        for z in 0..<coords.len div 2:
            polys[i].add makevec2(coords[2*z], coords[2*z + 1])
            if z == 2:
                polysCCW[i] = isCCW polys[i]
        omegas[i] = terms[1].parseFloat
        let pv = terms[2].split(" ").filter(x => x != "").toSeq.map(x => parseFloat x)
        pivots[i] = makevec2(pv[0], pv[1])

let
    iPolys = polys
    iDrawnPolys = drawnPolys

proc resetLevel() =
     polys = iPolys
     drawnPolys = iDrawnPolys

loadLeveL(level)

while not WindowShouldClose():
    ClearBackground C4
        
    BeginDrawing()

    for i in 0..<polys.len:
        polys[i] = polys[i].rotateVecSeq(degToRad omegas[i]/60, pivots[i])
        drawnPolys[i] = polys[i].mapIt(world2screen it)
    DrawRectangleLines(int(-offset.x * zoom), int(-offset.y * zoom), int(1920 * zoom), int(1080 * zoom), WHITE)

    drawnPolys = polys.map(x => x.map(y => world2screen y))
    for i in 0..<polys.len:
        if polys[i].len > 2: 
            drawPolygon drawnPolys[i], C3, polysCCW[i]
            for inx, v in drawnPolys[i].pairs:
                DrawCircleV(v, 4, colorArr[inx mod colorArr.len])

    EndDrawing()
CloseWindow()