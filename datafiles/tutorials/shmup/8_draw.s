; Put every sprite where it belongs by writing its two control words.
; Channel 0: the ship. Channel 1: all four shots, one after another down
; the screen (one channel can show several sprites if they do not overlap).
; Channels 2-7: the enemies.
	lea	spr_Ship,a1
	move.w	ship_x,d0
	move.w	ship_y,d1
	moveq	#spr_Ship_h,d2
	tst.w	hurt_time		; blinking after a hit
	beq.s	.show
	btst	#2,tick+1
	beq.s	.show
	clr.l	(a1)			; hidden this frame
	bra.s	.shots
.show	bsr	set_sprite

.shots	lea	shotbuf,a1
	move.w	shot_next,d5		; oldest first = highest first
	moveq	#3,d6
	move.w	#-1000,d7		; where the previous shot ended
.c	move.w	d5,d0
	mulu	#6,d0
	lea	shots,a0
	add.w	d0,a0
	tst.w	(a0)
	beq.s	.nc
	move.w	4(a0),d1
	cmp.w	d7,d1
	ble.s	.nc			; would overlap the one above: skip
	move.w	2(a0),d0
	moveq	#spr_Shot_h,d2
	bsr	set_sprite
	move.w	d1,d7
	add.w	#spr_Shot_h+1,d7
	addq.l	#4,a1
	lea	spr_Shot+4,a2
	moveq	#spr_Shot_h*2-1,d0
.cp	move.w	(a2)+,(a1)+
	dbf	d0,.cp
.nc	addq.w	#1,d5
	and.w	#3,d5
	dbf	d6,.c
	clr.l	(a1)			; end of the chain

	lea	enemies,a0
	moveq	#5,d6
.en	move.l	E_BUF(a0),a1
	tst.w	E_STATE(a0)
	bne.s	.vis
	clr.l	(a1)			; free slot: nothing shown
	bra.s	.nn
.vis	move.w	E_X(a0),d0
	move.w	E_Y(a0),d1
	moveq	#16,d2
	bsr	set_sprite
.nn	lea	E_SIZE(a0),a0
	dbf	d6,.en
