include("estructuras.jl")
include("simplex.jl")
include("big_m.jl")

problema = ProblemaBase(0, 0, zeros(0), zeros(0, 0), zeros(0), zeros(Int, 0))
objetivo::Bool = false

function main()
    global problema
    global objetivo

    print("Ingrese el numero de variables: ")
    problema.numeroVariables = parse(Int, readline())
    print("Ingrese el numero de restricciones: ")
    problema.numeroRestricciones = parse(Int, readline())

    problema.coeficientesRestricciones = zeros(Float64, 0, problema.numeroVariables)

    println("Ingrese el coeficiente de las variables en la funcion objetivo: ")
    for i in 1:problema.numeroVariables
        print("Variable x$i: ")
        push!(problema.coeficientesObjetivo, parse(Float64, readline()))
    end

    println("Ingrese los coeficientes de las restricciones: ")
    for i in 1:problema.numeroRestricciones
        println("- Restriccion $i: ")
        fila = Float64[]
        for j in 1:problema.numeroVariables
            print("\t- Variable x$j: ")
            push!(fila, parse(Float64, readline()))
        end

        problema.coeficientesRestricciones = vcat(problema.coeficientesRestricciones, fila')
    end

    println("Ingrese los limites de las restricciones: ")
    for i in 1:problema.numeroRestricciones
        print("Restriccion $i: ")
        push!(problema.limitesRestricciones, parse(Float64, readline()))
    end

    usarBigM = false

    println("Ingrese los signos de las restricciones (1 para <=, 2 para >=, 3 para =): ")
    for i in 1:problema.numeroRestricciones
        print("Restriccion $i: ")
        numeroSigno = parse(Int, readline())
        if numeroSigno == 2 || numeroSigno == 3
            usarBigM = true
        end
        push!(problema.signos, numeroSigno)
    end

    print("Ingrese el objetivo (0 para maximizar, 1 para minimizar): ")
    objetivo = parse(Bool, readline())

    Base.run(`cmd /c cls`)

    if usarBigM
        metodoBigM(problema, objetivo)
    else
        metodoSimplex(problema, objetivo)
    end
end

main()