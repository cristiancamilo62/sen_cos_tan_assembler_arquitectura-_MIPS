.data
    prompt:         .asciiz "Ingrese un �ngulo en grados: "
    result_msg:     .asciiz "El coseno de este �ngulo es: "
    pi:             .float 3.141592653589793    # Valor de ?
    degree_to_rad:  .float 0.017453292519943    # ?/180
    angle_360:      .float 360.0                # Para ajustar �ngulos fuera de rango
    one:            .float 1.0                  # Constante 1.0
    minus_one:      .float -1.0                 # Constante -1.0
    zero:           .float 0.0                  # Constante 0.0
    precision:      .float 0.0000001            # Precisi�n deseada para la serie
    two:            .float 2.0                  # Constante 2.0

.text
.globl main

main:
    # Mostrar mensaje para ingreso del �ngulo
    li $v0, 4                  # C�digo de syscall para imprimir string
    la $a0, prompt             # Cargar direcci�n del mensaje
    syscall

    # Leer el �ngulo en grados
    li $v0, 6                  # C�digo de syscall para leer float
    syscall                    # El �ngulo se almacena en $f0

    # Ajustar �ngulo si es negativo o mayor a 360
    jal adjust_angle           # Ajusta el �ngulo a rango [0, 360)

    # Convertir grados a radianes
    jal degrees_to_radians     # Convierte de grados a radianes, resultado en $f0

    # Calcular coseno mediante serie de Taylor
    jal calculate_cosine       # Calcula el coseno, resultado en $f0

    # Mostrar resultado
    li $v0, 4                  # C�digo para imprimir string
    la $a0, result_msg         # Cargar direcci�n del mensaje
    syscall

    li $v0, 2                  # C�digo para imprimir float
    mov.s $f12, $f0            # Mover resultado a $f12 para imprimirlo
    syscall

    # Terminar programa
    li $v0, 10                 # C�digo para salir
    syscall

#--------------------------------------------------
# Ajusta el �ngulo al rango [0, 360)
#--------------------------------------------------
adjust_angle:
    l.s $f1, angle_360         # Cargar 360.0 en $f1
    l.s $f2, zero              # Cargar 0.0 en $f2

adjust_negative:
    c.lt.s $f0, $f2            # Si �ngulo < 0
    bc1f adjust_positive       # Si no es negativo, verificar si es > 360
    add.s $f0, $f0, $f1        # Sumar 360 para hacerlo positivo
    j adjust_negative          # Verificar nuevamente

adjust_positive:
    c.lt.s $f0, $f1            # Si �ngulo < 360
    bc1t angle_adjusted        # Si es < 360, ya est� ajustado
    sub.s $f0, $f0, $f1        # Restar 360 para reducirlo
    j adjust_positive          # Verificar nuevamente

angle_adjusted:
    jr $ra                     # Volver a donde fue llamado

#--------------------------------------------------
# Convierte grados a radianes: rad = (pi/180) * grados
#--------------------------------------------------
degrees_to_radians:
    l.s $f1, degree_to_rad     # Cargar el factor de conversi�n (?/180)
    mul.s $f0, $f0, $f1        # Multiplicar el �ngulo por el factor
    jr $ra                     # Volver a donde fue llamado

#--------------------------------------------------
# Calcula el coseno usando la serie de Taylor
# cos(x) = 1 - x�/2! + x?/4! - x?/6! + ...
#--------------------------------------------------
calculate_cosine:
    # Inicializar variables para la serie de Taylor
    l.s $f1, one               # Resultado acumulado = 1.0 (primer t�rmino)
    mov.s $f2, $f0             # x (�ngulo en radianes)
    mul.s $f3, $f0, $f0        # x� en $f3
    
    # Variables para el c�lculo iterativo
    l.s $f4, one               # Valor actual del factorial
    l.s $f5, minus_one         # Signo alternante (-1)
    l.s $f6, precision         # Precisi�n requerida
    
    # Variables para el t�rmino actual
    mov.s $f8, $f3             # x� (potencia actual)
    li $t0, 2                  # n = 2 (empezamos con el segundo t�rmino: -x�/2!)
    li $t1, 2                  # contador para factorial
    
    # Calculamos 2! para el primer t�rmino
    l.s $f7, two               # Cargar 2.0
    mul.s $f4, $f4, $f7        # f4 = 2.0 (2!)
    
    # Calcular el segundo t�rmino: -x�/2!
    div.s $f9, $f8, $f4        # x�/2!
    mul.s $f9, $f9, $f5        # -x�/2!
    add.s $f1, $f1, $f9        # Sumar al resultado: 1.0 + (-x�/2!)
    
    # Continuar con los siguientes t�rminos
    li $t2, 10                 # L�mite m�ximo de iteraciones (5 t�rminos en total)
    li $t3, 1                  # Contador de iteraciones
    
taylor_loop:
    # Verificar si hemos alcanzado el l�mite de iteraciones
    beq $t3, $t2, taylor_done
    
    # Preparar para el siguiente t�rmino
    addi $t0, $t0, 2           # n += 2 (4, 6, 8, ...)
    
    # Actualizar potencia: x^n = x^(n-2) * x�
    mul.s $f8, $f8, $f3        # x^n = x^(n-2) * x�
    
    # Actualizar factorial: n! = (n-2)! * (n-1) * n
    addi $t1, $t0, -1          # n-1
    mtc1 $t1, $f7              # Mover n-1 a f7
    cvt.s.w $f7, $f7           # Convertir a float
    mul.s $f4, $f4, $f7        # f4 *= (n-1)
    
    mtc1 $t0, $f7              # Mover n a f7
    cvt.s.w $f7, $f7           # Convertir a float
    mul.s $f4, $f4, $f7        # f4 *= n
    
    # Actualizar signo: -1 * signo anterior
    l.s $f7, minus_one
    mul.s $f5, $f5, $f7        # Cambiar signo
    
    # Calcular el t�rmino actual: signo * x^n / n!
    div.s $f9, $f8, $f4        # x^n / n!
    mul.s $f9, $f9, $f5        # signo * x^n / n!
    
    # Verificar si el t�rmino es lo suficientemente peque�o
    abs.s $f10, $f9            # |t�rmino|
    c.lt.s $f10, $f6           # Si |t�rmino| < precisi�n
    bc1t taylor_done           # Terminar si el t�rmino es muy peque�o
    
    # Sumar el t�rmino al resultado
    add.s $f1, $f1, $f9        # Sumar t�rmino al resultado
    addi $t3, $t3, 1           # Incrementar contador de iteraciones
    
    j taylor_loop              # Continuar con el siguiente t�rmino
    
taylor_done:
    mov.s $f0, $f1             # Mover resultado final a $f0
    jr $ra                     # Volver a donde fue llamado