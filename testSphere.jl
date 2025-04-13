using Plots
#plotly()


theta = range(0, stop=2π, length=100)
phi = range(0, stop=π, length=50)
x = Float64[]
y = Float64[]
z = Float64[]

for t in theta
    for p in phi
        push!(x, sin(p) * cos(t))
        push!(y, sin(p) * sin(t))
        push!(z, cos(p))
    end
end


scatter3d(x, y, z, marker = (2, :auto), color = :blue, legend = false)