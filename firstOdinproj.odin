package main

import "core:fmt"
import m "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"
import c "core:time"

Vector2f32 :: l.Vector2f32
Error :: 0.0135
num_buckets :: 800
width::40

Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    rad:f32
}




collision :: proc(a,b : ^Object) -> (Object, Object){
    temp_res := (a.pos - b.pos) * (a.pos - b.pos)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    if((temp_res[0] + temp_res[1]) < temp_max-Error){
        na := a^
        nb := b^
        centereda:= b^.pos - a^.pos
        centereda = l.vector_normalize(centereda)
        proja := l.projection(a^.vel, centereda)
        projb := l.projection(b^.vel, centereda)
        na.vel = a^.vel - proja
        na.vel = na.vel + projb
        nb.vel = b^.vel - projb
        nb.vel = nb.vel + proja
        //budge section
        midpoint := (a^.pos + b^.pos) * 0.5
        tempa := l.normalize(a^.pos - midpoint)
        tempb := l.normalize(b^.pos - midpoint)
        na.pos = midpoint + (tempa * (a^.rad+Error))
        nb.pos = midpoint + (tempb * (b^.rad+Error))
        return na, nb
    }
    return a^, b^
}




main::proc(){
    
    window_width: i32= 1000
    window_height: i32= 500
    max_x:f32 = cast(f32)window_width
    max_y:f32 = cast(f32)window_height
    cell_size: f32=25
    rad:f32 = 5
    Object_list: [dynamic]Object
    Coll_bloc:[num_buckets][4]i16//assumes max is going to be hexagonish pattern, hence 6 distinct objects
    for i in 0..<num_buckets{
        for j in 0..<6{
            Coll_bloc[i][j] = -1
        }
    }
    temp_obj:Object= {{0,0},{0,0},0}

    for i in 0..<50{
        for j in 0..<50{
            temp_obj = {{(20.0+(cast(f32)j*15)),(20.0+(cast(f32)i*15))},{0.5,0.5},rad}
            append(&Object_list, temp_obj)
        }
    }
    for i in 0..<len(Object_list){
        Object_list[i].pos += Object_list[i].vel
            //below is window edge collision
            if(Object_list[i].pos[0]+Object_list[i].rad > max_x){
                Object_list[i].pos[0] = max_x - Object_list[i].rad
                Object_list[i].vel[0] *= -1
            }
            if(Object_list[i].pos[1]+Object_list[i].rad > max_y){
                Object_list[i].pos[1] = max_y - Object_list[i].rad
                Object_list[i].vel[1] *= -1
            }
            if(Object_list[i].pos[0]-Object_list[i].rad <0){
                Object_list[i].pos[0] = Object_list[i].rad
                Object_list[i].vel[0] *= -1
            }
            if(Object_list[i].pos[1]-Object_list[i].rad < 0){
                Object_list[i].pos[1] = Object_list[i].rad
                Object_list[i].vel[1] *= -1
            }
    }
    //first sorting
    x_index:i16 = 0
    y_index:i16 = 0
    for i in 0..<len(Object_list){
        x_index = cast(i16)(Object_list[i].pos[0]/cell_size)
        y_index = cast(i16)(Object_list[i].pos[1]/cell_size)
        place: for j in 0..<4{
            if(Coll_bloc[x_index+(y_index*width)][j] == -1){
                Coll_bloc[x_index+(y_index*width)][j] = cast(i16)i
                break place
            }
        }
    }
    tempx:i32
    tempy:i32
    tempr:f32
    rl.SetTargetFPS(60)
    rl.InitWindow(window_width, window_height, "Bloop")
    length := len(Object_list)
    game_loop: for !rl.WindowShouldClose(){
        //c.stopwatch_start(&time)
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        for i in 0..<length{
            tempx = cast(i32)Object_list[i].pos[0]
            tempy = cast(i32)Object_list[i].pos[1]
            tempr = cast(f32)Object_list[i].rad
            rl.DrawCircle(tempx,tempy,tempr, rl.RED)
            Object_list[i].pos += Object_list[i].vel
            //below is window edge collision
            if(Object_list[i].pos[0]+Object_list[i].rad > max_x){
                Object_list[i].pos[0] = max_x - Object_list[i].rad
                Object_list[i].vel[0] *= -1
            }
            if(Object_list[i].pos[1]+Object_list[i].rad > max_y){
                Object_list[i].pos[1] = max_y - Object_list[i].rad
                Object_list[i].vel[1] *= -1
            }
            if(Object_list[i].pos[0]-Object_list[i].rad <0){
                Object_list[i].pos[0] = Object_list[i].rad
                Object_list[i].vel[0] *= -1
            }
            if(Object_list[i].pos[1]-Object_list[i].rad < 0){
                Object_list[i].pos[1] = Object_list[i].rad
                Object_list[i].vel[1] *= -1
            }
            
            x_index = auto_cast m.floor_f32(Object_list[i].pos[0]/cell_size)
            y_index = auto_cast m.floor_f32(Object_list[i].pos[1]/cell_size)
            place_2: for j in 0..<4{
                if(Coll_bloc[x_index+(y_index*width)][j] == -1){
                    Coll_bloc[x_index+(y_index*width)][j] = cast(i16)i
                    break place_2
                }
            }
            
        }
        /* needs to iterate through the neighboring buckets, 
        for i in 0..<num_buckets{
            
        }
        */
        rl.EndDrawing()
        //c.stopwatch_stop(&time)
        //fmt.println(time)
    }
    
    
    rl.CloseWindow()
    
}

