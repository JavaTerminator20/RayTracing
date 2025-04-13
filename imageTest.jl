using LinearAlgebra
using Plots

gr()

f1(x,y,z) = [x^2 + y^2 + z^2 - 1]
f2(x, y) = [x^2 + y^2 - 1]
f3(x) = sqrt(1 - x^2)
f4(x, y) = [1 - x^2 - y^2]

function upper_sphere(x, y)
    val = x^4 - y^2
    if val >=0
        return sqrt(val)
    else
        return NaN
    end
end

function lower_spehre(x, y)
    val = 1 - x^2 - y^2
    if val >= 0
        return -sqrt(val)
    else
        return NaN
    end
end

x = LinRange(-1, 1, 100)
y = LinRange(-1, 1, 100)
#y = sqrt.(1 .- x.^2)


y2 = [f3(xi) for xi in x]
z_upper = [upper_sphere(xi, yi) for xi in x, yi in y]
z_lower = [lower_spehre(xi, yi) for xi in x, yi in y]

surface(x, y, z_upper, aspect_ration=:equal)
#surface!(x, y, z_lower, aspect_ration=:equal)


