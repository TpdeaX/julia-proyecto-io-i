
function corregir_fila_objetivo!(fila_objetivo::Vector{Float64}, tabla::Matrix{Float64}, variables_basicas::Vector{String}, variables_artificiales::Vector{String})
    valor_m = 1_000_000.0
    total_columnas = size(tabla, 2)

    for (i, var_basica) in enumerate(variables_basicas)
        if var_basica in variables_artificiales
            for j in 1:total_columnas
                fila_objetivo[j] += valor_m * tabla[i, j]
            end
        end
    end

    return fila_objetivo
end


function mostrar_cambio_fila_objetivo(fila_original::Vector{Float64}, tabla::Matrix{Float64}, variables_basicas::Vector{String}, variables_artificiales::Vector{String})
    fila_temporal = copy(fila_original)
    total_columnas = size(tabla, 2)
    valor_m = 1_000_000.0

    println("\nConversion de la fila objetivo:")
    mostrar_fila("F0", fila_temporal, true)

    for (i, var_basica) in enumerate(variables_basicas)
        if var_basica in variables_artificiales
            println("F0 = F0 + M * fila de ", var_basica)
            for j in 1:total_columnas
                fila_temporal[j] += valor_m * tabla[i, j]
            end
            mostrar_fila("F0", fila_temporal, false)
        end
    end

    if isempty(variables_artificiales)
        println("No hay variables artificiales; la fila objetivo no necesita correccion.")
    end
end


function metodo_big_m(problema::ProblemaBase, objetivo::Bool)
    tabla, nombres_variables, tipos_columnas, variables_basicas, variables_artificiales = construir_tabla_inicial(problema)
    fila_objetivo = crear_fila_objetivo(problema, nombres_variables, tipos_columnas, objetivo)
    fila_objetivo_sin_corregir = copy(fila_objetivo)
    numero_iteracion = 1

    println("Ejecutando el metodo Big-M...")
    corregir_fila_objetivo!(fila_objetivo, tabla, variables_basicas, variables_artificiales)

    println("Objetivo: ", objetivo ? "minimizar" : "maximizar")
    println("\nInicializacion de la iteracion:")
    mostrar_bi_ni(nombres_variables, variables_basicas)
    
    println("Fila objetivo inicial, antes de corregir las artificiales:")
    mostrar_tabla_inicial(tabla, nombres_variables, variables_basicas, fila_objetivo_sin_corregir, true)
    
    mostrar_cambio_fila_objetivo(fila_objetivo_sin_corregir, tabla, variables_basicas, variables_artificiales)
        
    println("\nMatriz inicial despues de corregir la fila objetivo:")
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
    println("Variables artificiales: ", variables_artificiales)
    
    valor_objetivo = objetivo ? fila_objetivo[end] : -fila_objetivo[end]
    println("Valor de la funcion objetivo: ", valor_objetivo)

    return tabla, fila_objetivo, nombres_variables, tipos_columnas, variables_basicas, variables_artificiales, solucion
end