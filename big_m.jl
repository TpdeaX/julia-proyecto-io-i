function corregirFilaObjetivo!(filaObjetivo::Vector{Float64}, tabla::Matrix{Float64}, variablesBasicas::Vector{String}, variablesArtificiales::Vector{String})
    valorM = 1_000_000.0
    totalColumnas = size(tabla, 2)

    for (i, varBasica) in enumerate(variablesBasicas)
        if varBasica in variablesArtificiales
            for j in 1:totalColumnas
                filaObjetivo[j] += valorM * tabla[i, j]
            end
        end
    end

    return filaObjetivo
end

function mostrarCambioFilaObjetivo(filaOriginal::Vector{Float64}, tabla::Matrix{Float64}, variablesBasicas::Vector{String}, variablesArtificiales::Vector{String})
    filaTemporal = copy(filaOriginal)
    totalColumnas = size(tabla, 2)
    valorM = 1_000_000.0

    println("\nConversion de la fila objetivo:")
    mostrarFila("F0", filaTemporal, true)

    for (i, varBasica) in enumerate(variablesBasicas)
        if varBasica in variablesArtificiales
            println("F0 = F0 + M * fila de ", varBasica)
            for j in 1:totalColumnas
                filaTemporal[j] += valorM * tabla[i, j]
            end
            mostrarFila("F0", filaTemporal, false)
        end
    end

    if isempty(variablesArtificiales)
        println("No hay variables artificiales; la fila objetivo no necesita correccion.")
    end
end

function metodoBigM(problema::ProblemaBase, objetivo::Bool)
    tabla, nombresVariables, tiposColumnas, variablesBasicas, variablesArtificiales = construirTablaInicial(problema)
    filaObjetivo = crearFilaObjetivo(problema, nombresVariables, tiposColumnas, objetivo)
    filaObjetivoSinCorregir = copy(filaObjetivo)
    numeroIteracion = 1

    println("Ejecutando el metodo Big-M...")
    corregirFilaObjetivo!(filaObjetivo, tabla, variablesBasicas, variablesArtificiales)

    println("Objetivo: ", objetivo ? "minimizar" : "maximizar")
    println("\nInicializacion de la iteracion:")
    mostrarBiNi(nombresVariables, variablesBasicas)
    
    println("Fila objetivo inicial, antes de corregir las artificiales:")
    mostrarTablaInicial(tabla, nombresVariables, variablesBasicas, filaObjetivoSinCorregir, true)
    
    mostrarCambioFilaObjetivo(filaObjetivoSinCorregir, tabla, variablesBasicas, variablesArtificiales)
        
    println("\nMatriz inicial despues de corregir la fila objetivo:")
    mostrarTablaInicial(tabla, nombresVariables, variablesBasicas, filaObjetivo, false)

    while true
        huboPivote = hacerUnaIteracion!(tabla, filaObjetivo, nombresVariables, variablesBasicas)
        if !huboPivote
            break
        end

        println("\nIteracion ", numeroIteracion)
        mostrarBiNi(nombresVariables, variablesBasicas)
        println("Tabla despues del pivote:")
        mostrarTablaInicial(tabla, nombresVariables, variablesBasicas, filaObjetivo, false)
        numeroIteracion += 1
    end

    solucion = obtenerSolucion(tabla, variablesBasicas, problema.numeroVariables)
    println("\nSolucion encontrada:")
    for i in 1:problema.numeroVariables
        println("x$i = ", solucion[i])
    end
    println("Variables basicas finales: ", variablesBasicas)
    println("Variables artificiales: ", variablesArtificiales)
    
    valorObjetivo = objetivo ? filaObjetivo[end] : -filaObjetivo[end]
    println("Valor de la funcion objetivo: ", valorObjetivo)

    return tabla, filaObjetivo, nombresVariables, tiposColumnas, variablesBasicas, variablesArtificiales, solucion
end