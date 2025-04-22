
CameraDefaultDirection = [1;0;0]
CameraRotation = [0;0;0]
CameraPosition = [0;0;0]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = [200;150]#[800;600]

#LIGHT SOURCE aka SUN

lightSources = [
    [3, 4, 6],
]
lightColor = [RGB{N0f8}(1, 1, 1)]
lightPower = [7]


#SCENE OBJECTS AND THEIR DERIVATIVES
s1P = [10.0, 0.0, 2.0, 3.0] #light blue sphere
Sphere1(X) = (X[1] - s1P[1])^2 + (X[2] - s1P[2])^2 + (X[3] - s1P[3])^2 - s1P[4]^2
GradS1(X) = [2*(X[1]-s1P[1])  2*(X[2]-s1P[2])  2*(X[3]-s1P[3])]


Plane1(X) = X[1]*0 + X[2]*0 + X[3]*1 + 3 #SPODI
GradP1(X) = [0 0 1]



# x+forward, y+down, z+left
#objects je sestavljen tako: [Funkcija, Gradient, isReflective. color, isPassThrough]
Objects = [
    [Sphere1, GradS1, RGB{N0f8}(0,1,1), false, false],
    [Plane1, GradP1, RGB{N0f8}(1,1,1), false, false]
]
mattObjects = []