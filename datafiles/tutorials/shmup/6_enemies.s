; Enemies: a new one every 40 frames at a random column. Each falls 1 or 2
; lines a frame and sways on a sine wave. Exploding ones show their blast
; (spr_Boom) for 16 frames, then the slot is free again.
	subq.w	#1,spawn_time
	bpl.s	.fly
	move.w	#40,spawn_time
	lea	enemies,a0
	moveq	#5,d0
.free	tst.w	E_STATE(a0)
	beq.s	.new
	lea	E_SIZE(a0),a0
	dbf	d0,.free
	bra.s	.fly			; all six busy
.new	move.w	#1,E_STATE(a0)
	bsr	random
	and.l	#$ffff,d0
	divu	#256,d0
	swap	d0			; remainder: 0-255
	add.w	#24,d0
	move.w	d0,E_BASE(a0)
	move.w	#-16,E_Y(a0)
	bsr	random
	and.w	#63,d0
	move.w	d0,E_PHASE(a0)
	bsr	random
	and.w	#1,d0
	addq.w	#1,d0
	move.w	d0,E_SPEED(a0)
	move.l	E_BUF(a0),a1		; its picture: the SPR-EDIT enemy
	lea	spr_Enemy+4,a2
	bsr	copy_image

.fly	lea	enemies,a0
	moveq	#5,d6
.m	move.w	E_STATE(a0),d0
	beq.s	.n
	cmp.w	#2,d0
	beq.s	.boom
	move.w	E_SPEED(a0),d1
	add.w	d1,E_Y(a0)
	cmp.w	#258,E_Y(a0)
	blt.s	.sway
	clr.w	E_STATE(a0)		; gone past the bottom
	bra.s	.n
.sway	addq.w	#1,E_PHASE(a0)
	move.w	E_PHASE(a0),d1
	lsr.w	#1,d1
	and.w	#63,d1
	lea	sine,a1
	move.b	(a1,d1.w),d1
	ext.w	d1
	add.w	E_BASE(a0),d1
	move.w	d1,E_X(a0)
	bra.s	.n
.boom	subq.w	#1,E_TIMER(a0)
	bne.s	.n
	clr.w	E_STATE(a0)
.n	lea	E_SIZE(a0),a0
	dbf	d6,.m
