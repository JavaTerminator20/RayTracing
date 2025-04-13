using Plots
using LinearAlgebra
#using StaticArrays
using Images, ColorTypes, FileIO

plotly()

# origin = [0.0, 0.0, 0.0]

# image_width = 800
# image_height = 600

# for i in -45:1:45
#     angle = deg2rad(i)
#     plot!([0, sin(angle)], [0, 0], [0, cos(angle)], color=:black) 
#     scatter!([sin(angle)], [0], [cos(angle)], color=:red)
# end

# for j in -45:1:45
#     angle = deg2rad(j)
#     plot!([0, 0], [0, sin(angle)], [0, cos(angle)], color=:black)
#     scatter!([0], [sin(angle)], [cos(angle)], color=:red)

# end

# for i in -45:9:45, j in -45:9:45
#     angleLeft = deg2rad(i)
#     angleUp = deg2rad(j)
#     #ce za zadnjo komponento das cos(angle) dobis vektorje tko v kroznico
#     #ce pa das nakoncu neko fiksno vrednost recimo 1 pa dobis da koncne tocke
#     #vseh vektorjev nardijo neko ravnino
#     plot!([0, sin(angleLeft)], [0, sin(angleUp)], [0, 1], color=:black)
# end

#display(fig1)

CameraDefaultDirection = [1;0;0]
CameraRotation = [0;0;0]
CameraPosition = [0;0;0]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = [800;600]#[800;600]

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

#Pixels
Pixels = normalize.(Pixels);

#TESTING RAYS
# fig2 = plot()
# for point in Pixels
#     plot!([0, point[1]], [0, point[2]], [0, point[3]], color=:black)
# end
# scatter!([1], [0], [0], color=:red)
# display(fig2)
println("finished that")
Pixels = normalize.(Pixels)


r = 2
x0 = 5
y0 = 0
z0 = 0

sun = [0, 0, 10]
Sphere(X) = (X[1] - x0)^2 + (X[2] - y0)^2 + (X[3] - z0)^2 - r^2
Plane(X) = (X[1]*0 + X[2]*0 + X[3]*1 - 2)
GradS(X) = [2*(X[1]-x0)  2*(X[2]-y0)  2*(X[3]-z0)]


bg_color = RGB{N0f8}(0.4, 0.45,0.5)  # sky blue
black_color = RGB{N0f8}(0, 0, 0)  # black color
# Create image buffer
img = Array{RGB{N0f8}}(undef, CameraResolution[1], CameraResolution[2])
for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
    img[i,j] = bg_color
end

#do elementov matrik se dostopa: A[x, y]

function signChange(f, vec, step = 0.5, max = 10)
    k = 0
    prev = sign(f(vec))
    for outer k in 1.1:step:max
        now = sign(f(k.*vec))
        if now != prev
            return [(k-step).*vec, k.*vec]
        end
        prev = now;
    end
    return -1
end


function calcAngle(sun, gradient, pointOnSphere)
    normal = gradient(pointOnSphere)
    normal = normalize(normal)

    vecToSun = sun .- pointOnSphere
    vecToSun = normalize(vecToSun)

    #return clamp(dot(normal, vecToSun), 0.0, 1.0)
    koef = acos(dot(normal, vecToSun)); #dot product je med 0 in 1
    if (koef > (pi / 2))
        return 0.0 
    else
        return cos(koef)
    end
end

#USELESS PIECE OF CODE
# function newton(F, JF, X0; tol = 1e-8, maxit = 1000)
#     #X = newton(F, JF, X0, tol, maxit) solves the (nonlinear) 
#     #system F(X) = 0 using the Newton's iteration with initial
#     #guess X0. (JF is the Jacobi matrix of F.)
#     X0_2 = X0
#     #maxit = stevilo iteracij
#     X = X0
#     n = 1
#     for outer n in 1:maxit #outer se uporabi zato, da lahko potem n vkljucimo v izpisu stevile iteracij
#         #izvedemo en korak Newtnove iteracije
#         X = X0 - pinv(JF(X0)) * F(X0)

#         #preverimo ali smo znotraj zahtevane natancnosti
#         if norm(X-X0) + norm(F(X)) < tol #obe vrednosti morajo biti majhne, zato ju sestejemo, njuna vsota mora biti < tol
#             break;
#         end
#         X0 = X #ce nismo prekinili izvajanja for zanke: (vzamemo nov priblizek in delamo z njem)
#     end
#     #opozorilo, ce v maxit se vedno nismo znotraj zahtevane natancnosti
#     if n == maxit
#         @warn "no convergence after $maxit iterations."
#     end
#     #println("starting point: $(X0) convergence: $(X)")
#     return X  #izpis bo izgledal; (sol = resitev, numit = 24)
# end

function Bisection(point1, point2, F, maxit = 1000, tol=1e-6)
    for i in 1:maxit
        middle = (point1 .+ point2) ./ 2
        oddaljenost = F(middle)
        if (abs(oddaljenost) < tol)
            return middle
        end
        if (oddaljenost < 0)
            point2 = middle
        else
            point1 = middle
        end
    end
    
end


println("creating image")
global index = 0
global counter = 0
for y in 1:1:CameraResolution[2]
    for x in 1:1:CameraResolution[1]
        ray = Pixels[x, y]
        #println("drawing ray $(index)/$(CameraResolution[1]*CameraResolution[2]) using ray: $(ray)")
        twoApproxPoint = signChange(Sphere, ray) #dobimo dve tocki, ena je pred objektom, druga v objektu
        if twoApproxPoint != -1
            bisectionPoint = Bisection(twoApproxPoint[1], twoApproxPoint[2], Sphere)
            #najdi kot med normalo in izvirom svetlobe
            koef = calcAngle(sun, GradS, bisectionPoint)
            img[x, y] = RGB{N0f8}(koef, koef, koef)
            global counter += 1
        end
        #println("drawing pixel: $(index)/$(CameraResolution[1]*CameraResolution[2])")
        global index += 1
    end
end
println("done")
println("found: $(counter) dots")
save("test2.png", img)



