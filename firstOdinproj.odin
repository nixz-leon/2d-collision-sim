package main

import "core:fmt"
import l "core:math/linalg"
import rl "vendor:raylib"

Vector2f32 :: l.Vector2f32

Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    rad:f32
}


collision :: proc(a,b : Object) -> (Object, Object){
    if(l.distance(a.pos, b.pos) < (a.rad + b.rad)){
        fmt.println("col event")
        na := a
        nb := b
        centereda:= b.pos - a.pos
        centereda = l.vector_normalize(centereda)
        proja := l.projection(a.vel, centereda)
        projb := l.projection(b.vel, centereda)
        na.vel = a.vel - 2*proja
        nb.vel = b.vel - 2*projb
        return na, nb
    }
    return a,b
}


update :: proc(a:Object) -> (Object){
    na := a
    na.pos += a.vel
    return na
}

edgecollision :: proc(a:Object, max_x,max_y: i32) -> (Object){
    max_x:f32 = cast(f32)max_x
    max_y:f32 = cast(f32)max_y
    na := a
    if(a.pos[0]+a.rad > max_x){
        na.pos[0] = max_x - a.rad
        na.vel[0] *= -1
    }
    if(a.pos[1]+a.rad > max_y){
        na.pos[1] = max_y - a.rad
        na.vel[1] *= -1
    }
    if(a.pos[0]-a.rad <0){
        na.pos[0] = a.rad
        na.vel[0] *= -1
    }
    if(a.pos[1]-a.rad < 0){
        na.pos[1] = a.rad
        na.vel[1] *= -1
    }
    return na
}

draw :: proc(a:^Object, color:rl.Color){
    tempx:i32 = cast(i32)a^.pos[0]
    tempy:i32 = cast(i32)a^.pos[1]
    tempr:f32 = cast(f32)a^.rad
    rl.DrawCircle(tempx,tempy,tempr, color)
}


main::proc(){
    
    window_width: i32= 1280
    window_height: i32= 720
    rl.InitWindow(window_width, window_height, "My first game")
    circ1:Object = {{(1280/2)-100,720/2},{4,0},5}
    circ2:Object = {{(1280/2)+100,(720/2)-0.1},{-4,0},5}

    tempx:i32
    tempy:i32
    tempr:f32
    
    game_loop: for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        circ1 = update(circ1)
        circ2 = update(circ2)
        circ1 = edgecollision(circ1, window_width, window_height)
        circ2 = edgecollision(circ2, window_width, window_height)
        circ1, circ2 = collision(circ1, circ2)
        draw(&circ1, rl.RED)
        draw(&circ2, rl.GREEN)
        rl.EndDrawing()
    }
    
    rl.CloseWindow()
    
}

