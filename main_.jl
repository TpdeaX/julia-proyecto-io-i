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

    problema.coeficientes_objetivo = zeros(Float64, 0, problema.numero_variables)

    print("Ingrese los coeficientes de las variables de la funcion objetivo")

    for i in 1:problema.numero_variables
        print("Variable x$i: ")
        push!(problema.coeficientes_objetivo, parse(Float64, readline()))
    end

    print("Ingrese los coeficientes de las variables de las restricciones: ")

    for i in 1:problema.numero_restricciones
        println("-Restriccion $i: ")
        fila = Float64[]
        for j in 1:problema.numero_restricciones
            print("\t-Variable x$j: ")
            push!()
        end
    end

    

end