; Collisions. A shot inside an enemy's 16x16 box blows it up; an enemy that
; reaches the ship blows up too and the ship blinks for 2 seconds.
	lea	shots,a0
	moveq	#3,d0
.s	tst.w	(a0)
	beq.s	.ns
	move.w	2(a0),d1
	addq.w	#8,d1			; the middle of the shot
	move.w	4(a0),d2
	lea	enemies,a1
	moveq	#5,d3
.e	cmp.w	#1,E_STATE(a1)
	bne.s	.ne
	move.w	d1,d4
	sub.w	E_X(a1),d4
	cmp.w	#15,d4			; 0-15 = inside (unsigned, so
	bhi.s	.ne			; negative counts as outside too)
	move.w	d2,d4
	sub.w	E_Y(a1),d4
	addq.w	#4,d4
	cmp.w	#20,d4
	bhi.s	.ne
	clr.w	(a0)			; the shot is used up
	bsr	explode
	bra.s	.ns
.ne	lea	E_SIZE(a1),a1
	dbf	d3,.e
.ns	addq.l	#6,a0
	dbf	d0,.s

	tst.w	hurt_time
	beq.s	.ship
	subq.w	#1,hurt_time
	bra.s	.done
.ship	lea	enemies,a1
	moveq	#5,d3
.e2	cmp.w	#1,E_STATE(a1)
	bne.s	.ne2
	move.w	E_X(a1),d4
	sub.w	ship_x,d4
	add.w	#12,d4
	cmp.w	#24,d4
	bhi.s	.ne2
	move.w	E_Y(a1),d4
	sub.w	ship_y,d4
	add.w	#12,d4
	cmp.w	#24,d4
	bhi.s	.ne2
	bsr	explode
	move.w	#100,hurt_time
.ne2	lea	E_SIZE(a1),a1
	dbf	d3,.e2
.done
