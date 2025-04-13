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
CameraResolution = [400;300]#[800;600]

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

Plane(X) = (X[1]*0 + X[2]*0 + X[3]*1 - 2)

#LIGHT SOURCE aka SUN
sun = [0, 0, 10]
s1P = [7, 0, -2, 3]
Sphere1(X) = (X[1] - s1P[1])^2 + (X[2] - s1P[2])^2 + (X[3] - s1P[3])^2 - s1P[4]^2
GradS1(X) = [2*(X[1]-s1P[1])  2*(X[2]-s1P[2])  2*(X[3]-s1P[3])]

s2P = [5, 0, 2, 0.75]
Sphere2(X) = (X[1] - s2P[1])^2 + (X[2] - s2P[2])^2 + (X[3] - s2P[3])^2 - s2P[4]^2
GradS2(X) = [2*(X[1]-s2P[1])  2*(X[2]-s2P[2])  2*(X[3]-s2P[3])]

Objects = [[Sphere2, GradS2], [Sphere1, GradS1]]


bg_color = RGB{N0f8}(0.4, 0.45,0.5)  # sky blue
black_color = RGB{N0f8}(0, 0, 0)  # black color
# Create image buffer
img = Array{RGB{N0f8}}(undef, CameraResolution[1], CameraResolution[2])
for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
    img[i,j] = bg_color
end

#do elementov matrik se dostopa: A[x, y]

function signChange(f, vec, origin = [0, 0, 0], step = 0.3, max = 10)
    k = 0
    #dobimo dejanski vektor z upostevanjem zacetne tocke 
    prev = sign(f(vec .+ origin))
    for outer k in 1.1:step:max
        now = sign(f((k.*vec) .+ origin))
        if now != prev
            return [((k-step).*vec) .+ origin, (k.*vec) .+ origin]
        end
        prev = now;
    end
    return -1
end


function calcAngle(sun, gradient, pointOnSphere)
    normal = gradient(pointOnSphere)
    normal = normalize(normal)

    #CE JE SONCE TOCKA
    # vecToSun = sun .- pointOnSphere
    # vecToSun = normalize(vecToSun)

    #CE SONCE NI TOCKA AMPAK SPLOSNA SMER
    vecToSun = normalize(sun)

    #preveri ce na poti od tocke na objektu do vira svetlobe zadanes objekt
    for object in Objects
        if (signChange(object[1], vecToSun, pointOnSphere, 0.1, 5) != -1) #ce zadanemo nek objekt na poti do sonca
            return 0.0      #potem samo returnamo 0, ker je v senci
        end
    end
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

for y in 1:1:CameraResolution[2]
    for x in 1:1:CameraResolution[1]
        ray = Pixels[x, y]
        distanceToCamera = 1000.0
        for object in Objects
            twoApproxPoint = signChange(object[1], ray) #dobimo dve tocki, ena je pred objektom, druga v objektu
            if twoApproxPoint != -1
                if (norm(twoApproxPoint[1]) < distanceToCamera) #ce najdemo objekt ki je blizje kameri, potem tega izrisemo
                    distanceToCamera = norm(twoApproxPoint[1])
                    bisectionPoint = Bisection(twoApproxPoint[1], twoApproxPoint[2], object[1])
                    #najdi kot med normalo in izvirom svetlobe
                    koef = calcAngle(sun, object[2], bisectionPoint)
                    img[x, y] = RGB{N0f8}(koef, koef, koef)
                end

            end

        end

    end
end
println("done")
println("found: $(counter) dots")
save("test2.png", img)



