function contarVariablesAdicionales(signos::Vector{Int})
    total = 0
    for signo in signos
        if signo == 1   
            total += 1
        elseif signo == 2 
            total += 2
        else
            total += 1
        end
    end
    return total
end

function construirTablaInicial(problema::ProblemaBase)
    variablesAdicionales = contarVariablesAdicionales(problema.signos)
    totalColumnas = problema.numeroVariables + variablesAdicionales + 1

    tabla = zeros(Float64, problema.numeroRestricciones, totalColumnas)

    nombresVariables = String[]
    tiposColumnas = String[]
    variablesBasicas = String[]
    variablesArtificiales = String[]

    for i in 1:problema.numeroVariables
        push!(nombresVariables, "x$i")
        push!(tiposColumnas, "original")
    end

    for i in 1:problema.numeroRestricciones
        for j in 1:problema.numeroVariables
            tabla[i, j] = problema.coeficientesRestricciones[i, j]
        end
        tabla[i, totalColumnas] = problema.limitesRestricciones[i]
    end

    columnaActual = problema.numeroVariables + 1

    for i in 1:problema.numeroRestricciones
        signo = problema.signos[i]

        if signo == 1
            nombre = "x$columnaActual"
            push!(nombresVariables, nombre)
            push!(tiposColumnas, "holgura")
            push!(variablesBasicas, nombre)

            tabla[i, columnaActual] = 1.0
            columnaActual += 1

        elseif signo == 2
            nombreExceso = "x$columnaActual"
            push!(nombresVariables, nombreExceso)
            push!(tiposColumnas, "exceso")
            tabla[i, columnaActual] = -1.0
            columnaActual += 1

            nombreArtificial = "x$columnaActual"
            push!(nombresVariables, nombreArtificial)
            push!(tiposColumnas, "artificial")
            push!(variablesBasicas, nombreArtificial)
            push!(variablesArtificiales, nombreArtificial)
            tabla[i, columnaActual] = 1.0
            columnaActual += 1

        elseif signo == 3
            nombre = "x$columnaActual"
            push!(nombresVariables, nombre)
            push!(tiposColumnas, "artificial")
            push!(variablesBasicas, nombre)
            push!(variablesArtificiales, nombre)

            tabla[i, columnaActual] = 1.0
            columnaActual += 1
        end
    end

    return tabla, nombresVariables, tiposColumnas, variablesBasicas, variablesArtificiales
end

function mostrarNumero(numero::Float64, mostrarM::Bool)
    if mostrarM && numero == -1_000_000.0
        return "-M"
    elseif mostrarM && numero == 1_000_000.0
        return "M"
    else
        return string(round(numero, digits=4))
    end
end

function mostrarFila(nombre::String, valores, mostrarM::Bool)
    texto = rpad(nombre, 6)
    for valor in valores
        texto *= rpad(mostrarNumero(valor, mostrarM), 12)
    end
    println(texto)
end

function mostrarTablaInicial(tabla::Matrix{Float64}, nombresVariables::Vector{String}, variablesBasicas::Vector{String}, filaObjetivo::Vector{Float64}, mostrarM::Bool)
    encabezado = rpad("Base", 6)
    totalFilas = size(tabla, 1)

    println("\nTabla del metodo:")
    for nombre in nombresVariables
        encabezado *= rpad(nombre, 12)
    end
    encabezado *= rpad("LD", 12)
    println(encabezado)
    
    mostrarFila("F0", filaObjetivo, mostrarM)
    
    for i in 1:totalFilas
        mostrarFila(variablesBasicas[i], tabla[i, :], false)
    end
end

function mostrarBiNi(nombresVariables::Vector{String}, variablesBasicas::Vector{String})
    noBasicas = String[]

    for nombre in nombresVariables
        if !(nombre in variablesBasicas)
            push!(noBasicas, nombre)
        end
    end

    println("BI (variables basicas): ", variablesBasicas)
    println("NI (variables no basicas): ", noBasicas)
end

function crearFilaObjetivo(problema::ProblemaBase, nombresVariables::Vector{String}, tiposColumnas::Vector{String}, objetivo::Bool)
    signoObjetivo = objetivo ? -1.0 : 1.0
    totalColumnas = length(nombresVariables)
    filaObjetivo = zeros(Float64, totalColumnas + 1)

    for i in 1:problema.numeroVariables
        filaObjetivo[i] = signoObjetivo * problema.coeficientesObjetivo[i]
    end

    for i in 1:totalColumnas
        if tiposColumnas[i] == "artificial"
            filaObjetivo[i] = -1_000_000.0
        end
    end

    return filaObjetivo
end

function buscarColumnaPivote(filaObjetivo::Vector{Float64})
    posicion = 0
    mayor = 0.0
    limiteEvaluacion = length(filaObjetivo) - 1

    for i in 1:limiteEvaluacion
        if filaObjetivo[i] > 0.0
            if posicion == 0 || filaObjetivo[i] > mayor
                mayor = filaObjetivo[i]
                posicion = i
            end
        end
    end

    return posicion
end

function buscarFilaPivote(tabla::Matrix{Float64}, columnaPivote::Int)
    posicion = 0
    menor = 0.0
    totalFilas = size(tabla, 1)

    for i in 1:totalFilas
        if tabla[i, columnaPivote] > 0
            cociente = tabla[i, end] / tabla[i, columnaPivote]
            if posicion == 0 || cociente < menor
                menor = cociente
                posicion = i
            end
        end
    end

    return posicion
end

function hacerPivote!(tabla::Matrix{Float64}, filaObjetivo::Vector{Float64}, filaPivote::Int, columnaPivote::Int)
    totalFilas = size(tabla, 1)
    totalColumnas = size(tabla, 2)
    pivote = tabla[filaPivote, columnaPivote]

    println("Elemento pivote: ", pivote)
    println("Paso 1: dividir la fila pivote entre ", pivote)
    for j in 1:totalColumnas
        tabla[filaPivote, j] /= pivote
    end

    for i in 1:totalFilas
        if i != filaPivote
            factor = tabla[i, columnaPivote]
            println("Paso 2: fila ", i, " = fila ", i, " - (", factor, ") * fila pivote")
            for j in 1:totalColumnas
                tabla[i, j] -= factor * tabla[filaPivote, j]
            end
        end
    end

    factorObjetivo = filaObjetivo[columnaPivote]
    println("Paso 3: fila objetivo = fila objetivo - (", factorObjetivo, ") * fila pivote")
    for j in 1:totalColumnas
        filaObjetivo[j] -= factorObjetivo * tabla[filaPivote, j]
    end
end

function hacerUnaIteracion!(tabla::Matrix{Float64}, filaObjetivo::Vector{Float64}, nombresVariables::Vector{String}, variablesBasicas::Vector{String})
    columnaPivote = buscarColumnaPivote(filaObjetivo)

    if columnaPivote == 0
        return false
    end

    println("Columna pivote: ", nombresVariables[columnaPivote], " (columna ", columnaPivote, ")")

    filaPivote = buscarFilaPivote(tabla, columnaPivote)

    println("Fila pivote: ", filaPivote, " (variable basica actual: ", variablesBasicas[filaPivote], ")")
    hacerPivote!(tabla, filaObjetivo, filaPivote, columnaPivote)
    variablesBasicas[filaPivote] = nombresVariables[columnaPivote]
    println("Nueva variable basica: ", variablesBasicas[filaPivote])

    return true
end

function obtenerSolucion(tabla::Matrix{Float64}, variablesBasicas::Vector{String}, numeroVariables::Int)
    solucion = zeros(Float64, numeroVariables)

    for (i, variableBasica) in enumerate(variablesBasicas)
        numero = parse(Int, variableBasica[2:end])
        if numero <= numeroVariables
            solucion[numero] = round(tabla[i, end], digits=4)
        end
    end

    return solucion
end

function metodoSimplex(problema::ProblemaBase, objetivo::Bool)
    println("Ejecutando el metodo Simplex...")

    tabla, nombresVariables, tiposColumnas, variablesBasicas, _ = construirTablaInicial(problema)
    filaObjetivo = crearFilaObjetivo(problema, nombresVariables, tiposColumnas, objetivo)
    numeroIteracion = 1

    println("Objetivo: ", objetivo ? "minimizar" : "maximizar")
    println("\nInicializacion de la iteracion:")
    mostrarBiNi(nombresVariables, variablesBasicas)
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

    valorObjetivo = objetivo ? filaObjetivo[end] : -filaObjetivo[end]
    println("Valor de la funcion objetivo: ", valorObjetivo)

    return tabla, filaObjetivo, nombresVariables, tiposColumnas, variablesBasicas, solucion
end
