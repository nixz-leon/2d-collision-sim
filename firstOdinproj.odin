package main

import "core:fmt"
import m "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"
import c "core:time"

Vector2f32 :: l.Vector2f32
Error :: 0.0135
num_buckets :: 5000
width::100
height::50
Image_sideLeng :: 1024

Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    rad:f32
}




collision :: proc(a,b : ^Object) -> (Object, Object){
    delta := (a.pos - b.pos)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    if(((delta[0]*delta[0]) + (delta[1]*delta[1])) < temp_max-Error){
        na := a^
        nb := b^
        delta = l.vector_normalize(delta)
        proja := l.projection(a^.vel, delta)
        projb := l.projection(b^.vel, delta)
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

Full_collosion :: proc(Object_list :[]Object, Coll_bloc :[num_buckets][4]int, index:int){
    //so just generate a array of all the valid indices, can be dynamic
    //and then do the naive pairwise matching collosion checks for that
    check_range: [dynamic]int
    for i in  -1..=1{
        for j in -1..=1{
            //find index

        }
    }
}


main::proc(){
    
    window_width: i32= 1000
    window_height: i32= 500
    max_x:f32 = cast(f32)window_width
    max_y:f32 = cast(f32)window_height
    cell_size: f32=25
    rad:f32 = 3
    Object_list: [dynamic]Object
    Coll_bloc:[num_buckets][4]int//assumes max is going to be hexagonish pattern, hence 6 distinct objects
    for i in 0..<num_buckets{
        for j in 0..<4{
            Coll_bloc[i][j] = -1
        }
    }
    temp_obj:Object= {{0,0},{0,0},0}

    for i in 0..<100{
        for j in 0..<100{
            temp_obj = {{(20.0+(cast(f32)j*5)),(20.0+(cast(f32)i*5))},{0.5,0.5},rad}
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
    x_index:int = 0
    y_index:int = 0
    for i in 0..<len(Object_list){
        x_index = cast(int)(Object_list[i].pos[0]/cell_size)
        y_index = cast(int)(Object_list[i].pos[1]/cell_size)
        place: for j in 0..<4{
            if(Coll_bloc[x_index+(y_index*width)][j] == -1){
                Coll_bloc[x_index+(y_index*width)][j] = cast(int)i
                break place
            }
        }
    }
    tempx:i32
    tempy:i32
    tempr:f32


    rl.InitWindow(window_width, window_height, "Bloop")
    image:rl.Image = rl.LoadImage("output.png")
    texture:rl.Texture2D = rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)
    scale:= ((rad*2)-1)/(auto_cast Image_sideLeng)

    
    rl.SetTargetFPS(90)
    length := len(Object_list)
    game_loop: for !rl.WindowShouldClose(){
        //c.stopwatch_start(&time)
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        for i in 0..<length{
            tempx = cast(i32)Object_list[i].pos[0]
            tempy = cast(i32)Object_list[i].pos[1]
            tempr = cast(f32)Object_list[i].rad
            //rl.DrawCircle(tempx,tempy,tempr, rl.RED)
            rl.DrawTextureEx(texture, Object_list[i].pos, 0.0, scale, rl.WHITE)
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
                    Coll_bloc[x_index+(y_index*width)][j] = i
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

