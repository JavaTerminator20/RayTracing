CameraDefaultDirection = [1;0;0]
CameraRotation = [0;0;0]
CameraPosition = [0;0;0]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = [800;600]  #[800;600]

#LIGHT SOURCE aka SUN
lightSources = [
    [0.0, 0.0, 15.0],
    #[2.0, -4, 0.0],
    #[3.0, -6.0, 0.0]
]
#lightSources = [5.0, 0.0, 3.0]
lightColor = [RGB{N0f8}(1, 1, 1),RGB{N0f8}(1, 1, 1), RGB{N0f8}(0, 1, 0)]
#sun = [-6.0, -15.0, -15.0]   

#SCENE OBJECTS AND THEIR DERIVATIVES
s4P = [15, 0, 1, 1.3] #purple sphere
Sphere4(X) = (X[1] - s4P[1])^2 + (X[2] - s4P[2])^2 + (X[3] - s4P[3])^2 - s4P[4]^2
GradS4(X) = [2*(X[1]-s4P[1])  2*(X[2]-s4P[2])  2*(X[3]-s4P[3])]

Plane1(X) = X[1]*0 + X[2]*0 + X[3]*1 +3 #SPODI
# function Plane1(X)
#     if (X[2] > -2.8 && X[2] < 2.8)
#         return X[1]*0 + X[2]*0 + X[3]*1 +3
#     else 
#         return 1
#     end
# end
GradP1(X) = [0 0 1]

Plane2(X) = X[1]*1 + X[2]*0 + X[3]*0 + 10 #ZADI
GradP2(X) = [1 0 0]

Plane3(X) = X[1]*1 + X[2]*0 + X[3]*0 - 25 #SPREDI
# function Plane3(X)
#     if (X[2] < 2 && X[2] > -2)
#         return X[1]*1 + X[2]*0 + X[3]*0 - 20
#     else
#         return -1
#     end
# end
GradP3(X) = [-1 0 0]

Plane4(X) = X[1]*0 + X[2]*1 + X[3]*0 + 2 #LEVO
# function Plane4(X)
#     if (X[3] > -2.9 && X[1] < 19)
#         return X[1]*0 + X[2]*1 + X[3]*0 + 2
#     else
#         return 1
#     end
# end
GradP4(X) = [0 1 0]

Plane5(X) = X[1]*0 + X[2]*1 + X[3]*0 - 2 #DESNO
# function Plane5(X)
#     if (X[3] > -2.9 && X[1] < 19)
#         return X[1]*0 + X[2]*1 + X[3]*0 - 2
#     else
#         return -1
#     end
# end
GradP5(X) = [0 -1 0]

# x+forward, y+down, z+left
#objects je sestavljen tako: [Funkcija, Gradient, isReflective. color, isPassThrough]
Objects = [
    [Sphere4, GradS4, false, RGB{N0f8}(1.0, 0.0, 1.0), false], 
    [Plane1, GradP1, false, RGB{N0f8}(1,1,1), false],
    [Plane2, GradP2, false, RGB{N0f8}(0.5, 1, 0.5), false],
    [Plane3, GradP3, false, RGB{N0f8}(0.5, 0.5, 1), false],
    [Plane4, GradP4, true, RGB{N0f8}(1, 1, 0), false],
    [Plane5, GradP5, true, RGB{N0f8}(0, 1, 1), false]
]

mattObjects = [2, 3, 4, 5, 6]