
name = "sceneMirror.png"

CameraDirection = [1;0;0]
CameraRotation = [0.0;0.0;0.0]
CameraPosition = [0.0;0.0;0.0]
CameraFOV = 90
CameraAspectRatio = [16;10]
CameraResolution = [3840;2400]


NumberOfLights = 1
Lights_host = [
    Light(Global, 0.0f0, (5.0f0, -10.0f0, -20.0f0), (1.0f0, 1.0f0, 1.0f0))
]


NumberOfObjects = 5
Objects_host = [
    Object(Sphere, (10.0f0,0.0f0, 2.0f0), 4.0f0, 0.0f0, (0.5f0, 0.5f0, 0.5f0), 2),
    Object(Sphere, (5.0f0,-3.5f0, 2.0f0), 1.0f0, 0.0f0, (1.0f0, 0.0f0, 0.0f0), 1),
    Object(Sphere, (3.0f0,-2.0f0, -1.0f0), 0.65f0, 0.0f0, (0.0f0, 1.0f0, 0.0f0), 1),
    Object(Sphere, (5.0f0, 1.5f0, -1.0f0), 1.0f0, 3.0f0, (1.0f0, 0.0f0, 1.0f0), 1),
    Object(Plane, (0.0f0, 0.0f0, 1.0f0), 3.0f0, 0.0f0, (1.0f0, 1.0f0, 1.0f0), 1)
]

