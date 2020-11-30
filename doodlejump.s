.data
	displayAddress: .word 0x10008000
	backgroundColor: .word 0xfff7e6
	platformColor: .word 0x663300
	doodlerColor: .word 0x33cc33
	endGameScreenColor: .word 0x66ccff
	doodler: .word 14, 28 # initial X,Y values of doodler to center at the bottom
	doodlerOffsets: .word 4, 128, 132, 136, 256, 264
	# randomly choose from an array of 10, 11 or 12 px that will separate the platforms vertically
	# this makes it a reasonable height to jump to
	# X values are randomized
	verticalSeparators: .word 8, 9, 10
	#verticalSeparators_1: .word 10, 11, 12
	platformValues: .word 12, 31, 0, 0, 0, 0, 0, 0 # [(X,Y)_1,...,(X,Y)_n], here n=4
	platformValuesSize: .word 32 # n platforms * 8 bytes, here n=4
	platformWidth: .word 8
	gameStatus: .word 1 # 1: alive, 0: gameover
	jumpHeight: .word 13
	score: .word 0
	scoreLetters: .word 0, 4, 8, 128, 256, 260, 264, 392, 512, 516, 520,
				16, 20, 24, 144, 272, 400, 528, 532, 536,
				32, 36, 40, 160, 168, 288, 296, 416, 424, 544, 548, 552,
				48, 52, 56, 176, 184, 304, 432, 560,
				64, 68, 72, 192, 320, 324, 328, 448, 576, 580, 584	
				208, 592
	zero: .word 0, 4, 8, 128, 136, 256, 264, 384, 392, 512, 516, 520
	one: .word 4, 8, 136, 264, 392, 520
	two: .word 0, 4, 8, 136, 256, 260, 264, 384, 512, 516, 520
	three: .word 0, 4, 8, 136, 256, 260, 264, 392, 512, 516, 520
	four: .word 0, 8, 128, 136, 256, 260, 264, 392, 520
	five: .word 0, 4, 8, 128, 256, 260, 264, 392, 512, 516, 520
	six: .word 0, 4, 8, 128, 256, 260, 264, 384, 392, 512, 516, 520
	seven: .word 0, 4, 8, 128, 136, 264, 392, 520
	eight: .word 0, 4, 8, 128, 136, 256, 260, 264, 384, 392, 512, 516, 520
	nine: .word 0, 4, 8, 128, 136, 256, 260, 264, 392, 520
	firstDigit: .word 0
	secondDigit: .word 0
	thirdDigit: .word 0
	
.text
	lw $s0, displayAddress	# $s0 stores the base address for display
	lw $s1, backgroundColor # $s1 stores background color
	lw $s2, platformColor # $s2 stores platform color
	lw $s3, doodlerColor # $s3 stores doodler color
	lw $s4, endGameScreenColor # $s4 stores endScreenColor
	lw $s5, jumpHeight # $s5 stores jump height
	
initialSetup:
	la $t0, platformValues
	lw $t1, platformValuesSize
	
	li $t2, 8 # index of current, start with 2nd platform
	initialSetupLoop:
		add $t3, $t2, $t0 # get addr of current
		jal getRandomX
		sw $v0, 0($t3) # save X of current
		addi $t3, $t3, -8 # get addr of prev
		lw $t4, 4($t3) # get Y value of prev
		jal getVerticalSeparator
		sub $t4, $t4, $v0 # add vertical separator to prev Y to get Y of current
		addi $t3, $t3, 8 # return to addr of current
		sw $t4, 4($t3) # save Y of current
		addi $t2, $t2, 8 # update current index
		blt $t2, $t1, initialSetupLoop # loop if current index < arraySize

mainLoop:
	jal drawBackground
	jal drawPlatforms
	jal drawDoodler
	
	lw $a0, firstDigit
	li $a1, 116
	jal drawDigit
	lw $a0, secondDigit
	li $a1, 100
	jal drawDigit
	lw $a0, thirdDigit
	beqz $a0, noThirdDigit
	li $a1, 84
	jal drawDigit
	noThirdDigit:
	
	jal keyboardInput
	
	la $t0, doodler 
	lw $t1, 4($t0) # get Y of doodler
	# 8px from the top is the threshold needed to scroll up
	ble $t1, 8, scrollUp # if Y of doodler < 8px, scroll up
	noScrollUp:
	
	# refresh rate = 45 ms
	li $v0, 32
	li $a0, 45
	syscall
		
	j mainLoop

keyboardInput:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t9, 0xffff0000 
	beq $t9, 1, input
	j noInput
	input:
		lw $t9, 0xffff0004 
		beq $t9, 0x6a, moveLeft # check if "j"
		beq $t9, 0x6b, moveRight # check if "k"
	noInput:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

moveLeft: # moveLeft()
	la $t8, doodler
	lw $t9, 0($t8)
	addi $t9, $t9, -2
	bltz $t9, leftBorderReached
	j moveLeftContinue
	leftBorderReached:
		li $t9, 31
	moveLeftContinue:
		sw $t9, 0($t8)
	j noInput
	
moveRight: # moveRight()
	la $t8, doodler
	lw $t9, 0($t8)
	addi $t9, $t9, 2
	bgt $t9, 31, rightBorderReached
	j moveRightContinue
	rightBorderReached:
		li $t9, 0
	moveRightContinue:
		sw $t9, 0($t8)
	j noInput

scrollUp: # scrollUp()
	lw $t0, firstDigit
	lw $t1, secondDigit
	lw $t2, thirdDigit
	addi $t0, $t0, 1
	ble $t0, 9, skipIncrement
	li $t0, 0
	addi $t1, $t1, 1
	ble $t1, 9, skipIncrement
	li $t1, 0
	addi $t2, $t2, 1
	skipIncrement:
	sw $t0, firstDigit
	sw $t1, secondDigit
	sw $t2, thirdDigit

	la $t0, platformValues
	lw $t1, platformValuesSize
	
	li $t2, 8 # index of current, start with 2nd platform
	transferPlatformValues:
		add $t3, $t2, $t0 # get addr of current
		lw $t4, 0($t3) # get X of current
		lw $t5, 4($t3) # get Y of current
		addi $t3, $t3, -8 # get addr of prev
		sw $t4, 0($t3) # replace X of prev
		sw $t5, 4($t3) # replace Y of prev
		addi $t2, $t2, 8 # update current index
		blt $t2, $t1, transferPlatformValues # loop if current index < arraySize
	
	# generate new last platform
	addi $t2, $t1, -8 # index of last platform
	add $t2, $t2, $t0 # get addr of last platform
	jal getRandomX
	sw $v0, 0($t2) # save X of new last platform
	addi $t2, $t2, -8 # get addr of 2nd last platform
	lw $t3, 4($t2) # get Y of 2nd last platform
	jal getVerticalSeparator
	sub $t3, $t3, $v0 # add vertical separator from prev platform Y value to get Y of current
	addi $t2, $t2, 8 # get addr of last platform
	sw $t3, 4($t2) # save Y of new last platform
	
	scrollUpLoop:
		la $t0, platformValues
		lw $t1, platformValuesSize
		lw $t2, 4($t0) # Y of platform 1 
		blt $t2, 31, pushdown # pushdown if Y of platform 1 < 31px(bottom of screen)
		j scrollUpLoopBreak # break loop if Y of platform 1 reaches bottom
		
		pushdown: # push down all platforms by 1px
		li $t3, 0 # index of current
		pushdownLoop:
			add $t4, $t3, $t0 # get addr of current
			lw $t5, 4($t4) # get Y of current
			addi $t5, $t5, 1 # decrement height of current
			sw $t5, 4($t4) # update Y of current
			addi $t3, $t3, 8 # update current index
			blt $t3, $t1, pushdownLoop # loop if current index < arraySize
		
		jal drawBackground
		jal drawPlatforms
		jal drawDoodler
		
		lw $a0, firstDigit
		li $a1, 116
		jal drawDigit
		lw $a0, secondDigit
		li $a1, 100
		jal drawDigit
		lw $a0, thirdDigit
		beqz $a0, noThirdDigit_1
		li $a1, 84
		jal drawDigit
		noThirdDigit_1:
		
		jal keyboardInput
		
		# refresh rate = 45 ms
		li $v0, 32
		li $a0, 45
		syscall
		
		j scrollUpLoop
		
	scrollUpLoopBreak:			
	j noScrollUp

drawBackground: # drawBackground()
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	move $t7, $s0 # disp addr
	drawBackgroundLoop:
		sw $s1, 0($t7)
		addi $t7, $t7, 4 # update disp addr
		ble $t7, 0x10008ffc, drawBackgroundLoop # loop if < bottom-right corner addr
		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

drawPlatforms: # drawPlatforms()
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $t7, $a0
	la $t0, platformValues
	lw $t1, platformValuesSize
	li $t2, 0 # index of current
	drawPlatformLoop:
		add $t3, $t2, $t0 # get addr of current
		lw $t4, 0($t3) # get X of current
		lw $t5, 4($t3) # get Y of current
		move $a0, $t4 # prepare args for func call
		move $a1, $t5
		jal XYToAddressOffset
		move $t6, $v0 # addr offset of current
		add $t6, $t6, $s0 # get disp addr of current
		
		# check if addr within range, i.e display addr <= x <= bottom-right corner addr
		blt $t6, $s0, notWithinAddrRange
		bgt $t6, 0x10008ffc, notWithinAddrRange 
		lw $t5, platformWidth # loop counter
		drawPlatformWidth:
			sw $s2, 0($t6)
			addi $t6, $t6, 4 # get next px
			addi $t5, $t5, -1 # update counter
			bgtz $t5, drawPlatformWidth # loop while counter > 0	
		notWithinAddrRange:
		
		addi $t2, $t2, 8 # update current index
		blt $t2, $t1, drawPlatformLoop # loop if current index < arraySize
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

drawDoodler: # drawDoodler()
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, doodler
	lw $a0, 0($t0) # get X of doodler
	lw $a1, 4($t0) # get Y of doodler
	# continuous jumping
	beqz $s5, moveDown # if jump height reached, move down
	# else:
	addi $a1, $a1, -1 # increment dooldler height
	addi $s5, $s5, -1 # reduce jump height threshold
	j drawDoodlerContinue
	moveDown:
		addi $a1, $a1, 1 # decrement dooldler height
		move $t3, $a1 # keep current Y
		addi $a1, $a1, 3 # get Y of doodler bottom
		jal XYToAddressOffset
		add $t1, $v0, $s0 # disp addr of doodler bottom
		
		# check for new platform under doodler along doodler width
		lw $t2, 0($t1)
		beq $t2, $s2, resetJumpHeight 
		lw $t2, 4($t1)
		beq $t2, $s2, resetJumpHeight
		lw $t2, 8($t1)
		beq $t2, $s2, resetJumpHeight
		move $a1, $t3 # restore current Y
		j drawDoodlerContinue
		
	resetJumpHeight: 
		lw $s5, jumpHeight # reset jump height because new platform under doodler
		move $a1, $t3
		
	drawDoodlerContinue:	
		sw $a1, 4($t0) # update Y of doodler
		
	bgt $a1, 31, endGame # end game if doodler reaches bottom of screen

	# draw doodler
	jal XYToAddressOffset
	move $t0, $v0 # starting addr to render doodler
	add $t0, $t0, $s0 # add base disp addr
	la $t1, doodlerOffsets
	li $t2, 0 # counter
	renderDoodler:
		add $t3, $t2, $t1
		lw $t4, 0($t3)
		add $t4, $t4, $t0
		sw $s3, 0($t4)
		addi $t2, $t2, 4 # update counter
		blt $t2, 24, renderDoodler	
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
endGame: # endGame()
	li $v0, 32
	li $a0, 100
	syscall
	
	jal drawBackground
	addi $t0, $s0, 1300 # starting addr to render 'SCORE'
	la $t1, scoreLetters
	li $t2, 0 # counter
	renderLetters:
		add $t3, $t2, $t1
		lw $t4, 0($t3)
		add $t4, $t4, $t0
		sw $s4, 0($t4)
		addi $t2, $t2, 4
		blt $t2, 212, renderLetters	
	
	lw $t0, thirdDigit
	beqz $t0, noThirdDigit_2
	lw $a0, firstDigit 
	li $a1, 2248
	jal drawDigit
	
	lw $a0, secondDigit 
	li $a1, 2232
	jal drawDigit
	
	lw $a0, thirdDigit
	li $a1, 2216
	jal drawDigit
	j drawDigitDone
	
	noThirdDigit_2:
	lw $a0, firstDigit 
	li $a1, 2240
	jal drawDigit
	
	lw $a0, secondDigit 
	li $a1, 2224
	jal drawDigit
	
	drawDigitDone:
	la $t7, gameStatus
	sw $zero, 0($t7) # gameStatus = 0
	endGameScreenLoop: # stay on endGameScreen until user restart
		lw $t7, 0xffff0000
		beq $t7, 1, checkRestart
		j noRestart
		checkRestart:
			lw $t7, 0xffff0004
			beq $t7, 0x73, restartGame # press 's' to restart
		noRestart:
		lw $t7, gameStatus
		beqz $t7, endGameScreenLoop
		
drawDigit: # drawDigit(digit, starting offset)
	bne $a0, 0, num1
	la $t1, zero
	li $t5, 48
	j numChosen
	num1:
	bne $a0, 1, num2
	la $t1, one
	li $t5, 24
	j numChosen
	num2:
	bne $a0, 2, num3
	la $t1, two
	li $t5, 44
	j numChosen
	num3:
	bne $a0, 3, num4
	la $t1, three
	li $t5, 44
	j numChosen
	num4:
	bne $a0, 4, num5
	la $t1, four
	li $t5, 36
	j numChosen
	num5:
	bne $a0, 5, num6
	la $t1, five
	li $t5, 44
	j numChosen
	num6:
	bne $a0, 6, num7
	la $t1, six
	li $t5, 48
	j numChosen
	num7:
	bne $a0, 7, num8
	la $t1, seven
	li $t5, 32
	j numChosen
	num8:
	bne $a0, 8, num9
	la $t1, eight
	li $t5, 52
	j numChosen
	num9:
	la $t1, nine
	li $t5, 40
	numChosen:	
	# render digit
	add $a1, $a1, $s0 # starting addr to render numbers
	li $t2, 0 # counter
	renderDigit:
		add $t3, $t2, $t1
		lw $t4, 0($t3)
		add $t4, $t4, $a1
		sw $s4, 0($t4)
		addi $t2, $t2, 4
		blt $t2, $t5, renderDigit
	jr $ra
	
restartGame: # restartGame() resets all objects to their initial values
	# reset platforms values
	la $t0, platformValues
	lw $t1, platformValuesSize
	li $t3, 12
	li $t4, 31
	sw $t3, 0($t0)
	sw $t4, 4($t0)
	li $t2, 8	
	resetPlatforms:
		add $t3, $t2, $t0
		sw $zero, 0($t3)
		sw $zero, 4($t3)
		addi $t2, $t2, 8
		blt $t2, $t1, resetPlatforms
	
	# reset doodler values
	la $t8, doodler
	li $t0, 14
	li $t1, 28
	sw $t0, 0($t8)
	sw $t1, 4($t8)
	
	lw $s5, jumpHeight # reset jumpHeight
	# reset score
	sw $zero, firstDigit 
	sw $zero, secondDigit 
	sw $zero, thirdDigit 
	
	# reset game status to 1
	la $t0, gameStatus
	li $t1, 1
	sw $t1, 0($t0)
	
	j initialSetup
	
XYToAddressOffset: # XYToAddressOffset(X, Y) converts X,Y from px to address offset in bytes
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	sll $t8, $a0, 2 # X*4 
	li $t9, 128
	mult $a1, $t9
	mflo $t9 # Y*128
	add $v0, $t8, $t9 # X*4 + Y*128 gives the address offset
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
		
getRandomX: # getRandomX() returns a random X in px
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# since platform width 8px, 32-8=24 possible platform locations per line
	# choose a random number between 0 and 24
	li $a0, 0
	li $a1, 25
	li $v0, 42 
	syscall
	move $v0, $a0 # get random number
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

getVerticalSeparator: # getVerticalSeparator() returns a random vertical separator in px
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# choose a random number out of 0, 1 or 2
	li $a0, 0
	li $a1, 3 
	li $v0, 42 
	syscall
	move $t7, $a0 # get random number
	la $t8, verticalSeparators
	sll $t7, $t7, 2 # *4 to get index to retrieve from array(index 0,4 or 8)
	add $t8, $t8, $t7
	lw $t7, 0($t8) # get value from array
	move $v0, $t7 # return value
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
getRandomNumber: # getRandomNumber(min, max) returns a random number in the range
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $v0, 42
	syscall
	move $v0, $a0
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
