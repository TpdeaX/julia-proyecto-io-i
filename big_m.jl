# big_m.jl

# 1er pasito : contruir la tabla incial
function construir_tabla_inicial(problema::ProblemaBase)

    coeficienteRestriccionesCopia = copy(problema.coeficientes_restricciones)
    nombreVariable = ["x$i" for i in 1:problema.numero_variables] 
    #variable para asignar el tipo de variable ,y se le asigna el tipo original a las variales originales, al principio todas son originales
    nombreTipo_Columna = fill("original", problema.numero_variables)
    
    filas = Vector{Vector{Float64}}()#se crea un arreglo que almacena otros arreglos con el valor de cada fila
    limites = Float64[] #lado derecho de las restricciones
    variables_basicas = String[]
    variables_artificiales = String[]
    siguiente_variable = problema.numero_variables + 1

    for i in 1:problema.numero_restricciones
        # Las columnas nuevas de otras restricciones deben comenzar en cero.
        columnas_anteriores = length(nombreVariable) - problema.numero_variables
        fila = vcat(vec(coeficienteRestriccionesCopia[i, :]), zeros(columnas_anteriores))
        signo = problema.signos[i]

        if signo == 1
            # Una restricción <= obtiene una variable de holgura.
            nombre = "x$siguiente_variable"
            siguiente_variable += 1
            push!(nombreVariable, nombre)
            push!(nombreTipo_Columna, "holgura")
            # Las filas anteriores tambien necesitan esta nueva columna.
            for fila_anterior in filas
                push!(fila_anterior, 0.0)
            end
            push!(fila, 1.0)
            push!(variables_basicas, nombre)

        elseif signo == 2
            # Una restricción >= obtiene una variable de exceso y una artificial.
            nombre_exceso = "x$siguiente_variable"
            siguiente_variable += 1
            push!(nombreVariable, nombre_exceso)
            push!(nombreTipo_Columna, "exceso")
            # La variable de exceso se resta 
            for fila_anterior in filas
                push!(fila_anterior, 0.0)
            end
            push!(fila, -1.0)

            nombre_artificial = "x$siguiente_variable"
            siguiente_variable += 1
            push!(nombreVariable, nombre_artificial)
            push!(nombreTipo_Columna, "artificial")
            # La artificial permite formar una base inicial.
            for fila_anterior in filas
                push!(fila_anterior, 0.0)
            end
            push!(fila, 1.0)
            push!(variables_basicas, nombre_artificial)
            push!(variables_artificiales, nombre_artificial)
            
        elseif signo == 3
            # Una igualdad obtiene directamente una variable artificial.
            nombre = "x$siguiente_variable"
            siguiente_variable += 1
            push!(nombreVariable, nombre)
            push!(nombreTipo_Columna, "artificial")
            for fila_anterior in filas
                push!(fila_anterior, 0.0)
            end
            push!(fila, 1.0)
            push!(variables_basicas, nombre)
            push!(variables_artificiales, nombre)
        else
            error("Signo no válido en la restricción $i")
        end

        push!(limites, problema.limites_restricciones[i])
        push!(filas, fila)
    end

    # El lado derecho se agrega al final, despues de todas las columnas.
    numero_columnas = length(nombreVariable)
    tabla = zeros(Float64, problema.numero_restricciones, numero_columnas + 1)
    for i in 1:problema.numero_restricciones
        push!(filas[i], limites[i])
        tabla[i, :] = filas[i] #copiar la fila a la tabla
    end

    return tabla, nombreVariable, nombreTipo_Columna, variables_basicas, variables_artificiales
end


function mostrar_numero(numero; mostrar_m=false)
    if mostrar_m && numero == -1_000_000.0
        return "-M"
    elseif mostrar_m && numero == 1_000_000.0
        return "M"
    else
        return string(round(numero, digits=4))
    end
end


function mostrar_fila(nombre, valores; mostrar_m=false)#mostar fila completa de la tabla
    texto = rpad(nombre, 6) #variable para nombre de la fila ej:F0, X3,X4 #rpad para que se vea ordenado espacio 6 veces
    for valor in valores
        texto *= rpad(mostrar_numero(valor, mostrar_m=mostrar_m), 12) # el * signifivc concatenar al nuevo texto
    end
    println(texto)
end


# Ahora la fila objetivo es obligatoria (tercer argumento posicional)
function mostrar_tabla_inicial(tabla, nombreVariable, variables_basicas, fila_objetivo; fila_objetivo_m=false)
    println("\nTabla del método:")
    encabezado = rpad("Base", 6)
    for nombre in nombreVariable
        encabezado *= rpad(nombre, 12)
    end
    encabezado *= rpad("LD", 12)
    println(encabezado)
    
    mostrar_fila("F0", fila_objetivo, mostrar_m=fila_objetivo_m)
    
    for i in 1:size(tabla, 1)
        mostrar_fila(variables_basicas[i], tabla[i, :])
    end
end


function mostrar_bi_ni(nombreVariable, variables_basicas)
    no_basicas = String[]
    for nombre in nombreVariable
        if !(nombre in variables_basicas)
            push!(no_basicas, nombre)
        end
    end

    println("BI (variables básicas): ", variables_basicas)
    println("NI (variables no básicas): ", no_basicas)
end


function crear_fila_objetivo(problema, nombreVariable, nombreTipo_Columna, objetivo)
    # Big-M transforma minimización en maximización cambiando sus signos.
    signo_objetivo = 1.0
    if objetivo
        signo_objetivo = -1.0
    end
    fila_objetivo = zeros(Float64, length(nombreVariable) + 1)

    for i in 1:problema.numero_variables
        fila_objetivo[i] = signo_objetivo * problema.coeficientes_objetivo[i]
    end

    # Las variables artificiales reciben la penalización M.
    for i in 1:length(nombreVariable)
        if nombreTipo_Columna[i] == "artificial"
            fila_objetivo[i] = -1_000_000.0
        end
    end

    return fila_objetivo
end


function corregir_fila_objetivo!(fila_objetivo, tabla, variables_basicas, variables_artificiales)
    M = 1_000_000.0

    for i in 1:length(variables_basicas)
        if variables_basicas[i] in variables_artificiales
            # Como la artificial ya es basica, se combina su fila con la objetiva
            # para que su coeficiente quede en cero.
            fila_objetivo .+= M .* tabla[i, :]
        end
    end

    return fila_objetivo
end


function mostrar_cambio_fila_objetivo(fila_original, tabla, variables_basicas, variables_artificiales, nombreVariable)
    fila_temporal = copy(fila_original)
    println("\nConversión de la fila objetivo:")
    mostrar_fila("F0", fila_temporal, mostrar_m=true)

    for i in 1:length(variables_basicas)
        if variables_basicas[i] in variables_artificiales
            println("F0 = F0 + M * fila de ", variables_basicas[i])
            fila_temporal .+= 1_000_000.0 .* tabla[i, :]
            mostrar_fila("F0", fila_temporal)
        end
    end

    if isempty(variables_artificiales)
        println("No hay variables artificiales; la fila objetivo no necesita corrección.")
    end
end


function buscar_columna_pivote(fila_objetivo)
    posicion = 0
    mayor = 0.0

    # No se revisa la ultima posicion: es el lado derecho, no una variable.
    for i in 1:length(fila_objetivo)-1
        if fila_objetivo[i] > mayor
            mayor = fila_objetivo[i]
            posicion = i
        end
    end

    return posicion
end


function buscar_fila_pivote(tabla, columna_pivote)
    posicion = 0
    menor = Inf   #inifnito para comarar y agarrar el valooor menor

    for i in 1:size(tabla, 1)
        if tabla[i, columna_pivote] > 0
            # La razon minima indica que restriccion limita el aumento.
            cocienteMinimo = tabla[i, end] / tabla[i, columna_pivote]
            if cocienteMinimo < menor
                menor = cocienteMinimo
                posicion = i
            end
        end
    end

    return posicion
end


function hacer_pivote!(tabla, fila_objetivo, fila_pivote, columna_pivote)
    pivote = tabla[fila_pivote, columna_pivote]
    println("Elemento pivote: ", pivote)
    println("Paso 1: dividir la fila pivote entre ", pivote)
    # hacemos que el elemento pivote sea igual a 1.
    tabla[fila_pivote, :] ./= pivote

    for i in 1:size(tabla, 1)
        if i != fila_pivote #signifiva que no modifique la fila pivote pero si las demas
            factor = tabla[i, columna_pivote]
            println("Paso 2: fila ", i, " = fila ", i, " - (", factor, ") * fila pivote")
            # Luego hacemos ceros en esa columna para las otras restricciones.
            tabla[i, :] .-= factor .* tabla[fila_pivote, :]
        end
    end

    factor = fila_objetivo[columna_pivote]
    println("Paso 3: fila objetivo = fila objetivo - (", factor, ") * fila pivote")
    # Finalmente hacemos cero el coeficiente de la columna pivote en Z.
    fila_objetivo .-= factor .* tabla[fila_pivote, :]
end


function hacer_una_iteracion!(tabla, fila_objetivo, nombreVariable, variables_basicas)
    columna_pivote = buscar_columna_pivote(fila_objetivo)

    if columna_pivote == 0 #si devuelve 0 ya no encontre ningun coeficinete positivo
        return false
    end

    println("Columna pivote: ", nombreVariable[columna_pivote], " (columna ", columna_pivote, ")")

    fila_pivote = buscar_fila_pivote(tabla, columna_pivote)

    println("Fila pivote: ", fila_pivote, " (variable básica actual: ", variables_basicas[fila_pivote], ")")
    hacer_pivote!(tabla, fila_objetivo, fila_pivote, columna_pivote)
    variables_basicas[fila_pivote] = nombreVariable[columna_pivote]
    println("Nueva variable básica: ", variables_basicas[fila_pivote])

    return true
end


function obtener_solucion(tabla, nombreVariable, variables_basicas, numero_variables)
    # Una variable basica toma el lado derecho de su fila.
    solucion = zeros(Float64, numero_variables)

    for i in 1:length(variables_basicas)
        nombre = variables_basicas[i]
        # Se quita la x para obtener el número de la variable.
        numero = parse(Int, nombre[2:end])
        if numero <= numero_variables
            solucion[numero] = round(tabla[i, end], digits=4)
        end
    end

    return solucion
end


function metodo_big_m(problema::ProblemaBase, objetivo::Bool)

    tabla, nombreVariable, nombreTipo_Columna, variables_basicas, variables_artificiales = construir_tabla_inicial(problema)

    println("Ejecutando el método Big-M...")

    fila_objetivo = crear_fila_objetivo(problema, nombreVariable, nombreTipo_Columna, objetivo)
    fila_objetivo_sin_corregir = copy(fila_objetivo)
    corregir_fila_objetivo!(fila_objetivo, tabla, variables_basicas, variables_artificiales)

    println("Objetivo: ", objetivo ? "minimizar" : "maximizar")
    println("\nInicialización de la iteración:")
    mostrar_bi_ni(nombreVariable, variables_basicas)
    
    println("Fila objetivo inicial, antes de corregir las artificiales:")
    # Llamada corregida con la fila objetivo como argumento obligatorio
    mostrar_tabla_inicial(tabla, nombreVariable, variables_basicas, fila_objetivo_sin_corregir, fila_objetivo_m=true)
    
    mostrar_cambio_fila_objetivo(fila_objetivo_sin_corregir, tabla, variables_basicas,
        variables_artificiales, nombreVariable)
        
    println("\nMatriz inicial después de corregir la fila objetivo:")
    # Llamada corregida con la fila objetivo como argumento obligatorio
    mostrar_tabla_inicial(tabla, nombreVariable, variables_basicas, fila_objetivo)

    numero_iteracion = 1
    seguirIteraciones = true
    while seguirIteraciones
        seguirIteraciones = hacer_una_iteracion!(tabla, fila_objetivo, nombreVariable, variables_basicas)
        if !seguirIteraciones
            break
        end

        println("\nIteración ", numero_iteracion)
        mostrar_bi_ni(nombreVariable, variables_basicas)
        println("Tabla después del pivote:")
        # Llamada corregida con la fila objetivo como argumento obligatorio
        mostrar_tabla_inicial(tabla, nombreVariable, variables_basicas, fila_objetivo)
        numero_iteracion += 1
    end

    solucion = obtener_solucion(tabla, nombreVariable, variables_basicas, problema.numero_variables)
    println("\nSolución encontrada:")
    for i in 1:problema.numero_variables
        println("x$i = ", solucion[i])
    end
    println("Variables básicas finales: ", variables_basicas)
    println("Variables artificiales: ", variables_artificiales)
    valorObjetivo = objetivo ? fila_objetivo[end] : -fila_objetivo[end]
    println("Valor de la función objetivo: ", valorObjetivo)

    return tabla, fila_objetivo, nombreVariable, nombreTipo_Columna, variables_basicas, variables_artificiales, solucion
end