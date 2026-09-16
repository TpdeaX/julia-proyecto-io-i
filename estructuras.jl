mutable struct ProblemaBase
    numeroVariables::Int
    numeroRestricciones::Int
    coeficientesObjetivo::Vector{Float64}
    coeficientesRestricciones::Matrix{Float64}
    limitesRestricciones::Vector{Float64}
    signos::Vector{Int}
end
