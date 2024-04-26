package main

import "core:fmt"
import m "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"
import c "core:time"

Vector2f32 :: l.Vector2f32

MyInt::i32

window_width:: cast(MyInt)2000
window_height:: cast(MyInt)1200

max_x:: cast(f32)window_width
max_y:: cast(f32)window_height
cell_size:: cast(f32)5

Error :: 0.0135
width::cast(MyInt)((window_width)/(cast(MyInt)cell_size))
height::cast(MyInt)((window_height)/(cast(MyInt)cell_size))
num_buckets :: cast(MyInt)(width*height)
Image_sideLeng :: 1024
Depth::10




Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    rad:f32
}

//this function is fine
//takes in Object type, and returns Object of updated position and the hash bucket it belongs in
update :: proc (a :Object) -> (Object, MyInt){
    index:MyInt
    na := a
    na.pos+=na.vel
    //na.vel+= {0,0.00001*(max_y-na.pos[1])}
    na = edge_coll(na)
    x_index := m.floor_f32((na.pos[0]/cell_size))
    y_index := m.floor_f32(na.pos[1]/cell_size)
    index = cast(MyInt)(x_index + ((auto_cast width)*y_index))
    if index < 0{
        fmt.println(a.pos, " goes to ", x_index, ", ", y_index)    
    }
    //fmt.println(a.pos, " goes to ", x_index, ", ", y_index)
    return na, index
}



collision :: proc(a,b : Object) -> (Object, Object){
    delta := (a.pos - b.pos)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    if(((delta[0]*delta[0]) + (delta[1]*delta[1])) < temp_max-Error){
        na := a
        nb := b
        delta = l.vector_normalize(delta)
        proja := l.projection(na.vel, delta)
        projb := l.projection(nb.vel, delta)
        na.vel = na.vel - proja + projb
        nb.vel = nb.vel - projb + proja
        na.pos+=(na.vel*0.0000005) // step slightly in velocity direction, to encourage better seperatation during the budge
        //budge section
        midpoint := (na.pos + nb.pos) * 0.5
        tempa := l.normalize(na.pos - midpoint)
        tempb := l.normalize(nb.pos - midpoint)
        na.pos = midpoint + (tempa * (na.rad+Error))
        nb.pos = midpoint + (tempb * (nb.rad+Error))
        return na, nb
    }
    return a, b
}

//
coll_list_gen :: proc(obs :^[dynamic]Object, block :[dynamic][Depth]MyInt, index:MyInt, new_pairs: ^[dynamic][2]MyInt){
    //so just generate a array of all the valid indices, can be dynamic
    //and then do the naive pairwise matching collosion checks for that
    check_range: [dynamic]MyInt
    defer delete(check_range)
    ind:MyInt
    //the below for loop is generating excessive indices
    for i in  -1..=1{
        for j in -1..=1{
            bucket: for k in 0..<Depth{
                ind =  block[index+(((auto_cast i)*width) + (auto_cast j))][k]
                if(ind == -1){
                    break bucket
                }
                append_elem(&check_range, ind)
            }
        }
    }
    
    pairs:[dynamic][2]MyInt
    if(len(check_range) > 1){
        temp:[2]MyInt
        for i in 0..< (len(check_range)-2){
            for j in (i+1)..< len(check_range)-1{
                temp[0] = check_range[i]
                temp[1] = check_range[j]
                append(&new_pairs^, temp)
            }
        }
    }
}

edge_coll::proc(a: Object) -> (Object){
    na := a
    if(na.pos[0]+na.rad > max_x){
        na.pos[0] = max_x - na.rad
        na.vel[0] *= -1
    }
    if(na.pos[1]+na.rad > max_y){
        na.pos[1] = max_y - na.rad
        na.vel[1] *= -1
    }
    if(na.pos[0]-na.rad <0){
        na.pos[0] = na.rad
        na.vel[0] *= -1
    }
    if(na.pos[1]-na.rad < 0){
        na.pos[1] = na.rad
        na.vel[1] *= -1
    }
    return na
}

main::proc(){
    
    rad:f32 = 3
    Object_list: [dynamic]Object
    Coll_bloc:[dynamic][Depth]MyInt//assumes max is going to be hexagonish pattern, hence 6 distinct objects
    resize(&Coll_bloc, (auto_cast num_buckets))
    fmt.println(len(Coll_bloc))
    for i in 0..<num_buckets{
        for j in 0..<Depth{
            Coll_bloc[i][j] = -1
        }
    }
    
    temp_obj:Object= {{0,0},{0,0},0}
    temp_index:MyInt
    for i in 0..<100{
        for j in 0..<100{
            temp_obj = {{(3.0+(cast(f32)j*6)),(3.0+(cast(f32)i*6))},{1.5,0},rad}
            append(&Object_list, temp_obj)
        }
    }
    
    for i in 0..<100{
        for j in 0..<100{
            temp_obj = {{(10.0+(cast(f32)j*10)),(100.0+(cast(f32)i*10))},{-1.5,0.01},rad}
            append(&Object_list, temp_obj)
        }
    }
    

    length := len(Object_list)

    tempx:i32
    tempy:i32
    tempr:f32
    
    rl.InitWindow((auto_cast window_width), (auto_cast window_height), "Bloop")
    image:rl.Image = rl.LoadImage("output.png")
    texture:rl.Texture2D = rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)
    scale:= ((rad*2)-1)/(auto_cast Image_sideLeng)
    
    
    rl.SetTargetFPS(60)
    temp:Object
    game_loop: for !rl.WindowShouldClose(){
        pairs:[dynamic][2]MyInt
        
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        for i in 0..<length{
            rl.DrawTextureEx(texture, Object_list[i].pos, 0.0, scale, rl.WHITE)
            temp, temp_index = update(Object_list[i])
            if(temp.pos[0] <0){
                fmt.println()
            }
            col1: for t in 0..<Depth{
                if(temp_index < 0){
                    fmt.println(Object_list[i].pos, " ", width)
                }
                if(Coll_bloc[temp_index][t] == -1){
                    Coll_bloc[temp_index][t] = auto_cast i
                    break col1
                }
            }
        }
        /*
        for i in 1..<length-2{
            for j in (i+1)..<length-1{
                Object_list[i],Object_list[j] = collision(Object_list[i],Object_list[j])
            }
        }
        */
        
        for i in 1..<height-1{
            for j in 1..<width-1{
                temp_pairs:[dynamic][2]MyInt
                coll_list_gen(&Object_list, Coll_bloc, ((i*width) + j),&temp_pairs)
                if len(temp_pairs) != 0{
                    append(&pairs, ..temp_pairs[:])
                }
                delete(temp_pairs)
            }   
        }
        
        //fmt.println("Pairs: ", pairs)
        for passes in 0..<1{
            if len(pairs) != 0{
                for i in 0..<len(pairs){
                    Object_list[pairs[i][0]] = edge_coll(Object_list[pairs[i][0]])
                    Object_list[pairs[i][1]] = edge_coll(Object_list[pairs[i][1]])
                    Object_list[pairs[i][0]],Object_list[pairs[i][1]] = collision(Object_list[pairs[i][0]],Object_list[pairs[i][1]])
                    Object_list[pairs[i][0]] = edge_coll(Object_list[pairs[i][0]])
                    Object_list[pairs[i][1]] = edge_coll(Object_list[pairs[i][1]])
                }
            }
        }
        
    
        for i in 0..<num_buckets{   
            for j in 0..<Depth{
                Coll_bloc[i][j] = -1
            }
        }
        
        fmt.println(rl.GetFrameTime())
        rl.EndDrawing()
        delete(pairs)
    }
    
    
    
    rl.CloseWindow()
}

