include("estructuras.jl")
include("simplex.jl")
include("big_m.jl")

problema = ProblemaBase(0, 0, zeros(0), zeros(0, 0), zeros(0), String[])
objetivo::Bool = 0

function main()
    global problema
    global objetivo

    print("Ingrese el número de variables: ")
    problema.numero_variables = parse(Int, readline())
    print("Ingrese el número de restricciones: ")
    problema.numero_restricciones = parse(Int, readline())
    println("Ingrese el coeficiente de las variables en la función objetivo: ")
    for i in 1:problema.numero_variables
        print("Variable x$i: ")
        push!(problema.coeficientes_objetivo, parse(Float64, readline()))
    end

    #se inicializa la matriz
    problema.coeficientes_restricciones = Matrix{Float64}(undef, 0, problema.numero_variables)

    println("Ingrese los coeficientes de las restricciones: ")
    for i in 1:problema.numero_restricciones
        println("- Restricción $i: ")
        fila = Float64[]
        for j in 1:problema.numero_variables
            print("\t- Variable x$j: ")
            push!(fila, parse(Float64, readline()))
        end

        problema.coeficientes_restricciones = vcat(problema.coeficientes_restricciones, fila')
    end

    println("Ingrese los límites de las restricciones: ")
    for i in 1:problema.numero_restricciones
        print("Restricción $i: ")
        push!(problema.limites_restricciones, parse(Float64, readline()))
    end

    usar_big_m = false

    println("Ingrese los signos de las restricciones (<=, >=, =): ")
    for i in 1:problema.numero_restricciones
        print("Restricción $i: ")
        entrada = readline()
        if entrada == ">="
            usar_big_m = true
        end
        push!(problema.signos, entrada)
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