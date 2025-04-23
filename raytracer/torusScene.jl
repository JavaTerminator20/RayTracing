
name = "sceneTorus.png"

CameraDirection = [1;0;0]
CameraRotation = [0.0;0.0;0.0]
CameraPosition = [0.0;0.0;0.0]
CameraFOV = 90
CameraAspectRatio = [16;10]
CameraResolution = [3840;2400]


NumberOfLights = 1
Lights_host = [
    Light(Global, 0.0f0, (0.31578, -0.78947, -0.52631), (1.0f0, 1.0f0, 1.0f0))
]


NumberOfObjects = 3
Objects_host = [
    Object(Sphere, (5.0f0, 1.5f0, -1.0f0), 1.0f0, 0.0f0, (1.0f0, 0.0f0, 1.0f0), 1),
    Object(Torus, (12.0f0, -4.5f0, 3.0f0), 1.5f0, 3.0f0, (0.0f0, 1.0f0, 1.0f0), 1),
    Object(Plane, (0.0f0, 0.0f0, 1.0f0), 3.0f0, 0.0f0, (1.0f0, 1.0f0, 1.0f0), 1)
]

