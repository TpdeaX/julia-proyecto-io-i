mutable struct ProblemaBase
    numero_variables::Int
    numero_restricciones::Int
    coeficientes_objetivo::Vector{Float64}
    coeficientes_restricciones::Matrix{Float64}
    limites_restricciones::Vector{Float64} 
    signos::Vector{Int}
end
