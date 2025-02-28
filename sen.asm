# Programa en MIPS para calcular el seno de un ángulo usando series de Taylor
# sin(x) = x - x^3/3! + x^5/5! - x^7/7! + x^9/9! - ...
# El programa acepta ángulos en grados (positivos) y los normaliza
# Da valor exacto 0 para ángulos de 0, 180 y 360 grados

.data
    prompt:     .asciiz "Ingrese el valor del angulo en grados (debe ser positivo): "
    error_msg:  .asciiz "Error: El angulo debe ser positivo. Intente de nuevo.\n"
    result_msg: .asciiz "El valor de sin(x) es: "
    angle_msg:  .asciiz "Angulo normalizado (grados): "
    newline:    .asciiz "\n"
    const_one:  .float 1.0
    const_zero: .float 0.0
    const_neg:  .float -1.0
    pi:         .float 3.14159265359
    f180:       .float 180.0    # Para convertir grados a radianes y comprobar cuadrante
    f360:       .float 360.0    # Para normalizar ángulos
    epsilon:    .float 0.0001   # Margen de error para valores cercanos a 0, 180, 360
    
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
    bc1t check_special_angles
    sub.s $f0, $f0, $f1  # ángulo = ángulo - 360
    j normalize_angle
    
check_special_angles:
    # Verificar si el ángulo es cercano a 0, 180 o 360 grados
    lwc1 $f2, const_zero   # Cargar 0.0
    lwc1 $f3, f180         # Cargar 180.0
    lwc1 $f4, f360         # Cargar 360.0
    lwc1 $f5, epsilon      # Cargar margen de error
    
    # Verificar si ángulo ? 0
    sub.s $f6, $f0, $f2    # f6 = ángulo - 0
    abs.s $f6, $f6         # f6 = |ángulo - 0|
    c.lt.s $f6, $f5        # Si |ángulo - 0| < epsilon
    bc1t angle_is_zero
    
    # Verificar si ángulo ? 180
    sub.s $f6, $f0, $f3    # f6 = ángulo - 180
    abs.s $f6, $f6         # f6 = |ángulo - 180|
    c.lt.s $f6, $f5        # Si |ángulo - 180| < epsilon
    bc1t angle_is_zero
    
    # Verificar si ángulo ? 360
    sub.s $f6, $f0, $f4    # f6 = ángulo - 360
    abs.s $f6, $f6         # f6 = |ángulo - 360|
    c.lt.s $f6, $f5        # Si |ángulo - 360| < epsilon
    bc1t angle_is_zero
    
    # Si no es un ángulo especial, continuar con el cálculo normal
    j continue_calculation
    
angle_is_zero:
    # Para ángulos de 0, 180 o 360, establecer resultado exacto como 0.0
    lwc1 $f0, const_zero   # Cargar 0.0 como resultado
    
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
    
    # Mostrar mensaje de resultado
    li $v0, 4
    la $a0, result_msg
    syscall
    
    # Imprimir el resultado (valor del seno = 0.0)
    mov.s $f12, $f0        # 0.0 en $f12
    li $v0, 2              # Código de syscall para imprimir float
    syscall
    
    # Imprimir nueva línea y terminar
    li $v0, 4
    la $a0, newline
    syscall
    
    # Terminar programa
    li $v0, 10
    syscall
    
continue_calculation:
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
    
    # Guardar el ángulo normalizado para verificar el cuadrante después
    mov.s $f9, $f0
    
    # Convertir de grados a radianes: radianes = grados * (PI / 180)
    lwc1 $f1, pi        # Cargar PI
    lwc1 $f2, f180      # Cargar 180.0
    div.s $f3, $f1, $f2  # f3 = PI / 180
    mul.s $f12, $f0, $f3 # f12 = grados * (PI / 180) = radianes
    
    # Llamar a la función para calcular seno
    jal calculate_sine
    
    # El resultado está en $f0
    # Verificar si el ángulo está en el tercer o cuarto cuadrante (entre 180 y 360 grados)
    # En ese caso, el seno debe ser negativo
    lwc1 $f2, f180      # Cargar 180.0
    c.lt.s $f2, $f9     # Si 180 < ángulo (ángulo > 180), invertir signo
    bc1f skip_sign_change
    
    # Invertir el signo del resultado
    neg.s $f0, $f0
    
skip_sign_change:
    # Mover resultado a $f12 para imprimir
    mov.s $f12, $f0
    
    # Mostrar mensaje de resultado
    li $v0, 4
    la $a0, result_msg
    syscall
    
    # Imprimir el resultado (valor del seno)
    li $v0, 2       # Código de syscall para imprimir float
    syscall
    
    # Imprimir nueva línea
    li $v0, 4
    la $a0, newline
    syscall
    
    # Terminar programa
    li $v0, 10
    syscall

# Función para calcular el seno usando serie de Taylor
calculate_sine:
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
    
term_loop:
    # Si no es el primer término, calcular siguiente término de la serie
    beq $t2, 5, skip_first_term  # Si es el primer término, ya está en $f2
    jal next_term
    
    # Actualizar resultado acumulado ($f2 += $f3)
    add.s $f2, $f2, $f3
    
skip_first_term:
    # Decrementar contador de términos
    addi $t2, $t2, -1
    
    # Si quedan términos, continuar el bucle
    bgtz $t2, term_loop
    
    # Mover resultado final a $f0
    mov.s $f0, $f2
    
    # Restaurar valores de la pila
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    # Retornar
    jr $ra

# Función para calcular el siguiente término de la serie
next_term:
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