using Images
using ColorTypes
using FileIO
using LinearAlgebra
using ProgressMeter

function newton(F, JF, X0; tol = 1e-8, maxit = MaxNewtonIteration)
    # set two variables which will be used (also) outside the for loop
    X = X0
    n = 1
    # first evaluation of F
    Y = F(X)
    
    for outer n = 1:maxit
        # execute one step of Newton's iteration
        X = X0 - JF(X0)\Y
        Y = F(X)
        # check if the result is within prescribed tolerance
        if norm(X-X0) + norm(Y) < tol
            break;
        end
        # otherwise repeat
        X0 = X
    end

    # a warning if maxit was reached
    if n == maxit
        @warn "no convergence after $maxit iterations"
        
    end
    # let's return a named tuple
    return (X = X, n = n)

end

function newtonPoint(v,t0,t,k,Objects;Point = true)
    F = Objects[k][1]
    Grad = Objects[k][2]
    
    Graf(t) = F( (v .*t) .+ t0 )
    dg(t) = dot( v, Grad( (v .*t) .+ t0) )
    
    param = newton(Graf,dg,t).X
    
    t1 = (v .*param) .+ t0
    if Point
        return t1
    else
        return param
    end
end

CameraDefaultDirection = [1;0;0]
CameraRotation = [0;0;0]
CameraPosition = [0,0,0]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = CameraAspectRatio.*100 #[800;600]

include("krofScene.jl"); 
#include("mirrorScene.jl");
#include("glassBallScene.jl");
#include("simpleScene.jl")

NumberOfObjects = size(Objects)[1] -1

#----------------------------------------------------------------
#konstante

MaxDistanceRender = 40      #REDNER distance
step = 1
ShadowIntensity = 20         #manjše kot je bolj je MOČNEJŠA SENCA

SpecularIntensity = 12      #koliko se objekt SVETLIKA (Glassy)

MirrorColorInensity = 0.0   #koliko barve OGLEDALO obdrži
MaxMirorReflectionDepth = 4 #kolikokrat se največkrat žarek odbije iz odgledala v ogledalo

GlassColorIntensity = 0.3   #koliko barve STEKLO obdrži

KoefStekla = 1.5            #yes
KoefZraka = 1.0             #yes

MaxNewtonIteration = 50
#----------------------------------------------------------------
#Kreiranje KAMERO / vsak vektor je pixel
print("Računam Pixel vectorje....")
Pixels = [zeros(3) for i in 1:CameraResolution[1], j in 1:CameraResolution[2]]

fx = tan(deg2rad(CameraFOV) / 2)
fy = fx*(CameraAspectRatio[2]/CameraAspectRatio[1])
dx = (fx*2)/(CameraResolution[1]-1)
dy = (fy*2)/(CameraResolution[2]-1)
for y in 1:1:CameraResolution[2]
    for x in 1:1:CameraResolution[1]
        Pixels[x,y] = [1;-fx+(x-1)*dx;fy-(y-1)*dy]
        
    end
end

#print(Pixels[1,1])
#print(Pixels[70,60])

Pixels = normalize.(Pixels)
#----------------------------------------------------------------
function signChange(f, vec, t0 = [0,0,0], step = step, max = MaxDistanceRender)
    #Preverimo če smo zadeli objekt, to se zgodi ko se predznaj funkciji spremeni
    #RETURN VALUE:(t:koef raztega vektorija vec)
    #       t: Zadeli smo objekt->(vrnemo approximiran razteg)   
    #    -  1: nismo zadeli objekta
    prev = sign(f( t0 .+ vec))
    for i in step:step:max
        now = sign(f( t0 .+ (i .*vec)))
        if now != prev 
            return i - step/2
        end
        prev = now;
    end
    return -1
end
#----------------------------------------------------------------
PixelScalarValues = [[-1.0;0] for i in 1:CameraResolution[1], j in 1:CameraResolution[2]]

@showprogress 1 "Presečišca Vektorjev...." for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
    
    #izbere tistega ki je bližje kameri
    #najblizji = [RaztegKoef,IndxObjekta]
    najblizji = [0,0]
    for k = 1:NumberOfObjects
        F = Objects[k][1] 
        temp = signChange(F, Pixels[i,j],CameraPosition)
        if temp != -1
            temp = newtonPoint(Pixels[i,j],CameraPosition,temp,k,Objects;Point = false)
        end
        if  temp != -1 && ( temp < najblizji[1]  || najblizji[1] == 0)
            najblizji = [temp,k]
        end        
    end
    # najbližji = [0,0] -> nic ni zadel
    k = Int(najblizji[2])
    if k == 0
        PixelScalarValues[i,j] = najblizji
        continue
    end

    najblizji[1] = newtonPoint(Pixels[i,j],CameraPosition,najblizji[1],k,Objects; Point = false)
    
    PixelScalarValues[i,j] = najblizji 
end
#----------------------------------------------------------------------------------------
"""
function euler_to_rotation_matrix(θx, θy, θz)
    # θx = pitch (rotation around X)
    # θy = yaw   (rotation around Y)
    # θz = roll  (rotation around Z)

    Rx = [
        1.0  0.0          0.0;
        0.0  cos(θx)  -sin(θx);
        0.0  sin(θx)   cos(θx)
    ]

    Ry = [
        cos(θy)   0.0  sin(θy);
        0.0       1.0  0.0;
       -sin(θy)   0.0  cos(θy)
    ]

    Rz = [
        cos(θz)  -sin(θz)  0.0;
        sin(θz)   cos(θz)  0.0;
        0.0       0.0      1.0
    ]

    # Combine rotations: R = Rz * Ry * Rx
    return Rz * Ry * Rx
end
#if !(@isdefined test)
#    include("test.jl")
#end
#rot = euler_to_rotation_matrix(deg2rad(CameraRotation[1]), deg2rad(CameraRotation[2]),  deg2rad(CameraRotation[3]))

#for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
    #Pixels[i,j] = rot*Pixels[i,j]
#end
"""

#a