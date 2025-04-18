CameraDefaultDirection = [1;0;0]
CameraRotation = [0;0;0]
CameraPosition = [0;0;0]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = [200;150]#[800;600]

#LIGHT SOURCE aka SUN
lightSources = [
    [-50.0, 100.0, 200.0],
    #[3.0, 2.5, 1.0],
    #[3.0, -6.0, 0.0]
]
#lightSources = [5.0, 0.0, 3.0]
lightColor = [RGB{N0f8}(1, 1, 1),RGB{N0f8}(0, 0, 1), RGB{N0f8}(0, 1, 0)]
#sun = [-6.0, -15.0, -15.0]   

#SCENE OBJECTS AND THEIR DERIVATIVES
s1P = [10.0, 0.0, 2.0, 4.0] #light blue sphere
Sphere1(X) = (X[1] - s1P[1])^2 + (X[2] - s1P[2])^2 + (X[3] - s1P[3])^2 - s1P[4]^2
GradS1(X) = [2*(X[1]-s1P[1])  2*(X[2]-s1P[2])  2*(X[3]-s1P[3])]

s2P = [5, -3.5, 2, 1] #red sphere
Sphere2(X) = (X[1] - s2P[1])^2 + (X[2] - s2P[2])^2 + (X[3] - s2P[3])^2 - s2P[4]^2
GradS2(X) = [2*(X[1]-s2P[1])  2*(X[2]-s2P[2])  2*(X[3]-s2P[3])]

s3P = [3, -2, -1, 0.65] #green sphere
Sphere3(X) = (X[1] - s3P[1])^2 + (X[2] - s3P[2])^2 + (X[3] - s3P[3])^2 - s3P[4]^2
GradS3(X) = [2*(X[1]-s3P[1])  2*(X[2]-s3P[2])  2*(X[3]-s3P[3])]

s4P = [5, 1.5, -1, 1] #purple sphere
Sphere4(X) = (X[1] - s4P[1])^2 + (X[2] - s4P[2])^2 + (X[3] - s4P[3])^2 - s4P[4]^2
GradS4(X) = [2*(X[1]-s4P[1])  2*(X[2]-s4P[2])  2*(X[3]-s4P[3])]

Plane1(X) = X[1]*0 + X[2]*0 + X[3]*1 +3
GradP1(X) = [0 0 1]
# x+forward, y+down, z+left
#objects je sestavljen tako: [Funkcija, Gradient, isReflective. color, isPassThrough]
Objects = [
    [Sphere1, GradS1, true, RGB{N0f8}(0.5,0.5,0.5), false],  #RGB{N0f8}(0,0.69,0.63)
    [Sphere2, GradS2, false, RGB{N0f8}(1,0,0), false],           #RGB{N0f8}(1,0,0)
    [Sphere3, GradS3, false, RGB{N0f8}(0,1,0), false],
    [Sphere4, GradS4, false, RGB{N0f8}(1.0, 0.0, 1.0), false], 
    [Plane1, GradP1, false, RGB{N0f8}(1,1,1), false]
]