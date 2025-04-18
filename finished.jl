using LinearAlgebra, StaticArrays, Images, ColorTypes, CUDA

# CAMERA FUNCTIONS
function createPixels(CameraResolution, CameraAspectRatio, CameraFOV)
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

    Pixels = normalize.(Pixels);
    
    return Pixels
end
function CameraLookTowards(CameraRotation, CameraDirection, CameraPosition)
    pos = CameraDirection .- CameraPosition
    CameraRotation[3] = rad2deg(atan(pos[2]/pos[1]))
    CameraRotation[2] = rad2deg(atan(pos[3]/pos[1]))
end
function euler_to_rotation_matrix(θx, θy, θz)
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
    return Rz * Ry * Rx
end
function RotateCamera(Pixels, CameraResolution, CameraRotation, CameraDirection, CameraPosition)
    
    if CameraDirection != [1;0;0]
        CameraLookTowards(CameraRotation, CameraDirection, CameraPosition)
    end

    rot = euler_to_rotation_matrix(deg2rad(CameraRotation[1]), deg2rad(CameraRotation[2]),  deg2rad(CameraRotation[3]))

    for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
        Pixels[i,j] = rot*Pixels[i,j]
    end
end
function CreateCamera(CameraResolution, CameraAspectRatio, CameraFOV, CameraRotation = [0.0;0.0;0.0], CameraDirection = [1;0;0], CameraPosition = [0;0;0])
    Pixels = createPixels(CameraResolution, CameraAspectRatio, CameraFOV)

    if CameraRotation != [0.0;0.0;0.0]
        RotateCamera(Pixels, CameraResolution, CameraRotation, CameraDirection, CameraPosition)
    end

    return Pixels
end








# OBJECT FUNCTIONS
@enum ObjectType Sphere Plane
struct Object
    type::ObjectType
    xyz::SVector{3, Float32}
    c::Float32
end
@inline function f(obj::Object, vec::SVector{3, Float32})
    if obj.type == Sphere
        return functionSphere(obj, vec)
    elseif obj.type == Plane
        return functionPlane(obj, vec)
    end
    return 0.0f0
end
@inline function gradf(obj::Object, vec::SVector{3, Float32})
    if obj.type == Sphere
        return gradientSphere(obj, vec)
    elseif obj.type == Plane
        return gradientPlane(obj, vec)
    end
    return SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
end
# Sphere
@inline function functionSphere(obj::Object, p::SVector{3, Float32})
    return (p[1] - obj.xyz[1])*(p[1] - obj.xyz[1]) + (p[2] - obj.xyz[2])*(p[2] - obj.xyz[2]) + (p[3] - obj.xyz[3])*(p[3] - obj.xyz[3]) - obj.c^2
end
@inline function gradientSphere(obj::Object, p::SVector{3, Float32})
    return SVector{3, Float32}(2f0*(p[1] - obj.xyz[1]), 2f0*(p[2] - obj.xyz[2]), 2f0*(p[3] - obj.xyz[3]))
end
# Plane
@inline function functionPlane(obj::Object, p::SVector{3, Float32})
    return obj.xyz[1]*p[1] + obj.xyz[2]*p[2] + obj.xyz[3]*p[3] + obj.c
end
@inline function gradientPlane(obj::Object, p::SVector{3, Float32})
    return SVector{3, Float32}(obj.xyz)
end




function signChange_kernel(cam::SVector{3, Float32}, ray::SVector{3, Float32}, obj::Object)
    t_approx::Float32 = -1.0f0

    step = 0.5f0
    maxdist = 1000.0f0
    t_prev = 1.0f0
    temp::SVector{3, Float32} = (cam[1] + t_prev*ray[1], cam[2] + t_prev*ray[2], cam[3] + t_prev*ray[3])
    prev_val::Float32 = f(obj, temp)

    t = step
    while t <= maxdist
        p::SVector{3, Float32} = (cam[1] + t*ray[1], cam[2] + t*ray[2], cam[3] + t*ray[3])
        val::Float32 = f(obj, p)

        if val * prev_val < 0f0
            t_approx = (t + t - step) / 2f0
            break
        end
        prev_val = val
        t += step
    end

    return t_approx
end
function newton_kernel(cam::SVector{3, Float32}, ray::SVector{3, Float32}, obj::Object, t::Float32)
    maxit = 100
    tol = 0.00001f0

    for iter in 1:maxit
        pt::SVector{3, Float32} = (cam[1] + t*ray[1], cam[2] + t*ray[2], cam[3] + t*ray[3])       
        fval::Float32 = f(obj, pt)
        grad::SVector{3, Float32} = gradf(obj, pt)
        d = grad[1]*ray[1] + grad[2]*ray[2] + grad[3]*ray[3]  # dot product

        if d == 0f0
            break  # Avoid divide by zero
        end

        t_next = t - fval / dm
        if abs(t_next - t) < tol
            t = t_next
            break
        end
        t = t_next
    end
    
    return t;
end
function closestIntersection_kernel(cam::SVector{3, Float32}, ray::SVector{3, Float32}, Objects::AbstractVector{Object}, NumberOfObjects::Int32)
    min_t::Float32 = 1.0f10
    obj_index::Int32 = 0

    for k in 1:NumberOfObjects
        obj::Object = Objects[k];
        t_approx::Float32 = signChange_kernel(cam, ray, obj)
        if t_approx != -1.0
            t::Float32 = newton_kernel(cam, ray, obj, t_approx)

            if t > 0f0 && t < min_t
                min_t = t
                obj_index = k
            end
        end
    end
    
    if obj_index != 0
        return SVector{2, Float32}(min_t, Float32(obj_index))
    else
        return SVector{2, Float32}(-1.0f0, 0.0f0)
    end
end


#function multiplyColors(color1::RGB{N0f8}, color2::RGB{N0f8})
#    redC = red(color1) * red(color2)
#    greenC = green(color1) * green(color2)
#    blueC = blue(color1) * blue(color2)
#    return RGB{N0f8}(redC, greenC, blueC)
#    
#end



# MAIN KERNEL
function raytrace_kernel(CameraPosition::SVector{3, Float32}, Pixels::CuDeviceMatrix{SVector{3, Float32}}, NumberOfObjects::Int32, Objects::CuDeviceVector{Object}, Image)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    W = size(Pixels, 1)
    H = size(Pixels, 2)
    if i <= W && j <= H
        ray::SVector{3, Float32} = ((Pixels[i, j])[1], (Pixels[i, j])[2], (Pixels[i, j])[3])

        res::SVector{2, Float32} = closestIntersection_kernel(CameraPosition, ray, Objects, NumberOfObjects)
        
        light::SVector{3, Float32} = (1.0f0, 1.0f0, -1.0f0)
        color::SVector{3, Float32} = (0.243137f0, 1.0f0, 0.0f0)
        if res[1] == -1.0
            Image[j,i] = SVector{3, Float32}(0.8f0, 0.9f0, 1.0f0);
        else
            point::SVector{3, Float32} = SVector{3, Float32}(CameraPosition[1] + res[1]*ray[1], CameraPosition[2] + res[1]*ray[2], CameraPosition[3] + res[1]*ray[3])
            obj::Object = Objects[Int32(res[2])];
            gr::SVector{3, Float32} = gradf(obj, point)
            koef::Float32 = acos(dot(normalize(light), normalize(gr)))
            if koef >= (Float32(pi)/2.0f0) && koef <= (3.0f0*Float32(pi))/2.0f0
                intensity::Float32 = cos(abs(Float32(pi)-koef))
                Image[j,i] = SVector{3, Float32}(intensity*color[1], intensity*color[2], intensity*color[3])
            else
                Image[j,i] = SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
            end
        end
        
    end
    return
end





# CAMERA
CameraDirection = [1;0;0]
CameraRotation = [0.0;0.0;0.0]
CameraPosition = [0.0;0.0;0.0]
CameraFOV = 60
CameraAspectRatio = [16;10]
CameraResolution = [3840;2400]#[800;600]
Pixels = CreateCamera(CameraResolution, CameraAspectRatio, CameraFOV, CameraRotation, CameraDirection, CameraPosition);

# OBJECTS
NumberOfObjects = 2
Objects_host = [Object(Sphere, (5.0f0, 0.0f0, 0.0f0), 1.0f0), Object(Plane, (0.0f0, 0.0f0, 1.0f0), 3.0f0)]
Objects = CuArray(Objects_host)

# LIGHT
#sun = [-10.0, 4.0, 10.0]


#Intersections = CUDA.fill(SVector(-1.0f0, 0.0f0), CameraResolution[1], CameraResolution[2])
Rays = CuArray([SVector{3, Float32}(Pixels[i,j]...) for i in 1:CameraResolution[1], j in 1:CameraResolution[2]]);
Image = CUDA.fill(SVector(0.0f0, 0.0f0, 0.0f0), CameraResolution[2], CameraResolution[1])

# LAUNCH RAYTRACER
threads = (16, 16)
blocks = (cld(CameraResolution[1], threads[1]), cld(CameraResolution[2], threads[2]))
@cuda threads=threads blocks=blocks raytrace_kernel(
    SVector{3, Float32}(CameraPosition),
    Rays, 
    Int32(NumberOfObjects), 
    Objects,
    Image
)





# CREATE IMAGE
jImage = Array(Image)
Img = Array{RGB{N0f8}}(undef, CameraResolution[2], CameraResolution[1])
for i = 1:CameraResolution[2], j = 1:CameraResolution[1]
    Img[i,j] = RGB{N0f8}((jImage[i,j])[1], (jImage[i,j])[2], (jImage[i,j])[3])
end
save("scene.png", Img)
