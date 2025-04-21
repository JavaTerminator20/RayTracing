include("startup.jl")

LightSource = [
    [3, 4, 10],
]

function calcCollision(v,t0,Objects,k = 0,IgnoreObjIndx = 0)
    #Izračuna kater Objekt zadene najprej
    #RETURN VALUE:
    #   [0,0,false]: Nič ni zadel
    #   [KoefRatzega,IndexObjeta,Collision]: Zadel je objekt z approx raztegom KoefRatzega
    t = 0
    if k != 0
        #Iščemo objekte ki so bližje od k-tega
        t = signChange(Objects[k][1],v, t0)
    end
    #najblizji =[KoefRaztega,IndxObjekta,Ali je Collision]
    najblizji = [t,k,false]
    for i = 1:NumberOfObjects
        if i != IgnoreObjIndx
            temp = signChange(Objects[i][1],v,t0)
            if temp != -1 && ( temp < najblizji[1] || najblizji[1] == 0)
                najblizji = [temp,i,true]
            end
        end
    end
    return najblizji
end

function reflect_ray(v,n)
    v = normalize(v)
    n = normalize(n)
    if dot(v,n) < 0 # v1 = [-1,1] , v2 = [1,-1],  n = [0,1] ; reflectedV1 = reflectedV2
        return normalize(v .- 2*dot(v,n)*n)
    else 
        return normalize(2*dot(v,n)*n .-v)
    end
end

function specular_highlight(kameraVector,t0,Grad,lv,lsource,moc,shininess)
    white = RGB{Float64}(1,1,1)
    v = 0 .- kameraVector # V kaze proti kameri
    n = normalize(Grad(t0))

    reflectedLV = reflect_ray(lv,n)
    
    distance = max(0,1 - ( norm(t0 .- lsource) / (moc*10) ) )
    
    return (white*max(0, dot(v,reflectedLV)*distance)^shininess)
end

function getRGB(koef,rgb,alpha = 1,rgb2 = RGB{Float64}(0,0,0))
        r =  max(0, min(1, (alpha*rgb.r + (1-alpha)*rgb2.r)*(koef) ) )
        g =  max(0, min(1, (alpha*rgb.g + (1-alpha)*rgb2.g)*(koef) ) )
        b =  max(0, min(1, (alpha*rgb.b + (1-alpha)*rgb2.b)*(koef) ) )
        return RGB(r,g,b)
end

function getRGBSum(rgb::RGB{Float64},rgb2::RGB{Float64} = rgb)
    r =  max(0, min(1, (rgb.r + rgb2.r) ) )
    g =  max(0, min(1, (rgb.g + rgb2.g) ) )
    b =  max(0, min(1, (rgb.b + rgb2.b) ) )
    return RGB{Float64}(r,g,b)
end

function calcAngle(lv,lSource,t0,Objects,k,ShadowIntensity; senca = true,IgnoreObjIndx = 0,moc = 100)
    # senca = true, računamo senco 
    # senca = false, NE računamo senco
    #RETURN VALUE:
    #   koef: za koliko zatemniti "barvo"

    Grad = Objects[k][2]
    if senca
        normala = normalize(Grad(t0))
        koef = dot(normala,0 .- lv)
        
        # Ali je pred nasim objektom kakšen objekt
        param,HitObjIndx,Collision = calcCollision(lv, lSource, Objects, k, IgnoreObjIndx) 
       
        # ali uporabimo newtonovo metodo da iračunamo t za vektor lv od lightsourca do t0
        # ali pa izračunamo njuno razdaljo ker že imamo točno podano točko na objektu to naredimo tukaj
        dolzina = 1 - ( norm(t0 .- lSource) / moc )
        dolzina = dolzina^2
        #^2 ker moc svetlobe pada kvadratno
        if Collision == true
        #Objekt je v senci
            HitObjIndx = Int(HitObjIndx)
            t1 = newtonPoint(lv,lSource,param,HitObjIndx,Objects)    
            sencaKoef = min(1, norm(t1 .- t0)/ShadowIntensity)^2

            return max(0,koef*dolzina*sencaKoef)
        else
            return max(0,koef*dolzina)
        end
    else
        normala = normalize(Grad(t0))
        koef =  dot(normala,0 .-lv)
        return max(0,koef)  
    end
    
   return (0,0)
end

function refract_ray(v,normala,n1,n2)
    # SNELL'S LAW
    # zlomi vektor z določinimi n1 in n2
    v = normalize(v) # vektor gleda v tocko / (izvor) tam ko je normala
    n = normalize(normala)
    
    produkt = -dot(v, n)
    if produkt < 0
        n = 0 .-n
        produkt = -dot(v,n)
    end

    r = n1/n2
    pod_korenom = 1 - (r^2)*(1- produkt^2)

    if pod_korenom < 0
        println("Total refraction")
        # implement reflection inside object
        useless_number = 1231242
        return useless_number 
    end 
    return normalize(r.*v +(r.*produkt - sqrt(pod_korenom)).*n)
end 

function calcColor(v,t0,LightSource,Grad,k,color;senca = true)
    #Izračuna barvo pixla
    v = normalize(v)
    planeColor = color
    color = getRGB(0,color)#zacetna barva = BLACK

    for (lsource,moc) in LightSource
        lv = normalize(t0 .- lsource)
        koef = calcAngle(lv,lsource,t0,Objects,k,ShadowIntensity;senca = senca,moc = moc)
        if koef != 0
            color = getRGBSum(color,getRGB(koef,planeColor))
            
            specular_color = specular_highlight(v,t0,Grad,lv,lsource,moc,SpecularIntensity)
            color = getRGBSum(color,specular_color)        
        end
    end
    return color
end

function mirror(kameraVector,normala,t0,LightSource,Objects,CurrObjIndx,alpha,depth = 0)
    v = kameraVector
    n = normala
    
    Grad = Objects[CurrObjIndx][2]
    
    currColor = calcColor(v,t0,LightSource,Grad,CurrObjIndx,Objects[CurrObjIndx][3];senca = false)
    #projekciramo vektor cez normalo
    odbojniVektor = reflect_ray(v,n)
    #---------------------------------------------------------------------------------------------------------------------
    #Išče najbližji objekt ki ga zadane odbojniVektor
    # hrani t(razteg vektorja) in indeks zadenega objekta
    t,HitObjIndx,Collision = calcCollision(odbojniVektor,t0,Objects)
    k = Int(HitObjIndx)# indeks objekta ko smo ga zadeli z odbojnimvektorjem
    
    
    if Collision == false 
        #OdbojniVektor ni nič zadel in recemo da je zadel nebo
        return getRGB(1,currColor, alpha,bg_color)
    end
    #------------------------------------------------------------------------------------------------------------------------
    #Izračunamo točko na Zadetem objektu
    TockaNaZadetemObjektu = newtonPoint(odbojniVektor,t0,t,k,Objects)
    #------------------------------------------------------------------------------------------------------------------------
    #--------- ZADELI SMO ŠE ENKRAT MIRROR----------------------------------------------------------------------------------    
    if Objects[k][4] == true && depth < MaxMirorReflectionDepth #MIRROR
        Grad = Objects[k][2]
        normala = normalize(Grad(TockaNaZadetemObjektu))
        reflectedColor = mirror(odbojniVektor,normala,TockaNaZadetemObjektu,LightSource,Objects,k,alpha,depth+1)
    elseif Objects[k][5] == true # GLASS
    #--------- ZADELI SMO STEKLEN OBJEKT----------------------------------------------------------------------------------   
        normala = normalize(Objects[k][2](TockaNaZadetemObjektu))
        glassColor = glass(odbojniVektor,normala,TockaNaZadetemObjektu,LightSource,Objects,k)
        reflectedColor = glassColor
    else
    #--------- ZADELI SMO NAVADEN OBJEKT----------------------------------------------------------------------------------   
        reflectedColor = calcColor(odbojniVektor,TockaNaZadetemObjektu,LightSource,Grad,k,Objects[k][3]) 
    end
    
    return getRGB(1,currColor,alpha,reflectedColor) 
end

function glass(kameraVector,normala,t0,LightSource,Objects,CurrObjIndx)
    alpha = GlassColorIntensity
    currColor = Objects[CurrObjIndx][3]
    v = kameraVector
    n = normala
    #Lomljen žarek v objekt 
    #-------------V OBJEKTU------------------------------------------------------------
    EnterVektor = refract_ray(v,n,KoefZraka,KoefStekla)

    # raztegKoef, ObjectIndx,Collision
    t,HitObject,Collision = calcCollision(EnterVektor,t0,Objects)
    
    if HitObject != CurrObjIndx
        #nismo zadeli roba objekta
        print("NAPAKA:",HitObject)
        if HitObject == 0 return  bg_color end     
        return Objects[Int(HitObject)][3]
    end

    k = Int(HitObject)

    t1 = newtonPoint(EnterVektor,t0,t,k,Objects)
    normala = 0 .-normalize(Objects[k][2](t1))
    #-------------IZVEN OBJEKTA------------------------------------------------------------
    zlomljenVektor = refract_ray(EnterVektor, normala,KoefStekla,KoefZraka) #Zlomljen Vektor skozi Objekt

    # iščemo objekt ki ga zlomljenj zarek zadane
    t,HitObject,Collision = calcCollision(zlomljenVektor,t1,Objects)
    
    k = Int(HitObject)
    if Collision == false
    #ce zarek ni nic zadel
        return getRGB(1,currColor,alpha,bg_color)
    end
    
    HitColor = Objects[k][3]
    Grad = Objects[k][2]
    
    t2 = newtonPoint(zlomljenVektor,t1,t,k,Objects)
    
    if Objects[k][4] == true
    #---------------- ZADELI SMO MIRROR-------------------------------------------------------------------------
        normala = Grad(t2)
        seenColor = mirror(zlomljenVektor,normala,t2,LightSource,Objects,k,MirrorColorInensity)
        
    elseif Objects[k][5] == true
    #---------------- ZADELI SMO STEKLEN OBJEKT še enkrat-------------------------------------------------------------------------
        normala = Grad(t2)
        seenColor = glass(zlomljenVektor,normala,t2,LightSource,Objects,k)
    
    else
        seenColor = calcColor(zlomljenVektor,t2,LightSource,Grad,k,HitColor)
    end
    

    return getRGB(1,currColor,alpha,seenColor)
end

# Create image buffer
img = Array{RGB{Float64}}(undef, CameraResolution[2], CameraResolution[1])
    
@showprogress 1 "Slika: " for i = 1:CameraResolution[1], j = 1:CameraResolution[2]
    if PixelScalarValues[i,j][2] == 0 
        img[j,i] = bg_color
    else
        k = Int(PixelScalarValues[i,j][2])
        v = Pixels[i,j]
        Grad = Objects[k][2]
        t0 = v .* PixelScalarValues[i,j][1]

        if Objects[k][4]
        #---------------- ZADELI SMO MIRROR-------------------------------------------------------------------------
            normala = normalize(Grad(t0))
            color = mirror(v,normala,t0,LightSource,Objects,k,MirrorColorInensity)
        
        elseif Objects[k][5]
        #---------------- ZADELI SMO STEKLEN OBJEKT-------------------------------------------------------------------------
            normala = normalize(Grad(t0))
            color = glass(v,normala,t0,LightSource,Objects,k) 
        else
        #---------------- ZADELI SMO NAVADEN OBJEKT------------------------------------------------------------------------
            color = calcColor(v,t0,LightSource,Grad,k,Objects[k][3])
        end

        img[j,i] = color
     end
end
save("CoolImage.png", img)