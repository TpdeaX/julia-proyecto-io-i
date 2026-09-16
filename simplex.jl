function contar_variables_adicionales(signos::Vector{Int})
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

function construir_tabla_inicial(problema::ProblemaBase)
    variables_adicionales = contar_variables_adicionales(problema.signos)
    total_columnas = problema.numero_variables + variables_adicionales + 1

    tabla = zeros(Float64, problema.numero_restricciones, total_columnas)

    nombres_variables = String[]
    tipos_columnas = String[]
    variables_basicas = String[]
    variables_artificiales = String[]

    for i in 1:problema.numero_variables
        push!(nombres_variables, "x$i")
        push!(tipos_columnas, "original")
    end

    for i in 1:problema.numero_restricciones
        for j in 1:problema.numero_variables
            tabla[i, j] = problema.coeficientes_restricciones[i, j]
        end
        tabla[i, total_columnas] = problema.limites_restricciones[i]
    end

    columna_actual = problema.numero_variables + 1

    for i in 1:problema.numero_restricciones
        signo = problema.signos[i]

        if signo == 1
            nombre = "x$columna_actual"
            push!(nombres_variables, nombre)
            push!(tipos_columnas, "holgura")
            push!(variables_basicas, nombre)

            tabla[i, columna_actual] = 1.0
            columna_actual += 1

        elseif signo == 2
            nombre_exceso = "x$columna_actual"
            push!(nombres_variables, nombre_exceso)
            push!(tipos_columnas, "exceso")
            tabla[i, columna_actual] = -1.0
            columna_actual += 1

            nombre_artificial = "x$columna_actual"
            push!(nombres_variables, nombre_artificial)
            push!(tipos_columnas, "artificial")
            push!(variables_basicas, nombre_artificial)
            push!(variables_artificiales, nombre_artificial)
            tabla[i, columna_actual] = 1.0
            columna_actual += 1

        elseif signo == 3
            nombre = "x$columna_actual"
            push!(nombres_variables, nombre)
            push!(tipos_columnas, "artificial")
            push!(variables_basicas, nombre)
            push!(variables_artificiales, nombre)

            tabla[i, columna_actual] = 1.0
            columna_actual += 1
        end
    end

    return tabla, nombres_variables, tipos_columnas, variables_basicas, variables_artificiales
end

function mostrar_numero(numero::Float64, mostrar_m::Bool)
    if mostrar_m && numero == -1_000_000.0
        return "-M"
    elseif mostrar_m && numero == 1_000_000.0
        return "M"
    else
        return string(round(numero, digits=4))
    end
end

function mostrar_fila(nombre::String, valores, mostrar_m::Bool)
    texto = rpad(nombre, 6)
    for valor in valores
        texto *= rpad(mostrar_numero(valor, mostrar_m), 12)
    end
    println(texto)
end

function mostrar_tabla_inicial(tabla::Matrix{Float64}, nombres_variables::Vector{String}, variables_basicas::Vector{String}, fila_objetivo::Vector{Float64}, mostrar_m::Bool)
    encabezado = rpad("Base", 6)
    total_filas = size(tabla, 1)

    println("\nTabla del metodo:")
    for nombre in nombres_variables
        encabezado *= rpad(nombre, 12)
    end
    encabezado *= rpad("LD", 12)
    println(encabezado)
    
    mostrar_fila("F0", fila_objetivo, mostrar_m)
    
    for i in 1:total_filas
        mostrar_fila(variables_basicas[i], tabla[i, :], false)
    end
end

function mostrar_bi_ni(nombres_variables::Vector{String}, variables_basicas::Vector{String})
    no_basicas = String[]

    for nombre in nombres_variables
        if !(nombre in variables_basicas)
            push!(no_basicas, nombre)
        end
    end

    println("BI (variables basicas): ", variables_basicas)
    println("NI (variables no basicas): ", no_basicas)
end

function crear_fila_objetivo(problema::ProblemaBase, nombres_variables::Vector{String}, tipos_columnas::Vector{String}, objetivo::Bool)
    signo_objetivo = objetivo ? -1.0 : 1.0
    total_columnas = length(nombres_variables)
    fila_objetivo = zeros(Float64, total_columnas + 1)

    for i in 1:problema.numero_variables
        fila_objetivo[i] = signo_objetivo * problema.coeficientes_objetivo[i]
    end

    for i in 1:total_columnas
        if tipos_columnas[i] == "artificial"
            fila_objetivo[i] = -1_000_000.0
        end
    end

    return fila_objetivo
end

function buscar_columna_pivote(fila_objetivo::Vector{Float64})
    posicion = 0
    mayor = 0.0
    limite_evaluacion = length(fila_objetivo) - 1

    for i in 1:limite_evaluacion
        if fila_objetivo[i] > 0.0
            if posicion == 0 || fila_objetivo[i] > mayor
                mayor = fila_objetivo[i]
                posicion = i
            end
        end
    end

    return posicion
end

function buscar_fila_pivote(tabla::Matrix{Float64}, columna_pivote::Int)
    posicion = 0
    menor = 0.0
    total_filas = size(tabla, 1)

    for i in 1:total_filas
        if tabla[i, columna_pivote] > 0
            cociente = tabla[i, end] / tabla[i, columna_pivote]
            if posicion == 0 || cociente < menor
                menor = cociente
                posicion = i
            end
        end
    end

    return posicion
end

function hacer_pivote!(tabla::Matrix{Float64}, fila_objetivo::Vector{Float64}, fila_pivote::Int, columna_pivote::Int)
    total_filas = size(tabla, 1)
    total_columnas = size(tabla, 2)
    pivote = tabla[fila_pivote, columna_pivote]

    println("Elemento pivote: ", pivote)
    println("Paso 1: dividir la fila pivote entre ", pivote)
    for j in 1:total_columnas
        tabla[fila_pivote, j] /= pivote
    end

    for i in 1:total_filas
        if i != fila_pivote
            factor = tabla[i, columna_pivote]
            println("Paso 2: fila ", i, " = fila ", i, " - (", factor, ") * fila pivote")
            for j in 1:total_columnas
                tabla[i, j] -= factor * tabla[fila_pivote, j]
            end
        end
    end

    factor_objetivo = fila_objetivo[columna_pivote]
    println("Paso 3: fila objetivo = fila objetivo - (", factor_objetivo, ") * fila pivote")
    for j in 1:total_columnas
        fila_objetivo[j] -= factor_objetivo * tabla[fila_pivote, j]
    end
end

function hacer_una_iteracion!(tabla::Matrix{Float64}, fila_objetivo::Vector{Float64}, nombres_variables::Vector{String}, variables_basicas::Vector{String})
    columna_pivote = buscar_columna_pivote(fila_objetivo)

    if columna_pivote == 0
        return false
    end

    println("Columna pivote: ", nombres_variables[columna_pivote], " (columna ", columna_pivote, ")")

    fila_pivote = buscar_fila_pivote(tabla, columna_pivote)

    println("Fila pivote: ", fila_pivote, " (variable basica actual: ", variables_basicas[fila_pivote], ")")
    hacer_pivote!(tabla, fila_objetivo, fila_pivote, columna_pivote)
    variables_basicas[fila_pivote] = nombres_variables[columna_pivote]
    println("Nueva variable basica: ", variables_basicas[fila_pivote])

    return true
end

function obtener_solucion(tabla::Matrix{Float64}, variables_basicas::Vector{String}, numero_variables::Int)
    solucion = zeros(Float64, numero_variables)

    for (i, variable_basica) in enumerate(variables_basicas)
        numero = parse(Int, variable_basica[2:end])
        if numero <= numero_variables
            solucion[numero] = round(tabla[i, end], digits=4)
        end
    end

    return solucion
end

function metodo_simplex(problema::ProblemaBase, objetivo::Bool)
    println("Ejecutando el metodo Simplex...")

    tabla, nombres_variables, tipos_columnas, variables_basicas, _ = construir_tabla_inicial(problema)
    fila_objetivo = crear_fila_objetivo(problema, nombres_variables, tipos_columnas, objetivo)
    numero_iteracion = 1

    println("Objetivo: ", objetivo ? "minimizar" : "maximizar")
    println("\nInicializacion de la iteracion:")
    mostrar_bi_ni(nombres_variables, variables_basicas)
    mostrar_tabla_inicial(tabla, nombres_variables, variables_basicas, fila_objetivo, false)

    while true
        hubo_pivote = hacer_una_iteracion!(tabla, fila_objetivo, nombres_variables, variables_basicas)
        if !hubo_pivote
            break
        end

        println("\nIteracion ", numero_iteracion)
        mostrar_bi_ni(nombres_variables, variables_basicas)
        println("Tabla despues del pivote:")
        mostrar_tabla_inicial(tabla, nombres_variables, variables_basicas, fila_objetivo, false)
        numero_iteracion += 1
    end

    solucion = obtener_solucion(tabla, variables_basicas, problema.numero_variables)
    println("\nSolucion encontrada:")
    for i in 1:problema.numero_variables
        println("x$i = ", solucion[i])
    end
    println("Variables basicas finales: ", variables_basicas)

    valor_objetivo = objetivo ? fila_objetivo[end] : -fila_objetivo[end]
    println("Valor de la funcion objetivo: ", valor_objetivo)

    return tabla, fila_objetivo, nombres_variables, tipos_columnas, variables_basicas, solucion
end
