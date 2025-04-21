CameraDefaultDirection = [1;0;0]
CameraRotation = [45;0;0]
#CameraPosition = [0;0;0]
CameraPosition = [5;5;5]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = CameraAspectRatio.*100 #[800;600]

#LIGHT SOURCE aka SUN
lightSources = [
    #[-50.0, 100.0, 200.0],
    [2.0, 100.0, 3.0],
    #[2.0, -50, 3.0]
    #[3.0, -6.0, 0.0]
]

lightColor = [RGB{N0f8}(1, 1, 1),RGB{N0f8}(0, 0, 1), RGB{N0f8}(0, 1, 0)]
lightPower = [100]
abc = [3,2,1]

Elipsoid(X) =((X[1] - eP[1])/abc[1])^2 + ((X[2] - eP[2])/abc[2])^2 + ((X[3] - eP[3])/abc[3])^2 - 1
GradE(X) = [ 2*(X[1]-eP[1])/(abc[1]^2) 2*(X[2]-eP[2])/(abc[2]^2) 2*(X[3]-eP[3])/(abc[3]^2)]

fP = [20,0,0]
F(X) = (cos(X[2]))*sin(X[3]-fP[3]) - (X[1]-fP[1]) 
GradF(X) = [-1 -sin(X[2])*sin(X[3]-fP[3])  (cos(X[2]))*cos(X[3]-fP[3])]

F(X) = (cos(X[2]))*sin(X[3]-fP[3])*5 - (X[1]-fP[1]) 
GradF(X) = [-1 -sin(X[2])*sin(X[3]-fP[3])*5  5*(cos(X[2]))*cos(X[3]-fP[3])]
"""
fP2 = [30,0,0]
F(X) = X[2]*sin(X[3]-fP2[3]) - (X[1]-fP2[1]) 
GradF(X) = [-1 sin(X[3]-fP2[3])  (X[2])*cos(X[3]-fP2[3])]
"""
Plane1(X) = X[1]*0 + X[2]*0 + X[3]*1 +3
GradP1(X) = [0 0 1]

# function Plane1(X)
#     if (X[2] < 4 && X[2] > -3)
#         return X[1]*0 + X[2]*0 + X[3]*1 +3
#     else
#         return 1
#     end
# end
# x+forward, y+down, z+left
#objects je sestavljen tako: [Funkcija, Gradient, isReflective. color, isPassThrough]
Objects = [
  
    #[Elipsoid,GradE,false,RGB{N0f8}(0,0,1),false],
    [F,GradF,false,RGB{N0f8}(1,0,0),false]
    #[F2,GradF2,false,RGB{N0f8}(1,0,0),false],
    #[Plane1, GradP1, false, RGB{N0f8}(1,1,1), false]
]