; The ship: joystick in port 2 moves it, fire shoots. Leave the stick for
; 3 seconds and it flies itself (attract mode) until you touch it again.
	move.w	JOY1DAT(a6),d0		; bit 1 right, bit 9 left
	move.w	d0,d1
	lsr.w	#1,d1
	eor.w	d0,d1			; now bit 0 down, bit 8 up
	moveq	#0,d2			; dx
	moveq	#0,d3			; dy
	btst	#1,d0
	beq.s	.nr
	moveq	#2,d2
.nr	btst	#9,d0
	beq.s	.nl
	moveq	#-2,d2
.nl	btst	#0,d1
	beq.s	.nd
	moveq	#2,d3
.nd	btst	#8,d1
	beq.s	.nu
	moveq	#-2,d3
.nu	btst	#7,$bfe001		; CIA-A: fire button, 0 = pressed
	seq	d4

	move.w	d2,d5			; touched anything?
	or.w	d3,d5
	or.b	d4,d5
	beq.s	.idle
	clr.w	idle_time
	bra.s	.move
.idle	cmp.w	#150,idle_time
	bhs.s	.auto
	addq.w	#1,idle_time
	bra.s	.move

.auto	move.w	#152,d5			; attract mode: aim at the first enemy
	lea	enemies,a0
	moveq	#5,d6
.find	cmp.w	#1,E_STATE(a0)
	bne.s	.next
	move.w	E_X(a0),d5
	bra.s	.aim
.next	lea	E_SIZE(a0),a0
	dbf	d6,.find
.aim	sub.w	ship_x,d5
	cmp.w	#2,d5
	ble.s	.a1
	moveq	#2,d2
	bra.s	.a2
.a1	cmp.w	#-2,d5
	bge.s	.a2
	moveq	#-2,d2
.a2	moveq	#-1,d4			; keep firing
	cmp.w	#200,ship_y		; and drift back to line 200
	beq.s	.move
	blt.s	.down
	moveq	#-1,d3
	bra.s	.move
.down	moveq	#1,d3

.move	add.w	ship_x,d2		; new x, kept on screen
	bpl.s	.x0
	moveq	#0,d2
.x0	cmp.w	#304,d2
	ble.s	.x1
	move.w	#304,d2
.x1	move.w	d2,ship_x
	add.w	ship_y,d3		; new y
	cmp.w	#24,d3
	bge.s	.y0
	moveq	#24,d3
.y0	cmp.w	#236,d3
	ble.s	.y1
	move.w	#236,d3
.y1	move.w	d3,ship_y
	move.b	d4,fire
