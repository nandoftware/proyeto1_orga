# caja registradora
.include "Stock" 	
.data
truquito: .word 0 
codigo: .space 11 # necesita 9B para un codigo (el sistema implementado lee cadenas de texto), 1B para el salto de linea, y  1B mas para el operador
bienvMSJ: .asciiz "¡Bienvenido a un nuevo dia en la caja registradora! ingresa los codigos de los productos\n"

# vamos a guardar una lista enlazada con los productos de la compra actual,
# para eso vamos a guardar el codigo del pruducto, el precio total, y su nombre
# el precio total debe ser actualizado cuado lo actualizemos en el tejemaneje
# el codigo debe ser un word, 4B, la cantidad 4B, el precio total son otros dos words, 8B, y su nombre son 16B = 32
raizActual: .word 0
cabezaActual: .word 0

# vamos a guardar una lista enlazada con todos los productos compredos en el dia,
# mismo formato de next que la lista de compra actual
# 4B para el next, 4B para el codigo, 4B para la cantidad total del producto, 8B para la parte entera y decimal y 16B para el nombre
raizCierre: .word 0
cabezaCierre: .word 0


EX_001MSJ: .asciiz "El producto no esta en el stock, ingresa otro codigo:\n"
EX_002MSJ: .asciiz "No hay mas stock del producto, ingresa otro codigo:\n"
EX_003MSJ: .asciiz "No puedes aumentar la cantidad si no hay productos en la compra, ingresa otro codigo:\n"
EX_004MSJ: .asciiz "No se pueden eliminar mas productos, ingresa otro codigo:\n"
EX_005MSJ: .asciiz "codigo no valido, ingreso letras; ingresa otro codigo:\n"
DOLAR: .asciiz "\t$"
PUNTO: .asciiz "."
N: .asciiz "\n"
IGUAL: .asciiz  " = "
X: .asciiz "\tX"
MENOS: .asciiz "\t-"
TOTAL: .asciiz "Total compra:\t$"
STOCK: .asciiz " stock "
LINEAS: .asciiz "------------------------\n" 
TOTAL2: .asciiz "Total cierre de caja:\t$"
.text
j Bienvenida

# ewsta funcion asume que ya esta en $t0 la direcion del string
# y que el $t1 ta esta la primera cifra del codigo
ReadString:
loop:	
	bge $t1, 58, EX_005
	beq $t1, 10, endLoop# si son iguales, ya tenemos el codigo, podemos leerlo
	
	add $t1, $t1, -48 # lo combierto en un numero 
	
	mul $t2, $t3, $t2 # desplazo como si estubiera en base 10 a $t2 (donde voy a guardar el codigo)
	add $t2, $t2, $t1
	add $t0, $t0, 1 # actualizao el indice de $t0 en 1
	
	lb $t1, ($t0) # cargo el primer digito de izq a der
	b loop
endLoop: jr $ra

# Inicializamos Lista (IL)
ILCompraActual:
	# necesitamos 32B para todo y 4 mas para la direccion (que estará al principio)
	li $v0, 9
	la, $a0 4
	syscall
	sw $v0, raizActual # raiz tiene la direccion en memoria que le asigno el sbrk en el heap que represenata un nest para el hacia el primer elemento
	sw $v0, cabezaActual
	jr $ra
	
# Agregar Cabeza (AC)
ACCompraActual: 
	lw $s1, cabezaActual
	
	li $v0,9 
	li $a0, 36 
	syscall
	
	sw $v0, ($s1)
	sw $v0, cabezaActual
	lw $s1, cabezaActual 
	# ahora en $s1 tengo la direccion del heap
	# y para este momento en $a1 tengo la direccion del producto en el stock
	# ademas 32($s1) es donde va el apuntador al siguiente elemento
	
	lw $t8, ($a1) # guardamos el codigo del producto
	sw $t8, 4($s1) # meto el codigo en la lista de compra actual
	sw $a3, 8($s1) # en $a3 esta la cantidad de productos de un mismo en este momento
	sw $t4, 12($s1) # en $t4 estara la parte entera total
	sw $t5, 16($s1) # en $t5 estara la parte decimal total
	
	la  $t4, ($a1)
nombre:	lb $t8 16($t4)
	sb $t8, 20($s1)
	beq $t8, 0, lito
	add $t4, $t4, 1
	add $s1, $s1, 1
	b nombre
	
lito:	

	jr $ra

# Recorrer Lista (RL)
RLCompraActual:
	
	lw $t7, raizActual # cargamos la direcion a la que apunta la raiz --- el penultimo
	lw $t6, ($t7) # y aqui la direcion a la que apunta el primer word de $t7 (next) --- el ultimo
	beqz $t6, EX_003 
	lw $t8, ($t6) # y aqui la direcion a la que apunta el primer word de $t6 (next.next) ---- el siguiente
	
empieza:
	beqz $t8,termino
	lw $t7, ($t7)
	lw $t6, ($t7)
	lw $t8, ($t6)
	
	
	b empieza
termino:
	# en $t6 esta el ultimo elemento
	jr $ra
# Eliminar de la Lista (EL)	
ELCompraActual: # esta funcion elimina el ultimo elemnto de la lista, y ademas supone que ese elemento esta en $t6 y que el aterior esta en $t7
	beqz $t6, EX_004

	li $t8, 0
	sw $t8, ($t7)
	la $t8, ($t7)
	sw $t8, cabezaActual
	jr $ra

# Inicializamos Lista (IL)
ILCierreDelDia:
	li $v0, 9
	la, $a0 4
	syscall
	sw $v0, raizCierre 
	sw $v0, cabezaCierre
	jr $ra
	
# Agregar Cabeza (AC)
ACCierreDelDia: 
	
	#tenemos el productoi en ($t1) 
	
	lw $s1, cabezaCierre
	
	li $v0,9 
	li $a0, 36 
	syscall
	
	sw $v0, ($s1)
	sw $v0, cabezaCierre
	lw $s1, cabezaCierre 

	# todo lo debemos sacar de la lista enlazada de la compra actual
	
	# el codigo
	lw $t8, 4($t1)
	sw $t8, 4($s1) 
	
	# la cantidada
	lw $t8, 8($t1)
	sw $t8, 8($s1)
	
	# la parte entera
	lw $t8, 12($t1)
	sw $t8, 12($s1) 
	
	# la parte decimal
	lw $t8, 16($t1)
	sw $t8, 16($s1)
	
	
	la  $t4, ($t1)
nombre2:	
	lb $t8 20($t4)
	sb $t8, 20($s1)
	beq $t8, 0, lito2
	add $t4, $t4, 1
	add $s1, $s1, 1
	b nombre2
	
lito2:	
	jr $ra

# Actualizo producto de Cierre
AProductoCierre:
# parte decimal primero por si hay un carry
	lw $t8, 16($t1) # parte decimal del de la lista Actual
	lw $t7, 16($t2) # parte decimal del de la lista de Cierre
	add $t7, $t8, $t7
	
	li $t3,0 # aqui esta el carry
deci2:
	blt $t7, 0x64, endDeci2	
	sub $t7,$t7,0x64
	add $t3, $t3, 1
	b deci2
endDeci2:
	sw $t7, 16($t2)
	
	# ahora la parte entera
	lw $t8, 12($t1) # parte entera del de la lista Actual
	lw $t7, 12($t2) # parte entera del de la lista de Cierre
	add $t7, $t8, $t7
	add $t7, $t3, $t7
	
	sw $t7, 12($t2)
	jr $ra

RLActual2Cierre:
	move $t0, $ra
	lw $t1, raizActual
	lw $t1, ($t1)
	
recorriendo:
	beqz $t1, reocorrido 
	lw $t2, raizCierre
	lw $t2, ($t2)
	
RecorriendoInterno:

	beqz $t2, RecorridoInterno
	# verificamos si eciste el codigo 4($t1) en algun 4($t2)
	lw $t3 4($t1)
	lw $t4 4($t2)
	beq $t3, $t4, HayEnCierre # el prodducto actual esta en Cierre
	lw $t2, ($t2)
	b RecorriendoInterno 
HayEnCierre:
	jal AProductoCierre
	lw $t1, ($t1)
	b recorriendo
RecorridoInterno:
	jal ACCierreDelDia
	lw $t1, ($t1)
	b recorriendo# si llegamos hasta aca es que el producto en Actual no esta en Cierre
reocorrido:
	jr $t0

MostrarTotal:
	lw $t1, raizActual
	lw $t1, ($t1)
	
	li $t5, 0 # decimal total
	li $t7,0 # aqui esta el carry
calcDeci:
	beqz $t1, Int
	
	lw $t3 16($t1) # decimales del elemento en ($t1)
	add $t5, $t5, $t3
	
deci3:
	blt $t5, 0x64, endDeci3	
	sub $t5,$t5,0x64
	add $t7, $t7, 1
	b deci3
endDeci3: # al terminar en $t5 queda la parte decimal que es
	lw $t1, ($t1)
	b calcDeci
	
Int: 
	lw $t1, raizActual
	lw $t1, ($t1)
	
	li $t6, 0 # entero total
calcInt:
	beqz $t1, SumarCarry
	
	lw $t3 12($t1) # decimales del elemento en ($t1)
	add $t6, $t6, $t3
	lw $t1, ($t1)
	b calcInt
	
SumarCarry: 
	add $t6, $t6, $t7
	
Mostrar:

	li $v0, 4
	la $a0, TOTAL
	syscall
	
	li $v0, 1
	move $a0, $t6
	syscall
	
	li $v0, 4
	la $a0, PUNTO
	syscall
	
	li $v0, 1
	move $a0, $t5
	syscall
	
	li $v0, 4
	la $a0, N
	syscall

	jr $ra
	
	
MostrarTotal2:
	lw $t1, raizCierre
	lw $t1, ($t1)
	
	li $t5, 0 # decimal total
	li $t7,0 # aqui esta el carry
calcDeciCierre:
	beqz $t1, IntCierre
	
	lw $t3 16($t1) # decimales del elemento en ($t1)
	add $t5, $t5, $t3
	
deci4:
	blt $t5, 0x64, endDeci4	
	sub $t5,$t5,0x64
	add $t7, $t7, 1
	b deci4
endDeci4: # al terminar en $t5 queda la parte decimal que es
	lw $t1, ($t1)
	b calcDeciCierre
	
IntCierre: 
	lw $t1, raizCierre
	lw $t1, ($t1)
	
	li $t6, 0 # entero total
calcIntCierre:
	beqz $t1, SumarCarryCierre
	
	lw $t3 12($t1) # decimales del elemento en ($t1)
	add $t6, $t6, $t3
	lw $t1, ($t1)
	b calcIntCierre
	
SumarCarryCierre: 
	add $t6, $t6, $t7
	
MostrarCierre:

	li $v0, 4
	la $a0, TOTAL2
	syscall
	
	li $v0, 1
	move $a0, $t6
	syscall
	
	li $v0, 4
	la $a0, PUNTO
	syscall
	
	li $v0, 1
	move $a0, $t5
	syscall
	
	li $v0, 4
	la $a0, N
	syscall

	jr $ra
	

MostrarListaCierre:
	move $t9, $ra
	lw $t1, raizCierre
	lw $t1, ($t1)
	
MostrarProductosVendidos:
	beqz $t1, MostrarCierreCaja
	
	# muestra el nombre 
	li $v0, 4
	la $t2, 20($t1)
	move $a0, $t2
	syscall
	
	la $a0, N
	syscall
	
	la $a0, X
	syscall
	
	# mostramos la cantidad
	li $v0, 1
	lw $a0, 8($t1)
	syscall
	
	li $t2, 0x10010000
	lw $t4, ($t2)
	lw $t3, 4($t1) # codigo del producto en la lista
buscaStock:

	beq  $t4, $t3, TengoStock
	add $t2, $t2, 0x20
	lw $t4, ($t2)
	b buscaStock
TengoStock:
	
	li $v0, 4
	la $a0, STOCK
	syscall
	
	# muestro lo que queda en el stock
	li $v0, 1
	lw $a0, 4($t2)
	syscall
	
	li $v0, 4
	la $a0, DOLAR
	syscall
	
	li $v0, 1
	lw $a0, 12($t1)
	syscall
	
	li $v0, 4
	la $a0, PUNTO
	syscall

	li $v0, 1
	lw $a0, 16($t1)
	syscall
	
	li $v0, 4
	la $a0, N
	syscall
	
	lw $t1, ($t1)
	b MostrarProductosVendidos

MostrarCierreCaja:
	li $v0, 4
	la $a0, LINEAS
	syscall
	
	li $v0, 4
	la $a0, N
	syscall
	
	jal MostrarTotal2
	jr $t9
# la seccion de bienvenida, aqui nda mas coloco un mensaje de bienvenida,
# tal vez deba hacer esto por dia. 
Bienvenida: 	
	li $v0, 4
	la $a0, bienvMSJ	
	syscall
	
	jal ILCierreDelDia
	
	j CicloCompraActual

# Funcion CicloCompraActual tendra:
	# priemro capta el codigo del producto
	# segundo debe recivir el codigo de operacion sobre el producto/compra
	#tercero: dar el total de la cuenta de la compra actual
CicloCompraActual:
	lw $v0, raizActual
	bnez  $v0, ingresarCodigo
	# de una creamos la lista de la compra actual solo si no la hemos creado ya, raiz no es cero
	jal ILCompraActual

# Funcion ingresarProducto deberá:
	# captar el codigo del producto ingresado por el usuario, de momento lo dejo en el registro $t0  
ingresarCodigo:
	li $v0, 8
	la $a0, codigo
	li $a1, 11
	syscall
	move $t0, $a0 # movemos a $t0 la direcion de lo que sea que acabamos de imgresar
	lb $s0, ($t0)
	
	# el string que metemos empieza con alguno de estos 3 codigos o es un numero solito
	# si no es ninguno de los operadores, sigue hacia ObtenerProd
	beq $s0, 42, IncrementarProducto
	beq $s0, 43, TerminarCompraActual
	beq $s0, 45, RestarProducto
	beq $s0, 47, TerminarDia
	
	
	
# esta funcion se debe encargar de comparar el codigo que hay en (t0) con cada codigo de los productos
# y devolver el que coincida

# como el stock comienza siempre en 0x10010000 pues vamos viendo desde alli si el codigo
# (el primer valor) es 0, si no, seguimos viendo
	
ObtenerProd:
	li $a1, 0x10010000
	lb $t1, ($t0) # cargo el primer digito de izq a der
	li $t2, 0
	li $t3, 10
	jal ReadString
	
LeerStock:
	lw $a2, ($a1) # en $a2 se va guardando el codigo del producto que vamos leyendo
	beqz $a2, EX_001 # el producto no esta en el stock
	 
	beq $a2, $t2, FacturarProducto  # si $a2 y $t2 son iguales, en $a1 esta la direccion de memoria donde esta el producto en stock
	add $a1, $a1, 0x20
	b LeerStock
	
# debe colocar en la lista de la compra del dia el producto
FacturarProducto:
	lw $a2, 4($a1)
	beqz $a2, EX_002
	
	li $a3, 1
	lw $t4, 8($a1)
	lw $t5, 12($a1)

	jal ACCompraActual
	
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
	add $a2, $a2, -1
	sw $a2, 4($a1)
	
	
	
	j CicloCompraActual
	
# si meti un operdando es porque en 
IncrementarProducto:
	add $t0, $t0, 1
	lb $t1, ($t0) # cargo el primer digito de izq a der
	li $t2, 0 
	li $t3, 10
	jal ReadString
	
	#vamos a recorrer la lista para llegar al ultimo elemento con algo y a ese le modificamos la cantidad del producto y el precio
	jal RLCompraActual
	
	lw $a3, 8($t6) # la cantidad de productos antes de incrementar
	mul $t2, $t2, $a3 # la nueva cantidad 
	sw $t2, 8($t6)
	lw $t3, 4($t6)
	li $a1, 0x10010000
obt: # obtener el producto en stock 
	lw $t1, ($a1)
	beq $t1, $t3, endObt  # si $a2 y $t2 son iguales, en $a1 esta la direccion de memoria donde esta el producto en stock
	add $a1, $a1, 0x20
	b obt
endObt:
	# ahora le restamos la cantidad de $t2 al stock
	add $a2, $a2, $a3
	sub $a2, $a2, $t2
	sw $a2, 4($a1)
	
	
	
	# ahora hay que multiplicar el precio
	# primero la parte decimal
	lw $t1, 16($t6)
	mul $t1, $t2, $t1
	li $t3,0 # aqui esta el carry
deci:
	blt $t1, 0x64, endDeci	
	sub $t1,$t1,0x64
	add $t3, $t3, 1
	b deci
endDeci:
	sw $t1, 16($t6)
	
	
	#ahora la parte entera
	lw $t1 12($t6)
	mul $t1, $t2, $t1
	add $t1, $t3, $t1
	sw $t1, 12($t6)
	
	
	li $v0, 4
	la $a0, X
	syscall
	
	li $v0, 1
	move $a0, $t2
	syscall
	
	li $v0, 4
	la $a0, IGUAL
	syscall
	
	la $a0, DOLAR
	syscall
	
	li $v0, 1
	lw $a0, 12($t6)
	syscall
	
	li $v0, 4
	la $a0, PUNTO
	syscall
	
	li $v0, 1
	lw $a0, 16($t6)
	syscall
	
	li $v0, 4
	la $a0, N
	syscall

	j CicloCompraActual
	
RestarProducto:
	add $t0, $t0, 1
	lb $t1, ($t0) # cargo el primer digito de izq a der
	li $t2, 0  # obtenemos en t2 cuantos elementos debemos eliminar
	li $t3, 10
	jal ReadString
	
	# imprimimos el menos [cantidad de elementos]
	li $v0, 4
	la $a0, MENOS
	syscall
	
	li $v0, 1
	move $a0, $t2
	syscall
	move $t2, $a0
	
	li $v0, 4
	la $a0, N
	syscall
	
	# iteramos la cantidad que diga $t2, y para cada iteracion recorremos, cambiamos el apuntador del penultimo y lo avisamos por la salida
elimi:	beqz $t2, finEliminacion 
	jal RLCompraActual
	
	
	li $v0, 4
	la $a0, MENOS
	syscall
	
	lw $a0, ($t7)
	add $a0, $a0, 20
	syscall
	#lw $a0, 24($t6)
	#syscall
	#lw $a0, 28($t6)
	#syscall
	#lw $a0, 32($t6)
	#syscall
	
	la $a0, X
	syscall
	
	li $v0, 1
	lw $a0, 8($t6)
	syscall
	
	li $v0, 4
	la $a0, MENOS
	syscall
	
	# parte entera
	li $v0, 1
	lw $a0, 12($t6)
	syscall
	
	li $v0, 4
	la $a0, PUNTO
	syscall

	# parte decimal
	li $v0, 1
	lw $a0, 16($t6)
	syscall
	
	li $v0, 4
	la $a0, N
	syscall
	
	jal ELCompraActual 
	
	sub $t2, $t2, 1
	b elimi
finEliminacion:
	j CicloCompraActual

TerminarCompraActual:

	# quiere recorrer la lista actual y preguntar si un elemento alli ya estaba en la lista de cierrre
	# para eso mientras recorro la lista actual tambien recorro toda la lista de cirre para ver si cada elemento por el que paso
	# esta o no en la lista de cierre
	# si esta, debo operar sobre la cantidad y el precio,
	# si no esta debo agregarlo con todo
	
	jal RLActual2Cierre
	jal MostrarTotal

	# reseteamos lista actual
	li $v0, 0
	sw $v0, raizActual
	sw $v0, cabezaActual
	
	
	j CicloCompraActual
	
TerminarDia:

	# debo mastrar el cierre de caja, para eso debo crear una funcion
	# que recorrar toda la lista de cierre y vaya imprimiendo sus elementos
	
	jal MostrarListaCierre
	
	li $v0, 0
	sw $v0, raizActual
	sw $v0, cabezaActual
	
	li $v0, 0
	sw $v0, raizCierre
	sw $v0, cabezaCierre
	j Bienvenida
Main: 








EX_001: # el producto no esta en el stock
	li $v0, 4
	la $a0, EX_001MSJ	
	syscall
	j CicloCompraActual

EX_002: # no hay estock del producto
	li $v0, 4
	la $a0, EX_002MSJ
	syscall
	j CicloCompraActual
	
EX_003: # no hemos metido nada en la compra y ya queremos aumentar el numero del ultimo producto
	li $v0, 4
	la $a0, EX_003MSJ
	syscall
	j CicloCompraActual
	
EX_004: # intentamos restar pero no hay mas que restar
	li $v0, 4
	la $a0, EX_004MSJ
	syscall
	j CicloCompraActual
	
EX_005: # metemos letras en el codigo
	li $v0, 4
	la $a0, EX_005MSJ
	syscall
	j CicloCompraActual
	
FinishProgram:
	li $v0, 10
	syscall
