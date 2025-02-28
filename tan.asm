# Programa en MIPS para calcular la tangente de un ángulo
# tangente(x) = seno(x) / coseno(x)
# El programa acepta ángulos en grados y los normaliza al rango [0, 360)
# Maneja casos especiales donde el coseno es cero (tangente indefinida)

.data
    prompt:         .asciiz "Ingrese el valor del angulo en grados: "
    error_msg:      .asciiz "Error: El angulo debe ser positivo. Intente de nuevo.\n"
    result_msg:     .asciiz "El valor de tan(x) es: "
    undefined_msg:  .asciiz "Tangente indefinida (division por cero)\n"
    angle_msg:      .asciiz "Angulo normalizado (grados): "
    sin_msg:        .asciiz "Seno del angulo: "
    cos_msg:        .asciiz "Coseno del angulo: "
    newline:        .asciiz "\n"
    const_one:      .float 1.0
    const_zero:     .float 0.0
    const_neg:      .float -1.0
    pi:             .float 3.14159265359
    f90:            .float 90.0      # Para detectar divisiones por cero (cos(90) = 0)
    f180:           .float 180.0     # Para convertir grados a radianes
    f270:           .float 270.0     # Para detectar divisiones por cero (cos(270) = 0)
    f360:           .float 360.0     # Para normalizar ángulos
    epsilon:        .float 0.0001    # Margen de error para valores cercanos a 0
    precision:      .float 0.0000001 # Precisión para series de Taylor
    
.text
.globl main

main:
    # Mostrar prompt al usuario
    li $v0, 4
    la $a0, prompt
    syscall
    
    # Leer el valor del ángulo en grados
    li $v0, 6       # Código de syscall para leer float
    syscall
    
    # Verificar si el ángulo es negativo
    lwc1 $f2, const_zero   # Cargar 0.0
    c.lt.s $f0, $f2        # Si f0 < 0 (ángulo negativo)
    bc1f angle_is_valid    # Si no es negativo, continuar
    
    # Mostrar mensaje de error para ángulo negativo
    li $v0, 4
    la $a0, error_msg
    syscall
    j main                 # Volver a pedir el ángulo
    
angle_is_valid:
    # $f0 contiene el valor del ángulo en grados
    # Normalizar el ángulo al rango [0, 360)
    lwc1 $f1, f360      # Cargar 360.0
    
normalize_angle:
    # Comprobar si el ángulo es >= 360
    c.lt.s $f0, $f1     # Si f0 < f1 (ángulo < 360), saltar
    bc1t check_special_cases
    sub.s $f0, $f0, $f1  # ángulo = ángulo - 360
    j normalize_angle
    
check_special_cases:
    # Verificar si el ángulo es cercano a 90 o 270 grados (donde coseno = 0)
    lwc1 $f2, f90         # Cargar 90.0
    lwc1 $f3, f270        # Cargar 270.0
    lwc1 $f4, epsilon     # Cargar margen de error
    
    # Verificar si ángulo ? 90
    sub.s $f5, $f0, $f2    # f5 = ángulo - 90
    abs.s $f5, $f5         # f5 = |ángulo - 90|
    c.lt.s $f5, $f4        # Si |ángulo - 90| < epsilon
    bc1t tangent_undefined
    
    # Verificar si ángulo ? 270
    sub.s $f5, $f0, $f3    # f5 = ángulo - 270
    abs.s $f5, $f5         # f5 = |ángulo - 270|
    c.lt.s $f5, $f4        # Si |ángulo - 270| < epsilon
    bc1t tangent_undefined
    
    # Si no es un caso especial, continuar con el cálculo normal
    j calculate_tangent
    
tangent_undefined:
    # Para ángulos de 90 o 270, la tangente es indefinida
    
    # Mostrar el ángulo normalizado
    li $v0, 4
    la $a0, angle_msg
    syscall
    
    mov.s $f12, $f0        # Mover ángulo a $f12 para imprimir
    li $v0, 2              # Código de syscall para imprimir float
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Mostrar mensaje de tangente indefinida
    li $v0, 4
    la $a0, undefined_msg
    syscall
    
    # Terminar programa
    li $v0, 10
    syscall
    
calculate_tangent:
    # Mostrar el ángulo normalizado
    li $v0, 4
    la $a0, angle_msg
    syscall
    
    mov.s $f12, $f0      # Mover ángulo normalizado a $f12 para imprimir
    li $v0, 2            # Código de syscall para imprimir float
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Guardar el ángulo para calcular seno y coseno
    mov.s $f25, $f0      # Guardar ángulo original
    
    # Calcular el seno del ángulo
    mov.s $f12, $f0      # Colocar ángulo como parámetro
    jal calculate_sine   # Llamar a la función para calcular seno
    
    # Guardar resultado del seno
    mov.s $f20, $f0      # Guardar el seno calculado
    
    # Mostrar el seno calculado (opcional, para depuración)
    li $v0, 4
    la $a0, sin_msg
    syscall
    
    mov.s $f12, $f20     # Mover seno a $f12 para imprimir
    li $v0, 2            # Código de syscall para imprimir float
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Calcular el coseno del ángulo
    mov.s $f12, $f25     # Recuperar ángulo original
    jal calculate_cosine # Llamar a la función para calcular coseno
    
    # Guardar resultado del coseno
    mov.s $f21, $f0      # Guardar el coseno calculado
    
    # Mostrar el coseno calculado (opcional, para depuración)
    li $v0, 4
    la $a0, cos_msg
    syscall
    
    mov.s $f12, $f21     # Mover coseno a $f12 para imprimir
    li $v0, 2            # Código de syscall para imprimir float
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Verificar si el coseno es muy cercano a cero
    lwc1 $f22, epsilon   # Cargar margen de error
    abs.s $f23, $f21     # f23 = |coseno|
    c.lt.s $f23, $f22    # Si |coseno| < epsilon
    bc1t tangent_undefined  # Si coseno ? 0, tangente indefinida
    
    # Calcular tangente = seno / coseno
    div.s $f0, $f20, $f21  # f0 = seno / coseno
    
    # Mostrar mensaje de resultado
    li $v0, 4
    la $a0, result_msg
    syscall
    
    # Imprimir el resultado (valor de la tangente)
    mov.s $f12, $f0     # Mover resultado a $f12 para imprimir
    li $v0, 2           # Código de syscall para imprimir float
    syscall
    
    # Imprimir nueva línea
    li $v0, 4
    la $a0, newline
    syscall
    
    # Terminar programa
    li $v0, 10
    syscall

#--------------------------------------------------------------
# Función para calcular el seno usando serie de Taylor
# sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...
#--------------------------------------------------------------
calculate_sine:
    # Convertir de grados a radianes: radianes = grados * (PI / 180)
    lwc1 $f1, pi        # Cargar PI
    lwc1 $f2, f180      # Cargar 180.0
    div.s $f3, $f1, $f2 # f3 = PI / 180
    mul.s $f12, $f12, $f3 # f12 = grados * (PI / 180) = radianes
    
    # Guardar valores en la pila
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Inicializar registros
    mov.s $f0, $f12         # f0 = x (valor inicial en radianes)
    mov.s $f1, $f12         # f1 = x (para cálculos de potencia)
    mov.s $f2, $f12         # f2 = resultado acumulado = x inicialmente
    
    # Cargar constantes en coma flotante
    lwc1 $f4, const_one     # f4 = 1.0 (constante)
    lwc1 $f5, const_neg     # f5 = -1.0 (para cambiar signo)
    
    # Variables para el cálculo
    li $t0, 1               # t0 = exponente actual
    li $t1, 1               # t1 = factorial actual
    li $t2, 5               # t2 = número de términos a calcular
    
sine_term_loop:
    # Si no es el primer término, calcular siguiente término de la serie
    beq $t2, 5, skip_sine_first_term  # Si es el primer término, ya está en $f2
    jal sine_next_term
    
    # Actualizar resultado acumulado ($f2 += $f3)
    add.s $f2, $f2, $f3
    
skip_sine_first_term:
    # Decrementar contador de términos
    addi $t2, $t2, -1
    
    # Si quedan términos, continuar el bucle
    bgtz $t2, sine_term_loop
    
    # Mover resultado final a $f0
    mov.s $f0, $f2
    
    # Restaurar valores de la pila
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    # Retornar
    jr $ra

# Función para calcular el siguiente término de la serie del seno
sine_next_term:
    # Guardar valores en la pila
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $t3, 4($sp)
    
    # Incrementar exponente por 2 (x^1, x^3, x^5, ...)
    addi $t0, $t0, 2
    
    # Calcular x^n (potencia)
    mul.s $f1, $f1, $f12    # f1 *= x
    mul.s $f1, $f1, $f12    # f1 *= x (multiplicamos dos veces para obtener x^3, x^5, ...)
    
    # Calcular factorial del denominador
    move $t3, $t0           # Guardar exponente actual
    mul $t1, $t1, $t3       # t1 *= t0
    addi $t3, $t3, -1       # t3 = t0 - 1
    mul $t1, $t1, $t3       # t1 *= (t0-1)
    
    # Convertir factorial a flotante
    mtc1 $t1, $f7
    cvt.s.w $f7, $f7        # f7 = n! como float
    
    # Calcular término: (x^n)/n!
    div.s $f8, $f1, $f7     # f8 = x^n / n!
    
    # Cambiar signo para este término
    mul.s $f3, $f8, $f5     # f3 = término con signo para esta iteración
    
    # Cambiar signo para próxima iteración (alternar entre positivo y negativo)
    neg.s $f5, $f5          # Invertir el signo para el próximo término
    
    # Restaurar valores de la pila
    lw $ra, 0($sp)
    lw $t3, 4($sp)
    addi $sp, $sp, 8
    
    # Retornar
    jr $ra

#--------------------------------------------------------------
# Función para calcular el coseno usando serie de Taylor
# cos(x) = 1 - x²/2! + x?/4! - x?/6! + ...
#--------------------------------------------------------------
calculate_cosine:
    # Convertir de grados a radianes: radianes = grados * (PI / 180)
    lwc1 $f1, pi        # Cargar PI
    lwc1 $f2, f180      # Cargar 180.0
    div.s $f3, $f1, $f2 # f3 = PI / 180
    mul.s $f12, $f12, $f3 # f12 = grados * (PI / 180) = radianes
    
    # Inicializar variables para la serie de Taylor
    lwc1 $f1, const_one     # Resultado acumulado = 1.0 (primer término)
    mov.s $f2, $f12         # x (ángulo en radianes)
    mul.s $f3, $f2, $f2     # x² en $f3
    
    # Variables para el cálculo iterativo
    lwc1 $f4, const_one     # Valor actual del factorial
    lwc1 $f5, const_neg     # Signo alternante (-1)
    lwc1 $f6, precision     # Precisión requerida
    
    # Variables para el término actual
    mov.s $f8, $f3          # x² (potencia actual)
    li $t0, 2               # n = 2 (empezamos con el segundo término: -x²/2!)
    li $t1, 2               # contador para factorial
    
    # Calculamos 2! para el primer término
    mtc1 $t1, $f7           # Mover 2 a f7
    cvt.s.w $f7, $f7        # Convertir a float
    mul.s $f4, $f4, $f7     # f4 = 2.0 (2!)
    
    # Calcular el segundo término: -x²/2!
    div.s $f9, $f8, $f4     # x²/2!
    mul.s $f9, $f9, $f5     # -x²/2!
    add.s $f1, $f1, $f9     # Sumar al resultado: 1.0 + (-x²/2!)
    
    # Continuar con los siguientes términos
    li $t2, 10              # Límite máximo de iteraciones (5 términos en total)
    li $t3, 1               # Contador de iteraciones
    
cosine_taylor_loop:
    # Verificar si hemos alcanzado el límite de iteraciones
    beq $t3, $t2, cosine_taylor_done
    
    # Preparar para el siguiente término
    addi $t0, $t0, 2        # n += 2 (4, 6, 8, ...)
    
    # Actualizar potencia: x^n = x^(n-2) * x²
    mul.s $f8, $f8, $f3     # x^n = x^(n-2) * x²
    
    # Actualizar factorial: n! = (n-2)! * (n-1) * n
    addi $t1, $t0, -1       # n-1
    mtc1 $t1, $f7           # Mover n-1 a f7
    cvt.s.w $f7, $f7        # Convertir a float
    mul.s $f4, $f4, $f7     # f4 *= (n-1)
    
    mtc1 $t0, $f7           # Mover n a f7
    cvt.s.w $f7, $f7        # Convertir a float
    mul.s $f4, $f4, $f7     # f4 *= n
    
    # Actualizar signo: -1 * signo anterior
    neg.s $f5, $f5          # Cambiar signo
    
    # Calcular el término actual: signo * x^n / n!
    div.s $f9, $f8, $f4     # x^n / n!
    mul.s $f9, $f9, $f5     # signo * x^n / n!
    
    # Verificar si el término es lo suficientemente pequeño
    abs.s $f10, $f9         # |término|
    c.lt.s $f10, $f6        # Si |término| < precisión
    bc1t cosine_taylor_done # Terminar si el término es muy pequeño
    
    # Sumar el término al resultado
    add.s $f1, $f1, $f9     # Sumar término al resultado
    addi $t3, $t3, 1        # Incrementar contador de iteraciones
    
    j cosine_taylor_loop    # Continuar con el siguiente término
    
cosine_taylor_done:
    mov.s $f0, $f1          # Mover resultado final a $f0
    jr $ra                  # Volver a donde fue llamado