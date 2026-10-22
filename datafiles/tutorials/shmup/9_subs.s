; Subroutines the blocks call with BSR. The main loop ends with BRA, so the
; program never falls into this column: it only runs when called.

; a1 = a sprite's control words, d0 = x, d1 = y, d2 = height.
; VSTART = y + $2C and HSTART = x + 128 in the 320x256 window.
set_sprite:
	movem.l	d0-d4,-(sp)
	add.w	#128,d0			; HSTART
	add.w	#$2c,d1			; VSTART
	move.w	d1,d3
	add.w	d2,d3			; VSTOP
	move.w	d1,d4
	lsl.w	#8,d4			; SPRxPOS: VSTART bits 7-0 ...
	move.w	d0,d2
	lsr.w	#1,d2
	move.b	d2,d4			; ... and HSTART bits 8-1
	move.w	d4,(a1)
	move.w	d3,d4
	lsl.w	#8,d4			; SPRxCTL: VSTOP bits 7-0 ...
	btst	#8,d1
	beq.s	.v
	bset	#2,d4			; ... VSTART bit 8
.v	btst	#8,d3
	beq.s	.s
	bset	#1,d4			; ... VSTOP bit 8
.s	btst	#0,d0
	beq.s	.h
	bset	#0,d4			; ... HSTART bit 0
.h	move.w	d4,2(a1)
	movem.l	(sp)+,d0-d4
	rts

; a1 = enemy record: it explodes (picture spr_Boom, 16 frames) with a bang.
explode:
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#2,E_STATE(a1)
	move.w	#16,E_TIMER(a1)
	move.l	E_BUF(a1),a1
	lea	spr_Boom+4,a2
	bsr	copy_image
	bsr	sfx_boom
	movem.l	(sp)+,d0-d7/a0-a6
	rts

; Copies a 16-row picture (a2 = its rows) into the sprite buffer at a1.
copy_image:
	movem.l	d0/a1-a2,-(sp)
	addq.l	#4,a1			; after the control words
	moveq	#31,d0
.c	move.w	(a2)+,(a1)+
	dbf	d0,.c
	movem.l	(sp)+,d0/a1-a2
	rts

; Random 32-bit number in d0 (xorshift).
random:
	move.l	d1,-(sp)
	move.l	seed,d0
	move.l	d0,d1
	lsl.l	#8,d1
	lsl.l	#5,d1
	eor.l	d1,d0			; x ^= x << 13
	move.l	d0,d1
	swap	d1
	and.l	#$ffff,d1
	lsr.w	#1,d1
	eor.l	d1,d0			; x ^= x >> 17
	move.l	d0,d1
	lsl.l	#5,d1
	eor.l	d1,d0			; x ^= x << 5
	move.l	d0,seed
	move.l	(sp)+,d1
	rts

; a0 = a star plane, d6 = stars - 1: sets random pixels in its first 256 rows.
plot_stars:
	bsr	random
	and.l	#$ffff,d0
	divu	#320,d0
	swap	d0			; x = remainder 0-319
	move.w	d0,d2
	bsr	random
	and.w	#255,d0			; y
	mulu	#40,d0
	move.w	d2,d1
	lsr.w	#3,d1
	add.w	d1,d0			; byte = y * 40 + x / 8
	move.w	d2,d1
	and.w	#7,d1
	eor.w	#7,d1			; bit = 7 - (x & 7)
	bset	d1,(a0,d0.w)
	dbf	d6,plot_stars
	rts

; a0 = a star plane: copies rows 0-255 to rows 256-511.
double_plane:
	lea	40*256(a0),a1
	move.w	#40*256/4-1,d0
.c	move.l	(a0)+,(a1)+
	dbf	d0,.c
	rts

; The Copper list: plane pointers (the stars block updates them), the
; eight sprite pointers and a background colour fade, every frame.
build_copper:
	lea	copper,a0
	move.w	#BPL1PTH,(a0)+
	clr.w	(a0)+
	move.w	#BPL1PTL,(a0)+
	clr.w	(a0)+
	move.w	#BPL2PTH,(a0)+
	clr.w	(a0)+
	move.w	#BPL2PTL,(a0)+
	clr.w	(a0)+
	move.w	#SPR0PTH,d1
	lea	sprite_list,a1
	moveq	#7,d2
.sp	move.l	(a1)+,d0
	move.w	d1,(a0)+
	swap	d0
	move.w	d0,(a0)+
	addq.w	#2,d1
	move.w	d1,(a0)+
	swap	d0
	move.w	d0,(a0)+
	addq.w	#2,d1
	dbf	d2,.sp
	lea	fade,a1			; WAIT line, colour - until 0
.fd	move.w	(a1)+,d0
	beq.s	.end
	move.w	d0,(a0)+
	move.w	#$fffe,(a0)+
	move.w	#COLOR00,(a0)+
	move.w	(a1)+,(a0)+
	bra.s	.fd
.end	move.l	#$fffffffe,(a0)+	; end of list
	rts
