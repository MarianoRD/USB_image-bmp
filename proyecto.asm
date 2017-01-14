# Proyecto 1
#
# Hecho por:
#	Mariano Rodríguez 12-10892
#	Pablo Gonzalez 13-10575

# Uso de registros:
#	$s0: File descriptor
#	$s1: Dirección del inicio de los datos para el display (Heap)
#	$s2: Dirección del inicio de los datos de la imagen
#	$s3: Ancho de la imagen
#	$s4: Alto de la imagen
#	$s5: Ancho*Alto*4

.data
	solicitud:	.asciiz "\nIntroduzca el nombre de la imagen: "
	anchoimg:	.asciiz "\nAncho de la imagen: "
	altoimg:	.asciiz "\nAlto de la imagen: "
	bitscolor:	.asciiz "\nBits por color: "
	nombre: 	.space 20
	.align 2  
	tipo:		.space 2 # Debe contener las letras BM
	.align 2
	tamano:		.space 6 # Tamano del archivo .bmp
	.align 2
	basura:		.space 30
	
	# Conectar Bitmap
	conectar:	.asciiz "\nPor favor abra, configure y conecte el Bitmap Display, con los siguientes datos: "
	.align 2
	ancho:		.space 4 # Ancho de la imagen
	alto:		.space 4 # Alto de la imagen
	direccion:	.asciiz "\nDirección base de memoria: "
	dirheap:	.asciiz "0x10040000 "
	presione:	.asciiz "\nPresione enter para continuar: "
	
	# Menu
	titulomenu: 	.asciiz "\nSeleccione una opción: "
	.align 2
	# Opciones del menu
	opciones: 	.word iBN, iFlipVertical, iFlipHorizontal, iRota
	opcion1:	.asciiz "\n1-.Convertir Imagen en Blanco y Negro"
	opcion2:	.asciiz "\n2-.Hacer un Flip Vertical a la Imagen"
	opcion3:	.asciiz "\n3-.Hacer un Flip Horizontal a la Imagen"
	opcion4:	.asciiz "\n4-.Rotar la Imagen"
	opcion9:	.asciiz "\n9-.Salir"
	porfavor:	.asciiz "\nPor favor seleccione una opción: "

.text
	# Impresion de 'solicitud'
	la $a0, solicitud
	li $v0, 4
	syscall
	# Recepción del nombre
	la $a0, nombre
	la $a1, 19 # Cantidad de caracteres
	li $v0, 8
	syscall

# Borrar \n 

borrarsalto:
	# Funcion que borra el salto de linea (\n) al final del nombre de la imagen
	lb $t0, nombre($t1)
	beq $t0, 0xA, borrar
	addi $t1, $t1, 1
	b borrarsalto

# Borrar el salto de linea
borrar:
	sb $zero, nombre($t1)

main:	
	# Abre el archivo
	la $a0, nombre
	li $a1, 0 # Flag, 0: lectura, 1: escritura
	li $a2, 0 # Flag mode
	li $v0, 13
	syscall
	
	# Guarda el "file descriptor"
	move $s0, $v0
	
	# Lee el archivo
	move $a0, $s0
	la $a1, tipo # Busca los primeros dos bytes
	li $a2, 2
	li $v0, 14
	syscall
	
	# Verifica que sea un .bmp
	lb $t1, tipo
	lb $t2, tipo+1
	bne $t1, 0x42, salir
	bne $t2, 0x4D, salir
	
	# Busca el tamaño del archivo
	la $a1, tamano
	li $a2, 4
	li $v0, 14
	syscall
	
	# Lee los 12 bytes siguientes (basura)
	la $a1, basura
	li $a2, 12
	li $v0, 14
	syscall
	
	# Lee el ancho de la imagen
	la $a1, ancho
	li $a2, 4
	li $v0, 14
	syscall
	
	# Lee el alto de la imagen
	la $a1, alto
	li $a2, 4
	li $v0, 14
	syscall
	
	# Más basura
	la $a1, basura
	li $a2, 28
	li $v0, 14
	syscall
	
	# Calculo del tamano de la imagen (4B/color)
	lw $s3, ancho	# Guardo el ancho de la imagen
	lw $s4, alto	# Guardo el alto de la imagen
	mul $t2, $s3, $s4 	# Multiplico alto por ancho
	mul $t2, $t2, 4		# Multiplico el resultado por 4 que va a ser la cantidad de bytes por pixel
	
	
	# Reservar la memoria para la imagen
	move $a0, $t2
	li $v0, 9
	syscall
	
	# Guarda direccion del heap del display
	move $s1, $v0
	
	# Calculo del tamano del heap de informacion
	ld $t2, tamano
	subi $t2, $t2, 54 # Tamaño de la imagen menos la cabecera
	sd $t2, tamano
	
	
	# Reservar la memoria para la informacion de la imagenn
	move $a0, $t2
	li $v0, 9
	syscall
	
	# Guarda direccion del heap de info
	move $s2, $v0
	
	# Reservo memoria extra para la función de rotación
	mulu $t2, $s3, $s4
	move $a0, $t2
	li $v0, 9
	
	# Solicito al usuario que abra y conecte el Bitmap Display
	jal conectarbitmap
	
	# Ciclos de arreglo de los pixeles
	 # $t0: Ancho de la fila
	 # $t1: 2*t0
	 # $t2: Apuntador de memoria de la informacion
	 # $t3: Contador de filas
	 # $t4: Apuntador de memoria de la imagen
	 # $t5: Contador de columnas
	 # $t6: Pixel siendo operado por el momento

	# Cargando registros
	# $t1 ya cargado 
	move $t5, $s3
	mulu $t0, $s3, 3 # Ancho de cada fila ($t0)
	add $t1, $t0, $t0 # ($t1)
	
	# Calculo de los pixeles de la imagen
	mulu $t2, $s3, $s4
	mulu $t3, $t2, 4
	move $s5, $t3

	# Calculo de la ultima fila de los datos (primera de la imagen)
	mulu $t2, $s3, $s4
	mulu $t3, $t2, 3
	move $t2, $s2 # Apuntador de memoria ($t2)
	addu $t2, $t3, $t2
	
	# Lee el resto de la imagen
	move $a0, $s0
	move $a2, $t3 # Calculado en li.171
	move $a1, $s2
	li $v0, 14
	syscall
	
	move $t3, $s4 # Cantidad de filas
	move $t4, $s1 # ($t4)
	subu $t2, $t2, $t0

	# Modifica los pixeles de 3B->4B y los guarda en el espacio de la imagen
	ccol: 	beqz $t5, cfilas
		jal leepixel
		sw $t6, ($t4)
		addi $t4, $t4, 4 # Mueve el apuntador de memoria de la imagen
		addi $t2, $t2, 3 # Mueve el apuntador de memoria de la información
		subi $t5, $t5, 1
		j ccol
		
	# Reposiciona el apuntador para leer otra fila
	cfilas:
		beqz $t3, menu
		sub $t2, $t2, $t1 # Lleva la memoria al inicio de la fila anterior
		move $t5, $s3
		subi $t3, $t3, 1
		j ccol

# ------------------------------------------------------ FUNCIONES ------------------------------------------------------#

conectarbitmap:

	# Imprime la solicitud
	la $a0, conectar
	li $v0, 4
	syscall

	# Imprime los datos de la imagen (ancho y alto)
	# Ancho
	la $a0, anchoimg
	li $v0, 4
	syscall
	lw $a0, ancho
	li $v0, 1
	syscall
	
	# Guarda el ancho y el alto en los registros
	lw $s3, ancho
	lw $s4, alto
	
	# Alto
	la $a0, altoimg
	li $v0, 4
	syscall
	lw $a0, alto
	li $v0, 1
	syscall
	
	# Dirección
	la $a0, direccion
	li $v0, 4
	syscall
	la $a0, dirheap
	syscall
	
	# Continuar
continuar: la $a0, presione
	li $v0, 4
	syscall
	li $v0, 12
	syscall
	# Chequeo de que haya sido enter
	bne $v0, 0xA, continuar
	jr $ra
	
# Menu
# Registros:
#	$t1: Direccion de 'opciones'
#	$t2: Opcion seleccionada desplazada
#	$t3: Direccion de la opcion seleccionada por el usuario
menu:   # Titulo
	la $a0, titulomenu
	li $v0, 4
	syscall
	# Opcion 1
	la $a0, opcion1
	syscall
	# Opcion 2
	la $a0, opcion2
	syscall
	# Opcion 3
	la $a0, opcion3
	syscall
	# Opcion 4
	la $a0, opcion4
	syscall
	# Salir
	la $a0, opcion9
	syscall
	# Introduccion
	li $t9, 5
introduccion: 
	la $a0, porfavor
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	# Verificaciones
	beqz $v0, introduccion # Si introducen 0
	beq $v0, 9, salir # Si introducen 9
	bge $v0, 5, introduccion # Si introducen x >= 5
	# Salto a las distintas opciones
	subu $v0, $v0, 1
	sll $t2, $v0, 2
	lw $t3, opciones($t2)
	# Saltamos a la opcion seleccionada
	jr $t3

# Funciones

leepixel: # Lee el pixel
	move $t6, $zero # Vacia $t6
	lbu $t6, ($t2) # Lee Pixel B
	lbu $t8, 1($t2) # Lee Pixel G
	sll $t8, $t8, 8
	or $t6, $t6, $t8
	lbu $t8, 2($t2) # Pixel R
	sll $t8, $t8, 16
	or $t6, $t6, $t8
	jr $ra
# Blanco y negro
# Registros:
	#$t0: Dirección de memoria primera linea
	#t1: Color R
	#t2: Color G
	#t3: Color B
	#t4: Cantidad de pixeles
iBN:
	move $t0, $s1 # Carga la direccion del inicio del display
	move $t4, $s5
bn: 
	beqz $t4, menu
	lbu $t1, 1($t0) #
	lbu $t2, 2($t0) # Carga el pixel
	lbu $t3, 3($t0) #
	addu $t3, $t3, $t2 #
	addu $t3, $t3, $t1 # Calcula la escala de grises
	divu  $t3, $t3, 3 #
	sll $t2, $t3, 8
	sll $t1, $t3, 16
	or $t3, $t3, $t2
	or $t3, $t3, $t1
	sw $t3, ($t0)
	addiu $t0, $t0, 4
	subu $t4, $t4, 4
	j bn

# Flip Vertical
# Registros:
	#$t0: Dirección de memoria primera linea
	#$t1: Direccion de memoria ultima linea
	#$t2: 2*(Ancho de linea (4B/p))
	#$t3: Cantidad de lineas de media imagen
	#$t4: Pixel superior
	#$t5: Pixel inferior
	#$t6: Ancho de la imagen
iFlipVertical: 
	move $t0, $s1 # Carga la direccion del inicio del display
	mulu $t2, $s3, 4 # Ancho de cada linea
	move $t3, $s5 #
	addu $t1, $t0, $t3 # Direccion de memoria ultima linea
	subu $t1, $t1, $t2 #
	mulu $t2, $t2, 2 # 2*(Ancho de linea)
	divu $t3, $s4, 2 # Cantidad de lineas de cada mitad de imagen
	move $t6, $s3
flipVertical: 
	beqz $t6, reiniciaFilaV
	# Cambia los pixeles
	lw $t4, ($t0)
	lw $t5, ($t1)
	sw $t5, ($t0)
	sw $t4, ($t1)
	# Mueve los punteros
	addiu $t0, $t0, 4
	addiu $t1, $t1, 4
	subu $t6, $t6, 1
	j flipVertical

reiniciaFilaV:
	beqz $t3, menu
	subu $t3, $t3, 1
	subu $t1, $t1, $t2
	move $t6, $s3
	j flipVertical

# Flip Horizontal
# Registros:
	#$t0: Dirección de memoria primera linea
	#$t1: Direccion de memoria ultimo pixel, primera linea
	#$t2: 3/2*(Ancho de linea (4B/p))
	#$t3: (Ancho de linea (4B/p))/2
	#$t4: Pixel izquierdo
	#$t5: Pixel derecho
	#$t6: Columnas / 2
	#$t7: Cantidad de filas de la imagen
iFlipHorizontal: 
	move $t0, $s1 # Carga la direccion del inicio del display
	mulu $t3, $s3, 2 # (Ancho de cada linea)/2
	mulu $t2, $t3, 2 # Ancho de la linea
	addu $t1, $t0, $t2 # Direccion del ultimo pixel de la primera linea
	subu $t1, $t1, 4 #
	addu $t2, $t2, $t3 # 3/2*(Ancho de linea)
	divu $t6, $s3, 2
	move $t7, $s4
flipHorizontal: 
	beqz $t6, reiniciaFilaH
	# Cambia los pixeles
	lw $t4, ($t0)
	lw $t5, ($t1)
	sw $t5, ($t0)
	sw $t4, ($t1)
	# Mueve los punteros
	addiu $t0, $t0, 4
	subu $t1, $t1, 4
	subu $t6, $t6, 1
	j flipHorizontal

reiniciaFilaH:
	beqz $t7, menu
	subu $t7, $t7, 1
	addu $t0, $t0, $t3 # Reinicia pixel izquierdo
	addu $t1, $t1, $t2 # Reinicia pixel derecho
	divu $t6, $s3, 2
	j flipHorizontal

# Rotación
# Registros:
#	$t0: Ancho
#	$t1: Alto
#	$t2: Dirección Heap
#	$t3: Dirección Información
#	$t4: Ancho*4
#	$t5: Pixel a rotar
#	$t6: Alto*4
#	$t7: Temporal
iRota:
	move $t0, $s3 # Ancho
	move $t1, $s4 # Alto
	move $t2, $s1 # Direccion Heap
	mulu $t4, $t0, 4 # Ancho*4
	move $t3, $s2 # Direccion Información
	mulu $t6, $t1, 4 # Alto*4
	addu $t3, $t3, $t6
	subu $t3, $t3, 4
	move $t7, $zero
rotaL:
	beqz $t1, reiniciaRota
	lw $t5, ($t2)
	sw $t5, ($t3)
	# Mueve los punteros
	subu $t3, $t3, 4
	addu $t2, $t2, $t6
	subu $t1, $t1, 1
	j rotaL
reiniciaRota:
	beqz $t0, irotaS
	move $t1, $s4 # Alto
	subu $t0, $t0, 1 # Columna - 1
	# Reposiciona el apuntador
	addiu $t7, $t7, 4
	move $t2, $s1
	addu $t2, $t2, $t7
	addu $t3, $t3, $t6
	addu $t3, $t3, $t6	
	j rotaL
# Registros:
#	$t0: Dirección del Heap
#	$t1: Dirección de la Información
#	$t3: Información siendo movida
#	$t4: Cantidad de Iteraciones
irotaS:
	move $t0, $s1
	move $t1, $s2
	move $t3, $zero
	mulu $t4, $s3, $s4
	mulu $t4, $t4, 4
rotaS:
	beqz $t4, menu
	lw $t3, ($t1)
	sw $t3, ($t0)
	# Muevo los punteros
	addiu $t0, $t0, 4
	addiu $t1, $t1, 4
	sub $t4, $t4, 4
	j rotaS

# Sale del programa
salir:
	li $v0, 10
	syscall
