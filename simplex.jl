# simplex.jl
function metodo_simplex(problema::ProblemaBase, objetivo::Bool)
    println("Ejecutando el método Simplex normal...")

        println("Número de variables: ", problema.numero_variables)
    println("Número de restricciones: ", problema.numero_restricciones)
    println("Coeficientes de la función objetivo: ", problema.coeficientes_objetivo)
    println("Coeficientes de las restricciones: ", problema.coeficientes_restricciones)
    println("Límites de las restricciones: ", problema.limites_restricciones)
    println("Signos de las restricciones: ", problema.signos)

    println("Objetivo: ", objetivo)

    Base.run(`cmd /c pause`)
end