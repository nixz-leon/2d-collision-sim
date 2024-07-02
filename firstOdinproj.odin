package main

import "core:fmt"
import m "core:math"
import l "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"
import c "core:time"

Vector2f32 :: l.Vector2f32

MyInt::i32

window_width:: cast(MyInt)2400
window_height:: cast(MyInt)1400

max_x:: cast(f32)window_width
max_y:: cast(f32)window_height
cell_size:: cast(f32)5

Error :: 0.0135
width::cast(MyInt)((window_width)/(cast(MyInt)cell_size))+1
height::cast(MyInt)((window_height)/(cast(MyInt)cell_size))+1
num_buckets :: cast(MyInt)(width*height)
Image_sideLeng :: 1024
Depth::10

Gravity::0.01



Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    rad:f32
}

//this function is fine
//takes in Object type, and returns Object of updated position and the hash bucket it belongs in
update :: proc (a :^Object, index:^[9]MyInt){
    a.pos+=a.vel
    edge_coll(a)
    offset := a.rad
    x_center := cast(MyInt)m.floor_f32((a.pos[0]/cell_size))
    y_center := cast(MyInt)m.floor_f32(a.pos[1]/cell_size)
    x_top := cast(MyInt)m.floor_f32((a.pos[0]-offset)/cell_size)
    y_left := cast(MyInt)m.floor_f32((a.pos[1]-offset)/cell_size)
    x_bot :=  cast(MyInt)m.floor_f32((a.pos[0]+offset)/cell_size)
    y_right := cast(MyInt)m.floor_f32((a.pos[1]+offset)/cell_size)
    //temp_width:= width
    index[0] = (x_center + ((width)*y_center))
    index[1] = (x_center + ((width)*y_left))
    index[2] = (x_bot + ((width)*y_center))
    index[3] = (x_bot + ((width)*y_left))
    index[4] = (x_top + ((width)*y_center))
    index[5] = (x_top + ((width)*y_left))
    index[6] = (x_top + ((width)*y_right))
    index[7] = (x_center + ((width)*y_right))
    index[8] = (x_bot + ((width)*y_right))
}
//next major source for opt
collision :: proc(a,b : ^Object){
    delta := (a.pos - b.pos)
    temp := l.dot(delta, delta)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    if(temp < temp_max-Error){
        midpoint := (a.pos + b.pos) *0.5
        tempa := a.pos - midpoint
        tempb := b.pos - midpoint
        /*
        if(tempa == {0,0}){
            tempb = l.normalize(tempb)
            tempa = -1*tempb
        }else {
            tempa = l.normalize(tempa)
            tempb = -1*tempa
        }
        */
        tempb = l.normalize(tempb)
        tempa = -1*tempb
        a.pos = midpoint + (tempa * (a.rad+Error))
        b.pos = midpoint + (tempb * (b.rad+Error))
        //total_mass:= a.mass+b.mass
        delta = l.vector_normalize(delta)
        tempa = l.projection(a.vel, delta)
        tempb = l.projection(b.vel, delta)
        a.vel += (tempb - tempa)
        b.vel += (tempa - tempb)
        //a.pos+=(a.vel*0.0000005)
        
    }
}

coll_list_gen :: proc(blocks :[dynamic][Depth]MyInt, index:MyInt, new_pairs: ^[dynamic][2]MyInt){
    if(blocks[index][1] == -1){// quick exit, seeing if there is more than one object in a block
        return
    }
    //fmt.println(blocks[index])
    Num_in_buck:int = 2
    for i in 1..<Depth{
        if(blocks[index][i] == -1){
            break
        }
        Num_in_buck +=1
    }
    temp:[2]MyInt
    for i in 0..<(Num_in_buck-2){
        for j in i..<(Num_in_buck-1){
            temp[0] = blocks[index][i]
            temp[1] = blocks[index][j]
            if(temp[0] != temp[1]){
                append(&new_pairs^, temp)
            }
        }
    }
    //fmt.println(new_pairs)
    return
}
coll_fun ::proc(blocks :[dynamic][Depth]MyInt, index:MyInt, Ob_list:[dynamic]Object){
    if(blocks[index][1] == -1){// quick exit, seeing if there is more than one object in a block
        return
    }
    //fmt.println(blocks[index])
    Num_in_buck:int = 2
    for i in 1..<Depth{
        if(blocks[index][i] == -1){
            break
        }
        Num_in_buck +=1
    }
    temp:[2]MyInt
    for i in 0..<(Num_in_buck-2){
        for j in i..<(Num_in_buck-1){
            temp[0] = blocks[index][i]
            temp[1] = blocks[index][j]
            if(temp[0] != temp[1]){
                collision(&Ob_list[temp[0]], &Ob_list[temp[1]])
            }
        }
    }
}

edge_coll::proc(a: ^Object){
    if(a.pos[0]+a.rad > max_x){ //right edge
        a.pos[0] = max_x - a.rad
        a.vel[0] *= -1
    } else if(a.pos[0]-a.rad <0){ //left edge
        a.pos[0] = a.rad
        a.vel[0] *= -1
    }
    if(a.pos[1]+a.rad > max_y){ // bottom edge
        a.pos[1] = max_y - a.rad
        a.vel[1] *= -1
        //a.force[1] -= Gravity
    }else if(a.pos[1]-a.rad < 0){//top edge
        a.pos[1] = a.rad
        a.vel[1] *= -1
    }
    //return na
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

    
    rad:f32 = 2
    tempsad :[9]MyInt = {-1,-1,-1,-1,-1,-1,-1,-1,-1}
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
    num1:f32
    num2:f32
    for i in 0..<200{
        for j in 0..<250{
            num1 = 0.01
            num2 = 0.0
            //fmt.println(num1, num2)
            temp_obj = {{(03.0+(cast(f32)j*5.5)),(3.0+(cast(f32)i*5.5))},{num1,num2},rad}
            append(&Object_list, temp_obj)
        }
    }
    
    for i in 0..<200{
        for j in 0..<250{
            temp_obj = {{(12.0+(cast(f32)j*5.5)),(7.0+(cast(f32)i*5.5))},{0.325,0.25},rad}
            append(&Object_list, temp_obj)
        }
    }
    
    
    
    
    
    

    length := len(Object_list)

    tempx:i32
    tempy:i32
    tempr:f32
    
    rl.InitWindow((auto_cast window_width), (auto_cast window_height), "Bloop")
    image:rl.Image = rl.LoadImage("output2.png")
    rl.ImageColorTint(&image, rl.BLUE)
    texture:rl.Texture2D = rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)
    scale:= ((rad*2)-1)/(auto_cast Image_sideLeng)
    

    rl.SetTargetFPS(60)
    temp, temp2:Object
    temppos: Vector2f32
    
    game_loop: for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        for i in 0..<length{
            //temppos = Object_list[i].pos
            rl.DrawTextureEx(texture, (Object_list[i].pos-Object_list[i].rad), 0.0, scale, rl.WHITE)
            update(&Object_list[i],&tempsad)
            //need to find a faster insertion of indicies
            for a in 0..<9{
                col1: for t in 0..<Depth{
                    if(Coll_bloc[tempsad[a]][t] == auto_cast i){
                        break col1
                    }else if(Coll_bloc[tempsad[a]][t] == -1){
                        Coll_bloc[tempsad[a]][t] = auto_cast i
                        break col1
                    }
                }
            }
        }
        for i in 0..<num_buckets{   
            coll_fun(Coll_bloc, i, Object_list)
            for j in 0..<Depth{
                Coll_bloc[i][j] = -1
            }
        }
        fmt.println(rl.GetFPS())
        rl.EndDrawing()
    }
    rl.CloseWindow()
        
}

