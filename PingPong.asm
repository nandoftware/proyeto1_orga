# Ping Pong
.data

# hay 31 caracteres por columna sin contar el /n (pa que quede simetrico bonito en el MMIO, 
# y convnientemente simetrico en la memoria)
# hay 9 filas, dos para los bordes y 7 para el area de juego
TableroDeJuego: .ascii "##############0-0##############\n"
AreaJugable: .ascii "                               \n                               \n                               \nHo                            H\n                               \n                               \n                               \n"
BordeDeAbajo: .ascii "###############################\f"

#direciones directas al byte de los puntos
PuntosJugIzq: .word 0x1001000e
PuntosJugDer: .word 0x10010010

# las paletas solos se mueven en (0,y) donde 1<=y<=6 para el jugadpr 1
# y en (30,y) donde 31<=y<=6 para el jugadpr 2

# el area: cada cuadricula es un Byte
# /|0 |1 |2 |3 |4 |5 |6 |7 |8 |9 |10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30| X
# 1|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
# 2|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
# 3|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
# 4|H |o |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  | H|
# 5|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
# 6|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
# 7|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |()|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
# Y


# para la posicion de las paletas tenemos que en la memoria estan alineados, pero los ascii esta guardados al reves, de todas formas se mueven solo en y,
# es decir le resto 0x20 a la direcion del H y es como si se moviera en y
# las paletas empiezan en el centro
PosJugUno: .byte 0, 4
PosJugDos: .byte 30, 4
PosPelota: .byte 1, 4
OffSet: .byte 32
UnidadY: .byte 0x20
UnidadX: .byte 0x01

# el estado del juego

#ESTADOS POSIBLES	A HEX
# 0101 | 0110 | 	0x05 | 0x06 | 
# 1001 | 1010 | 	0x09 | 0x0a | 

# el PRIMER bit es 1: 
# 	[]se esta esperando a que algun jugador haga servicio
# 	[]los jugadores se pueden mover 
#	[]la pelota se mueve con el jugador de servicio
# el SEGUNDO bit es 1: 
#	[]el juego se esta jugando
#	[]los jugadores se pueden mover
#	[]la pelota se mueve por las "fisicas"

#x
# LOS DOS PRIMEROS bits estan prendidos:
#	[]el juego se termino
#	[]ninguno de los jugadores ni la pelota se pueden mover
#	[]sale un mensaje de juego terminado, presionar una tecla para volver a empezar
#x

# el TERCER bit esta prendido si el jug 2 hace servicio; apagado si no
# el CUARTO bit esta prendido si el jug 1 hace sercicio; apagado si no 

# el estado inicial es 5
EstadoDelJuego: .byte 0x05






.text 
j DosJugadores
# quiero hacer una funcion que refresque la "pantalla", quiero que tenga un tiempo de refrescado
# primero quiero leer ascii que forma la imagen que se ve en pantalla. A ese ascii siempre le voy a dejar un /t al final (eso es lo que limpia la pantalla)
RefrescarPantalla:
	# guardamos en $s6 el tiempo en el que comenzamos a refrescar
	#li $v0, 30
	#syscall
	#move $s6, $a1
	
	# li $t0 0xffff0000 # las tres primeras palabras son el ready bit receptor, la data recibida, y el ready bit del transmisor
	li $t0 0xffff0008 # aqui la primera palabras es el Ready bit del transmisor y la segunda es donde se coloca el ascii a imprimir 
	
	la $t1, TableroDeJuego # como el tablero es el primero y yo sigo hasta /f tons nada mas necesito esta direccion
loopImprimirAscii:
	
	lb $t2, ($t1)
	
	# si el byte que esta en $t2 es /t(12) entonces ya refrescamos toda la pantalla
	# y toca esperar a cuano la podamos vlver a refescar
	beq $t2, 12, Esperar # pero si no es igual seguimos actualizando direcciones
	lb $t3, ($t0)
	 
PuedoEscribir: 
	beq $t3, 1, PuedesEscribir
	b PuedoEscribir
	
PuedesEscribir:
	sb $t2, 4($t0)
	add $t1, $t1, 1
	b loopImprimirAscii
	
Esperar:

	li $s7, 0
EsperarLoop:
	bge $s7, 20000, TermineEsperar
	add $s7, $s7, 1
	b EsperarLoop
TermineEsperar:

	# guardamos en $s6 el tiempo en el que comenzamos a refrescar
	#li $v0, 30
	#syscall
	#sub $s6, $s6, $a1
	
	#li $v0, 32
	#li $a0, 200
	#sub $a0, $a0, $s6
	#syscall
	
	#li $v0, 1
	#li $a0, 64
	#syscall
	
	sb $t2, 4($t0)
	jr $ra 
# -------------------------------------------------------------------------------------------------------------------------------------

# ESTA DUNCION PIDE LA DIRECION DE LAS COORDENADAS DE LOS JUGADORES Y DEVUELVE LAS COORDENADAS Y PASADAS AL HEX DE LA DIRECION
#	[] $a1 PosJugUno o PosJugDos
#	[] $s0 = coordenada y
CoordToHexJug:
	lb $s0, 1($a1) # aqui ta la coordenada y
	lb $t3, ($a1) # aqui esta la coordena x
	
	lb $t2, OffSet # aqui esta el offset
	mul $s0, $s0, $t2 # aqui paso la conversion de numeros de las coordenadas del area del juego a los ultimos bits de la direcion de memoria del ascii
	add $s0, $s0, 0x10010000 # y nuevamente en $t0 esta la direcion en memoria donde esta la paleta
	add $s0, $s0, $t3 # por ultimo, le sumamos la coordenada en x para acomodarlo en su xolumna correspondiente
	jr $ra
	
# ------------------------------------------------------------------------------------------------------------------------------------------------

# ESTA FUNCION PIDE LA DIRECION DE LAS COORDENADAS, LA DIRECCION DE LA NUEVA POSICION
# LA CANTIDAD QUE SE VA A DESPLAZAR LA COORDENADA (1 O -1) Y EL OBJETO, NO DEVUELVE NADA
#	[] $a1 PosJugUno o PosJugDos
#	[] $a2 la direcion de la posicion nueva
#	[] $a3 1 o -1
#	[] $t0 "H"(72) u "o"(111)
ActualizarPos:
	move $t2, $t0 # era un H harcodeada
	sb $t2, ($a2) # le guardamos la H en la posicion nueva
	
	# aca nomas le rest
	lb $t2, 1($a1)
	add $t2, $t2, $a3
	sb $t2, 1($a1)
	jr $ra

# ---------------------------------------------------------------------------------------------------------------------------------------
# ESTA FUNCION NO RECIVE PARAMETROS Y DEVUELVE EL ESTADO DEL JUEGO Y EL JUGADOR QUE SIRVE
#	[]$s0: 1 si se esta esperando servicio o 0 si se esta jugando
#	[]$s1: 1 si el jugador 1 hace servicio o 0 si el jugador 2 hace servicio
ObtenerEstado:
	# en $t0 esta la mascara para obtener si se esta esperando servicio o se esta jugando
	li $t0, 0x01

	# en $t2 la mascara para quein hace servicio
	li $t2, 0x04
	
	lb $s0, EstadoDelJuego # metemos en $s0 el estado del juego
	
	and $s0, $t0, $s0 # le hacemos un AND para que en $s0 quede 1 o 0
	and $s1, $t2, $s0 # en $s1 dejamos el AND de $t1 quedando 100 0 0000
	srl $s1, $s1, 2
	jr $ra
	
# ---------------------------------------------------------------------------------------------------------------------------------------
# LA FUNCION NO RECIVE NI DEVUELVE NADA
LeerInterrupcion:
	move $t8, $ra
	li $t0 0xffff0000 # la primera palabra es el Ready bit y la segunda es el ascii de la tecla presionada
	lb $t1, ($t0) # aqui esta el Ready bit
	# si esta en 0 no hay interrupcion no hay que leer nada
	# si esta en 1 hubo una interrupcion, hay que captarla
InterrupLoop:
	beqz $t1, TerminarCaptacion
	lb $t1, 4($t0)
	jal ObtenerEstado
	# si $t1 no era 0 hay que ver que tecla presione y pa donde llevarlo
	beq $t1, 87, TeclW # 87 = W, si no es W puede ser w
	beq $t1, 119, TeclW # 119 = w
	
	beq $t1, 83, TeclS # 83 = S
	beq $t1, 115, TeclS # 115 = s
	
	beq $t1, 88, TeclX # 88 = X
	beq $t1, 120, TeclX # 120 = x
	
	beq $t1, 79, TeclO # 79 = O
	beq $t1, 111, TeclO # 111 = o
	
	beq $t1, 75, TeclK # 75 = K
	beq $t1, 107, TeclK # 107 = k
	
	beq $t1, 77, TeclM # 77 = M
	beq $t1, 109, TeclM # 109 = m

TerminarCaptacion:
	jr $t8

	# para este momento tengo en $s0 y en $s1 cositas
	# si $s0 es igual a 0 se esta jugando, solo se mueven los jugadores
	# si $s0 es 1 es porque se esta esperanso servicio, hay que ver si este es el jugaro que sirve para mover la pelota tambien
	# si $s1 es 0 entonces sirve el jugador 1
# ----------------------------------
TeclW:
	beqz $s0, NormalW
QuienTienePelotaW:
	beqz $s1, ConPelotaW
	j NormalW
ConPelotaW:
	li $s5, 111
	la $s6, PosPelota
	li $s7, -1
	jal MovSoloVertical
NormalW:
	li $s5, 72
	la $s6, PosJugUno
	li $s7, -1
	jal MovSoloVertical
	jr $t8
# ----------------------------------	
	
TeclS:
	beqz $s0, NormalS
QuienTienePelotaS:
	beqz $s1, ConPelotaS
	j NormalS
ConPelotaS:
	li $s5, 111
	la $s6, PosPelota
	li $s7, 1
	jal MovSoloVertical
NormalS:
	li $s5, 72
	la $s6, PosJugUno
	li $s7, 1
	jal MovSoloVertical
	jr $t8
# ----------------------------------
	
TeclX:
	jal JugUnoServicio
# ----------------------------------
	
TeclO:
	beqz $s0, NormalO
QuienTienePelotaO:
	beq $s1, 1, ConPelotaO
	j NormalO
ConPelotaO:
	li $s5, 111
	la $s6, PosPelota
	li $s7, -1
	jal MovSoloVertical
NormalO:
	li $s5, 72
	la $s6, PosJugDos
	li $s7, -1
	jal MovSoloVertical
	jr $t8
# ----------------------------------
	
TeclK:
	beqz $s0, NormalK
QuienTienePelotaK:
	beq $s1, 1, ConPelotaK
	j NormalK
ConPelotaK:
	li $s5, 111
	la $s6, PosPelota
	li $s7, 1
	jal MovSoloVertical
NormalK:
	li $s5, 72
	la $s6, PosJugDos
	li $s7, 1
	jal MovSoloVertical
	jr $t8
# ----------------------------------
	
TeclM:
	jal JugDosServicio
# ------------------------------------------------------------------------------------------------------------------------------------------------

MovPelotaArriba:
	move $t9, $ra
	
	la $a1, PosPelota # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	sub $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la pelota
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, -1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 111 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9
MovPelotaAbajo:
	move $t9, $ra
	
	la $a1, PosPelota # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	add $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la pelota
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, 1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 111 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9


	
# ------------------------------------------------------------------------------------------------------------------------------------------------
	# cuando llegamos a ver como debe moverse el jugador 1 tenemos en $t1 el ascii de la tecla
MovJugUnoArriba:

	la $a1, PosJugUno # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	move $t9, $ra
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	sub $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la paleta
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, -1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 72 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9

# ------------------------------------------------------------------------------------------------------------------------------------------------
MovJugUnoAbajo:
	la $a1, PosJugUno # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	move $t9, $ra
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	add $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la paleta
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, 1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 72 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9
	
# ------------------------------------------------------------------------------------------------------------------------------------------------
JugUnoServicio:
	jr $ra
	
# ------------------------------------------------------------------------------------------------------------------------------------------------
MovJugDosArriba:
	la $a1, PosJugDos # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	move $t9, $ra
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	sub $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la paleta
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, -1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 72 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9
	
# ------------------------------------------------------------------------------------------------------------------------------------------------
MovJugDosAbajo:
	la $a1, PosJugDos # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	move $t9, $ra
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	add $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la paleta
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, 1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 72 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9

# ------------------------------------------------------------------------------------------------------------------------------------------------
JugDosServicio:
	jr $ra
	
# ------------------------------------------------------------------------------------------------------------------------------------------------
# ESTA FUNCION RECIBE LA POSCION DEL OBJETO A MOVER, LA DIRECION EN Y A MOVER Y EL ASCII DEL OBJETO
#	[] $s5 ascii del objeto
#	[] $s6 una direcion de una posicion en coordenadas
#	[] $s7 1 (ABAJO), -1 (ARRIBA)
MovSoloVertical:
	move $t9, $ra
	
	move $a1, $s6 # primero eta la direcion de las coordenadas x e y
	
	# que se le pasa como parametro a esta funcion
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY # le metemos cuando debe desplazarse en memoria
	mul $t2, $t2, $s7 # lo multiplicamos por 1 o menos 1 segun sea la direcion
	add $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la paleta
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	move $a3, $s7 # y metemos en $a3 cuando vamos a desplazar la coordenada
	move $t0, $s5 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9
# ---------------------------------------------------bucle de juego para dos jugadores-------------------------------------------------
DosJugadores:

MainLoop:
	
	beq $zero, 1, finish	
	jal RefrescarPantalla
	
	jal LeerInterrupcion
	
	b MainLoop
	
	
finish:
	li $v0, 10
	syscall
	
#MovJugDosAbajo:
	la $a1, PosJugDos # primero eta la direcion de las coordenadas x e y 
	# que se le pasa como parametro a esta funcion
	move $t9, $ra
	jal CoordToHexJug
	# y la funcion devuelve el hex en $s0, lo trasladamos a $t0 solo porque me da flojera ir cambiando lo $t0 que ya tenia
	move $t0, $s0
	
	# ahora hay que limpiar el string colocando espacios
	sb $t2, ($t0)
	# sb $t2, 2($t0)
	
	lb $t2, UnidadY
	add $t0, $t0, $t2 # ahora en $t0 esta la direcion de donde debe estar la paleta
	
	move $a2, $t0 # movemos a $a2 la direcion que veniamos tratando en $t0
	li $a3, 1 # y metemos en $a3 cuando vamos a desplazar la coordenada
	li $t0, 72 # metemos el objeto que queremos mover
	jal ActualizarPos 
	
	jr $t9
