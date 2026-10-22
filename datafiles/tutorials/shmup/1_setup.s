; STAR BLASTER - screen setup. Runs once.
; Two bitplanes of stars, eight hardware sprites and our own Copper list.
; The sprites come from SPR-EDIT: spr_Ship, spr_Shot, spr_Enemy, spr_Boom.
E_STATE	equ	0		; enemy record: 0 free, 1 flying, 2 exploding
E_X	equ	2
E_Y	equ	4
E_PHASE	equ	6		; where it is on its sine wave
E_BASE	equ	8		; the column it sways around
E_TIMER	equ	10		; explosion frames left
E_SPEED	equ	12		; lines it falls per frame
E_BUF	equ	14		; its sprite buffer in chip RAM (long)
E_SIZE	equ	18
ENEMY_BUF	equ	(2+16*2+2)*2	; control words, 16 rows, end marker

	lea	CUSTOM,a6
	tst.b	DMACONR(a6)		; early Agnus: read DMACONR once
.blit	btst	#6,DMACONR(a6)		; let any OS blit finish
	bne.s	.blit
	move.w	#$1fff,INTENA(a6)	; OS interrupts off (the music keeps EXTER)
	move.w	#$1fff,INTREQ(a6)
	move.w	#$7df0,DMACON(a6)	; display off; DMAEN and audio stay on
	move.w	#$2c81,DIWSTRT(a6)	; the usual 320x256 PAL window
	move.w	#$2cc1,DIWSTOP(a6)
	move.w	#$0038,DDFSTRT(a6)
	move.w	#$00d0,DDFSTOP(a6)
	move.w	#$2200,BPLCON0(a6)	; two bitplanes, colour on
	clr.w	BPLCON1(a6)
	move.w	#$0024,BPLCON2(a6)	; sprites in front of the stars
	clr.w	BPLCON3(a6)		; ECS / AGA defaults
	move.w	#$0011,BPLCON4(a6)	; AGA: sprites use colours 16-31
	clr.w	BPL1MOD(a6)
	clr.w	BPL2MOD(a6)
	clr.w	FMODE(a6)		; AGA: classic fetch width

	move.w	#$447,COLOR01(a6)	; far stars: dim
	move.w	#$aaf,COLOR02(a6)	; near stars: bright
	move.w	#$fff,COLOR03(a6)
	lea	spr_Ship_colours,a0	; sprites 0-1 use colours 17-19
	lea	COLOR17(a6),a1
	move.w	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	lea	COLOR21(a6),a1		; sprites 2-7: 21-23, 25-27, 29-31
	moveq	#2,d1
.pal	lea	spr_Enemy_colours,a0
	move.w	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	addq.l	#2,a1
	dbf	d1,.pal

	move.l	#$2545f491,seed		; any non-zero start for random
	lea	stars_far,a0		; scatter the stars, then copy each
	move.w	#99,d6			; 256-line plane below itself so it
	bsr	plot_stars		; can scroll round for ever
	lea	stars_near,a0
	moveq	#39,d6
	bsr	plot_stars
	lea	stars_far,a0
	bsr	double_plane
	lea	stars_near,a0
	bsr	double_plane

	lea	enemies,a0		; each enemy slot gets its own buffer
	lea	enemy_bufs,a1
	moveq	#5,d0
.eb	move.l	a1,E_BUF(a0)
	lea	E_SIZE(a0),a0
	lea	ENEMY_BUF(a1),a1
	dbf	d0,.eb

	move.w	#152,ship_x
	move.w	#210,ship_y
	move.w	#256,far_y
	move.w	#256,near_y
	move.w	#50,spawn_time

	bsr	build_copper
	move.l	#copper,COP1LC(a6)
	move.w	d0,COPJMP1(a6)		; start it now
	move.w	#$83a0,DMACON(a6)	; DMAEN, bitplanes, Copper, sprites on
