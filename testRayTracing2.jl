using Plots
using LinearAlgebra
#using StaticArrays
using Images, ColorTypes, FileIO

plotly()


CameraDefaultDirection = [1;0;0]
CameraRotation = [0;0;0]
CameraPosition = [0;0;0]
CameraFOV = 90
CameraAspectRatio = [4;3]
CameraResolution = [40;30]#[800;600]

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

#TESTING RAYS
# fig2 = plot()
# for point in Pixels
#     plot!([0, point[1]], [0, point[2]], [0, point[3]], color=:black)
# end
# scatter!([1], [0], [0], color=:red)
# display(fig2)
println("rays are created")

#LIGHT SOURCE aka SUN
sun = [-2, -4, -1]

#SCENE OBJECTS AND THEIR DERIVATIVES
s1P = [7, -1, 0, 2]
Sphere1(X) = (X[1] - s1P[1])^2 + (X[2] - s1P[2])^2 + (X[3] - s1P[3])^2 - s1P[4]^2
GradS1(X) = [2*(X[1]-s1P[1])  2*(X[2]-s1P[2])  2*(X[3]-s1P[3])]

s2P = [5, 0, 2, 0.75]
Sphere2(X) = (X[1] - s2P[1])^2 + (X[2] - s2P[2])^2 + (X[3] - s2P[3])^2 - s2P[4]^2
GradS2(X) = [2*(X[1]-s2P[1])  2*(X[2]-s2P[2])  2*(X[3]-s2P[3])]

Plane1(X) = X[1]*0 + X[2]*1 + X[3]*0 -3
GradP1(X) = [0 -1 0]

Objects = [[Sphere1, GradS1], [Plane1, GradP1]]


bg_color = RGB{N0f8}(0.4, 0.45,0.5)  # sky blue
black_color = RGB{N0f8}(0, 0, 0)  # black color
# Create image buffer
img = Array{RGB{N0f8}}(undef, CameraResolution[1], CameraResolution[2])
for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
    img[i,j] = bg_color
end

#do elementov matrik se dostopa: A[x, y]

function signChange(f, vec, origin = [0.0, 0.0, 0.0], step = 0.3, max = 80)
    k = 1.1
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
        if (signChange(object[1], vecToSun, pointOnSphere, 0.1, 8) != -1) #ce zadanemo nek objekt na poti do sonca
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


function Bisection(point1, point2, F, maxit = 1000, tol=1e-6)
    #zamenjavo tock point1 in point2 naredimo zato, ker je bisekcija napisana tako da
    #predpostavimo da je F(point1) > 0, F(opint2) < 0 .... in ce je ravno obratno
    #moramo zamenjati, drugace bisekcija ne bo konvergirala, ker se bodo meje narobe postavile
    if (F(point1) < 0)
        a = point1
        point1 = point2
        point2 = a
    end
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
    println("NO CONVERGENCE IN BISECTION")
    
end

function difuseColor(startingPoint, F, G, step = 0.3, maxD = 5) #F je enacba objekta, G je gradient
    
normalVec = vec(normalize(G(startingPoint))) #zato ker G da output [x y z], mi rabimo pa [x, y, z] kar ni isto 
#tisto ta prvo je matrika, da drugo pa array  
    color = nothing
    disToIntersect = 10000.0
    intersectPt = nothing
    for object in Objects
        twoApproxPts = signChange(object[1], normalVec, startingPoint, step, maxD)
        if twoApproxPts != -1
            
            if (norm(twoApproxPts[1] .- startingPoint) < disToIntersect)
                disToIntersect = norm(twoApproxPts[1] .- startingPoint)
                intersectPt = Bisection(twoApproxPts[1], twoApproxPts[2], object[1])

                color = calcAngle(sun, object[2], intersectPt)
            end
        end
    end

    if (isnothing(intersectPt)) #ce ni presecisca, potem ne rabimo dodati nobene barve
        return 0.0
    end
    #return 0.2
    disToIntersect = norm(intersectPt .- startingPoint) #bolj tocna vrednost (izboljsana z bisekcijo)
    koef = 1 - disToIntersect / maxD #vrednost bo med 0 in 1, saj gledamo razdaljo do 4e stran

    return koef*color

end

b = signChange(Plane1, [-0.381, 0.26, 0.887], [6.239, -0.48, 1.775], 0.3, 80)

println(b)
Bisection(b[1], b[2], Plane1)
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
                    color = calcAngle(sun, object[2], bisectionPoint)

                    #zdaj pa narisi vektor iz normale (na objektu) in preveri ali zadane objekt
                    #ce zadane, potem izracunaj osvetljenost tega objekta. Na podlagi njegove 
                    #osvetljenosti in oddaljenosti od njega dodaj neko kolicino barve v to tocko
                    addColor = difuseColor(bisectionPoint, object[1], object[2])
                    color += addColor
                    #popravek za barvo ce je manj od 0 ali vec od 1
                    color = min(color, 1); color = max(0, color)
                    img[x, y] = RGB{N0f8}(color, color , color)
                    color += addColor
                    (color > 1) ? color=1 : nothing #popravimo da je vedno color <= 1
                end

            end

        end

    end
end
println("done")
save("test2.png", img)






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

