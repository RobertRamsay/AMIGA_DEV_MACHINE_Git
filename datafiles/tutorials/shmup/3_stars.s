; Parallax stars: the far plane scrolls 1 line a frame, the near one 2.
; Moving a bitplane pointer up one row (40 bytes) scrolls it down a line;
; the Copper list loads the pointers every frame.
	move.w	far_y,d0
	subq.w	#1,d0
	bpl.s	.f
	add.w	#256,d0			; wrap: rows 256-511 repeat rows 0-255
.f	move.w	d0,far_y
	mulu	#40,d0
	add.l	#stars_far,d0
	move.w	d0,copper+6		; BPL1PTL
	swap	d0
	move.w	d0,copper+2		; BPL1PTH

	move.w	near_y,d0
	subq.w	#2,d0
	bpl.s	.n
	add.w	#256,d0
.n	move.w	d0,near_y
	mulu	#40,d0
	add.l	#stars_near,d0
	move.w	d0,copper+14		; BPL2PTL
	swap	d0
	move.w	d0,copper+10		; BPL2PTH
