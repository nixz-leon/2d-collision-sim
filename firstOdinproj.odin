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
cell_size:: cast(f32)10

Error :: 0.0135
width::cast(MyInt)((window_width)/(cast(MyInt)cell_size))
height::cast(MyInt)((window_height)/(cast(MyInt)cell_size))
num_buckets :: cast(MyInt)(width*height)
Image_sideLeng :: 1024
Depth::30




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


//This code needs to be reworked where if the two objects are within Error of each other, it does different math to avoid floating point fuckery 
collision :: proc(a,b : ^Object){
    //fmt.println(a.pos)
    //fmt.println(b.pos)
    delta := (a.pos - b.pos)
    //fmt.println(delta)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    //fmt.println(temp_max)
    if(((delta[0]*delta[0]) + (delta[1]*delta[1])) < temp_max-Error){
        midpoint := (a.pos + b.pos) *0.5
        tempa := a.pos - midpoint
        tempb := b.pos - midpoint
        if(tempa == {0,0}){
            tempb = l.normalize(tempb)
            tempa = -1*tempb
        }else {
            tempa = l.normalize(tempa)
            tempb = -1*tempa
        }
        a.pos = midpoint + (tempa * (a.rad+Error))
        b.pos = midpoint + (tempb * (b.rad+Error))
        
        delta = l.vector_normalize(delta)
        proja := l.projection(a.vel, delta)
        projb := l.projection(b.vel, delta)
        a.vel = a.vel - proja + projb
        b.vel = b.vel - projb + proja
        a.pos+=(a.vel*0.0000005) // step slightly in velocity direction, to encourage better seperatation during the budge
        //budge section
        
    }
}

//
coll_list_gen :: proc(block :[dynamic][Depth]MyInt, index:MyInt, new_pairs: ^[dynamic][2]MyInt){
    //so just generate a array of all the valid indices, can be dynamic
    //and then do the naive pairwise matching collosion checks for that
    check_range: [dynamic]MyInt
    defer delete(check_range)
    ind:MyInt
    //the below for loop is generating excessive indices
    for i in  0..=2{
        for j in 0..=2{
            bucket: for k in 0..<Depth{
                ind =  block[index+(((auto_cast i)*width) + (auto_cast j))][k]
                if(ind == -1){
                    break bucket
                }else{
                    append_elem(&check_range, ind)
                }
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
    /*
    a,b:Object
    a = {{1253.5665,3},{-1.22825599,-0.95115495},3}
    b = {{1253.5664,3},{2.0940905,1.1682179},3}
    
    collision(&a, &b)
    fmt.println(a)
    fmt.println(b)
    */

    
    rad:f32 = 3
    Object_list: [dynamic]Object
    Coll_bloc:[dynamic][Depth]MyInt
    resize(&Coll_bloc, (auto_cast (num_buckets)))
    fmt.println(len(Coll_bloc))
    for i in 0..<num_buckets{//initalizing  to -1
        for j in 0..<Depth{
            Coll_bloc[i][j] = -1
        }
    }
    //these two loops for generating the intial positions for all the objects
    temp_obj:Object= {{0,0},{0,0},0}
    temp_index:MyInt
    for i in 0..<150{
        for j in 0..<300{
            temp_obj = {{(10.0+(cast(f32)j*6)),(3.0+(cast(f32)i*6))},{1.5,0},rad}
            append(&Object_list, temp_obj)
        }
    }
    /*
    for i in 0..<150{
        for j in 0..<300{
            temp_obj = {{(20.0+(cast(f32)j*7)),(100.0+(cast(f32)i*7))},{-1.5,1.0},rad}
            append(&Object_list, temp_obj)
        }
    }
    */
    

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
    temp, temp2:Object
    temppos: Vector2f32
    
    game_loop: for !rl.WindowShouldClose(){
        pairs:[dynamic][2]MyInt
        
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        for i in 0..<length{
            temppos = Object_list[i].pos
            rl.DrawTextureEx(texture, temppos, 0.0, scale, rl.WHITE)
            temp, temp_index = update(Object_list[i])
            if(temp.pos[0] <0 || Object_list[i].pos[0] < 0){
                fmt.println(temp, "from",  Object_list[i])
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
            Object_list[i] = temp
        }

        
        //need to edit this code to deal with width%2 !=0 case, and probably clean up the logic significantly 
        for i in 0..= (height-2)/2 -1 {
            for j in 0..= (width-2)/2 -1{
                temp_pairs:[dynamic][2]MyInt
                coll_list_gen(Coll_bloc, ((i*width*2) + j*2),&temp_pairs)
                if len(temp_pairs) != 0{
                    append(&pairs, ..temp_pairs[:])
                }
                delete(temp_pairs)
            }   
        }

    
    
    
        for passes in 0..<1{
            if len(pairs) != 0{
                for i in 0..<len(pairs){
                    temp = Object_list[pairs[i][0]]
                    temp2 = Object_list[pairs[i][1]]
                    temp = edge_coll(temp)
                    temp2 = edge_coll(temp2)
                    collision(&temp,&temp2)
                    if(cast(int)temp.pos[0] <0  || cast(int)temp2.pos[0] <0){
                        fmt.println(Object_list[pairs[i][0]], "and ", Object_list[pairs[i][1]], " goes to ", temp, "and ", temp2)
                        break game_loop
                    }
                    temp = edge_coll(temp)
                    temp2 = edge_coll(temp2)
                    Object_list[pairs[i][0]] = temp
                    Object_list[pairs[i][1]] = temp2
                
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

