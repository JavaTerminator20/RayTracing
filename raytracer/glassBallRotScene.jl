
name = "sceneGlassBallRot.png"

CameraDirection = [7;0;2]
CameraRotation = [40.0;0.0;0.0]
CameraPosition = [-2.0;5.5;2.0]#[-10.0;15.0;2.0]
CameraFOV = 90
CameraAspectRatio = [16;10]
CameraResolution = [3840;2400]


NumberOfLights = 1
Lights_host = [
    Light(Global, 0.0f0, (10.0f0, -4.0f0, -10.0f0), (1.0f0, 1.0f0, 1.0f0))
]

NumberOfObjects = 5
Objects_host = [
    Object(Sphere, (7.0f0, 0.0f0, 2.0f0), 3.0f0, 0.0f0, (0.0f0, 0.69f0, 0.63f0), 3),
    Object(Sphere, (20.0f0, -7.0f0, 4.0f0), 5.0f0, 0.0f0, (1.0f0, 0.0f0, 0.0f0), 1),
    Object(Sphere, (3.0f0, -1.5f0,-0.5f0), 0.65f0, 0.0f0, (0.0f0, 1.0f0, 0.0f0), 1),
    Object(Sphere, (25.0f0, 7.0f0, 13.0f0), 6.0f0, 0.0f0, (1.0f0, 0.0f0, 1.0f0), 1),
    Object(Plane, (0.0f0, 0.0f0, 1.0f0), 3.0f0, 0.0f0, (1.0f0, 1.0f0, 1.0f0), 1)
]
