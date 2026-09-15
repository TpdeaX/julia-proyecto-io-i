# Resta la fila elegida
function restar(fila_elegida, fila_paso, C)
    return fila_paso .- C .* fila_elegida
end

# Coeficiente minimo
function coeficiente_minimo(solucion, columna)
    minima = Inf
    posicion = -1
    for i in 1:length(columna)
        if columna[i] > 0
            aux = solucion[i] / columna[i]
            if aux < minima
                minima = aux
                posicion = i
            end
        end
    end
    return posicion
end

# Evaluar si en al funcion objetivo hay enteros positivos
function evaluador(fila_objetivo)
    maximo = 0.0
    posicion = -1
    for i in 1:length(fila_objetivo)
        if fila_objetivo[i] > maximo
            maximo = fila_objetivo[i]
            posicion = i
        end
    end
    return posicion
end

# Arma el tablero inicial
function construir_tabla_inicial(problema::ProblemaBase, objetivo::Bool)
    m = problema.numero_restricciones
    n = problema.numero_variables

    tablero = zeros(m + 1, n + m + 1)

    for i in 1:m
        holgura = zeros(m)
        holgura[i] = 1.0
        tablero[i + 1, :] = vcat(problema.coeficientes_restricciones[i, :], holgura, [problema.limites_restricciones[i]])
    end

    signo_objetivo = objetivo ? -1.0 : 1.0
    tablero[1, :] = vcat(signo_objetivo .* problema.coeficientes_objetivo, zeros(m), [0.0])

    return tablero
end

function metodo_simplex(problema::ProblemaBase, objetivo::Bool)
    println("Ejecutando el método Simplex para el objetivo: $(objetivo ? "minimizar" : "maximizar")...")

    m = problema.numero_restricciones
    n = problema.numero_variables
    tablero = construir_tabla_inicial(problema, objetivo)
    base = collect(n+1:n+m)  # variables básicas iniciales: las holguras

    while true
        fila_objetivo = tablero[1, 1:end-1]
        columna_pivote = evaluador(fila_objetivo)

        if columna_pivote == -1
            break 
        end

        solucion = tablero[2:end, end]
        columna = tablero[2:end, columna_pivote]
        fila_relativa = coeficiente_minimo(solucion, columna)

        if fila_relativa == -1
            error("El problema es no acotado (no hay fila válida para pivotear)")
        end

        fila_pivote = fila_relativa + 1  # fila 1 es la del objetivo
        pivote = tablero[fila_pivote, columna_pivote]
        tablero[fila_pivote, :] = tablero[fila_pivote, :] ./ pivote

        for i in 1:size(tablero, 1)
            if i != fila_pivote
                C = tablero[i, columna_pivote]
                tablero[i, :] = restar(tablero[fila_pivote, :], tablero[i, :], C)
            end
        end

        base[fila_relativa] = columna_pivote
    end

    solucion_x = zeros(n)
    for i in 1:m
        if base[i] <= n
            solucion_x[base[i]] = tablero[i + 1, end]
        end
    end

    valor_optimo = objetivo ? tablero[1, end] : -tablero[1, end]

    println("\nSolución encontrada:")
    for i in 1:n
        println("x$i = $(solucion_x[i])")
    end
    println("Valor de la función objetivo: $valor_optimo")

    return valor_optimo, solucion_x
end
