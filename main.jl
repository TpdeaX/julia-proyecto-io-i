include("estructuras.jl")
include("simplex.jl")
include("big_m.jl")

problema = ProblemaBase(0, 0, zeros(0), zeros(0, 0), zeros(0), zeros(Int, 0))
objetivo::Bool = false

function main()
    global problema
    global objetivo

    print("Ingrese el numero de variables: ")
    problema.numero_variables = parse(Int, readline())
    print("Ingrese el numero de restricciones: ")
    problema.numero_restricciones = parse(Int, readline())

    problema.coeficientes_restricciones = zeros(Float64, 0, problema.numero_variables)

    println("Ingrese el coeficiente de las variables en la funcion objetivo: ")
    for i in 1:problema.numero_variables
        print("Variable x$i: ")
        push!(problema.coeficientes_objetivo, parse(Float64, readline()))
    end

    println("Ingrese los coeficientes de las restricciones: ")
    for i in 1:problema.numero_restricciones
        println("- Restriccion $i: ")
        fila = Float64[]
        for j in 1:problema.numero_variables
            print("\t- Variable x$j: ")
            push!(fila, parse(Float64, readline()))
        end

        problema.coeficientes_restricciones = vcat(problema.coeficientes_restricciones, fila')
    end

    println("Ingrese los limites de las restricciones: ")
    for i in 1:problema.numero_restricciones
        print("Restriccion $i: ")
        push!(problema.limites_restricciones, parse(Float64, readline()))
    end

    usar_big_m = false

    println("Ingrese los signos de las restricciones (1 para <=, 2 para >=, 3 para =): ")
    for i in 1:problema.numero_restricciones
        print("Restriccion $i: ")
        numerosSigno = parse(Int, readline())
        if numerosSigno == 2 || numerosSigno == 3
            usar_big_m = true
        end
        push!(problema.signos, numerosSigno)
    end

    print("Ingrese el objetivo (0 para maximizar, 1 para minimizar): ")
    objetivo = parse(Bool, readline())

    Base.run(`cmd /c cls`)

    if usar_big_m
        metodo_big_m(problema, objetivo)
    else
        metodo_simplex(problema, objetivo)
    end
end

main()