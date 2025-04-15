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
CameraResolution = [200;150]#[800;600]

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
sun = [-200.0, 100.0, 100.0]
lightSources = [
    [-50.0, 100.0, 200.0],
    #[3.0, 2.5, 1.0],
    #[3.0, -6.0, 0.0]
]
#lightSources = [5.0, 0.0, 3.0]
lightColor = [RGB{N0f8}(1, 1, 1),RGB{N0f8}(0, 0, 1), RGB{N0f8}(0, 1, 0)]
#sun = [-6.0, -15.0, -15.0]   

#SCENE OBJECTS AND THEIR DERIVATIVES
s1P = [10.0, 0.0, 2.0, 4.0] #light blue sphere
Sphere1(X) = (X[1] - s1P[1])^2 + (X[2] - s1P[2])^2 + (X[3] - s1P[3])^2 - s1P[4]^2
GradS1(X) = [2*(X[1]-s1P[1])  2*(X[2]-s1P[2])  2*(X[3]-s1P[3])]

s2P = [5, -3.5, 2, 1] #red sphere
Sphere2(X) = (X[1] - s2P[1])^2 + (X[2] - s2P[2])^2 + (X[3] - s2P[3])^2 - s2P[4]^2
GradS2(X) = [2*(X[1]-s2P[1])  2*(X[2]-s2P[2])  2*(X[3]-s2P[3])]

s3P = [3, -2, -1, 0.65] #green sphere
Sphere3(X) = (X[1] - s3P[1])^2 + (X[2] - s3P[2])^2 + (X[3] - s3P[3])^2 - s3P[4]^2
GradS3(X) = [2*(X[1]-s3P[1])  2*(X[2]-s3P[2])  2*(X[3]-s3P[3])]

s4P = [5, 1.5, -1, 1] #purple sphere
Sphere4(X) = (X[1] - s4P[1])^2 + (X[2] - s4P[2])^2 + (X[3] - s4P[3])^2 - s4P[4]^2
GradS4(X) = [2*(X[1]-s4P[1])  2*(X[2]-s4P[2])  2*(X[3]-s4P[3])]

Plane1(X) = X[1]*0 + X[2]*0 + X[3]*1 +3
GradP1(X) = [0 0 1]
# x+forward, y+down, z+left
#objects je sestavljen tako: [Funkcija, Gradient, isReflective. color, isPassThrough]
Objects = [
    [Sphere1, GradS1, true, RGB{N0f8}(0.5,0.5,0.5), false],  #RGB{N0f8}(0,0.69,0.63)
    [Sphere2, GradS2, false, RGB{N0f8}(1,0,0), false],           #RGB{N0f8}(1,0,0)
    [Sphere3, GradS3, false, RGB{N0f8}(0,1,0), false],
    [Sphere4, GradS4, false, RGB{N0f8}(1.0, 0.0, 1.0), false], 
    [Plane1, GradP1, false, RGB{N0f8}(1,1,1), false]
]


bg_color = RGB{N0f8}(0.4, 0.45,0.5)  # sky blue
black_color = RGB{N0f8}(0, 0, 0)  # black color
# Create image buffer
img = Array{RGB{N0f8}}(undef, CameraResolution[2], CameraResolution[1])
for i = 1:CameraResolution[2], j = 1:CameraResolution[1]
    img[i,j] = bg_color
end

#do elementov matrik se dostopa: A[x, y]
#spreminjanje parametra max vpliva na to kako ravno bo zgledala ravnina
#vecji kot je, bolj ravna bo

function multiplyColors(color1, color2)
    color1 = RGB{N0f8}(color1)
    color2 = RGB{N0f8}(color2)
    redC = red(color1) * red(color2)
    greenC = green(color1) * green(color2)
    blueC = blue(color1) * blue(color2)
    return RGB{N0f8}(redC, greenC, blueC)
    
end

function signChange(f, vec, origin = [0.0, 0.0, 0.0], step = 0.3, max = 40)
    k = 1.1
    #dobimo dejanski vektor z upostevanjem zacetne tocke
    start = vec .* k .+ origin 
    prev = sign(f(start))
    if (f == Sphere1)
        #println(prev)
        #println(f((k.*vec) .+ origin))
    end

    for outer k in 1.1:step:max
        now = sign(f((k.*vec) .+ origin))

        if now != prev
            return [((k-step).*vec) .+ origin, (k.*vec) .+ origin]
        end
        prev = now;
    end
    
    return -1
end


function calcAngle(sun, gradient, pointOnSphere, objIndex)
    normal = gradient(pointOnSphere)
    normal = normalize(normal)
    
    stVirov = size(lightSources)[1]
    #factor = 1/stVirov
    factor = 0.7
    koeficienti = []
    for sun in lightSources
        #CE JE SONCE TOCKA
        vecToSun = sun .- pointOnSphere
        vecToSun = normalize(vecToSun)

        #CE SONCE NI TOCKA AMPAK SPLOSNA SMER
        #vecToSun = normalize(sun)

        #preveri ce na poti od tocke na objektu do vira svetlobe zadanes objekt - PREVERJANJE SENCE
        razdaljaDoSonca = norm(pointOnSphere .- sun)
        point_index = closestIntersec(vecToSun, 0.3, razdaljaDoSonca, pointOnSphere)
        intersecPoint = point_index[1]
        intersectIndex = point_index[2]
        if (!isnothing(intersecPoint)) #ce zadanemo nek objekt na poti do sonca
            if (intersectIndex != objIndex) #ce zadanemo nek objekti ki ni ta isti (izhodni - presecisce s samim sabo) 
                #ce pa je ta isti, potem pa mora biti razdalja vecja od 1 da preprecimo napake
                push!(koeficienti, 0.05) #potem samo returnamo 0, ker je v senci oz. 0.05 zradi vec virov svetlobe
                continue
            end
        end

        koef = acos(dot(normal, vecToSun)); #dot product je med 0 in 1
        if (koef > (pi / 2))
            push!(koeficienti, 0.0) 
        else
            push!(koeficienti, cos(koef))
        end

    end

    rezultat = RGB{N0f8}(0, 0, 0)
    n = length(koeficienti)
    for i in 1:1:n
        rezultat = clamp01(rezultat + lightColor[i] * factor * koeficienti[i])
    end

    return clamp01(rezultat)
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

function difuseColor(startingPoint, F, G, step = 0.3, maxD = 5) #F je  objekta, G je gradient
    #zdaj pa narisi vektor iz normale (na objektu) in preveri ali zadane objekt
    #ce zadane, potem izracunaj osvetljenost tega objekta. Na podlagi njegove 
    #osvetljenosti in oddaljenosti od njega dodaj neko kolicino barve v to tocko
    normalVec = vec(normalize(G(startingPoint))) #zato ker G da output [x y z], mi rabimo pa [x, y, z] kar ni isto, tisto ta prvo je matrika, da drugo pa array  
    point_index = closestIntersec(normalVec, 0.4, 5, startingPoint)
    intersectPt = point_index[1]
    objIndex = point_index[2]

    if (isnothing(intersectPt)) #ce ni presecisca, potem ne rabimo dodati nobene barve
        return 0.0
    end

    color = calcAngle(sun, Objects[objIndex][2], intersectPt, objIndex)

    #return 0.2
    disToIntersect = norm(intersectPt .- startingPoint) #bolj tocna vrednost (izboljsana z bisekcijo)
    koef = 1 - disToIntersect / maxD #vrednost bo med 0 in 1, saj gledamo razdaljo do 4e stran
    return koef*color

end

function closestIntersec(direction, step = 1.0, maxD = 40, origin = [0, 0, 0])
    distFromOrigin = 100000.0
    closestPoint = nothing
    #loop cez vse objekte da najdes najblizjega s katerim imamo intersection
    objIndex = 1
    returnIndex = -1
    for object in Objects
        twoApproxPts = signChange(object[1], direction, origin, step, maxD) #dobimo dve tocki, ena je pred objektom, druga v objektu
        if (twoApproxPts != -1) 
            #println("nasli signChange pri objektu: $(object[1])")
            #sem pridemo ce obstaja presecisce
            if (norm(twoApproxPts[1] .- origin) < distFromOrigin) #ce najdemo objekt ki je blizje izhodiscu, potem njega izrisemo (obarvamo)
                distFromOrigin = norm(twoApproxPts[1] .- origin)
                closestPoint = Bisection(twoApproxPts[1], twoApproxPts[2], object[1]) #bolj tocno izracunano presecisce
                returnIndex = objIndex
                #println("nov najbliji je: $(objIndex) z razdaljo $(distFromOrigin)")
            end
        end

        objIndex += 1
    end

    return [closestPoint, returnIndex] #vrnemo presecisce in index objekta ki ga sekamo
end 



function reflectRay(inputVector, pointOnObj, G)
    normala = vec(normalize(G(pointOnObj)))
    odbojniVec = normalize(inputVector .- 2*dot(inputVector, normala)*normala)
    return odbojniVec

end

#ratio = n1/n2  ko gremo iz n1 v n2
#air : 1.0
#water : 1.33
#glass : 1.5
function refractRay(inputVector, ratio, pointOnObj, G) #G je gradient
    normala = vec(normalize(G(pointOnObj)))
    inputVector = normalize(inputVector)
    cosi = clamp(dot(inputVector, normala), -1.0, 1.0)
    if (cosi < 0)  # ce prihajamo zunanje strani krogle
        cosi = -cosi
    else  #ce prihajamo iz znotranje strani krogle
        normala = -normala
        ratio = 1/ratio
    end

    k = 1.0 - ratio^2 * (1.0 - cosi^2) #preverimo ce je refrakcija mogoca
    if (k < 0)
        return nothing
    else
        return ratio * inputVector + (ratio * cosi - sqrt(k)) * normala
    end
   
end

function mirrorBounceColor()
    return nothing
end


reflectivity = 0.5 #koliko barve odbije ogledalo. 0.2 pa je vrednost barve ogledala 0 = matte barva; 1 = glossy (fully reflective)

#tej parametri vplivajo na steklo
ratio = 0.66667  #kolicnik med koef zraka (k=1.0) in koef stekla (k=1.5):  1.0 / 1.5
glassIOR = 1.5  #koeficinet stekla
glassColor = RGB{N0f8}(0.7, 0.85, 1.0)  #barva stekla
tintIntensity = 0.2  #kako zelo se barva stekla pozna
shadowIntensity = 0.4   #kako intenzivno je steklena krogla sencena
reflectBoost = 4  #vecja kot je vrednost, bolj bo intenzivna bara odseva in manj intenzivna barva ki se dobi z lamanjem

#DEJANSKI LOOP KI OBARVA VSAK PIXEL
counter = 0
stVsehPixl = CameraResolution[1] * CameraResolution[2]
percent = stVsehPixl / 100
prcntCounter = 1
println("drawing image")
for x in 1:1:CameraResolution[1]
    for y in 1:1:CameraResolution[2]
        global counter, prcntCounter
        counter += 1
        if (counter % percent == 0)
            println("$(prcntCounter)%")
            prcntCounter += 1
        end

        ray = Pixels[x, y]

        point_index = closestIntersec(ray, 0.5, 80)
        intersectPoint = point_index[1]
        objIndex = point_index[2]
        

        #ce zadanemo neki 
        if (!isnothing(intersectPoint) )
            #------KODA ZA TO CE JE OBJEKT KI SMO GA ZADELI IZ PASSTHROUGH------------------------------------------------------------------------------
            if (Objects[objIndex][5] == true)
                #ta del preracuna reflectColor komponento (barvo ki se dobi od odbitega zarka)
                reflectDir = reflectRay(ray, intersectPoint, Objects[objIndex][2])
                reflect_point_index = closestIntersec(reflectDir, 1.0, 40, intersectPoint)
                reflectPoint = reflect_point_index[1]
                objIndex2 = reflect_point_index[2]

                reflectColor = bg_color
                if (!isnothing(reflectPoint))
                    lightFactor = calcAngle(lightSources, Objects[objIndex2][2], reflectPoint, objIndex2)
                    reflectColor = multiplyColors(Objects[objIndex2][4], lightFactor)
                end

                #ta del preracuna refractColor komponento koncne barve (barvo ki se dobi zaradi zlomljenega zarka)
                ingoingDir = refractRay(ray, ratio, intersectPoint, Objects[objIndex][2])
                if (isnothing(ingoingDir)) #ce se zarek ne more refraktat
                    img[y, x] = reflectColor
                    continue
                end
                
                ingoingDir = ingoingDir ./ 5 #preprecimo da bi bil vektor vecji kot je sam objekt
                if (Objects[objIndex][1](ingoingDir .* 1.1 .+ intersectPoint) > 0)
                    println("vektor gleda vene iz krogle")
                end

                out_point_index = closestIntersec(ingoingDir, 0.2, 100, intersectPoint)
                outPoint = out_point_index[1] #to je tocka na objektu iz katerega pride zarek ven
                outObjIndex = out_point_index[2]


                if (Objects[objIndex][1](outPoint) > 1)
                    println("outTocka ni na krogli-----------------------------------")
                end

                outgoingDir = refractRay(ingoingDir, ratio, outPoint, Objects[outObjIndex][2])
                if (isnothing(ingoingDir)) #ce se zarek ne more refraktat
                    img[y, x] = reflectColor
                    continue
                end
                point_index2 = closestIntersec(outgoingDir, 0.5, 40, outPoint)
                intersectPoint2 = point_index2[1]
                objIndex2 = point_index2[2]

                refractColor = bg_color #ce ne zadanemo nobenega objekta bo refraktna barva barva ozadja, drugace pa barva objekta
                if (!isnothing(intersectPoint2))
                    lightFactor = calcAngle(lightSources, Objects[objIndex2][2], intersectPoint2, objIndex2)
                    refractColor = multiplyColors(Objects[objIndex2][4], lightFactor)
                end

                
                #zdaj pa je treba pravilno zdruziti ti dve barvi v koncen output (neka random formula ko sm jo najdel)
                normala = normalize(vec(Objects[objIndex][2](intersectPoint)))
                ingoingDir = normalize(ingoingDir)
                cosFi = clamp(dot(-ingoingDir, normala), 0.0, 1.0)
                R0 = ((glassIOR - 1.0) / (glassIOR + 1.0))^2
                reflect_ratio = R0 + (1.0 - R0) * (1.0 - cosFi)^5
                
                reflect_ratio *= reflectBoost #ta dodatek pojaca barvo osdibte svetlobe
                refract_ratio = 1.0 - reflect_ratio

                lightFactor = calcAngle(lightSources, Objects[objIndex][2], intersectPoint, objIndex) #to je koeficinet sencenja steklene krogle
                finalColor = clamp01(reflect_ratio * reflectColor + refract_ratio * refractColor) #zmesamo odbito in zlomljeno barvo
                tintedFinalColor = multiplyColors(RGB{N0f8}(finalColor), RGB{N0f8}(glassColor * 0.9)) #izracunamo tinted barvo glede na tint stekla
                finalColor = finalColor * (1-tintIntensity) + tintedFinalColor * tintIntensity #koncni barvi dodamo nekaj tinted barve glede na tintIntensity
                
                shadowedFinalColor = multiplyColors(finalColor, lightFactor)

                finalColor = (1 - shadowIntensity) * finalColor + shadowIntensity * shadowedFinalColor
                img[y, x] = finalColor
                continue

            end

            #-------KODA ZA TO CE JE OBJEKT KI GA JE ZADEL ZAREK OGLEDALO--------------------------------------------------------------------------
            if (Objects[objIndex][3] == true) #ce smo zadeli objekt ki je gledalo
                mirrorIntersect = intersectPoint #tocka na ogledalu
                mirrorIndex = objIndex #indeks ogledala
                bouncedRay = reflectRay(ray, intersectPoint, Objects[objIndex][2])
                bounced_point_index = closestIntersec(bouncedRay, 0.1, 10, intersectPoint)
                intersectPoint = bounced_point_index[1]
                objIndex = bounced_point_index[2]
                
                mirrorLightFactor = calcAngle(lightSources, Objects[mirrorIndex][2], mirrorIntersect, mirrorIndex) #to je koef za osvetlitev objekta ki je ogledalo

                if (isnothing(intersectPoint))  #ce zarek od objekta ni nikjer pristal (je zadel nebo)
                    #barva je sestavljena iz barve neba + barva ogledala
                    bgMirrorColor = multiplyColors(Objects[mirrorIndex][4], mirrorLightFactor) * (1-reflectivity)
                    img[y, x] = clamp01.(bg_color*reflectivity + bgMirrorColor)
                    continue

                else   #ce smo od ogledala se odbili in zadeli nek objekt
                    lightFactor = calcAngle(lightSources, Objects[objIndex][2], intersectPoint, objIndex) #koefcient za osvetltev objekta v katerega smo se odbili
                    #barva pixla bo 80% objekta in 20% od ogledala
                    objColor = multiplyColors(Objects[objIndex][4], lightFactor) * reflectivity
                    mirrorColor = multiplyColors(Objects[mirrorIndex][4], mirrorLightFactor) * (1-reflectivity)
                    pixelColor = clamp01.(objColor + mirrorColor)
                    img[y, x] = pixelColor
                    continue
                
                end
            end

            #------KODA CE JE OBJEKT NI ODBOJEN NITI PROSOJEN---------------------------------------------------------------------------------------------
            #najdi kot med normalo in izvirom svetlobe
            lightFactor = calcAngle(lightSources, Objects[objIndex][2], intersectPoint, objIndex)
            
            #addColor = difuseColor(intersectPoint, Objects[objIndex][1], Objects[objIndex][2])
            #color += addColor

            #koef = min(koef, 1); koef = max(0, koef) #popravek za barvo ce je manj od 0 ali vec od 1 -- mislim da ne rabimo
            img[y, x] = multiplyColors(Objects[objIndex][4], lightFactor)
        end
        
        
    end
end

println("done")
save("test3.png", img)

