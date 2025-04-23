#[Postran(Rotacija v smeri urinega kazalca, 90 = glava na levi rami);
#(90 = dol, -90 = gor) ; 
#(-90 = levo, 90 = desno) ]

# Za kot do objekta [x,y,z] z = arcsin(X[2]/(dolzina do sredisca objekta))
#                         y = - arcsin(X[2]/(dolzina do sredisca objekta)) NE POZABIT MINUSA !!!!
# KAMERA in resolucija
#-------------------------------------------------------------

#-------------------------------------------------------------
LightSource = [
    #Tocka, moc
    [[15,-8,7.5],30],
    [[15,8,7.5],30],
    [[8,4,4],30]
    #[[0,0,0],0]
]

t1 = [10, 0, 2]
r1 = 4
 
Sphere1(X) = (X[1]-t1[1])^2 + (X[2]-t1[2])^2 + (X[3]-t1[3])^2 - r1^2
GradSphere1(X) = [2*(X[1]-t1[1]),  2*(X[2]-t1[2]),  2*(X[3]-t1[3])] 


t2 = [5, -3.5, 2]
r2 = 1
Sphere2(X) = (X[1]-t2[1])^2 + (X[2]-t2[2])^2 + (X[3]-t2[3])^2 - r2^2
GradSphere2(X) = [2*(X[1]-t2[1]),  2*(X[2]-t2[2]),  2*(X[3]-t2[3])] 

t3 = [3, -2, -1]
r3 = 0.65

Sphere3(X) = (X[1]-t3[1])^2 + (X[2]-t3[2])^2 + (X[3]-t3[3])^2 - r3^2
GradSphere3(X) = [2*(X[1]-t3[1]),  2*(X[2]-t3[2]),  2*(X[3]-t3[3])] 

spt4 =[5,1.5,-1,1]
sr4 = 1

Sphere4(X) = (X[1]-spt4[1])^2 + (X[2]-spt4[2])^2 + (X[3]-spt4[3])^2 - sr4^2
GradSphere4(X) = [2*(X[1]-spt4[1]),  2*(X[2]-spt4[2]),  2*(X[3]-spt4[3])] 


# Tla
t4 = [0,0,-5]
v1 = [1,0,0]
v2 = [0,1,0]
n = cross(v1,v2)

Tla(X)=(X[1] - t4[1])*n[1] + (X[2] - t4[2])*n[2] + (X[3] -t4[3])*n[3]
N1(X)= [n[1], n[2], n[3]]
#desna stena
t5 = [0,10,0]

v3 = [1,0,0]
v4 = [0,0,1]
n2 = cross(v3,v4)

DesnaStena(X)=(X[1] - t5[1])*n2[1] + (X[2] - t5[2])*n2[2] + (X[3] -t5[3])*n2[3]
N2(X)= [n2[1], n2[2], n2[3]]

#leva stena
t6 = [0,-10,0]

v1 = [0,0,1]
v2 = [1,0,0]
n3 = cross(v1,v2)

LevaStena(X)=(X[1] - t6[1])*n3[1] + (X[2] - t6[2])*n3[2] + (X[3] -t6[3])*n3[3]
N3(X)= [n3[1], n3[2], n3[3]]

#sredinjski zid
t7 = [20,0,0]
v1 = [0,0,1]
v2 = [0,1,0]
n4 = cross(v1,v2)

ZadnjaStena(X)=(X[1] - t7[1])*n4[1] + (X[2] - t7[2])*n4[2] + (X[3] -t7[3])*n4[3]
N4(X)= [n4[1], n4[2], n4[3]]

#strop 
t8 = [0,0,10]

v1 = [0,1,0]
v2 = [1,0,0]
n5 = cross(v1,v2)

Strop(X)=(X[1] - t8[1])*n5[1] + (X[2] - t8[2])*n5[2] + (X[3] -t8[3])*n5[3]
N5(X)= [n5[1], n5[2], n5[3]]

t9 = [15,0,0]

TorusR = 3
Torusr = 2
#(TorusR - sqrt((X[1] - t9[1])^2 + (X[2]- t9[2] )^2))^2 + (X[2] - t9[2])^2 -Torusr^2
#[-2(TorusR- sqrt((X[1] - t9[1])^2 + (X[2]- t9[2] )^2))*(X[1]/sqrt((X[1] - t9[1])^2 + (X[2]- t9[2] )^2)),-2*(TorusR-sqrt((X[1] - t9[1])^2 + (X[2]- t9[2] )^2))*(X[2]/sqrt((X[1] - t9[1])^2 + (X[2]- t9[2] )^2)) ,2*X[3] ]
#Torus(X)= (TorusR - sqrt((X[1] - t9[1])^2 + (X[2]- t9[2] )^2))^2 + (X[2] - t9[2])^2 -Torusr^2
#X - Axis
Torus(X) = ((X[1] - t9[1] )^2 +(X[2]- t9[2])^2 + (X[3] - t9[3] )^2+ TorusR^2 - Torusr^2)^2 - 4*(TorusR^2)*((X[2] - t9[2] )^2 +(X[3] - t9[3])^2)
GradTorus(X) = [4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2))*( X[1]- t9[1] ) ,
                4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2))*( X[2]- t9[2] ) - 8*(TorusR^2)*(X[2] - t9[2]),
                4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2))*( X[3]- t9[3] ) - 8*(TorusR^2)*(X[3] - t9[3])
                ]
"""
                GradTorus(X) = [4*(X[1] - t9[1])*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2)^2 ) ,
                4*(X[2] - t9[2])*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2)^2 - 2*(TorusR^2) ),
                4*(X[3] - t9[3])*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2)^2 - 2*(TorusR^2) )
                ]
"""
#println("Torus na središču: ",Torus([8.1,0,0]))
#println("sing + ",sign(+3.0)," ",sign(Torus([8.1,0,0])),"  ",sign(-3))

#Y - Axis
"""
Torus(X) = ((X[1] - t9[1] )^2 +(X[2]- t9[2])^2 + (X[3] - t9[3] )^2+ TorusR^2 - Torusr^2)^2 - 4*(TorusR^2)*((X[1] - t9[1] )^2 +(X[3] - t9[3])^2)
GradTorus(X) = [4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3] )^2+ TorusR^2 - Torusr^2)^2)*( X[1]- t9[1] ) ,
                4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2)^2)*( X[2]- t9[2] ) - 8*(TorusR^2)*(X[2]- t9[2] ),
                4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2)^2)*( X[3]- t9[3] ) - 8*(TorusR^2)*(X[3] - t9[3])
                ]
"""
# Z -axis
"""
Torus(X) = ((X[1] - t9[1] )^2 +(X[2]- t9[2])^2 + (X[3] - t9[3] )^2+ TorusR^2 - Torusr^2)^2 - 4*(TorusR^2)*((X[1] - t9[1] )^2 +(X[2] - t9[2])^2)
GradTorus(X) = [4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3] )^2+ TorusR^2 - Torusr^2))*( X[1]- t9[1] ) - 8*(TorusR^2)*(X[1] - t9[1]),
                4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2))*( X[2]- t9[2] ) - 8*(TorusR^2)*(X[2]- t9[2] ),
                4*(((X[1] - t9[1])^2 +(X[2] - t9[2])^2 + (X[3] - t9[3])^2+ TorusR^2 - Torusr^2))*( X[3]- t9[3] ) 
                ]
"""
Objects = [
    #[Function   ,Gradient    ,Barva                    ,Mirror,Steklo]
    #[Sphere1    ,GradSphere1,RGB{Float64}(0.1,0.1,1.0),false ,true],
    #[Sphere2    ,GradSphere2,RGB{Float64}(0.0,1.0,1.0),false ,false],
    #[Sphere3    ,GradSphere3,RGB{Float64}(0.0,0.0,1.0),false ,false],
    #[Sphere4    ,GradSphere4,RGB{Float64}(0.0,0.0,1.0),false ,false],
    [Tla        ,N1         ,RGB{Float64}(1.0,1.0,1.0),false  ,false],
    [DesnaStena ,N2         ,RGB{Float64}(1.0,0.0,0.0),false  ,false],
    [LevaStena  ,N3         ,RGB{Float64}(1.0,1.0,0.0),false  ,false],
    [ZadnjaStena,N4         ,RGB{Float64}(1.0,0.0,1.0),false  ,false],
    [Strop      ,N5         ,RGB{Float64}(0.0,1.0,1.0),false  ,false],
    [Torus      ,GradTorus  ,RGB{Float64}(0.0,1.0,1.0),false   ,false],
    []
]

bg_color = RGB{Float64}(0.1,0.1,0.1)  # sky blue
