using Plots
using LinearAlgebra
#using StaticArrays
using Images, ColorTypes, FileIO
using Colors

#IMPORT SCENE
#include("./mirrorScene.jl")
#include("./mirrorScene2.jl")
include("./torusScene.jl")
#include("./torusScene2.jl")
#include("./multiLightScene.jl")
#include("./ifiniteMirrorScene.jl")
#include("./funcScene.jl")
#include("./simpleScene.jl")

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

    for outer k in k:step:max
        now = sign(f((k.*vec) .+ origin))
        if now != prev
            #return k - step/2 #vrnemo vmesno vrednost raztega (povprecje tock ko se zamenja predznak)
            return [(k - step/2), (((k-step).*vec) .+ origin), ((k.*vec) .+ origin)]
        end
        prev = now;
    end
    
    return -1
end

#ta metoda v bistvu ne racuna kota ampak izracuna barvo
function calcAngle(sun, gradient, pointOnSphere, objIndex, shadowModifier)
    normal = gradient(pointOnSphere)
    normal = normalize(normal)
    
    stVirov = size(lightSources)[1]
    factor = 1/stVirov #kako mocen bo vsak vir
    powerFactors = []

    #factor = 0.8
    i = 1
    koeficienti = []
    for sun in lightSources
        #CE JE SONCE TOCKA
        vecToSun = normalize(sun .- pointOnSphere)

        #CE SONCE NI TOCKA AMPAK SPLOSNA SMER
        #vecToSun = normalize(sun)

        #preveri ce na poti od tocke na objektu do vira svetlobe zadanes objekt - PREVERJANJE SENCE
        razdaljaDoSonca = norm(pointOnSphere .- sun)
        vrednost = (lightPower[i] / razdaljaDoSonca)^1.2
        push!(powerFactors, vrednost)
        i += 1

        point_index = closestIntersec(vecToSun/4, 1.2, 4*razdaljaDoSonca, pointOnSphere) #za faktor 4 se je vse zamaknilo, zato ker...
        #ce je nek objekt zelo blizu tal, potem bo vecToSun iz podlage kazal skozi ta objekt in nasli bomo napacno presecisce
        intersecPoint = point_index[1]
        intersectIndex = point_index[2]

        koef = acos(dot(normal, vecToSun)); #dot product je med 0 in 1
        if (koef > (pi / 2))
            push!(koeficienti, 0.0)
            continue 
        else
            #ce pridemo sem, potem osvetlimo objekt glede na kot svetlobe, temu pa zmnozimo shadowIntensity
            shadowIntensity = 1 #ce objekt ni v senci, potem se njegova barva ne bo spremenila
            dist = nothing
            if (!isnothing(intersecPoint)) #ce zadanemo nek objekt na poti do sonca - smo v senci
                dist = norm(pointOnSphere - intersecPoint)
                shadowIntensity = clamp01(dist / shadowModifier) #manjsi kot je shadowModifier, bolj svetla bo senca

            end
            push!(koeficienti, shadowIntensity*cos(koef))
        end

    end

    rezultat = RGB{N0f8}(0, 0, 0)
    n = length(koeficienti)
    
    for i in 1:1:n
        rezultat = clamp01(rezultat + lightColor[i] * powerFactors[i] * koeficienti[i])
    end

    return clamp01(rezultat)
end


function SpecularLight(objIndex, pointOnObj, G, vecToCamera, shineIntensity, shineArea)
    if (objIndex in mattObjects) #ce je objekt oznacen kot matt, potem ne dodaj nobene specular svetlobe
        return RGB{N0f8}(0, 0, 0)
    end
    vecToCamera = normalize(vecToCamera)
    lightSrcColor = RGB{N0f8}(0, 0, 0) #sestevek barv vseh virov svetlobe

    koef = 0
    i = 1
    for sun in lightSources
        lightVector = normalize(sun - pointOnObj) #vektor od objekta do vira svetlobe
        reflectedLight = reflectRay(lightVector, pointOnObj, G)
        shininess = shineArea  #vecja cifra pomeni manj specular svetlobe
        
        koef += max(dot(vecToCamera, reflectedLight), 0) ^ shininess

        lightSrcColor += lightColor[i] * koef
        i += 1
    end
    koef = clamp01(koef)
    #return RGB{N0f8}(1,1,1) * (koef * shineIntensity) #ne upostevamo barve svetlobe pri genereranju specular svetlobe
    return lightSrcColor * (koef * shineIntensity) # upostevamo barvo svetlobe pri genereranju specular svetlobe
end

function newton(F, JF, X0; tol = 1e-6, maxit = 30)
    # set two variables which will be used (also) outside the for loop
    X = X0
    n = 1
    # first evaluation of F
    Y = F(X)
    if (abs(Y) < tol)
        return X
    end
    for outer n = 1:maxit
        # execute one step of Newton's iteration
        X = X0 -  JF(X0)\Y
        Y = F(X)
        # check if the result is within prescribed tolerance
        if abs(Y) < tol
            break
        end
        # otherwise repeat
        X0 = X
    end

    # a warning if maxit was reached
    if n == maxit
        #println("no convergence after $maxit iterations")
        return -1
        
    end
    # let's return a named tuple
    return X

end

function newtonPoint(ray, origin, t, objIndex, approxPt1, approxPt2) 
    #t je priblizna vrednost raztega vektorja ray, kjer se nahaja dejanski collision
    F = Objects[objIndex][1]
    G = Objects[objIndex][2]
    
    GFunc(t) = F((ray .*t) .+ origin) #to je parametrizirana F funkcija (paramter t je razteg vektorja iz kamere)
    dg(t) = dot(ray, G((ray .*t) .+ origin))
    
    param = newton(GFunc,dg,t)  #param je razteg osnovnega vektorja (ray) da dobimo tocno tocko
    if param == -1 #ce newtonova metoda ni konvergirala vrni osnovni priblizek
        point = Bisection(approxPt1, approxPt2, F)
        return point
    end

    point = (ray .*param) .+ origin
    return point
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
    return (point1 + point2) ./ 2
    
end


function closestIntersec(ray, step = 0.1, maxD = 60, origin = [0, 0, 0])
    distFromOrigin = 100000.0
    closestPoint = nothing
    #loop cez vse objekte da najdes najblizjega s katerim imamo intersection
    objIndex = 1
    returnIndex = -1
    for object in Objects
        t_P1_P2 = signChange(object[1], ray, origin, step, maxD) #dobimo priblizni razteg vektorja
        approxT = t_P1_P2[1]
        approxVec = (ray .* approxT) .+ origin
        #twoApproxPts = signChange(object[1], ray, origin, step, maxD) #dobimo dve tocki, ena je pred objektom, druga v objektu
        if (approxT != -1) 
            approxPt1 = t_P1_P2[2]
            approxPt2 = t_P1_P2[3]
            #sem pridemo ce obstaja presecisce
            if (norm(approxVec .- origin) < distFromOrigin) #ce najdemo objekt ki je blizje izhodiscu, potem njega izrisemo (obarvamo)
                distFromOrigin = norm(approxVec .- origin)
                #closestPoint = Bisection(twoApproxPts[1], twoApproxPts[2], object[1]) #bolj tocno izracunano presecisce
                closestPoint = newtonPoint(ray, origin, approxT, objIndex, approxPt1, approxPt2)
                returnIndex = objIndex

            end
        end

        objIndex += 1
    end

    return [closestPoint, returnIndex] #vrnemo presecisce in index objekta ki ga sekamo
end 



function reflectRay(inputVector, pointOnObj, G)
    normala = vec(normalize(G(pointOnObj)))
    odbojniVec = normalize(inputVector .- 2*dot(inputVector, normala)*normala)
    return odbojniVec  #returna normaliziran odbojni vektor

end

#ratio = n1/n2  ko gremo iz n1 v n2
#air : 1.0
#water : 1.33
#glass : 1.5
function reflectPoint(point, pointOnObj, G)
    normal = normalize(vec(G(pointOnObj)))
    return point - 2 * dot(point - pointOnObj, normal)* normal
end


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

function mirrorBounceColor(ray, objIndex, pointOnObj, bounces, reflectivity, specularIntensity, specularArea, sun)
    if (Objects[objIndex][3] == false || bounces <= 0) #ce je ta objekt ni ogledalo
        lightFactor = calcAngle(lightSources, Objects[objIndex][2], pointOnObj, objIndex, shadowModifier)
        finalColor =  multiplyColors(Objects[objIndex][4], lightFactor)
        specLight = SpecularLight(objIndex, pointOnObj, Objects[objIndex][2], ray, specularIntensity, specularArea)
        finalColor = clamp01.(finalColor + specLight)
        return finalColor
    else 
        #zadeli smo ogledalo - objIndex je index objekta ki je ogledalo
        mirrorLightFactor = calcAngle(lightSources, Objects[objIndex][2], pointOnObj, objIndex, shadowModifier)
        mirrorColor = multiplyColors(Objects[objIndex][4], mirrorLightFactor)
        bounceRay = reflectRay(ray, pointOnObj, Objects[objIndex][2])
        point_index = closestIntersec(bounceRay, 0.3, 30, pointOnObj)
        intersectPt = point_index[1]
        intersectObjIndex = point_index[2]
        if (isnothing(intersectPt)) #ce odbit zarek ne zadane nicesar vrnemo barvo ozadja + barvo ogledala
            bgMirrorColor = mirrorColor * (1-reflectivity)
            return clamp01.(bg_color*reflectivity + bgMirrorColor)

        else #ce zadanemo nek objekt
            reflectedSun = reflectPoint(sun, pointOnObj, Objects[objIndex][2])
            objectColor = mirrorBounceColor(bounceRay, intersectObjIndex, intersectPt, bounces-1, reflectivity, specularIntensity, specularArea, sun)
            finalColor = clamp01.((1-reflectivity) * mirrorColor + reflectivity * objectColor)
            return finalColor
        end

    end
end

#parametri za sence
shadowModifier = 7 #manjsi kot je shadowModifier, bolj svetla bo senca

#parametri za SpecularLight
specularIntensity = 0.76 #kako mocna bo tista svetla pika
specularArea = 20  #vecja cifra, manjsa povrsina

#parametri za MIRROR
reflectivity = 0.8 #koliko barve odbije ogledalo.  0 = matte barva; 1 = glossy (fully reflective)

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

        point_index = closestIntersec(ray, 0.1, 40)
        intersectPoint = point_index[1]
        objIndex = point_index[2]
        

        #ce zadanemo neki 
        if (!isnothing(intersectPoint) )

            #-------KODA ZA TO CE JE OBJEKT KI GA JE ZADEL ZAREK OGLEDALO--------------------------------------------------------------------------
            if (Objects[objIndex][3] == true)
                fcolor = mirrorBounceColor(ray, objIndex, intersectPoint, 15, reflectivity, specularIntensity, specularArea, lightSources[1])
                img[y, x] = fcolor
                continue
            end

            #------KODA ZA TO CE JE OBJEKT KI SMO GA ZADELI IZ PASSTHROUGH------------------------------------------------------------------------------
            if (Objects[objIndex][5] == true)
                #ta del preracuna reflectColor komponento (barvo ki se dobi od odbitega zarka)
                reflectDir = reflectRay(ray, intersectPoint, Objects[objIndex][2])
                reflect_point_index = closestIntersec(reflectDir, 1.0, 40, intersectPoint)
                reflectedPoint = reflect_point_index[1]
                objIndex2 = reflect_point_index[2]

                reflectColor = bg_color
                if (!isnothing(reflectedPoint))
                    lightFactor = calcAngle(lightSources, Objects[objIndex2][2], reflectedPoint, objIndex2, shadowModifier)
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
                    lightFactor = calcAngle(lightSources, Objects[objIndex2][2], intersectPoint2, objIndex2, shadowModifier)
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

                lightFactor = calcAngle(lightSources, Objects[objIndex][2], intersectPoint, objIndex, shadowModifier) #to je koeficinet sencenja steklene krogle
                finalColor = clamp01(reflect_ratio * reflectColor + refract_ratio * refractColor) #zmesamo odbito in zlomljeno barvo
                tintedFinalColor = multiplyColors(RGB{N0f8}(finalColor), RGB{N0f8}(glassColor * 0.9)) #izracunamo tinted barvo glede na tint stekla
                finalColor = finalColor * (1-tintIntensity) + tintedFinalColor * tintIntensity #koncni barvi dodamo nekaj tinted barve glede na tintIntensity
                
                shadowedFinalColor = multiplyColors(finalColor, lightFactor)

                finalColor = (1 - shadowIntensity) * finalColor + shadowIntensity * shadowedFinalColor
                img[y, x] = finalColor
                continue

            end

            #------KODA CE JE OBJEKT NI ODBOJEN NITI PROSOJEN---------------------------------------------------------------------------------------------
            #najdi kot med normalo in izvirom svetlobe
            lightFactor = calcAngle(lightSources, Objects[objIndex][2], intersectPoint, objIndex, shadowModifier)

            specLight = SpecularLight(objIndex, intersectPoint, Objects[objIndex][2], ray, specularIntensity, specularArea)
            img[y, x] = clamp01(multiplyColors(Objects[objIndex][4], lightFactor) + specLight)
        end
        
        
    end
end

println("done")
save("test3.png", img)

