name = "sceneInfMirror.png"

CameraDirection = [1;0;0]
CameraRotation = [0.0;0.0;0.0]
CameraPosition = [0.0;0.0;0.0]
CameraFOV = 90
CameraAspectRatio = [16;10]
CameraResolution = [3840;2400]


NumberOfLights = 1
Lights_host = [
    Light(Point, 10000.0f0, (0.0f0, 0.0f0, 15.0f0), (1.0f0, 1.0f0, 1.0f0))
]

NumberOfObjects = 6
Objects_host = [
    Object(Sphere, (15.0f0, 0.0f0, 1.0f0), 1.3f0, 0.0f0, (1.0f0, 0.0f0, 1.0f0), 1),
    Object(Plane, (0.0f0, 0.0f0, 1.0f0), 3.0f0, 0.0f0, (1.0f0, 1.0f0, 1.0f0), 4),
    Object(Plane, (1.0f0, 0.0f0, 0.0f0), 10.0f0, 0.0f0, (0.5f0, 1.0f0, 0.5f0), 4),
    Object(Plane, (-1.0f0, 0.0f0, 0.0f0), 25.0f0, 0.0f0, (0.5f0, 0.5f0, 1.0f0), 4),
    Object(Plane, (0.0f0, 1.0f0, 0.0f0), 2.0f0, 0.0f0, (1.0f0, 1.0f0, 0.0f0), 2),
    Object(Plane, (0.0f0, -1.0f0, 0.0f0), 2.0f0, 0.0f0, (0.0f0, 1.0f0, 1.0f0), 2)
]

