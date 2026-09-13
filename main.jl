mutable struct ProblemaBase
    numero_variables::Int
    numero_restricciones::Int
    ganancia::Vector{Float64}
    coeficientes::Matrix{Float64}
    limites::Vector{Float64}
    signos::Vector{String}
end

mutable struct Metodo_Algoritmo
    algoritmo::Int
    objetivo::Int
end

function metodo_simplex(problema::ProblemaBase, objetivo::Int)
    println("Ejecutando el método Simplex para el objetivo: $(objetivo == 1 ? "maximizar" : "minimizar")...")

    println("Número de variables: ", problema.numero_variables)
    println("Número de restricciones: ", problema.numero_restricciones)
    println("Función objetivo: ", problema.ganancia)
    println("Coeficientes de las restricciones: ", problema.coeficientes)
    println("Límites de las restricciones: ", problema.limites)
    println("Signos de las restricciones: ", problema.signos)

    
    Base.run(`cmd /c pause`)
end

function metodo_big_m(problema::ProblemaBase, objetivo::Int)
    println("Ejecutando el método Big M para el objetivo: $(objetivo == 1 ? "maximizar" : "minimizar")...")
    Base.run(`cmd /c pause`)
end

function metodo_dual_simplex(problema::ProblemaBase, objetivo::Int)
    println("Ejecutando el método Dual Simplex para el objetivo: $(objetivo == 1 ? "maximizar" : "minimizar")...")
    Base.run(`cmd /c pause`)
end



function mostrar_menu_plantilla(menu_titulo, opciones_plantilla, funciones, problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo)
    indice = 0

    while indice != length(opciones_plantilla)

        Base.run(`cmd /c cls`)
        println(menu_titulo)
        for (i, opcion) in enumerate(opciones_plantilla)
            println("$i. $opcion")
        end
        println("Ingrese una opción:")

        ingresado = tryparse(Int, readline())

        if isnothing(ingresado)
            println("Opción no válida. Por favor, ingrese un número.")
            Base.run(`cmd /c pause`)
            continue
        end

        if ingresado < 1 || ingresado > length(opciones_plantilla)
            println("Opción no válida. Por favor, ingrese un número entre 1 y $(length(opciones_plantilla)).")
            Base.run(`cmd /c pause`)
            continue
        end

        indice = ingresado

        Base.run(`cmd /c cls`)
        funciones[indice](problema, opciones_resolver)
    end
    
end


function mostrar_menu_objetivo(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo)
    opciones_objetivo = ["Maximizar", "Minimizar", "Volver"]

    maximizar_pre(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
        opciones_resolver.objetivo = 1
        if opciones_resolver.algoritmo == 1
            metodo_simplex(problema, opciones_resolver.objetivo)
        elseif opciones_resolver.algoritmo == 2
            metodo_big_m(problema, opciones_resolver.objetivo)
        else
            metodo_dual_simplex(problema, opciones_resolver.objetivo)
        end
    end    
    minimizar_pre(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
        opciones_resolver.objetivo = 2
         if opciones_resolver.algoritmo == 1
            metodo_simplex(problema, opciones_resolver.objetivo)
        elseif opciones_resolver.algoritmo == 2
            metodo_big_m(problema, opciones_resolver.objetivo)
        else
            metodo_dual_simplex(problema, opciones_resolver.objetivo)
        end
    end
    volver(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
        #mejor que no haga nada pepeppepe
    end

    funciones = [maximizar_pre, minimizar_pre, volver]

    mostrar_menu_plantilla("=====MENU OBJETIVO====", opciones_objetivo, funciones, problema, opciones_resolver)
end

function mostrar_menu_algoritmos(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo)
    opciones_algoritmos = ["Simplex", "Big M", "Dual Simplex", "Volver"]

    simplex_pre(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
        opciones_resolver.algoritmo = 1
        mostrar_menu_objetivo(problema, opciones_resolver)
    end 
    big_m_pre(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
        opciones_resolver.algoritmo = 2
        mostrar_menu_objetivo(problema, opciones_resolver)
    end
    dual_simplex_pre(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
        opciones_resolver.algoritmo = 3
        mostrar_menu_objetivo(problema, opciones_resolver)
    end
    volver(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) = begin
       #la extraño pepeppe, no se porque se comporta como si nada paso pepepepepepepeppepepepep
    end

    funciones = [simplex_pre, big_m_pre, dual_simplex_pre, volver]
    mostrar_menu_plantilla("=====MENU ALGORITMOS====", opciones_algoritmos, funciones, problema, opciones_resolver)
end

function ingresar_problema!(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo)
    println("Ingrese el número de variables:")
    problema.numero_variables = parse(Int, readline())
    println("Ingrese el número de restricciones:")
    problema.numero_restricciones = parse(Int, readline())

    problema.ganancia = zeros(problema.numero_variables)
    println("Ingrese los coeficientes de la función objetivo:")
    
    for i in 1:problema.numero_variables
        print("Variable x$i: ")
        problema.ganancia[i] = parse(Float64, readline())
    end


    problema.coeficientes = zeros(problema.numero_restricciones, problema.numero_variables)
    println("Ingrese los coeficientes de las restricciones:")
    for i in 1:problema.numero_restricciones
        println("- Restricción $i: ")
        for j in 1:problema.numero_variables
            print("\t- Variable x$j: ")
            problema.coeficientes[i, j] = parse(Float64, readline())
        end

    end

    problema.limites = zeros(problema.numero_restricciones)
    println("Ingrese los límites de las restricciones (uno por línea):")
    for i in 1:problema.numero_restricciones
        print("Límite $i: ")
        problema.limites[i] = parse(Float64, readline())
    end

    problema.signos = Vector{String}(undef, problema.numero_restricciones)
    println("Ingrese los signos de las restricciones (uno por línea, '<=', '>=', '='):")
    for i in 1:problema.numero_restricciones
        print("Signo $i: ")
        problema.signos[i] = readline()

        if(problema.signos[i] != "<=" && problema.signos[i] != ">=" && problema.signos[i] != "=")
            println("Signo no válido. Por favor, ingrese '<=', '>=', o '='.")
            #falta modidicar el indice, esta wbda es mas inutil que alguien del grupo de microcontroladores
            i -= 1
        end

    end


    Base.run(`cmd /c cls`)
    println("Datos ingresados correctamente. Presione cualquier tecla para continuar...")
    Base.run(`cmd /c pause`)


end


function mostrar_menu_principal()

    datos_problema_principal = ProblemaBase(0, 0, zeros(0), zeros(0, 0), zeros(0), String[])
    opciones_algoritmos = Metodo_Algoritmo(0, 0)

    opciones = ["Ingresar Datos", "Resolver", "Salir"]
    funcion_mensaje_salir(problema::ProblemaBase, opciones_resolver::Metodo_Algoritmo) =  begin
        println("Saliendo del programa...")
        Base.run(`cmd /c pause`)
    end 
    funciones = [ingresar_problema!, mostrar_menu_algoritmos, funcion_mensaje_salir]
    mostrar_menu_plantilla("=====MENU PRINCIPAL====", opciones, funciones, datos_problema_principal, opciones_algoritmos)
end

mostrar_menu_principal()


