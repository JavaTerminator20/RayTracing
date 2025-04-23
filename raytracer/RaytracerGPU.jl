using LinearAlgebra, StaticArrays, Images, ColorTypes, Colors, CUDA

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

    if CameraRotation != [0.0;0.0;0.0] || CameraDirection != [1,0,0]
        RotateCamera(Pixels, CameraResolution, CameraRotation, CameraDirection, CameraPosition)
    end

    return Pixels
end


# OBJECT CODE
@enum ObjectType Sphere Plane Torus
struct Object
    type::ObjectType

    xyz::SVector{3, Float32}
    c::Float32
    R::Float32

    color::SVector{3, Float32}
    material::Int32 # 1-normal, 2-mirror, 3-glass, 4-normal,no specular
end
@inline function f(obj::Object, vec::SVector{3, Float32})
    if obj.type == Sphere
        return functionSphere(obj, vec)
    elseif obj.type == Plane
        return functionPlane(obj, vec)
    elseif obj.type == Torus
        return functionTorus(obj, vec)
    end
    return 0.0f0
end
@inline function gradf(obj::Object, vec::SVector{3, Float32})
    if obj.type == Sphere
        return gradientSphere(obj, vec)
    elseif obj.type == Plane
        return gradientPlane(obj, vec)
    elseif obj.type == Torus
        return gradientTorus(obj, vec)
    end
    return SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
end
# Sphere
@inline function functionSphere(obj::Object, p::SVector{3, Float32})
    return Float32((p[1] - obj.xyz[1])*(p[1] - obj.xyz[1]) + (p[2] - obj.xyz[2])*(p[2] - obj.xyz[2]) + (p[3] - obj.xyz[3])*(p[3] - obj.xyz[3]) - obj.c^2)
end
@inline function gradientSphere(obj::Object, p::SVector{3, Float32})
    return SVector{3, Float32}(2f0*(p[1] - obj.xyz[1]), 2f0*(p[2] - obj.xyz[2]), 2f0*(p[3] - obj.xyz[3]))
end
# Plane
@inline function functionPlane(obj::Object, p::SVector{3, Float32})
    return Float32(obj.xyz[1]*p[1] + obj.xyz[2]*p[2] + obj.xyz[3]*p[3] + obj.c)
end
@inline function gradientPlane(obj::Object, p::SVector{3, Float32})
    return SVector{3, Float32}(obj.xyz)
end
@inline function functionTorus(obj::Object, p::SVector{3, Float32})
    return Float32( ((p[1]-obj.xyz[1])^2 + (p[2]-obj.xyz[2])^2 + (p[3]-obj.xyz[3])^2 + obj.R^2 - obj.c^2)^2 - 4*(obj.R^2)*((p[2]-obj.xyz[2])^2 + (p[3]-obj.xyz[3])^2) )
end
@inline function gradientTorus(obj::Object, p::SVector{3, Float32})
    return SVector{3, Float32}(
        4*(p[1]-obj.xyz[1])*((p[1]-obj.xyz[1])^2 + (p[2]-obj.xyz[2])^2 + (p[3]-obj.xyz[3])^2 + obj.R^2 - obj.c^2),
        4*(p[2]-obj.xyz[2])*((p[1]-obj.xyz[1])^2 + (p[2]-obj.xyz[2])^2 + (p[3]-obj.xyz[3])^2 + obj.R^2 - obj.c^2 - 2.0f0*obj.R^2),
        4*(p[3]-obj.xyz[3])*((p[1]-obj.xyz[1])^2 + (p[2]-obj.xyz[2])^2 + (p[3]-obj.xyz[3])^2 + obj.R^2 - obj.c^2 - 2.0f0*obj.R^2)
    )
end

# LIGHT CODE
@enum LightType Global Point
struct Light
    type::LightType

    power::Float32
    source::SVector{3, Float32}
    color::SVector{3, Float32}
end


# UTIL CODE
@inline function cuda_clamp(x::Float32, bot::Float32, top::Float32)
    return max(min(x, top), bot)
end
@inline function cuda_clamp01(x::Float32)
    return clamp(x, 0.0f0, 1.0f0)
end

# INTERSECTION CODE
function signChange_kernel(cam::SVector{3, Float32}, ray::SVector{3, Float32}, obj::Object)
    t_approx::Float32 = -1.0f0

    step = 0.1f0
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

        t_next = t - fval / d
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

# LIGHTING CODE
@inline function multiplyColors(c1::SVector{3, Float32}, c2::SVector{3, Float32})
    return SVector{3, Float32}(c1[1]*c2[1], c1[2]*c2[2], c1[3]*c2[3])
end
@inline function reflectRay(input::SVector{3, Float32}, point::SVector{3, Float32}, obj::Object)
    normal::SVector{3, Float32} = normalize(gradf(obj, point))
    t::Float32 = 2.0f0 * dot(normal, input)#SVector{3, Float32}(normalize(input)))#if you normalize input it stops working for some reason
    return SVector{3, Float32}(normalize(SVector{3, Float32}(input[1]-(t*normal[1]), input[2]-(t*normal[2]), input[3]-(t*normal[3]))))
end
function refractRay(input::SVector{3, Float32}, ratio::Float32, intersect::SVector{3, Float32}, obj::Object)
    normal::SVector{3, Float32} = normalize(gradf(obj, intersect))
    input = normalize(input)
    cosi::Float32 = cuda_clamp(dot(input, normal), -1.0f0, 1.0f0)
    if (cosi < 0)  # ce prihajamo zunanje strani krogle
        cosi = -cosi
    else  #ce prihajamo iz znotranje strani krogle
        normal = SVector{3, Float32}(-normal[1], -normal[2], -normal[3])
        ratio = 1.0f0/ratio
    end

    k::Float32 = 1.0f0 - ratio*ratio * (1.0f0 - cosi*cosi) #preverimo ce je refrakcija mogoca
    if (k < 0.0f0)
        return SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0) #nothing
    else
        t::Float32 = ratio*cosi-sqrt(k)
        return SVector{3, Float32}(ratio*input[1] + t*normal[1], ratio*input[2] + t*normal[2], ratio*input[3] + t*normal[3])
    end
end
@inline function SpecularLight(ray::SVector{3, Float32}, intersect::SVector{3, Float32}, obj::Object, NumberOfLights::Int32, Lights::CuDeviceVector{Light})
    if obj.material == 4
        return SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
    end
    k::Float32 = 0.0f0
    for i in 1:NumberOfLights
        light::Light = Lights[i]
        if light.type == Global
            reflectedLight = reflectRay(SVector{3, Float32}(-(light.source[1]), -(light.source[2]), -(light.source[3])), intersect, obj)
            k = k + Float32(max(dot(ray, reflectedLight), 0.0f0)^c_specularArea) #vecja cifra pomeni manj specular svetlobe
        elseif light.type == Point
            reflectedLight = reflectRay(SVector{3, Float32}((light.source[1]-intersect[1]), (light.source[2]-intersect[2]), (light.source[3]-intersect[3])), intersect, obj)#light.direction
            k = k + Float32(max(dot(ray, reflectedLight), 0.0f0)^c_specularArea)
        end
    end
    return SVector{3, Float32}(cuda_clamp01(k)*c_specularIntensity, cuda_clamp01(k)*c_specularIntensity, cuda_clamp01(k)*c_specularIntensity)
end
@inline function calcAngle(intersect::SVector{3, Float32}, normal::SVector{3, Float32}, light::SVector{3, Float32}, NumberOfObjects::Int32, Objects::CuDeviceVector{Object})
    #vecToLight::SVector{3, Float32} = normalize(SVector{3, Float32}(light[1]-intersect[1], light[2]-intersect[2], light[3]-intersect[3]))
    #distanceToLight::Float32 = norm(SVector{3, Float32}(intersect[1] - light[1], intersect[2] - light[2], intersect[3] - light[3]))
    intensity::Float32 = 1.0f0
    intersect_info::SVector{2, Float32} = closestIntersection_kernel(intersect, light, Objects, NumberOfObjects)
    t::Float32 = intersect_info[1]
    if t != -1.0f0
        intensity = cuda_clamp01(norm(SVector{3, Float32}(t*light[1], t*light[2], t*light[3])) / c_shadowModifier)
    end

    k::Float32 = acos(dot(normal, light)); #dot product je med 0 in 1
    if k > (Float32(pi) / 2.0f0)
        return 0.0f0
    else
        return Float32(intensity*cos(k))
    end
end
function calculateLight(intersect::SVector{3, Float32}, obj::Object, NumberOfObjects::Int32, Objects::CuDeviceVector{Object}, NumberOfLights::Int32, Lights::CuDeviceVector{Light})
    outputColor::MVector{3, Float32} = MVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
    normal::SVector{3, Float32} = normalize(gradf(obj, intersect))

    factor::Float32 = 1.0f0

    for i in 1:NumberOfLights
        light::Light = Lights[i]
        k::Float32 = 0.0f0
        if light.type == Global
            vecLightDir::SVector{3, Float32} = normalize(SVector{3, Float32}(-1.0f0*(light.source[1]), -1.0f0*(light.source[2]), -1.0f0*(light.source[3])))
            k = calcAngle(intersect, normal, vecLightDir, NumberOfObjects, Objects)
        elseif light.type == Point
            vecToLight::SVector{3, Float32} = SVector{3, Float32}((light.source[1])-intersect[1], (light.source[2])-intersect[2], (light.source[3])-intersect[3])
            factor = light.power / (4.0f0*Float32(pi)^2 *(norm(vecToLight))^2)
            vecToLight = normalize(vecToLight)
            k = calcAngle(intersect, normal, vecToLight, NumberOfObjects, Objects)
        end
        outputColor[1] = cuda_clamp01(outputColor[1] + factor* k * light.color[1])#*factor*
        outputColor[2] = cuda_clamp01(outputColor[2] + factor* k * light.color[2])#*factor*
        outputColor[3] = cuda_clamp01(outputColor[3] + factor* k * light.color[3])#*factor*
    end

    return SVector{3, Float32}(outputColor)
end
function glass(ray::SVector{3, Float32}, intersect::SVector{3, Float32}, obj::Object, Objects::CuDeviceVector{Object}, NumberOfObjects::Int32, Lights::CuDeviceVector{Light}, NumberOfLights::Int32)

    #ta del preracuna reflectColor komponento (barvo ki se dobi od odbitega zarka)
    reflectDir::SVector{3, Float32} = reflectRay(ray, intersect, obj)
    reflectedIntersectInfo::SVector{2, Float32} = closestIntersection_kernel(intersect, reflectDir, Objects, NumberOfObjects)
    index::Int32 = Int32(reflectedIntersectInfo[2])
    t::Float32 = reflectedIntersectInfo[1]
    reflectedPoint::SVector{3, Float32} = SVector{3, Float32}(t*reflectDir[1]+intersect[1], t*reflectDir[2]+intersect[2], t*reflectDir[3]+intersect[3])

    reflectColor::SVector{3, Float32} = bg_color
    if t != -1.0f0
        lightFactor1::SVector{3, Float32} = calculateLight(reflectedPoint, Objects[index], NumberOfObjects, Objects, NumberOfLights, Lights)
        reflectColor = multiplyColors(lightFactor1, Objects[index].color)
    end

    #ta del preracuna refractColor komponento koncne barve (barvo ki se dobi zaradi zlomljenega zarka)
    ingoingDir::SVector{3, Float32} = refractRay(ray, c_ratio, intersect, obj)
    if ingoingDir[1] == 0.0f0 && ingoingDir[2] == 0.0f0 && ingoingDir[3] == 0.0f0 #ce se zarek ne more refraktat
        return reflectColor
    end
    
    ingoingDir = SVector{3, Float32}(ingoingDir[1]/5.0f0, ingoingDir[2]/5.0f0, ingoingDir[3]/5.0f0) #preprecimo da bi bil vektor vecji kot je sam objekt
    outPointInfo::SVector{2, Float32} = closestIntersection_kernel(intersect, ingoingDir, Objects, NumberOfObjects)
    outObjIndex::Int32 = Int32(outPointInfo[2])
    t2::Float32 = outPointInfo[1]
    outPoint::SVector{3, Float32} = SVector{3, Float32}(t2*ingoingDir[1] + intersect[1], t2*ingoingDir[2] + intersect[2], t2*ingoingDir[3] + intersect[3])
    outgoingDir::SVector{3, Float32} = refractRay(ingoingDir, c_ratio, outPoint, Objects[outObjIndex])# Objects[outObjIndex]
    if ingoingDir[1] == 0.0f0 && ingoingDir[2] == 0.0f0 && ingoingDir[3] == 0.0f0 #ce se zarek ne more refraktat
        return reflectColor
    end

    outIntersectInfo::SVector{2, Float32} = closestIntersection_kernel(outPoint, outgoingDir, Objects, NumberOfObjects)
    objIndex2::Int32 = Int32(outIntersectInfo[2])
    t3::Float32 = outIntersectInfo[1]
    intersectPoint2::SVector{3, Float32} = SVector{3, Float32}(t3*outgoingDir[1]+outPoint[1], t3*outgoingDir[2]+outPoint[2], t3*outgoingDir[3]+outPoint[3])
    refractColor::SVector{3, Float32} = bg_color #ce ne zadanemo nobenega objekta bo refraktna barva barva ozadja, drugace pa barva objekta
    if t3 != -1.0f0
        lightFactor2::SVector{3, Float32} = calculateLight(intersectPoint2, Objects[objIndex2], NumberOfObjects, Objects, NumberOfLights, Lights)
        refractColor = multiplyColors(Objects[objIndex2].color, lightFactor2)
    end

    
    #zdaj pa je treba pravilno zdruziti ti dve barvi v koncen output (neka random formula ko sm jo najdel)
    normala::SVector{3, Float32} = normalize(gradf(obj, intersect))
    ingoingDir = normalize(ingoingDir)
    cosFi::Float32 = cuda_clamp(dot(SVector{3, Float32}(-1.0f0 * ingoingDir[1], -1.0f0 * ingoingDir[2], -1.0f0 * ingoingDir[3]), normala), 0.0f0, 1.0f0)
    R0::Float32 = ((c_glassIOR - 1.0f0) / (c_glassIOR + 1.0f0))^2
    reflect_ratio::Float32 = R0 + (1.0f0 - R0) * (1.0f0 - cosFi)^5
    
    reflect_ratio = reflect_ratio * c_reflectBoost #ta dodatek pojaca barvo osdibte svetlobe
    refract_ratio::Float32 = 1.0f0 - reflect_ratio


    lightFactor::SVector{3, Float32} = calculateLight(intersect, obj, NumberOfObjects, Objects, NumberOfLights, Lights) #to je koeficinet sencenja steklene krogle
    finalColor::SVector{3, Float32} = SVector{3, Float32}(cuda_clamp01(reflect_ratio*reflectColor[1]+refract_ratio*refractColor[1]), cuda_clamp01(reflect_ratio*reflectColor[2]+refract_ratio*refractColor[2]), cuda_clamp01(reflect_ratio*reflectColor[3]+refract_ratio*refractColor[3])) #zmesamo odbito in zlomljeno barvo
    tintedFinalColor::SVector{3, Float32} = multiplyColors(finalColor, SVector{3, Float32}(0.9f0*c_glassColor[1], 0.9f0*c_glassColor[2], 0.9f0*c_glassColor[3])) #izracunamo tinted barvo glede na tint stekla
    finalColor = SVector{3, Float32}((1.0f0-c_tintIntensity)*finalColor[1] + c_tintIntensity*tintedFinalColor[1], (1.0f0-c_tintIntensity)*finalColor[2] + c_tintIntensity*tintedFinalColor[2], (1.0f0-c_tintIntensity)*finalColor[3] + c_tintIntensity*tintedFinalColor[3]) #koncni barvi dodamo nekaj tinted barve glede na tintIntensity

    shadowedFinalColor::SVector{3, Float32} = multiplyColors(finalColor, lightFactor)

    return SVector{3, Float32}((1.0f0-c_shadowIntensity)*finalColor[1] + c_shadowIntensity*shadowedFinalColor[1], (1.0f0-c_shadowIntensity)*finalColor[2] + c_shadowIntensity*shadowedFinalColor[2], (1.0f0-c_shadowIntensity)*finalColor[3] + c_shadowIntensity*shadowedFinalColor[3])
    #return reflectColor
end
@inline function mirrorBounceColor(ray::SVector{3, Float32}, intersect::SVector{3, Float32}, obj::Object, Objects::CuDeviceVector{Object}, NumberOfObjects::Int32, Lights::CuDeviceVector{Light}, NumberOfLights::Int32)
    currRay::SVector{3, Float32} = ray
    currIntr::SVector{3, Float32} = intersect
    currObj::Object = obj
    finalColor::SVector{3, Float32} = SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
    atten::Float32 = 1.0f0
    oRef::Float32 = 1.0f0 - c_reflectivity
    for bounce in 1:c_bounces
        #zadeli smo ogledalo - objIndex je index objekta ki je ogledalo
        mirrorLightFactor::SVector{3, Float32} = calculateLight(currIntr, currObj, NumberOfObjects, Objects, NumberOfLights, Lights)
        surfaceColor::SVector{3, Float32} = multiplyColors(currObj.color, mirrorLightFactor)
        finalColor = SVector{3, Float32}(atten*oRef*surfaceColor[1] + finalColor[1],atten*oRef*surfaceColor[2] + finalColor[2],atten*oRef*surfaceColor[3] + finalColor[3])
        atten = atten*c_reflectivity
        bounceRay::SVector{3, Float32} = reflectRay(currRay, currIntr, currObj)
        point_index::SVector{2, Float32} = closestIntersection_kernel(currIntr, bounceRay, Objects, NumberOfObjects)
        intrObjIndex::Int32 = Int32(point_index[2])
        intersectPt::Float32 = point_index[1]
        objIntersect::SVector{3, Float32} = SVector{3, Float32}(intersectPt*bounceRay[1] + currIntr[1], intersectPt*bounceRay[2] + currIntr[2], intersectPt*bounceRay[3] + currIntr[3])
        if intersectPt == -1.0f0
            finalColor = SVector{3, Float32}(atten*bg_color[1] + finalColor[1],atten*bg_color[2] + finalColor[2],atten*bg_color[3] + finalColor[3])
            break
        elseif Objects[intrObjIndex].material != 2
            objectLight::SVector{3, Float32} = calculateLight(objIntersect, Objects[intrObjIndex], NumberOfObjects, Objects, NumberOfLights, Lights)
            objColor::SVector{3, Float32} = multiplyColors(objectLight, Objects[intrObjIndex].color)
            specLight::SVector{3, Float32} = SpecularLight(currRay, currIntr, Objects[intrObjIndex], NumberOfLights, Lights)#currObj
            temp::SVector{3, Float32} = SVector{3, Float32}(objColor[1]+specLight[1], objColor[2]+specLight[2], objColor[3]+specLight[3])
            finalColor = SVector{3, Float32}(atten*temp[1] + finalColor[1],atten*temp[2] + finalColor[2],atten*temp[3] + finalColor[3])
            break
        elseif Objects[intrObjIndex].material == 2
            currRay = bounceRay
            currIntr = objIntersect
            currObj = Objects[intrObjIndex]
        end
    end
    return SVector{3, Float32}(cuda_clamp01(finalColor[1]), cuda_clamp01(finalColor[2]), cuda_clamp01(finalColor[3]))
end


# MAIN KERNEL
function raytrace_kernel(CameraPosition::SVector{3, Float32}, Pixels::CuDeviceMatrix{SVector{3, Float32}}, NumberOfObjects::Int32, Objects::CuDeviceVector{Object}, NumberOfLights::Int32, Lights::CuDeviceVector{Light}, Image::CuDeviceMatrix{SVector{3, Float32}})
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    W = size(Pixels, 1)
    H = size(Pixels, 2)


    if i <= W && j <= H
        ray::SVector{3, Float32} = ((Pixels[i, j])[1], (Pixels[i, j])[2], (Pixels[i, j])[3])
        intersect_info::SVector{2, Float32} = closestIntersection_kernel(CameraPosition, ray, Objects, NumberOfObjects)
        intersect::SVector{3, Float32} = (CameraPosition[1] + intersect_info[1]*ray[1], CameraPosition[2] + intersect_info[1]*ray[2], CameraPosition[3] + intersect_info[1]*ray[3])
        if intersect_info[1] == -1.0f0
            Image[j,i] = bg_color
            return
        end
        obj::Object = Objects[Int32(intersect_info[2])]
        if obj.material == 1 || obj.material == 4
            lightColor::SVector{3, Float32} = calculateLight(intersect, obj, NumberOfObjects, Objects, NumberOfLights, Lights)
            temp::SVector{3, Float32} = multiplyColors(obj.color, lightColor)
            specularLight::SVector{3, Float32} = SpecularLight(ray, intersect, obj, NumberOfLights, Lights)
            outputColor::SVector{3, Float32} = SVector{3, Float32}(temp[1]+specularLight[1], temp[2]+specularLight[2], temp[3]+specularLight[3]) 
            Image[j,i] = SVector{3, Float32}(Float32(cuda_clamp01(outputColor[1])), Float32(cuda_clamp01(outputColor[2])), Float32(cuda_clamp01(outputColor[3])))
            return
        end
        if obj.material == 2
            Image[j,i] = mirrorBounceColor(ray, intersect, obj, Objects, NumberOfObjects, Lights, NumberOfLights)
            return
        elseif obj.material == 3
            Image[j,i] = glass(ray, intersect, obj, Objects, NumberOfObjects, Lights, NumberOfLights)
            return
        end
        Image[j,i] = SVector{3, Float32}(0.0f0, 0.0f0, 0.0f0)
    end
    return
end




# background color
const bg_color::SVector{3, Float32} = SVector{3, Float32}(0.4, 0.45,0.5)

# specular light
const c_specularIntensity = 0.76f0
const c_specularArea = 20.f0

# shadow
const c_shadowModifier = 7.0f0 #manjsi kot je shadowModifier, bolj svetla bo senca
const c_bounces = 15

# mirror
const c_reflectivity = 0.8f0 #koliko barve odbije ogledalo.  0 = matte barva; 1 = glossy (fully reflective)

# glass
const c_ratio = 0.66667f0  #kolicnik med koef zraka (k=1.0) in koef stekla (k=1.5):  1.0 / 1.5
const c_glassIOR = 1.5f0  #koeficinet stekla
const c_glassColor = SVector{3, Float32}(0.7f0, 0.85f0, 1.0f0)  #barva stekla
const c_tintIntensity = 0.2f0  #kako zelo se barva stekla pozna
const c_shadowIntensity = 0.4f0   #kako intenzivno je steklena krogla sencena
const c_reflectBoost = 4.0f0





#include("./glassBallScene.jl")
#include("./glassBallRotScene.jl")
#include("./ifiniteMirrorScene.jl")
#include("./mirrorScene.jl")
#include("./multiLightScene.jl")
#include("./torusScene.jl")
#include("./torusScene2.jl")
#include("./mirrorScene2.jl")



Pixels = CreateCamera(CameraResolution, CameraAspectRatio, CameraFOV, CameraRotation, CameraDirection, CameraPosition);

Objects = CuArray(Objects_host)
Lights = CuArray(Lights_host)
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
    Int32(NumberOfLights),
    Lights,
    Image
)

# CREATE IMAGE
jImage = Array(Image)
Img = Array{RGB{N0f8}}(undef, CameraResolution[2], CameraResolution[1])
for i = 1:CameraResolution[2], j = 1:CameraResolution[1]
    Img[i,j] = RGB{N0f8}((jImage[i,j])[1], (jImage[i,j])[2], (jImage[i,j])[3])
end
save(name, Img)