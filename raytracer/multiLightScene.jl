
name = "sceneMultiLight.png"

CameraDirection = [1;0;0]
CameraRotation = [0.0;0.0;0.0]
CameraPosition = [0.0;0.0;0.0]
CameraFOV = 90
CameraAspectRatio = [16;10]
CameraResolution = [3840;2400]


NumberOfLights = 2
Lights_host = [
    Light(Point, 1000.0f0, (4.0f0, -2.5f0, 5.0f0), (1.0f0, 0.0f0, 0.0f0)),
    Light(Point, 1000.0f0, (4.0f0, 2.5f0, 5.0f0), (0.0f0, 0.0f0, 1.0f0))
]


NumberOfObjects = 2
Objects_host = [
    Object(Sphere, (10.0f0, 0.0f0, 2.0f0), 3.0f0, 0.0f0, (1.0f0, 1.0f0, 1.0f0), 1),
    Object(Plane, (0.0f0, 0.0f0, 1.0f0), 3.0f0, 0.0f0, (1.0f0, 1.0f0, 1.0f0), 1)
]

