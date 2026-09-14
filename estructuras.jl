# estructuras.jl

mutable struct ProblemaBase
    numero_variables::Int
    numero_restricciones::Int
    ganancia::Vector{Float64}
    coeficientes::Matrix{Float64}
    limites::Vector{Float64}
    signos::Vector{String}
end

mutable struct Metodo_Algoritmo
    algoritmo::Int
    objetivo::Int
end