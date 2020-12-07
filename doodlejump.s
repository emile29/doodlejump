#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Emile Li Tim Cheong, 1004811251
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Score count: display on screen(top-right corner)
# 2. Increase in difficulty as game progresses:
#		- platforms become smaller when at different score thresholds(see additional info)
#		- the speed is increased at scores 10 and 20.
# 3. Boosting: springs(grey colored) which enable doodler to jump over 2 platforms instead of one
# 4. Fancier graphics: 
#		- improved shape of doodler compared to demo video
#		- start and end screen(displays score at the end)
#		- pause/resume the game by pressing 'spacebar' and pause icon appears at top-left corner
# 5. Dynamic on-screen notifications: "NICE!" at score=10, "GREAT!" at score=20 and "WOW!" at score=30
#
# Link to video demonstration for final submission:
# - https://youtu.be/w3UjNaf5_lg
#
# Any additional information that the TA needs to know:
# For testing purposes, I set 3 difficulty levels based on score thresholds
# level 1 < 10 : normal size platforms only
# level 2 >= 10 : normal + small platforms and springs
# level 3 >= 20 : small + very small platforms and springs
#
# The score system works such that each time i scroll up the screen, i increment the score by 1.
#
#####################################################################

.data
	buffer: .space 4096
	backgroundColor: .word 0xfff7e6
	platformColor: .word 0x663300
	doodlerColor: .word 0x33cc33
	blueColor: .word 0x66ccff
	springColor: .word 0x808080
	doodler: .word 14, 27 # initial X,Y values of doodler to center at the bottom
	doodlerOffsets: .word 0, 4, 8, 128, 132, 136, 140, 256, 260, 264, 384, 392
	doodlerOffetsToColorBack: .word 132, 256, 264
	# randomly choose from an array of vertical separators that will separate the platforms vertically
	# this makes it a reasonable height to jump to
	# X values are randomized
	verticalSeparators: .word 7, 8
	platformValues: .word 12, 31, 8, 0, 0, 0, 8, 0, 0, 0, 8, 0, 0, 0, 8, 0, 0, 0, 8, 0# [(X,Y,width,spring/notSpring)_1,...,(X,Y,width,spring/notSpring)_n], here n=5
	platformValuesSize: .word 80 # n platforms * 16 bytes, here n=5
	platformWidthNormal: .word 8
	platformWidthSmall: .word 6
	platformWidthVerySmall: .word 4
	gameStatus: .word 1 # 1: alive, 0: gameover
	jumpHeight: .word 11
	boostHeight: .word 16
	boostStatus: .word 0
	scrollHeightThreshold: .word 10
	refreshRate: .word 40
	boostRefreshRate: .word 35
	pauseOffsets: .word 0, 8, 128, 136, 256, 264
	BYE: .word 0, 4, 8, 128, 140, 256, 260, 264, 384, 396, 512, 516, 520,
			20, 36, 148, 164, 280, 288, 412, 540, 
			44, 48, 52, 172, 300, 304, 308, 428, 556, 560, 564, 
			60, 188, 316, 572
	scoreLetters: .word 0, 4, 8, 128, 256, 260, 264, 392, 512, 516, 520,
				16, 20, 24, 144, 272, 400, 528, 532, 536,
				32, 36, 40, 160, 168, 288, 296, 416, 424, 544, 548, 552,
				48, 52, 56, 176, 184, 304, 432, 560,
				64, 68, 72, 192, 320, 324, 328, 448, 576, 580, 584	
				208, 592
	pressS: .word 0, 4, 8, 128, 136, 256, 260, 264, 384, 512,
			16, 20, 24, 144, 152, 272, 400, 528, 
			32, 36, 40, 160, 288, 292, 296, 416, 544, 548, 552,
			48, 52, 56, 176, 304, 308, 312, 440, 560, 564, 568,
			64, 68, 72, 192, 320, 324, 328, 456, 576, 580, 584,
			84, 92, 96, 100, 220, 348, 352, 356, 484, 604, 608, 612, 108
	toStart: .word 0, 128, 256, 260, 384, 512, 516,
			268, 272, 276, 396, 404, 524, 528, 532,
			32, 36, 40, 160, 288, 292, 296, 424, 544, 548, 552,
			48, 52, 56, 180, 308, 436, 564,
			64, 68, 72, 192, 200, 320, 324, 328, 448, 456, 576, 584,
			80, 84, 88, 208, 216, 336, 464, 592,
			96, 100, 104, 228, 356, 484, 612
	NICE: .word 0, 16, 128, 132, 144, 256, 264, 272, 384, 396, 400, 512, 528,
			24, 152, 280, 408, 536,
			32, 36, 40, 160, 288, 416, 544, 548, 552,
			48, 52, 56, 176, 304, 308, 312, 432, 560, 564, 568,
			64, 192, 320, 576
	GREAT: .word 0, 4, 8, 128, 256, 264, 384, 392, 512, 516, 520,
			16, 20, 24, 144, 152, 272, 400, 528, 
			32, 36, 40, 160, 288, 292, 296, 416, 544, 548, 552, 
			48, 52, 56, 176, 184, 304, 308, 312, 432, 440, 560, 568, 
			64, 68, 72, 196, 324, 452, 580, 
			80, 208, 336, 592
	WOW: .word 0, 24, 128, 152, 260, 268, 276, 388, 396, 404, 520, 528,
			32, 36, 40, 160, 168, 288, 296, 416, 424, 544, 548, 552,
			48, 72, 176, 200, 308, 316, 324, 436, 444, 452, 568, 576,
			80, 208, 336, 592 
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
	la $s0, buffer # $s0 stores the addr of buffer
	lw $s1, backgroundColor # $s1 stores background color
	lw $s2, platformColor # $s2 stores platform color
	lw $s3, doodlerColor # $s3 stores doodler color
	lw $s4, blueColor # $s4 stores blue color
	lw $s5, jumpHeight # $s5 stores jump height
	lw $s6, springColor # $s6 stores spring color
	
	# start screen
	jal drawBackground
	la $t0, pressS
	add $t1, $s0, 1284
	li $t2, 0 # index of current
	drawPressS:
		add $t3, $t2, $t0
		lw $t3, 0($t3)
		add $t3, $t3, $t1
		sw $s4, 0($t3)
		addi $t2, $t2, 4 # update current index
		blt $t2, 256, drawPressS
	la $t0, toStart
	add $t1, $s0, 2064
	li $t2, 0 # index of current
	drawToStart:
		add $t3, $t2, $t0
		lw $t3, 0($t3)
		add $t3, $t3, $t1
		sw $s4, 0($t3)
		addi $t2, $t2, 4 # update current index
		blt $t2, 240, drawToStart
		
	jal copyToScreen
	
	pressSToStart:
		li $v0, 32
		li $a0, 100
		syscall
		lw $t0, 0xffff0000
		bne $t0, 1, pressSToStart
		lw $t0, 0xffff0004
		bne $t0, 0x73, pressSToStart
	
initialSetup:
	la $t0, platformValues
	lw $t1, platformValuesSize
	
	li $t2, 16 # index of current, start with 2nd platform
	initialSetupLoop:
		add $t3, $t2, $t0 # get addr of current
		jal getRandomX
		sw $v0, 0($t3) # save X of current
		addi $t3, $t3, -16 # get addr of prev
		lw $t4, 4($t3) # get Y value of prev
		jal getVerticalSeparator
		sub $t4, $t4, $v0 # add vertical separator to prev Y to get Y of current
		addi $t3, $t3, 16 # return to addr of current
		sw $t4, 4($t3) # save Y of current
		addi $t2, $t2, 16 # update current index
		blt $t2, $t1, initialSetupLoop # loop if current index < arraySize

mainLoop:
	jal drawBackground
	jal drawPlatforms
	jal drawDoodler
	
	# draw score at top-right corner
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
	
	# draw onScreen disp 'NICE, GREAT, WOW'
	jal drawNiceGreatWow
	
	la $t0, doodler 
	lw $t1, 4($t0) # get Y of doodler
	lw $t2, scrollHeightThreshold
	ble $t1, $t2, scrollUp # if Y of doodler <= threshold(measured from top of screen), scroll up
	noScrollUp:
	
	jal keyboardInput
	
	jal copyToScreen
	
	# refresh rate
	lw $t1, boostStatus
	beqz $t1, normalRate_1
	li $v0, 32
	lw $a0, boostRefreshRate
	syscall
	j mainLoop
	normalRate_1:
	li $v0, 32
	lw $a0, refreshRate
	syscall
		
	j mainLoop

copyToScreen: # copyToScreen()
	li $t1, 0
	copy:
		add $t2, $t1, $s0	
		lw $t2, 0($t2)
		add $t3, $t1, $gp
		sw $t2, 0($t3)
		addi $t1, $t1, 4
		blt $t1, 4096, copy
	jr $ra

keyboardInput: # keyboardInput()
	lw $t9, 0xffff0000 
	beq $t9, 1, input
	j noInput
	input:
		lw $t9, 0xffff0004 
		beq $t9, 0x6a, moveLeft # check if "j"
		beq $t9, 0x6b, moveRight # check if "k"
		beq $t9, 0x20, pause # check if "spacebar"
	noInput:
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

pause: # pause()
	la $t7, pauseOffsets
	li $t8, 0
	drawPause:
		add $t9, $t8, $t7
		lw $t9, 0($t9)
		addi $t9, $t9, 0x10008000
		sw $s4, 0($t9)
		add $t8, $t8, 4
		blt $t8, 24, drawPause
	pauseLoop:
		li $v0, 32 # sleep for a bit
		li $a0, 100
		syscall
		lw $t7, 0xffff0000
		bne $t7, 1, pauseLoop
		lw $t7, 0xffff0004
		bne $t7, 0x20, pauseLoop # press "spacebar" again to resume		
	j noInput

scrollUp: # scrollUp()
	# increment score on each scroll up
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
	
	# increase speed(refresh rate) at score=10 and 20
	jal convertDigitsToScore
	bne $v0, 10, noIncreseInSpeed
	lw $t0, refreshRate
	lw $t1, boostRefreshRate
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	sw $t0, refreshRate
	sw $t1, boostRefreshRate
	j noIncreseInSpeed
	bne $v0, 20, noIncreseInSpeed 
	lw $t0, refreshRate
	lw $t1, boostRefreshRate
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	sw $t0, refreshRate
	sw $t1, boostRefreshRate
	noIncreseInSpeed:

	la $t0, platformValues
	lw $t1, platformValuesSize
	li $t2, 16 # index of current, start with 2nd platform
	transferPlatformValues:
		add $t3, $t2, $t0 # get addr of current
		lw $t4, 0($t3) # get X of current
		lw $t5, 4($t3) # get Y of current
		lw $t6, 8($t3) # get length of current
		lw $t7, 12($t3) # get springBool of current
		addi $t3, $t3, -16 # get addr of prev
		sw $t4, 0($t3) # replace X of prev
		sw $t5, 4($t3) # replace Y of prev
		sw $t6, 8($t3) # replace length of prev
		sw $t7, 12($t3) # replace springBool of prev
		addi $t2, $t2, 16 # update current index
		blt $t2, $t1, transferPlatformValues # loop if current index < arraySize
	
	# generate new last platform
	addi $t2, $t1, -16 # index of last platform
	add $t2, $t2, $t0 # get addr of last platform
	jal getRandomX
	sw $v0, 0($t2) # save X of new last platform
	addi $t2, $t2, -16 # get addr of 2nd last platform
	lw $t3, 4($t2) # get Y of 2nd last platform
	jal getVerticalSeparator
	sub $t3, $t3, $v0 # add vertical separator from prev platform Y value to get Y of current
	addi $t2, $t2, 16 # get addr of last platform
	sw $t3, 4($t2) # save Y of new last platform
	
	jal convertDigitsToScore
	move $t4, $v0 # $t4 stores the score
	blt $v0, 10, generateNormalOnly # if score >= 10, generateNormalOrSmall
	blt $v0, 20, generateNormalOrSmall # if score >= 20, generateSmallOrVerySmall
	# generateSmallOrVerySmall:
		li $a0, 0
		li $a1, 2
		jal getRandomNumber
		beqz $v0, generateSmallOnly
		lw $t5, platformWidthVerySmall # loop counter
		sw $t5, 8($t2)
		j chooseIfSpring	
	generateSmallOnly: 
		lw $t5, platformWidthSmall # loop counter
		sw $t5, 8($t2)	
		j chooseIfSpring
	generateNormalOrSmall: # else if score < 20
		li $a0, 0
		li $a1, 2
		jal getRandomNumber
		beqz $v0, generateNormalOnly
		lw $t5, platformWidthSmall # loop counter
		sw $t5, 8($t2)
		j chooseIfSpring	
	generateNormalOnly: # else if score < 10
		lw $t5, platformWidthNormal # loop counter
		sw $t5, 8($t2)	
	
	chooseIfSpring:
		blt $t4, 10, noSpring # if score >= 10
		li $a0, 0
		li $a1, 4
		jal getRandomNumber
		beq $v0, 3, hasSpring
		j noSpring
		hasSpring:
		li $t5, 1
		sw $t5, 12($t2) # spring property will have value 1, probability=1/4
		j scrollUpLoop
	noSpring:
		sw $zero, 12($t2) # spring property will have value 0
	
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
			addi $t3, $t3, 16 # update current index
			blt $t3, $t1, pushdownLoop # loop if current index < arraySize
		
		jal drawBackground
		jal drawPlatforms
		jal drawDoodler
		
		# draw score at top-right corner
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
		
		# draw onScreen disp 'NICE, GREAT, WOW'
		jal drawNiceGreatWow
		
		jal keyboardInput
		
		jal copyToScreen
		
		# refresh rate
		lw $t1, boostStatus
		beqz $t1, normalRate
		li $v0, 32
		lw $a0, boostRefreshRate
		syscall
		j scrollUpLoop
		normalRate:
		li $v0, 32
		lw $a0, refreshRate
		syscall
		
		j scrollUpLoop
		
	scrollUpLoopBreak:			
	j noScrollUp
	
drawNiceGreatWow: # drawNiceGreatWow()
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# NICE
	jal convertDigitsToScore
	bne $v0, 10, notNice
	la $t0, NICE
	addi $t3, $s0, 796
	li $t1, 0
	renderNice:
		add $t2, $t1, $t0
		lw $t2, 0($t2)
		add $t2, $t2, $t3
		sw $s4, 0($t2)
		addi $t1, $t1, 4
		blt $t1, 168, renderNice
	li $v0, 32
	li $a0, 18
	syscall
	notNice:
	# GREAT
	bne $v0, 20, notGreat
	la $t0, GREAT
	addi $t3, $s0, 788
	li $t1, 0
	renderGreat:
		add $t2, $t1, $t0
		lw $t2, 0($t2)
		add $t2, $t2, $t3
		sw $s4, 0($t2)
		addi $t1, $t1, 4
		blt $t1, 212, renderGreat
	li $v0, 32
	li $a0, 18
	syscall
	notGreat:	
	# WOW
	bne $v0, 30, notWow
	la $t0, WOW
	addi $t3, $s0, 792
	li $t1, 0
	renderWow:
		add $t2, $t1, $t0
		lw $t2, 0($t2)
		add $t2, $t2, $t3
		sw $s4, 0($t2)
		addi $t1, $t1, 4
		blt $t1, 160, renderWow
	li $v0, 32
	li $a0, 18
	syscall
	notWow:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

drawBackground: # drawBackground()
	li $t7, 0 # disp addr
	drawBackgroundLoop:
		add $t8, $t7, $s0 # add to buffer base addr
		sw $s1, 0($t8)
		addi $t7, $t7, 4 # update disp addr
		blt $t7, 4096, drawBackgroundLoop # loop if < bottom-right corner addr
	jr $ra

drawPlatforms: # drawPlatforms()
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, platformValues
	lw $t1, platformValuesSize
	li $t2, 0 # index of current platformValues
	drawPlatformLoop:
		add $t3, $t2, $t0 # get addr of current
		lw $a0, 0($t3) # get X of current
		lw $a1, 4($t3) # get Y of current
		jal XYToAddressOffset
		move $t6, $v0 # addr offset of current
		
		# check if addr within range, i.e display addr <= x <= bottom-right corner addr
		blt $t6, 0, platformNotWithinAddrRange
		bgt $t6, 4092, platformNotWithinAddrRange 
		add $t6, $t6, $s0 # get disp addr of current
		move $t8, $t6
		
		lw $t5, 8($t3) # loop counter
		move $t7, $t5 # $t7 stores the width
		drawPlatformWidth:
			sw $s2, 0($t6)
			addi $t6, $t6, 4 # get next px
			addi $t5, $t5, -1 # update counter
			bgtz $t5, drawPlatformWidth # loop while counter > 0	
		
		# drawSpringOnPlatform
		lw $t5, 12($t3)
		beqz $t5, noSpringOrDONE
		beq $t7, 8, withNormalWidth
		beq $t7, 6, withSmallWidth
		# withVerySmallWidth
		addi $t8, $t8, -128
		blt $t8, $s0, springNotWithinAddrRange
		li $t4, 0
		drawSpring:
			sw $s6, 0($t8)
			addi $t8, $t8, 4
			addi $t4, $t4, 1	
			blt $t4, 4, drawSpring
		j noSpringOrDONE
		withSmallWidth:
		addi $t8, $t8, -124
		blt $t8, $s0, springNotWithinAddrRange
		li $t4, 0
		drawSpring_1:
			sw $s6, 0($t8)
			addi $t8, $t8, 4
			addi $t4, $t4, 1	
			blt $t4, 4, drawSpring_1
		j noSpringOrDONE
		withNormalWidth:
		addi $t8, $t8, -120
		blt $t8, $s0, springNotWithinAddrRange
		li $t4, 0
		drawSpring_2:
			sw $s6, 0($t8)
			addi $t8, $t8, 4
			addi $t4, $t4, 1	
			blt $t4, 4, drawSpring_2
		noSpringOrDONE:
		springNotWithinAddrRange:
		
		platformNotWithinAddrRange:
		addi $t2, $t2, 16 # update current index
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
	lw $t1, boostStatus
	beqz $t1, noBoost_1
	beq $s5, 1, noBoost_1
	addi $a1, $a1, -2 # increment dooldler height
	addi $s5, $s5, -2 # reduce jump height threshold
	j drawDoodlerContinue
	noBoost_1:
	addi $a1, $a1, -1 # increment dooldler height
	addi $s5, $s5, -1 # reduce jump height threshold
	j drawDoodlerContinue
	moveDown:
		addi $a1, $a1, 1 # decrement dooldler height
		move $t3, $a1 # keep current Y
		addi $a1, $a1, 4 # get Y of doodler bottom
		jal XYToAddressOffset
		add $t1, $v0, $gp # disp addr of doodler bottom
		
		# check for spring under doodler along doodler width
		lw $t2, 0($t1)
		beq $t2, $s6, resetToBoostHeight 
		lw $t2, 4($t1)
		beq $t2, $s6, resetToBoostHeight
		lw $t2, 8($t1)
		beq $t2, $s6, resetToBoostHeight
		# check for new platform under doodler along doodler width
		lw $t2, 0($t1)
		beq $t2, $s2, resetToJumpHeight 
		lw $t2, 4($t1)
		beq $t2, $s2, resetToJumpHeight
		lw $t2, 8($t1)
		beq $t2, $s2, resetToJumpHeight
		move $a1, $t3 # restore current Y
		j drawDoodlerContinue
		
	resetToJumpHeight: 
		lw $s5, jumpHeight # reset to jump height because new platform under doodler
		sw $zero, boostStatus
		j jumpHeightSet
	resetToBoostHeight:
		lw $s5, boostHeight # reset to boost height because spring under doodler
		li $t1, 1
		sw $t1, boostStatus
	
	jumpHeightSet:
	move $a1, $t3 # restore current Y
		
	drawDoodlerContinue:	
	sw $a1, 4($t0) # update Y of doodler
		
	bgt $a1, 32, endGame # end game if doodler reaches bottom of screen

	# draw doodler
	jal XYToAddressOffset
	move $t0, $v0 # starting addr to render doodler
	# check if addr within range, i.e display addr <= x <= bottom-right corner addr
	blt $t0, 0, doodlerNotWithinAddrRange
	bgt $t0, 4092, doodlerNotWithinAddrRange 
	add $t0, $t0, $s0 # add base disp addr
	
	la $t1, doodlerOffsets
	li $t2, 0 # counter
	renderDoodler:
		add $t3, $t2, $t1
		lw $t4, 0($t3)
		add $t4, $t4, $t0
		addi $t5, $s0, 4096
		bge $t4, $t5, partOutOfRange
		sw $s3, 0($t4)
		addi $t2, $t2, 4 # update counter
		blt $t2, 48, renderDoodler	
	partOutOfRange:
	
	doodlerNotWithinAddrRange:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
endGame: # endGame()
	lw $ra, 0($sp) # pop $ra of drawDoodler caller func
	addi $sp, $sp, 4

	li $v0, 32
	li $a0, 100
	syscall
	
	jal drawBackground
	addi $t0, $s0, 800 # starting addr to render 'BYE'
	la $t1, BYE
	li $t2, 0 # counter
	renderBye:
		add $t3, $t2, $t1
		lw $t4, 0($t3)
		add $t4, $t4, $t0
		sw $s4, 0($t4)
		addi $t2, $t2, 4
		blt $t2, 144, renderBye	
	
	addi $t0, $s0, 1940 # starting addr to render 'SCORE'
	la $t1, scoreLetters
	li $t2, 0 # counter
	renderScore:
		add $t3, $t2, $t1
		lw $t4, 0($t3)
		add $t4, $t4, $t0
		sw $s4, 0($t4)
		addi $t2, $t2, 4
		blt $t2, 212, renderScore	
	
	lw $t0, thirdDigit
	beqz $t0, noThirdDigit_2
	lw $a0, firstDigit 
	li $a1, 2888
	jal drawDigit
	
	lw $a0, secondDigit 
	li $a1, 2872
	jal drawDigit
	
	lw $a0, thirdDigit
	li $a1, 2856
	jal drawDigit
	j drawDigitDone
	
	noThirdDigit_2:
	lw $a0, firstDigit 
	li $a1, 2880
	jal drawDigit
	
	lw $a0, secondDigit 
	li $a1, 2864
	jal drawDigit
	
	drawDigitDone:
	jal copyToScreen
	
	la $t7, gameStatus
	sw $zero, 0($t7) # gameStatus = 0
	endGameScreenLoop: # stay on endGameScreen until user restart
		li $v0, 32
		li $a0, 100
		syscall
		lw $t7, 0xffff0000
		beq $t7, 1, checkRestart
		j noRestart
		checkRestart:
			lw $t7, 0xffff0004
			beq $t7, 0x73, restartGame # press 's' to restart
		noRestart:
		lw $t7, gameStatus
		beqz $t7, endGameScreenLoop
	
restartGame: # restartGame() resets all objects to their initial values
	# reset platforms values
	la $t0, platformValues
	lw $t1, platformValuesSize
	li $t3, 12
	li $t4, 31
	li $t5, 8
	sw $t3, 0($t0)
	sw $t4, 4($t0)
	sw $t5, 8($t0)
	sw $zero, 12($t0)
	li $t2, 16 # index of current
	resetPlatforms:
		add $t3, $t2, $t0
		sw $zero, 0($t3)
		sw $zero, 4($t3)
		li $t5, 8
		sw $t5, 8($t3)
		sw $zero, 12($t3)
		addi $t2, $t2, 16 # update current index
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
	
	# reset refreshRates
	li $t0, 40
	li $t1, 35
	sw $t0, refreshRate
	sw $t1, boostRefreshRate
	
	# reset game status to 1
	la $t0, gameStatus
	li $t1, 1
	sw $t1, 0($t0)
	
	j initialSetup
	
drawDigit: # drawDigit(digit, starting offset)
	bne $a0, 0, num1
	la $t1, zero
	li $t5, 48 # setting the length of digit offsset array
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
		blt $t2, $t5, renderDigit # loop if still < array length
	jr $ra
	
XYToAddressOffset: # XYToAddressOffset(X, Y) converts X,Y from px to address offset in bytes
	sll $t8, $a0, 2 # X*4 
	li $t9, 128
	mult $a1, $t9
	mflo $t9 # Y*128
	add $v0, $t8, $t9 # X*4 + Y*128 gives the address offset	
	jr $ra
		
getRandomX: # getRandomX() returns a random X in px
	# since platform width 8px, 32-8=24 possible platform locations per line
	# choose a random number between 0 and 24
	li $a0, 0
	li $a1, 25
	li $v0, 42 
	syscall
	move $v0, $a0 # get random number
	jr $ra

getVerticalSeparator: # getVerticalSeparator() returns a random vertical separator in px
	# choose a random number out of 0 and 1
	li $a0, 0
	li $a1, 2
	li $v0, 42 
	syscall
	move $t7, $a0 # get random number
	la $t8, verticalSeparators
	sll $t7, $t7, 2 # *4 to get index to retrieve from array(index 0 or 4)
	add $t8, $t8, $t7
	lw $t7, 0($t8) # get value from array
	move $v0, $t7 # return value
	jr $ra
	
convertDigitsToScore: # convertDigitsToScore()
	lw $t4, firstDigit 
	lw $t3, secondDigit	
	li $t5, 10
	mult $t3, $t5
	mflo $t3
	add $t4, $t4, $t3 # add sum to first digit
	lw $t3, thirdDigit	
	li $t5, 100
	mult $t3, $t5
	mflo $t3
	add $v0, $t4, $t3 # $v0 = 3rd*100 + 2nd*10 + 1st
	jr $ra
	
getRandomNumber: # getRandomNumber(min, max) returns a random number in the range
	li $v0, 42
	syscall
	move $v0, $a0
	jr $ra
