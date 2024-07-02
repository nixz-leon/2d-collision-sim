package main

import "core:fmt"
import m "core:math"
import l "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"
import c "core:time"

Vector2f32 :: l.Vector2f32
Error :: 0.0135

Object :: struct{
    pos:Vector2f32,
    vel:Vector2f32,
    force:Vector2f32,
    mass:f32,
    rad:f32
}


collision :: proc(a,b : ^Object){
    delta := (a.pos - b.pos)
    temp := l.dot(delta, delta)
    temp_max := (a.rad + b.rad)*(a.rad + b.rad)
    fmt.println(delta, ", ",temp, ", " ,temp_max)
    if(temp < temp_max-Error){
        midpoint := (a.pos + b.pos) *0.5
        tempa := a.pos - midpoint
        tempb := b.pos - midpoint
        fmt.println("midpoint: ", midpoint)
        fmt.println("tempa: ", tempa)
        fmt.println("tempb: ", tempb)
        if(tempa == {0,0}){
            fmt.println("top_con")
            tempb = l.normalize(tempb)
            tempa = -1*tempb
        }else {
            fmt.println("Bottom_con")
            tempa = l.normalize(tempa)
            tempb = -1*tempa
        }
        fmt.println("tempa: ", tempa)
        fmt.println("tempb: ", tempb)
        /*
        if(a.pos == b.pos){
            fmt.println(a.pos, " vs ", b.pos)
            fmt.println(a.vel, " vs ", b.vel)
            a.pos -= l.normalize(a.vel)*0.01
            //b.pos -= l.normalize(b.vel)*0.01
            fmt.println(a.pos, " vs ", b.pos, " updated")
        }
        tempa := a.pos - midpoint
        tempa = l.normalize(tempa)
        tempb := -1*tempa
        */
        fmt.println("pre_change a pos: ", a.pos)
        fmt.println("pre_change b pos: ", b.pos)
        a.pos = midpoint + (tempa * (a.rad+Error))
        b.pos = midpoint + (tempb * (b.rad+Error))
        delta = a.pos - b.pos
        fmt.println("post_change a pos: ", a.pos)
        fmt.println("post_change b pos: ", b.pos)
        total_mass:= a.mass+b.mass
        fmt.println("Pre_normal_delta: ", delta)
        delta = l.vector_normalize(delta)
        fmt.println("Pre_normal_delta: ", delta)
        proja := l.projection(a.vel, delta)
        projb := l.projection(b.vel, delta)
        fmt.println("Proja: ", proja)
        fmt.println("Projb: ", projb)
        fmt.println("Pre A force", a.force)
        fmt.println("Pre B force", b.force)
        a.force += (projb - proja)
        b.force += (proja - projb)
        fmt.println("Post A force", a.force)
        fmt.println("PostB force", b.force)
        //a.pos+=(a.vel*0.0000005) // step slightly in velocity direction, to encourage better seperatation during the budge
        //budge section
        
    }
}


main::proc(){
    oba:Object={{15.54148, 678.6818},{-1.30083299, -0.56507105},{1.26163876, 0.15832871},1,3}
    obb:Object={{9.5827379, 678.015},{-0.00061762333, -0.7141394},{-1.4490206, 0.57530224},1,3}
    collision(&oba, &obb)
}