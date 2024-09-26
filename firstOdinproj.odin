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
cell_size:: cast(f32)10

Error :: 0.0135
width::cast(MyInt)((window_width)/(cast(MyInt)cell_size))+1
height::cast(MyInt)((window_height)/(cast(MyInt)cell_size))+1
num_buckets :: cast(MyInt)(width*height)
Image_sideLeng :: 1024
Depth::10

Gravity::0.01
G::5

//Step_func :: {1,0.7,0.2,0.0,0.0,0.0,0.2,0.7,1.0,0.7,0.2,0.0}


Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    force:Vector2f32,
    rad:f32,
    Atract_fact:f32
}

//this function is fine
//takes in Object type, and returns Object of updated position and the hash bucket it belongs in
update :: proc (a :^Object, index:^[9]MyInt){
    a.vel += a.force
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
    a.force = {0,0}
}
//next major source for opt
collision :: proc(a,b : ^Object,Step_func:^[12]f32){
    delta := (a.pos - b.pos)
    temp := l.dot(delta, delta)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    if(temp < temp_max-Error){
        //fmt.println("a")
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
    }/*else if((temp < (temp_max * 2))){
        //fmt.println("b")
        //midpoint := (a.pos + b.pos) *0.5
        //tempa := a.pos - midpoint
        //tempb := b.pos - midpoint
        //tempa = l.vector_normalize(tempa)
        //tempb = l.vector_normalize(tempb)
        index:i32= auto_cast (((temp/temp_max)-1)*11)
        //fmt.println("Normalize distance: ",temp/(temp_max))
        //fmt.println("Index: ", index)
        //fmt.println("Step_fun Value: ", Step_func[index])
        //fmt.println(index)
        tempa := l.projection(a.vel, b.vel)
        tempb := l.dot(tempa, tempa)
        if(tempb > 0){//I need to recheck the math for this such that if the objects are roughly going in the same direction, the object with greater velo will maintain its velo, minus some X for energy loss
                      //given it it "behind", and will attempt to drag along an object if it has lower velo, and is behind it, to try and maintain distance and momentum better
                      //will also include this energy loss within the collision, to emulate the effect of a wall, such that, a single object, with little momentum will not really disrupt the "wall"
            a.vel += a.vel*Step_func[index]
            b.vel += b.vel*Step_func[index]
        }
        //a.vel*=0.99
        //b.vel*=0.99
    }*/
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
coll_fun ::proc(blocks :[dynamic][Depth]MyInt, index:MyInt, Ob_list:[dynamic]Object, Step_func:^[12]f32){
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
                collision(&Ob_list[temp[0]], &Ob_list[temp[1]],Step_func)
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
    }else if(a.pos[1]-a.rad < 0){//top edge
        a.pos[1] = a.rad
        a.vel[1] *= -1
    }
    //return na
}

gen_blocks::proc(blocks: ^[dynamic][Depth]MyInt){
    resize(blocks, (auto_cast (num_buckets)))
    for i in 0..<num_buckets{//initalizing  to -1
        for j in 0..<Depth{
            blocks[i][j] = -1
        }
    }
}

gen_obs::proc(Ob_list: ^[dynamic]Object, Size:f32, Dist:f32 ,cord:[2]f32, Vel:[2]f32, r:[2]MyInt, Af:f32, Shape:MyInt){
    temp_obj:Object= {{0,0},{0,0},{0,0},0,0}
    if(Shape == 0){ //Center based rectangle
        x:f32= cord[0] - ((auto_cast r[0])*Dist)/2
        y:f32 = cord[1] - ((auto_cast r[1])*Dist)/2
        for i in 0..<r[1]{
            for j in 0..<r[0]{
                temp_obj = {{x,y}, Vel, {0,0}, Size, Af}
                append(Ob_list, temp_obj)
                x+= Dist
            }
            y += Dist
            x = cord[0] - ((auto_cast r[0])*Dist)/2
        }
    }else if(Shape ==1){ //left top corner centered
        x:f32 = cord[0]
        y:f32 = cord[1]
        for i in 0..<r[1]{
            for j in 0..<r[0]{
                temp_obj = {{x,y}, Vel, {0,0}, Size, Af}
                append(Ob_list, temp_obj)
                x+= Dist
            }
            y += Dist
            x = cord[0]
        }
    }else if(Shape==2){//allign to circ
       // area:= (cast(f32) num)*Dist
    }
}
get_col::proc(mag:f32) ->(rl.Color){
    temp:f32
    bot:[4]f32 = {100, 100, 100, 255}
    top:[4]f32 = { 190, 33, 55, 255 }
    mid:= (top + bot)*0.5
    s:= (top - bot)*0.5
    if(mag > 2){
        temp=1
    }else{
        temp=(mag/2)-1
    }
    c1 :=(mid + (s*temp))
    c2:rl.Color
    c2[0] = auto_cast c1[0]
    c2[1] = auto_cast c1[1]
    c2[2] = auto_cast c1[2]
    c2[3] = auto_cast c1[3]
    return c2
}

main::proc(){

    rad:f32 = 2
    tempsad :[9]MyInt = {-1,-1,-1,-1,-1,-1,-1,-1,-1}
    Object_list: [dynamic]Object
    Coll_bloc:[dynamic][Depth]MyInt
    gen_blocks(&Coll_bloc)
    /*
    {
        gen_obs(&Object_list, rad, 5, {1200, 1}, {0,0}, {5, 280},1,1)
        //gen_obs(&Object_list, rad, 5, {1000, 1}, {0,0}, {20, 280},1,1)
        //gen_obs(&Object_list, rad, 5, {800, 1}, {0,0}, {20, 280},1,1)
        //gen_obs(&Object_list, rad, 5, {600, 1}, {0,0}, {20, 280},1,1)
        //gen_obs(&Object_list, rad, 5, {400, 1}, {0,0}, {20, 280},1,1)
        //gen_obs(&Object_list, rad, 5, {200, 1}, {0,0}, {20, 280},1,1)
        v:f32=-1.0
        gen_obs(&Object_list, rad, 4,{1500,700}, {v, 0.0}, {1,1}, 1,0)
        gen_obs(&Object_list, rad, 4,{1506,700}, {v, 0.0}, {2,2}, 1,0)
        gen_obs(&Object_list, rad, 4,{1516,700}, {v, 0.0}, {3,3}, 1,0)
        gen_obs(&Object_list, rad, 4,{1530,700}, {v, 0.0}, {4,4}, 1,0)
        gen_obs(&Object_list, rad, 4,{1548,700}, {v, 0.0}, {5,5}, 1,0)
        gen_obs(&Object_list, rad, 4,{1570,700}, {v, 0.0}, {6,6}, 1,0)
        gen_obs(&Object_list, rad, 4,{1596,700}, {v, 0.0}, {7,7}, 1,0)
        gen_obs(&Object_list, rad, 4,{1624,700}, {v, 0.0}, {7,7}, 1,0)
        gen_obs(&Object_list, rad, 4,{1652,700}, {v, 0.0}, {7,7}, 1,0)
        gen_obs(&Object_list, rad, 4,{1680,700}, {v, 0.0}, {7,7}, 1,0)
        gen_obs(&Object_list, rad, 4,{1708,700}, {v, 0.0}, {7,7}, 1,0)
        gen_obs(&Object_list, rad, 4,{1734,700}, {v, 0.0}, {6,6}, 1,0)  
    }
    */
    gen_obs(&Object_list, rad, 4, {300,325}, {1.5,0.05}, {50,50}, 1, 1)
    gen_obs(&Object_list, rad, 4, {2000,575}, {-1.5,-0.05}, {50,50}, 1, 1)

    //gen_obs(&Object_list, rad, 4,{1500,700}, {0.0, 0.0}, {1,1}, 1,0)
    //gen_obs(&Object_list, rad, 4,{1504,700}, {0.0, 0.0}, {1,2}, 1,0)
    //gen_obs(&Object_list, rad, 4,{1508,700}, {0.0, 0.0}, {1,3}, 1,0)
    //gen_obs(&Object_list, rad, 4,{1512,700}, {0.0, 0.0}, {1,4}, 1,0)

    //gen_obs(&Object_list, rad, 12, {500,650}, {0.0, 0.0}, {2,2}, 0)
    //gen_obs(&Object_list, 2.0, 5, {1400,550}, {-0.5, 0.0}, {40,40}, 0)

    length := len(Object_list)

    tempx:i32
    tempy:i32
    tempr:f32
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow((auto_cast window_width), (auto_cast window_height), "Bloop")
    image:rl.Image = rl.LoadImage("output2.png")
    rl.ImageColorTint(&image, rl.WHITE)
    texture:rl.Texture2D = rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)
    scale:= ((rad*2)-1)/(auto_cast Image_sideLeng)
    colors:[7]rl.Color= {rl.SKYBLUE, rl.BLUE, rl.DARKBLUE, rl.DARKPURPLE, rl.PURPLE, rl.VIOLET, rl.RED}
    Step_func:[12]f32 ={0.0,0.0,0.0,-0.00390625,-0.0078125,-0.015625,-0.03125,-0.0,-0.0,-0.0,-0.0,-0.0}

    rl.SetTargetFPS(60)
    mag:f32
    c:rl.Color
    game_loop: for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        for i in 0..<length{
            mag = l.dot(Object_list[i].vel, Object_list[i].vel)
            c = get_col(mag)
            //c = rl.DARKBLUE
            //fmt.println(mag)
            //fmt.println(c)
            rl.DrawTextureEx(texture, (Object_list[i].pos-Object_list[i].rad), 0.0, (scale), c)
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
            coll_fun(Coll_bloc, i, Object_list, &Step_func)
            for j in 0..<Depth{
                Coll_bloc[i][j] = -1
            }
        }
        rl.DrawFPS(10,10)
        rl.EndDrawing()
    }
    rl.CloseWindow()
  }

