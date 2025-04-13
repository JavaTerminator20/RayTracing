using Images, ColorTypes, FileIO, LinearAlgebra

# Image resolution
width = 400
height = 400
aspect_ratio = width / height

# Viewport setup
viewport_height = 2.0
viewport_width = aspect_ratio * viewport_height
focal_length = 1.0  # distance from camera to viewport

# Camera origin
camera_origin = [0.0, 0.0, 1.0]

# Define the sphere
sphere_center = [0.0, 0.0, 0.0]
sphere_radius = 0.7

# Light direction
light_dir = normalize([1.0, -1.0, 1.0])

# Background color
bg_color = RGB{N0f8}(0.8, 0.9, 1.0)  # sky blue

# Create image buffer
img = Array{RGB{N0f8}}(undef, height, width)

# Loop over each pixel
for i in 1:height
    for j in 1:width
        # Compute x, y on the viewport
        u = (j - width/2) * viewport_width / width
        v = (height/2 - i) * viewport_height / height  # flip y for image coordinates

        # Ray direction from camera through pixel
        ray_dir = normalize([u, v, -focal_length])  # looking along -z

        # Ray-sphere intersection
        oc = camera_origin .- sphere_center
        a = dot(ray_dir, ray_dir)
        b = 2.0 * dot(oc, ray_dir)
        c = dot(oc, oc) - sphere_radius^2
        discriminant = b^2 - 4*a*c

        if discriminant < 0
            img[i, j] = bg_color
        else
            t = (-b - sqrt(discriminant)) / (2a)  # nearest hit point
            hit_point = camera_origin .+ t .* ray_dir
            normal = normalize(hit_point .- sphere_center)
            intensity = clamp(dot(normal, normalize(light_dir)), 0.0, 1.0)
            color = RGB{N0f8}(intensity, intensity, intensity)
            img[i, j] = color
        end
    end
end

# Save the image
save("raytraced_sphere_fixed.png", img)
