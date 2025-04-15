using CUDA
using CUDA: CuArray, @cuda, synchronize
using LinearAlgebra
using Images, ColorTypes, FileIO

# ------------------------------------------------
# Scene Setup (as immutable tuples for GPU use)
# ------------------------------------------------
# Spheres represented as tuples.
# Each sphere is defined as (center, radius, reflective, color)
# where center and color are tuples of Float32.
const spheres = (
    (center = (9.0f0, -3.0f0, -1.0f0), radius = 3.0f0, reflective = 1.0f0, color = (0.0f0, 0.69f0, 0.63f0)),
    (center = (4.5f0,  0.0f0,  2.5f0), radius = 0.75f0, reflective = 0.0f0, color = (1.0f0, 0.0f0, 0.0f0)),
    (center = (4.0f0,  1.0f0, -1.0f0), radius = 0.75f0, reflective = 0.0f0, color = (0.0f0, 1.0f0, 0.0f0))
)

# Plane is represented as a tuple with (normal, d, color).
# The plane equation is: dot(normal, X) + d = 0.
const plane = (normal = (0.0f0, 1.0f0, 0.0f), d = -3.0f0, color = (1.0f0, 1.0f0, 1.0f0))

# Sun direction (assumed normalized)
const sun_dir = ( -0.5f0, -1.0f0, -1.0f0 )  # normalized on host

# ------------------------------------------------
# Camera Parameters (on host)
# ------------------------------------------------
CameraFOV = 90.0
CameraAspectRatio = (4.0, 3.0)          # (width, height)
CameraResolution = (800, 600)           # (width, height)
fx = tan(deg2rad(CameraFOV)/2)
fy = fx * (CameraAspectRatio[2] / CameraAspectRatio[1])
dx = (fx*2) / (CameraResolution[1]-1)
dy = (fy*2) / (CameraResolution[2]-1)

# ------------------------------------------------
# GPU Ray Direction Generation
# ------------------------------------------------
# Allocate a CuArray for the ray directions: dimensions (width, height, 3)
rays_gpu = CuArray{Float32}(undef, CameraResolution[1], CameraResolution[2], 3)

# GPU kernel: compute per-pixel ray directions (unnormalized then normalized)
function compute_rays_kernel!(rays, fx::Float32, dx::Float32, fy::Float32, dy::Float32, width::Int32, height::Int32)
    x = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    y = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    if x < width && y < height
        # use 1-indexing for clarity
        px = Float32(x + 1)
        py = Float32(y + 1)
        r1 = 1.0f0
        r2 = -fx + (px - 1.0f0)*dx
        r3 = fy - (py - 1.0f0)*dy
        mag = sqrt(r1*r1 + r2*r2 + r3*r3)
        rays[x+1, y+1, 1] = r1 / mag
        rays[x+1, y+1, 2] = r2 / mag
        rays[x+1, y+1, 3] = r3 / mag
    end
    return
end

threads_per_block = (16, 16)
blocks_x = cld(CameraResolution[1], threads_per_block[1])
blocks_y = cld(CameraResolution[2], threads_per_block[2])
grid_dims = (blocks_x, blocks_y)

@cuda threads=threads_per_block blocks=grid_dims compute_rays_kernel!(
    rays_gpu, Float32(fx), Float32(dx), Float32(fy), Float32(dy),
    Int32(CameraResolution[1]), Int32(CameraResolution[2])
)
synchronize()

# ------------------------------------------------
# GPU Ray-Tracing Kernel
# ------------------------------------------------
# For each pixel, the kernel casts a ray from the origin in the direction given by rays.
# It computes intersections with all spheres and the plane and shades the hit point using a simple Lambertian model.
function raytrace_kernel!(img, rays, width::Int32, height::Int32, spheres, plane, sun)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    if i < width && j < height
        # Camera origin at (0,0,0)
        orig = (0.0f0, 0.0f0, 0.0f0)
        r1 = rays[i+1, j+1, 1]
        r2 = rays[i+1, j+1, 2]
        r3 = rays[i+1, j+1, 3]
        ray = (r1, r2, r3)
        
        best_t = 1e10f0    # large initial value
        hit_color = (0.4f0, 0.45f0, 0.5f0)  # default background (sky) color

        # --- Sphere Intersections ---
        for s in spheres
            # Unpack sphere parameters
            cx, cy, cz = s.center
            r_radius = s.radius
            # Compute quadratic coefficients for intersection:
            # Ray: orig + t * ray ; Sphere: |(orig + t*ray) - center|^2 = r^2.
            # Since orig = (0,0,0), we have oc = -center.
            oc1 = -cx
            oc2 = -cy
            oc3 = -cz
            a = r1*r1 + r2*r2 + r3*r3  # =1 because ray is normalized, but kept for clarity
            b = 2.0f0*(oc1*r1 + oc2*r2 + oc3*r3)
            c = oc1*oc1 + oc2*oc2 + oc3*oc3 - r_radius*r_radius
            disc = b*b - 4.0f0*a*c
            if disc > 0.0f0
                sqrt_disc = sqrt(disc)
                t1 = (-b - sqrt_disc) / (2.0f0*a)
                t2 = (-b + sqrt_disc) / (2.0f0*a)
                t = t1 > 0.0f0 ? t1 : t2
                if t > 0.0f0 && t < best_t
                    best_t = t
                    # Compute hit point = orig + t*ray
                    hitx = t * r1
                    hity = t * r2
                    hitz = t * r3
                    # Compute normal = (hit - center)
                    nx = hitx - cx
                    ny = hity - cy
                    nz = hitz - cz
                    nmag = sqrt(nx*nx + ny*ny + nz*nz)
                    nx /= nmag; ny /= nmag; nz /= nmag
                    # Lambertian shading: dot(normal, sun)
                    diffuse = max(0.0f0, nx*sun[1] + ny*sun[2] + nz*sun[3])
                    # Use sphere color
                    hit_color = ( s.color[1]*diffuse,
                                  s.color[2]*diffuse,
                                  s.color[3]*diffuse )
                end
            end
        end

        # --- Plane Intersection ---
        # Plane equation: dot(plane.normal, X) + d = 0
        ndot = plane.normal[1]*r1 + plane.normal[2]*r2 + plane.normal[3]*r3
        if abs(ndot) > 1e-6f0
            # t = - (dot(plane.normal, orig) + d) / ndot.  orig is (0,0,0)
            t_plane = - (plane.d) / ndot
            if t_plane > 0.0f0 && t_plane < best_t
                best_t = t_plane
                # For the plane, the normal is constant
                nx, ny, nz = plane.normal
                diffuse = max(0.0f0, nx*sun[1] + ny*sun[2] + nz*sun[3])
                hit_color = ( plane.color[1]*diffuse,
                              plane.color[2]*diffuse,
                              plane.color[3]*diffuse )
            end
        end

        # Write the computed color to the output image.
        img[i+1, j+1, 1] = hit_color[1]
        img[i+1, j+1, 2] = hit_color[2]
        img[i+1, j+1, 3] = hit_color[3]
    end
    return
end

# Allocate an image buffer on the GPU as a 3D CuArray (width × height × 3 for RGB)
img_gpu = CuArray{Float32}(undef, CameraResolution[1], CameraResolution[2], 3)

# Launch the raytracing kernel.
@cuda threads=threads_per_block blocks=grid_dims raytrace_kernel!(
    img_gpu, rays_gpu,
    Int32(CameraResolution[1]), Int32(CameraResolution[2]),
    spheres, plane, sun_dir
)
synchronize()

# ------------------------------------------------
# Retrieve and Save Output Image (on CPU)
# ------------------------------------------------
img_cpu = Array(img_gpu)
width, height, _ = size(img_cpu)
final_img = Array{RGB{N0f8}}(undef, width, height)
for i in 1:width, j in 1:height
    r = clamp01(img_cpu[i,j,1])
    g = clamp01(img_cpu[i,j,2])
    b = clamp01(img_cpu[i,j,3])
    final_img[i,j] = RGB{N0f8}(r, g, b)
end

save("test3_gpu.png", final_img)
println("done")
