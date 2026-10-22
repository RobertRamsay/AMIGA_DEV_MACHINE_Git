; Tables, variables and chip-RAM buffers.
sprite_list:			; what each sprite channel shows
	dc.l	spr_Ship, shotbuf
	dc.l	enemy_bufs+0*ENEMY_BUF, enemy_bufs+1*ENEMY_BUF
	dc.l	enemy_bufs+2*ENEMY_BUF, enemy_bufs+3*ENEMY_BUF
	dc.l	enemy_bufs+4*ENEMY_BUF, enemy_bufs+5*ENEMY_BUF
fade:				; Copper WAIT word, COLOR00: a deep space fade, 16 lines a step
	dc.w	$2c07,$001, $3c07,$002, $4c07,$002, $5c07,$003
	dc.w	$6c07,$103, $7c07,$103, $8c07,$104, $9c07,$204
	dc.w	$ac07,$204, $bc07,$205, $cc07,$304, $dc07,$304
	dc.w	$ec07,$303, $fc07,$302
	dc.w	0
sine:				; 64 steps of 20 * sin
	dc.b	0,2,4,6,8,10,11,13,14,16,17,18,19,19,20,20
	dc.b	20,20,20,19,19,18,17,16,14,13,11,10,8,6,4,2
	dc.b	0,-2,-4,-6,-8,-10,-11,-13,-14,-16,-17,-18,-19,-19,-20,-20
	dc.b	-20,-20,-20,-19,-19,-18,-17,-16,-14,-13,-11,-10,-8,-6,-4,-2
	even

	SECTION	shmup_vars,BSS
seed:		ds.l	1
tick:		ds.w	1
ship_x:		ds.w	1
ship_y:		ds.w	1
idle_time:	ds.w	1
fire:		ds.w	1
far_y:		ds.w	1
near_y:		ds.w	1
shot_cool:	ds.w	1
shot_next:	ds.w	1
shots:		ds.w	4*3
spawn_time:	ds.w	1
hurt_time:	ds.w	1
enemies:	ds.b	6*E_SIZE

	SECTION	shmup_chip,BSS_C	; DMA can only read chip RAM
copper:		ds.l	64
shotbuf:	ds.w	4*(2+8*2)+2		; four shots up to 8 rows high
enemy_bufs:	ds.b	6*ENEMY_BUF
stars_far:	ds.b	40*512
stars_near:	ds.b	40*512

	SECTION	code,CODE
