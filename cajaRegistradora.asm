# caja registradora
.include "Stock" 
.data
codigo: .space 6 # necesita 4B para un codigo, 1B para el salto de linea, y porsialasmoscas 1B mas para el operador
bienvMSJ: .asciiz "¡Bienvenido a la caja registradora! ingresa los codigos de los productos\n"

EX_001MSJ: .asciiz "El producto no esta en el stock, ingresa otro codigo:\n"
DOLAR: .asciiz "\t$"
PUNTO: .asciiz "."
N: .asciiz "\n"

.text
j Bienvenida

# ewsta funcion asume que ya esta en $t0 la direcion del string
# y que el $t1 ta esta la primera cifra del codigo
ReadString:
loop:	beq $t1, 10, LeerStock# si son iguales, ya tenemos el codigo, podemos leerlo
	
	add $t1, $t1, -48 # lo combierto en un numero 
	
	mul $t2, $t3, $t2 # desplazo como si estubiera en base 10 a $t2 (donde voy a guardar el codigo)
	add $t2, $t2, $t1
	add $t0, $t0, 1 # actualizao el indice de $t0 en 1
	
	lb $t1, ($t0) # cargo el primer digito de izq a der
	b loop

# la seccion de bienvenida, aqui nda mas coloco un mensaje de bienvenida,
# tal vez deba hacer esto por dia. 
Bienvenida: 	
	li $v0, 4
	la $a0, bienvMSJ	
	syscall
	j CicloCompraActual

# Funcion CicloCompraActual tendra:
	# priemro capta el codigo del producto
	# segundo debe recivir el codigo de operacion sobre el producto/compra
	#tercero: dar el total de la cuenta de la compra actual
CicloCompraActual:

# Funcion ingresarProducto deberá:
	# captar el codigo del producto ingresado por el usuario, de momento lo dejo en el registro $t0  
ingresarCodigo:
	li $v0, 8
	la $a0, codigo
	li $a1, 6
	syscall
	move $t0, $a0 # movemos a $t0 la direcion de lo que sea que acabamos de imgresar
	lb $s0, ($t0)
	
	# el string que metemos empieza con alguno de estos 3 codigos o es un numero solito
	# si no es ninguno de los operadores, sigue hacia ObtenerProd
	beq $s0, 42, IncrementarProducto
	beq $s0, 43, TerminarCompraActual
	beq $s0, 45, RestarProducto
	
	
	
# esta funcion se debe encargar de comparar el codigo que hay en (t0) con cada codigo de los productos
# y devolver el que coincida

# como el stock comienza siempre en 0x10010000 pues vamos viendo desde alli si el codigo
# (el primer valor) es 0, si no, seguimos viendo
ObtenerProd:
	li $a1, 0x10010000
	lb $t1, ($t0) # cargo el primer digito de izq a der
	li $t2, 0
	li $t3, 10
loop:	beq $t1, 10, LeerStock# si son iguales, ya tenemos el codigo, podemos leerlo
	
	add $t1, $t1, -48 # lo combierto en un numero 
	
	mul $t2, $t3, $t2 # desplazo como si estubiera en base 10 a $t2 (donde voy a guardar el codigo)
	add $t2, $t2, $t1
	add $t0, $t0, 1 # actualizao el indice de $t0 en 1
	
	lb $t1, ($t0) # cargo el primer digito de izq a der
	b loop
	
LeerStock:
	lw $a2, ($a1)
	beqz $a2, EX_001 # el producto no esta en el stock
	
	beq $a2, $t2, FacturarProducto  # si $a2 y $t2 son iguales, en $a1 esta la direccion de memoria donde esta el producto en stock
	add $a1, $a1, 0x20
	b LeerStock
	
# debe colocar en la lista de la compra del dia el producto
FacturarProducto:
	# imprime el nombre del producto
	li $v0, 4
	la $a0, 16($a1)
	syscall
	
	la $a0, DOLAR
	syscall
	
	li $v0, 1
	lw $a0, 8($a1)
	syscall
	
	li $v0, 4
	la $a0, PUNTO
	syscall
	
	li $v0, 1
	lw $a0, 12($a1)
	syscall
	
	li $v0, 4
	la $a0, N
	syscall
	
	# ahora le restamos por defecto 1 al stock
	lw $a2, 4($a1)
	add $a2, $a2, -1
	sw $a2, 4($a1)
	
	
	
	j CicloCompraActual
	
IncrementarProducto:
RestarProducto:
TerminarCompraActual:
Main: 








EX_001: # el producto no esta en el stock
	li $v0, 4
	la $a0, EX_001MSJ	
	syscall
	j CicloCompraActual
	
FinishProgram:
	li $v0, 10
	syscall
