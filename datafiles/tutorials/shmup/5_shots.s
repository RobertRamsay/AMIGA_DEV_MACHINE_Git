; Shots: up to four in flight, a new one every 8 frames while fire is held.
; Each record is 3 words: active, x, y. They fly up 6 lines a frame.
	tst.w	shot_cool
	beq.s	.ready
	subq.w	#1,shot_cool
	bra.s	.fly
.ready	tst.b	fire
	beq.s	.fly
	move.w	shot_next,d0		; the oldest slot (a ring of four)
	move.w	d0,d1
	mulu	#6,d1
	lea	shots,a0
	tst.w	(a0,d1.w)
	bne.s	.fly			; all four still flying
	move.w	#1,(a0,d1.w)
	move.w	ship_x,2(a0,d1.w)
	move.w	ship_y,d2
	subq.w	#6,d2
	move.w	d2,4(a0,d1.w)
	addq.w	#1,d0
	and.w	#3,d0
	move.w	d0,shot_next
	move.w	#8,shot_cool
	bsr	sfx_shoot		; a PLAY SFX node used as a subroutine

.fly	lea	shots,a0
	moveq	#3,d0
.m	tst.w	(a0)
	beq.s	.n
	subq.w	#6,4(a0)
	cmp.w	#-8,4(a0)
	bgt.s	.n
	clr.w	(a0)			; off the top: free again
.n	addq.l	#6,a0
	dbf	d0,.m
