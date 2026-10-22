; Wait until the beam has drawn the screen (line 303 on PAL), once a frame.
; Everything below runs 50 times a second.
.w1	move.l	VPOSR(a6),d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.s	.w1
.w2	move.l	VPOSR(a6),d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.s	.w2
	addq.w	#1,tick
