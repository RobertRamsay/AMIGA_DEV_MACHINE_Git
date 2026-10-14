; ============================================================================
;  Amiga Dev Machine - Game Kit runtime (platformer engine)
;
;  Included by the build after the program's nodes whenever a Game Kit node
;  is used. The nodes save every register, set their parameters and JSR here:
;
;    GAME SCREEN   gk_screen         320x256, 4 bitplanes, 8 sprites, own copper
;    DRAW MAP      gk_map  a0=map    tile map + tileset, draws the start room
;    PLAYER        gk_player a0=set  hero animation set, at the map's start
;    WAIT FRAME    gk_wait_frame     sync to the 50 Hz display
;    READ JOYSTICK gk_read_input     port 2 stick + fire
;    PHYSICS       gk_physics        run, jump, gravity, tile collision, rooms
;    TILE EVENTS   gk_events         collect / hazard / exit tiles
;    ENEMIES       gk_enemies        patrol, turn at walls and ledges, hurt
;    ANIMATE       gk_animate        idle / run / jump / fall states
;    DRAW SPRITES  gk_draw_sprites   hero + enemies into the hardware sprites
;
;  Data (baked by Amiga Dev Machine, scr_gamekit_emit):
;  map      0 T.w 2 cols.w 4 rows.w 6 rooms_x.w 8 rooms_y.w 10 width.w
;           12 height.w 14 spawn_x.w 16 spawn_y.w 18 tileset.l 22 cells.l
;           26 enemies.l                            (cells: width*height bytes)
;  tileset  0 T.w 2 count.w 4 tile_bytes.w 6 palette 16 words 38 flags.l
;           42 gfx.l   (gfx: per tile, 4 planes of T rows of T/8 bytes)
;  animset  0 height.w 2 colours 3 words, 8 + 12*state: count.w rate.w
;           right.l left.l (frames: height x (DATA.w, DATB.w))
;           states 0 idle 1 run 2 jump 3 fall
;  enemies  count.w, then x.w y.w speed.w animset.l per enemy (map pixels)
;
;  Positions are pixels inside the current room (one room = one screen);
;  the hero's are in 1/16 pixel. A room is cols*T x rows*T pixels at the
;  top left of the screen. Everything runs with the OS display, blitter and
;  OS interrupts switched off; the CIA-B music interrupt (ptplayer) stays.
; ============================================================================

GK_SOLID    equ 1
GK_PLATFORM equ 2
GK_HAZARD   equ 4
GK_COLLECT  equ 8
GK_EXIT     equ 16

GK_PLANE    equ 10240               ; 40 bytes x 256 lines
GK_SCREEN_BYTES equ GK_PLANE*4
GK_SPRBUF   equ 264                 ; pos, ctl, 64 rows x 2 words, end
GK_COPPER_BYTES equ 128
GK_MAX_EN   equ 6
GK_EN_SIZE  equ 16                  ; x.w y.w dir.w speed.w anim.l frame.w acc.w
GK_HIT_L    equ 3                   ; hit box: x+3 .. x+12 of the 16 px sprite
GK_HIT_R    equ 12

J_LEFT      equ 0
J_RIGHT     equ 1
J_UP        equ 2
J_DOWN      equ 3
J_FIRE      equ 4

; ---------------------------------------------------------------------------
; GAME SCREEN: take over the display and build the copper list.
gk_screen:
            move.l  gk_screen_ptr,d0
            bne     .have
            move.l  4.w,a6
            move.l  #GK_SCREEN_BYTES+GK_COPPER_BYTES+8*GK_SPRBUF,d0
            move.l  #$10002,d1              ; MEMF_CHIP | MEMF_CLEAR
            jsr     -198(a6)                ; AllocMem
            tst.l   d0
            beq     gk_fail
            move.l  d0,gk_screen_ptr
            add.l   #GK_SCREEN_BYTES,d0
            move.l  d0,gk_copper_ptr
            add.l   #GK_COPPER_BYTES,d0
            move.l  d0,gk_sprbuf
            move.l  4.w,a0
            move.w  #303,gk_vbl_line        ; PAL: after the 256-line display
            cmp.b   #50,530(a0)             ; ExecBase VBlankFrequency
            beq.s   .pal
            move.w  #255,gk_vbl_line        ; NTSC frames have 262 lines: 303 never comes
.pal
.have
            lea     $dff000,a6
            tst.b   2(a6)                   ; early Agnus: read DMACONR once before testing BBUSY
.bw1        btst    #6,2(a6)                ; let any OS blit finish
            bne.s   .bw1
            move.w  #$1fff,$9a(a6)          ; INTENA: OS interrupts off (keep master + EXTER for music)
            move.w  #$1fff,$9c(a6)          ; INTREQ
            move.w  #$7df0,$96(a6)          ; DMACON: display/blitter/copper off (DMAEN + audio kept, music plays on)
            move.w  #$2c81,$8e(a6)          ; DIWSTRT
            move.w  #$2cc1,$90(a6)          ; DIWSTOP
            move.w  #$0038,$92(a6)          ; DDFSTRT
            move.w  #$00d0,$94(a6)          ; DDFSTOP
            move.w  #$4200,$100(a6)         ; BPLCON0: 4 planes, colour
            clr.w   $102(a6)                ; BPLCON1
            move.w  #$0024,$104(a6)         ; BPLCON2: sprites in front of the playfield
            clr.w   $106(a6)                ; BPLCON3 (ECS/AGA)
            move.w  #$0011,$10c(a6)         ; BPLCON4 (AGA): sprites use colours 16-31
            clr.w   $108(a6)                ; BPL1MOD
            clr.w   $10a(a6)                ; BPL2MOD
            clr.w   $1fc(a6)                ; FMODE (AGA)
            lea     $180(a6),a0             ; all colours black until the map sets them
            moveq   #31,d0
.cl         clr.w   (a0)+
            dbf     d0,.cl

            move.l  gk_copper_ptr,a0        ; copper: plane and sprite pointers
            move.l  gk_screen_ptr,d0
            move.w  #$00e0,d1
            moveq   #3,d2
.cpl        move.w  d1,(a0)+
            swap    d0
            move.w  d0,(a0)+
            swap    d0
            addq.w  #2,d1
            move.w  d1,(a0)+
            move.w  d0,(a0)+
            addq.w  #2,d1
            add.l   #GK_PLANE,d0
            dbf     d2,.cpl
            move.l  gk_sprbuf,d0
            move.w  #$0120,d1
            moveq   #7,d2
.cps        move.w  d1,(a0)+
            swap    d0
            move.w  d0,(a0)+
            swap    d0
            addq.w  #2,d1
            move.w  d1,(a0)+
            move.w  d0,(a0)+
            addq.w  #2,d1
            add.l   #GK_SPRBUF,d0
            dbf     d2,.cps
            move.l  #$fffffffe,(a0)+
            move.l  gk_copper_ptr,$80(a6)   ; COP1LC
            move.w  d0,$88(a6)              ; COPJMP1
            move.w  #$83a0,$96(a6)          ; DMACON: DMAEN | BPLEN | COPEN | SPREN
            rts

; Out of chip RAM: a solid red screen, as the bootblock does.
gk_fail:    lea     $dff000,a6
            move.w  #$7fff,$96(a6)
.red        move.w  #$0f00,$180(a6)
            bra.s   .red

; ---------------------------------------------------------------------------
; DRAW MAP: a0 = map data.
gk_map:
            tst.l   gk_screen_ptr
            bne.s   .scr
            move.l  a0,-(sp)
            bsr     gk_screen               ; DRAW MAP works without GAME SCREEN too
            move.l  (sp)+,a0
.scr        move.l  a0,gk_map_ptr
            move.w  (a0),gk_T
            move.w  (a0),d0
            lsr.w   #3,d0
            move.w  d0,gk_rowbytes
            move.w  2(a0),gk_cols
            move.w  4(a0),gk_rows
            move.w  6(a0),gk_roomsx
            move.w  8(a0),gk_roomsy
            move.w  10(a0),gk_mw
            move.w  12(a0),gk_mh
            move.w  gk_cols,d0
            mulu    gk_T,d0
            move.w  d0,gk_roomw
            move.w  gk_rows,d0
            mulu    gk_T,d0
            move.w  d0,gk_roomh
            move.w  gk_mw,d0
            mulu    gk_T,d0
            move.w  d0,gk_mapw_px
            move.w  gk_mh,d0
            mulu    gk_T,d0
            move.w  d0,gk_maph_px
            move.l  22(a0),gk_pristine
            move.l  26(a0),gk_enemy_list
            move.l  18(a0),a1               ; tileset
            move.w  4(a1),gk_tilebytes
            move.l  38(a1),gk_flagtab
            move.l  42(a1),gk_gfx
            lea     6(a1),a2                ; palette -> COLOR00..15
            lea     gk_palette,a3
            lea     $dff180,a4
            moveq   #15,d0
.pal        move.w  (a2),(a3)+
            move.w  (a2)+,(a4)+
            dbf     d0,.pal

            move.w  14(a0),d0               ; start room and position
            ext.l   d0
            divu    gk_roomw,d0
            move.w  d0,gk_spawn_rx
            swap    d0
            move.w  d0,gk_spawn_x
            move.w  16(a0),d0
            ext.l   d0
            divu    gk_roomh,d0
            move.w  d0,gk_spawn_ry
            swap    d0
            move.w  d0,gk_spawn_y

            move.l  gk_cells,d0             ; the map's cells in RAM (collected tiles change)
            beq.s   .alloc
            move.l  d0,a1
            move.l  gk_cells_size,d0
            move.l  4.w,a6
            jsr     -210(a6)                ; FreeMem the previous map's
            clr.l   gk_cells
.alloc      moveq   #0,d0
            move.w  gk_mw,d0
            mulu    gk_mh,d0
            addq.l  #2,d0
            move.l  d0,gk_cells_size
            move.l  #$10002,d1
            move.l  4.w,a6
            jsr     -198(a6)                ; AllocMem
            tst.l   d0
            beq     gk_fail
            move.l  d0,gk_cells
            bsr     gk_reset_level
            rts

; Restores the cells from the map data, counts the pickups, puts the hero
; at the start and draws the start room.
gk_reset_level:
            move.l  gk_pristine,a0
            move.l  gk_cells,a1
            move.l  gk_flagtab,a2
            moveq   #0,d0
            move.w  gk_mw,d0
            mulu    gk_mh,d0
            moveq   #0,d2                   ; pickups left
            moveq   #0,d1
            bra.s   .in
.copy       move.b  (a0)+,d1
            move.b  d1,(a1)+
            btst    #3,0(a2,d1.w)           ; GK_COLLECT
            beq.s   .in
            addq.w  #1,d2
.in         subq.l  #1,d0
            bpl.s   .copy
            move.w  d2,gk_left
            clr.w   gk_collected
            bsr     gk_respawn
            rts

; Hero back to the start room and point.
gk_respawn:
            move.w  gk_spawn_x,d0
            lsl.w   #4,d0
            move.w  d0,gk_px
            move.w  gk_spawn_y,d0
            lsl.w   #4,d0
            move.w  d0,gk_py
            clr.w   gk_vx
            clr.w   gk_vy
            clr.w   gk_ground
            clr.w   gk_coyote
            move.w  #50,gk_invuln
            move.w  gk_spawn_rx,d0
            move.w  gk_spawn_ry,d1
            bsr     gk_enter_room
            rts

; d0 = room x, d1 = room y: draw it and load its enemies.
gk_enter_room:
            move.w  d0,gk_room_x
            move.w  d1,gk_room_y
            bsr     gk_draw_room
            bsr     gk_load_enemies
            rts

; Draws every tile of the current room.
gk_draw_room:
            movem.l d0-d7/a0-a6,-(sp)
            moveq   #0,d1                   ; row
.row        moveq   #0,d0                   ; column
.col        bsr     gk_cell_local           ; a0 = cell, d2 = tile
            bsr     gk_draw_tile
            addq.w  #1,d0
            cmp.w   gk_cols,d0
            blo.s   .col
            addq.w  #1,d1
            cmp.w   gk_rows,d1
            blo.s   .row
            movem.l (sp)+,d0-d7/a0-a6
            rts

; d0 = column, d1 = row in the current room -> a0 = cell address, d2.w = tile
gk_cell_local:
            move.l  d3,-(sp)
            move.w  gk_room_y,d3
            mulu    gk_rows,d3
            add.w   d1,d3                   ; world row
            mulu    gk_mw,d3
            move.l  gk_cells,a0
            add.l   d3,a0
            move.w  gk_room_x,d3
            mulu    gk_cols,d3
            add.w   d0,d3                   ; world column
            add.w   d3,a0
            moveq   #0,d2
            move.b  (a0),d2
            move.l  (sp)+,d3
            rts

; d0 = column, d1 = row (current room), d2 = tile: copies its 4 planes.
gk_draw_tile:
            movem.l d0-d5/a0-a2,-(sp)
            move.l  gk_gfx,a0
            mulu    gk_tilebytes,d2
            add.l   d2,a0                   ; source
            move.w  gk_T,d3
            mulu    d3,d1
            mulu    #40,d1
            move.l  gk_screen_ptr,a1
            add.l   d1,a1
            mulu    gk_rowbytes,d0
            add.w   d0,a1                   ; destination, plane 0
            moveq   #3,d5                   ; planes
.plane      move.l  a1,a2
            move.w  gk_T,d4
            subq.w  #1,d4
.line       move.w  gk_rowbytes,d3
            subq.w  #1,d3
            moveq   #0,d0
.byte       move.b  (a0)+,0(a2,d0.w)
            addq.w  #1,d0
            dbf     d3,.byte
            lea     40(a2),a2
            dbf     d4,.line
            add.l   #GK_PLANE,a1
            dbf     d5,.plane
            movem.l (sp)+,d0-d5/a0-a2
            rts

; d0.w = x, d1.w = y (room pixels, may be outside the room) -> d0.l = tile
; flags, a0 = cell address (0 outside the map), d2.w = tile.
; Left / right of the map counts as solid, above and below as empty.
gk_flags_at:
            movem.l d1/d3,-(sp)
            ext.l   d0
            ext.l   d1
            move.w  gk_room_x,d3
            mulu    gk_roomw,d3
            add.l   d3,d0                   ; world x
            bmi.s   .solid
            cmp.w   gk_mapw_px,d0
            bge.s   .solid
            move.w  gk_room_y,d3
            mulu    gk_roomh,d3
            add.l   d3,d1                   ; world y
            bmi.s   .empty
            cmp.w   gk_maph_px,d1
            bge.s   .empty
            divu    gk_T,d0                 ; world column
            divu    gk_T,d1                 ; world row
            mulu    gk_mw,d1
            and.l   #$ffff,d0
            add.l   d0,d1
            move.l  gk_cells,a0
            add.l   d1,a0
            moveq   #0,d2
            move.b  (a0),d2
            move.l  gk_flagtab,a1
            moveq   #0,d0
            move.b  0(a1,d2.w),d0
            movem.l (sp)+,d1/d3
            rts
.solid      moveq   #GK_SOLID,d0
            bra.s   .none
.empty      moveq   #0,d0
.none       sub.l   a0,a0
            moveq   #0,d2
            movem.l (sp)+,d1/d3
            rts

; d0.w = sprite x, d1.w = sprite y, d2.w = height, d3.w = flag mask ->
; Z clear (bne) when the hit box overlaps a tile with any of those flags.
; Samples the box edges at least every 7 pixels.
gk_box_hits:
            movem.l d0-d7/a0-a1,-(sp)
            move.w  d0,d4
            addq.w  #GK_HIT_L,d4            ; left
            move.w  d0,d5
            add.w   #GK_HIT_R,d5            ; right
            move.w  d1,d6                   ; top
            move.w  d1,d7
            add.w   d2,d7
            subq.w  #1,d7                   ; bottom
            move.w  d6,d1
.ys         cmp.w   d7,d1
            ble.s   .yok
            move.w  d7,d1
.yok        move.w  d4,d0                   ; walk x across the box at this y
.xs         cmp.w   d5,d0
            ble.s   .xok
            move.w  d5,d0
.xok        movem.l d0-d1,-(sp)
            bsr     gk_flags_at
            and.w   d3,d0
            movem.l (sp)+,d0-d1
            bne.s   .hit
            cmp.w   d5,d0
            beq.s   .xdone
            addq.w  #7,d0
            bra.s   .xs
.xdone      cmp.w   d7,d1
            beq.s   .miss
            addq.w  #7,d1
            bra.s   .ys
.miss       movem.l (sp)+,d0-d7/a0-a1
            clr.w   -(sp)                   ; Z set, every register kept
            tst.w   (sp)+
            rts
.hit        movem.l (sp)+,d0-d7/a0-a1
            move.w  #1,-(sp)                ; Z clear, every register kept
            tst.w   (sp)+
            rts

; d0.w = sprite x, d1.w = new y (one pixel lower than before), d2.w = height
; -> Z clear when the feet land on the top row of a Platform tile.
gk_feet_on_platform:
            movem.l d0-d7/a0-a1,-(sp)
            move.w  d1,d6
            add.w   d2,d6
            subq.w  #1,d6                   ; feet row (room y)
            move.w  gk_room_y,d7
            mulu    gk_roomh,d7
            add.w   d6,d7                   ; world feet row
            bmi.s   .no
            and.l   #$ffff,d7
            divu    gk_T,d7
            swap    d7
            tst.w   d7                      ; the top row of a tile?
            bne.s   .no
            move.w  d0,d4
            addq.w  #GK_HIT_L,d4
            move.w  d0,d5
            add.w   #GK_HIT_R,d5
.x          move.w  d4,d0
            move.w  d6,d1
            bsr     gk_flags_at
            and.w   #GK_PLATFORM,d0
            bne.s   .yes
            cmp.w   d5,d4
            beq.s   .no
            addq.w  #7,d4
            cmp.w   d5,d4
            ble.s   .x
            move.w  d5,d4
            bra.s   .x
.no         movem.l (sp)+,d0-d7/a0-a1
            clr.w   -(sp)
            tst.w   (sp)+
            rts
.yes        movem.l (sp)+,d0-d7/a0-a1
            move.w  #1,-(sp)
            tst.w   (sp)+
            rts

; ---------------------------------------------------------------------------
; PLAYER: a0 = animation set.
gk_player:
            move.l  a0,gk_anim
            move.w  (a0),gk_ph
            lea     $dff1a2,a1              ; COLOR17-19: sprite pair 0
            move.w  2(a0),(a1)+
            move.w  4(a0),(a1)+
            move.w  6(a0),(a1)+
            clr.w   gk_state
            clr.w   gk_frame
            clr.w   gk_acc
            clr.w   gk_face
            tst.l   gk_map_ptr
            beq.s   .nomap
            bsr     gk_respawn
.nomap      rts

; ---------------------------------------------------------------------------
; WAIT FRAME: until the beam passes line 303 (below the display).
gk_wait_frame:
            lea     $dff004,a0
            moveq   #0,d1
            move.w  gk_vbl_line,d1          ; 303 PAL, 255 NTSC (set by gk_screen)
            lsl.l   #8,d1
.w1         move.l  (a0),d0
            and.l   #$1ff00,d0
            cmp.l   d1,d0
            bne.s   .w1
.w2         move.l  (a0),d0
            and.l   #$1ff00,d0
            cmp.l   d1,d0
            beq.s   .w2
            addq.w  #1,gk_tick
            rts

; ---------------------------------------------------------------------------
; READ JOYSTICK: port 2 into gk_joy (J_* bits), new presses into gk_joy_new.
gk_read_input:
            move.w  $dff00c,d0              ; JOY1DAT
            moveq   #0,d1
            btst    #1,d0
            beq.s   .nr
            bset    #J_RIGHT,d1
.nr         btst    #9,d0
            beq.s   .nl
            bset    #J_LEFT,d1
.nl         move.w  d0,d2
            lsr.w   #1,d2
            eor.w   d0,d2
            btst    #0,d2
            beq.s   .nd
            bset    #J_DOWN,d1
.nd         btst    #8,d2
            beq.s   .nu
            bset    #J_UP,d1
.nu         btst    #7,$bfe001              ; fire (port 2) = CIA-A PRA bit 7, low
            bne.s   .nf
            bset    #J_FIRE,d1
.nf         move.w  gk_joy,d0
            not.w   d0
            and.w   d1,d0
            move.w  d0,gk_joy_new
            move.w  d1,gk_joy
            rts

; ---------------------------------------------------------------------------
; PHYSICS: run, jump, gravity, tile collision, room changes.
gk_physics:
            tst.l   gk_anim
            beq     .out
            tst.w   gk_invuln
            beq.s   .vuln
            subq.w  #1,gk_invuln
.vuln
            moveq   #0,d0                   ; ---- run ----
            move.w  gk_joy,d1
            btst    #J_LEFT,d1
            beq.s   .notl
            sub.w   gk_speed,d0
            move.w  #1,gk_face
.notl       btst    #J_RIGHT,d1
            beq.s   .notr
            add.w   gk_speed,d0
            clr.w   gk_face
.notr       move.w  d0,gk_vx

            tst.w   gk_ground               ; ---- jump (a little grace after a ledge) ----
            beq.s   .air
            move.w  #5,gk_coyote
            bra.s   .jmp
.air        tst.w   gk_coyote
            beq.s   .jmp
            subq.w  #1,gk_coyote
.jmp        move.w  gk_joy_new,d1
            and.w   #(1<<J_FIRE)|(1<<J_UP),d1
            beq.s   .nojump
            tst.w   gk_coyote
            beq.s   .nojump
            move.w  gk_jumpv,d0
            neg.w   d0
            move.w  d0,gk_vy
            clr.w   gk_coyote
            clr.w   gk_ground
            move.l  gk_sfx_jump,a0
            bsr     gk_play_sfx
.nojump     move.w  gk_joy,d1               ; let go early: a smaller jump
            and.w   #(1<<J_FIRE)|(1<<J_UP),d1
            bne.s   .held
            cmp.w   #-16,gk_vy
            bge.s   .held
            move.w  #-16,gk_vy
.held
            move.w  gk_vy,d0                ; ---- gravity ----
            add.w   gk_grav,d0
            cmp.w   gk_maxfall,d0
            ble.s   .fall
            move.w  gk_maxfall,d0
.fall       move.w  d0,gk_vy

            move.w  gk_px,d0                ; ---- move x, a pixel at a time ----
            add.w   gk_vx,d0
            asr.w   #4,d0                   ; target x
            move.w  gk_px,d4
            asr.w   #4,d4                   ; current x
            move.w  gk_py,d1
            asr.w   #4,d1
            move.w  gk_ph,d2
            moveq   #GK_SOLID,d3
            move.w  d0,d5
.mx         cmp.w   d4,d5
            beq.s   .mxdone
            move.w  d4,d0
            cmp.w   d4,d5
            bgt.s   .mxr                    ; target to the right
            subq.w  #1,d0
            bra.s   .mxt
.mxr        addq.w  #1,d0
.mxt        bsr     gk_box_hits
            bne.s   .mxblock
            move.w  d0,d4
            bra.s   .mx
.mxblock    lsl.w   #4,d4
            move.w  d4,gk_px
            clr.w   gk_vx
            bra.s   .my0
.mxdone     move.w  gk_px,d0
            add.w   gk_vx,d0
            move.w  d0,gk_px

.my0        move.w  gk_px,d0                ; ---- move y, a pixel at a time ----
            asr.w   #4,d0
            move.w  gk_py,d4
            asr.w   #4,d4                   ; current y
            move.w  gk_py,d5
            add.w   gk_vy,d5
            asr.w   #4,d5                   ; target y
            move.w  gk_ph,d2
            moveq   #GK_SOLID,d3
.my         cmp.w   d4,d5
            beq.s   .mydone
            move.w  d4,d1
            cmp.w   d4,d5
            bgt.s   .myd                    ; target below
            subq.w  #1,d1                   ; going up
            bsr     gk_box_hits
            bne.s   .myhead
            move.w  d1,d4
            bra.s   .my
.myd        addq.w  #1,d1                   ; going down
            bsr     gk_box_hits
            bne.s   .myland
            bsr     gk_feet_on_platform
            bne.s   .myland
            move.w  d1,d4
            bra.s   .my
.myhead     lsl.w   #4,d4
            move.w  d4,gk_py
            clr.w   gk_vy
            bra.s   .ground
.myland     lsl.w   #4,d4
            move.w  d4,gk_py
            clr.w   gk_vy
            bra.s   .ground
.mydone     move.w  gk_py,d0
            add.w   gk_vy,d0
            move.w  d0,gk_py

.ground     move.w  gk_px,d0                ; ---- standing on something? ----
            asr.w   #4,d0
            move.w  gk_py,d1
            asr.w   #4,d1
            addq.w  #1,d1
            move.w  gk_ph,d2
            moveq   #GK_SOLID,d3
            clr.w   gk_ground
            bsr     gk_box_hits
            bne.s   .onground
            bsr     gk_feet_on_platform
            beq.s   .rooms
.onground   tst.w   gk_vy
            bmi.s   .rooms
            move.w  #1,gk_ground

.rooms      move.w  gk_px,d0                ; ---- next room? (by the sprite's middle) ----
            asr.w   #4,d0
            addq.w  #8,d0
            bpl.s   .notleft
            move.w  gk_room_x,d1
            beq.s   .roomy
            move.w  gk_roomw,d2
            lsl.w   #4,d2
            add.w   d2,gk_px
            subq.w  #1,d1
            move.w  gk_room_y,d2
            bra.s   .switch
.notleft    cmp.w   gk_roomw,d0
            blt.s   .roomy
            move.w  gk_room_x,d1
            addq.w  #1,d1
            cmp.w   gk_roomsx,d1
            bge.s   .roomy
            move.w  gk_roomw,d2
            lsl.w   #4,d2
            sub.w   d2,gk_px
            move.w  gk_room_y,d2
            bra.s   .switch
.roomy      move.w  gk_py,d0
            asr.w   #4,d0
            move.w  gk_ph,d1
            lsr.w   #1,d1
            add.w   d1,d0                   ; middle y
            bpl.s   .notup
            move.w  gk_room_y,d2
            beq.s   .out
            move.w  gk_roomh,d1
            lsl.w   #4,d1
            add.w   d1,gk_py
            subq.w  #1,d2
            move.w  gk_room_x,d1
            bra.s   .switch
.notup      cmp.w   gk_roomh,d0
            blt.s   .out
            move.w  gk_room_y,d2
            addq.w  #1,d2
            cmp.w   gk_roomsy,d2
            bge.s   .fellout
            move.w  gk_roomh,d1
            lsl.w   #4,d1
            sub.w   d1,gk_py
            move.w  gk_room_x,d1
.switch     move.w  d1,d0
            move.w  d2,d1
            bsr     gk_enter_room
            bra.s   .out
.fellout    bsr     gk_kill
.out        rts

; Hurt: red flash, the hurt sound, back to the start (not while blinking
; after the last hit). gk_kill always does it (falling out of the map).
gk_die:
            tst.w   gk_invuln
            bne.s   gk_die_safe
gk_kill:
            move.l  gk_sfx_hurt,a0
            bsr     gk_play_sfx
            move.w  #$0f00,d0
            moveq   #12,d1
            bsr     gk_flash
            bsr     gk_respawn
gk_die_safe: rts

; d0 = colour, d1 = frames: shows the colour as the background, then the palette's.
gk_flash:
            move.w  d0,$dff180
            subq.w  #1,d1
.f          bsr     gk_wait_frame
            dbf     d1,.f
            move.w  gk_palette,$dff180
            rts

; a0 = ptplayer sfx structure or 0.
gk_play_sfx:
            ifd     GK_AUDIO
            move.l  a0,d0
            beq.s   .no
            movem.l d0-d7/a0-a6,-(sp)
            move.l  a0,-(sp)
            jsr     __adm_audio_init
            move.l  (sp)+,a0
            lea     $dff000,a6
            jsr     _mt_playfx
            movem.l (sp)+,d0-d7/a0-a6
.no
            endc
            rts

; ---------------------------------------------------------------------------
; TILE EVENTS: a0 = collect sfx, a1 = hurt sfx (0 = none), d0 = 1 when the
; exit needs every pickup collected first.
gk_events:
            move.l  a0,gk_sfx_collect
            move.l  a1,gk_sfx_hurt
            move.w  d0,gk_exit_all
            tst.l   gk_anim
            beq     .out
            moveq   #3,d7                   ; four points inside the hit box
.pt         move.w  gk_px,d0
            asr.w   #4,d0
            move.w  gk_py,d1
            asr.w   #4,d1
            btst    #0,d7
            beq.s   .l
            add.w   #GK_HIT_R-1,d0
            bra.s   .yy
.l          addq.w  #GK_HIT_L+1,d0
.yy         btst    #1,d7
            beq.s   .t
            add.w   gk_ph,d1
            subq.w  #3,d1
            bra.s   .look
.t          addq.w  #2,d1
.look       move.w  d0,d5                   ; keep the point
            move.w  d1,d6
            bsr     gk_flags_at
            move.l  a0,a2
            btst    #3,d0                   ; GK_COLLECT
            beq.s   .nocol
            move.l  a2,d4
            beq.s   .nocol
            clr.b   (a2)                    ; gone
            addq.w  #1,gk_collected
            subq.w  #1,gk_left
            move.w  d5,d0                   ; redraw that tile (empty)
            ext.l   d0
            divu    gk_T,d0
            move.w  d6,d1
            ext.l   d1
            divu    gk_T,d1
            cmp.w   gk_cols,d0
            bhs.s   .snd
            cmp.w   gk_rows,d1
            bhs.s   .snd
            moveq   #0,d2
            bsr     gk_draw_tile
.snd        move.l  gk_sfx_collect,a0
            bsr     gk_play_sfx
            bra.s   .next
.nocol      btst    #2,d0                   ; GK_HAZARD
            beq.s   .noh
            bsr     gk_die
            bra.s   .out
.noh        btst    #4,d0                   ; GK_EXIT
            beq.s   .next
            tst.w   gk_exit_all
            beq.s   .win
            tst.w   gk_left
            bgt.s   .next
.win        bsr     gk_level_done
            bra.s   .out
.next       dbf     d7,.pt
.out        rts

; Level done: three white flashes, then the level starts again.
gk_level_done:
            moveq   #2,d7
.f          move.w  #$0fff,d0
            moveq   #6,d1
            bsr     gk_flash
            move.w  gk_palette,d0
            moveq   #6,d1
            bsr     gk_flash
            dbf     d7,.f
            bsr     gk_reset_level
            rts

; ---------------------------------------------------------------------------
; Enemies of the current room into the slots (and their sprite colours).
gk_load_enemies:
            movem.l d0-d7/a0-a3,-(sp)
            clr.w   gk_en_count
            move.l  gk_enemy_list,d0
            beq     .done
            move.l  d0,a0
            move.w  (a0)+,d7                ; enemies in the map
            beq     .done
            subq.w  #1,d7
            lea     gk_enemies_tab,a1
            move.w  gk_room_x,d4
            mulu    gk_roomw,d4             ; room left (map px)
            move.w  gk_room_y,d5
            mulu    gk_roomh,d5             ; room top
.e          move.w  (a0),d0                 ; x
            sub.w   d4,d0
            bmi.s   .skip
            cmp.w   gk_roomw,d0
            bge.s   .skip
            move.w  2(a0),d1                ; y
            sub.w   d5,d1
            bmi.s   .skip
            cmp.w   gk_roomh,d1
            bge.s   .skip
            cmp.w   #GK_MAX_EN,gk_en_count
            bge.s   .skip
            move.w  d0,(a1)                 ; x
            move.w  d1,2(a1)                ; y
            move.w  #1,4(a1)                ; dir: right
            move.w  4(a0),6(a1)             ; speed
            move.l  6(a0),8(a1)             ; animset
            clr.w   12(a1)                  ; frame
            clr.w   14(a1)                  ; acc
            move.w  gk_en_count,d2          ; colours: slot n uses sprite n+2
            addq.w  #2,d2
            btst    #0,d2
            bne.s   .nocol                  ; odd channels share the even one's colours
            lsr.w   #1,d2
            lsl.w   #3,d2                   ; pair x 8 bytes
            lea     $dff1a2,a2
            add.w   d2,a2
            move.l  6(a0),a3
            move.w  2(a3),(a2)+
            move.w  4(a3),(a2)+
            move.w  6(a3),(a2)+
.nocol      addq.w  #1,gk_en_count
            lea     GK_EN_SIZE(a1),a1
.skip       lea     10(a0),a0
            dbf     d7,.e
.done       movem.l (sp)+,d0-d7/a0-a3
            rts

; ENEMIES: patrol, turn at walls / ledges / the room edge, animate, hurt the hero.
gk_enemies:
            move.w  gk_en_count,d7
            beq     .out
            subq.w  #1,d7
            lea     gk_enemies_tab,a3
.e          move.l  8(a3),a4                ; animset
            move.w  (a3),d0                 ; next x
            move.w  6(a3),d1
            muls    4(a3),d1
            add.w   d1,d0
            move.w  d0,d5
            tst.w   4(a3)                   ; the point just ahead
            bmi.s   .lft
            add.w   #GK_HIT_R+1,d0
            bra.s   .ahead
.lft        addq.w  #GK_HIT_L-1,d0
.ahead      move.w  d0,d6
            bmi.s   .turn
            cmp.w   gk_roomw,d0
            bge.s   .turn
            move.w  2(a3),d1                ; wall ahead (middle of the body)
            move.w  (a4),d2
            lsr.w   #1,d2
            add.w   d2,d1
            bsr     gk_flags_at
            and.w   #GK_SOLID,d0
            bne.s   .turn
            move.w  d6,d0                   ; ground ahead (just below the feet)
            move.w  2(a3),d1
            add.w   (a4),d1
            bsr     gk_flags_at
            and.w   #GK_SOLID|GK_PLATFORM,d0
            beq.s   .turn
            move.w  d5,(a3)
            bra.s   .anim
.turn       neg.w   4(a3)
.anim       move.w  14(a3),d0               ; run animation
            add.w   8+12*1+2(a4),d0         ; run rate
.adv        cmp.w   #50,d0
            blt.s   .advd
            sub.w   #50,d0
            move.w  12(a3),d1
            addq.w  #1,d1
            cmp.w   8+12*1(a4),d1           ; run count
            blo.s   .fr
            moveq   #0,d1
.fr         move.w  d1,12(a3)
            bra.s   .adv
.advd       move.w  d0,14(a3)

            tst.w   gk_invuln               ; touching the hero?
            bne.s   .next
            tst.l   gk_anim
            beq.s   .next
            move.w  gk_px,d0
            asr.w   #4,d0
            sub.w   (a3),d0
            bpl.s   .ax
            neg.w   d0
.ax         cmp.w   #10,d0
            bge.s   .next
            move.w  gk_py,d0
            asr.w   #4,d0
            move.w  2(a3),d1
            move.w  d0,d2                   ; overlap in y: hero top < enemy bottom
            add.w   gk_ph,d2                ; and enemy top < hero bottom
            cmp.w   d1,d2
            ble.s   .next
            add.w   (a4),d1
            cmp.w   d1,d0
            bge.s   .next
            move.l  a3,-(sp)
            move.w  d7,-(sp)
            bsr     gk_die
            move.w  (sp)+,d7
            move.l  (sp)+,a3
            bra.s   .out                    ; the room may have been reloaded
.next       lea     GK_EN_SIZE(a3),a3
            dbf     d7,.e
.out        rts

; ---------------------------------------------------------------------------
; ANIMATE: pick the hero's state and step its frames.
gk_animate:
            move.l  gk_anim,d0
            beq.s   .out
            move.l  d0,a0
            moveq   #0,d1                   ; idle
            tst.w   gk_ground
            bne.s   .ongr
            moveq   #2,d1                   ; jump (going up)
            tst.w   gk_vy
            bmi.s   .set
            moveq   #3,d1                   ; fall
            bra.s   .set
.ongr       tst.w   gk_vx
            beq.s   .set
            moveq   #1,d1                   ; run
.set        cmp.w   gk_state,d1
            beq.s   .same
            move.w  d1,gk_state
            clr.w   gk_frame
            clr.w   gk_acc
.same       mulu    #12,d1
            lea     8(a0,d1.w),a1           ; state record
            move.w  gk_acc,d0
            add.w   2(a1),d0                ; rate
.adv        cmp.w   #50,d0
            blt.s   .done
            sub.w   #50,d0
            move.w  gk_frame,d2
            addq.w  #1,d2
            cmp.w   (a1),d2
            blo.s   .ok
            moveq   #0,d2
.ok         move.w  d2,gk_frame
            bra.s   .adv
.done       move.w  d0,gk_acc
.out        rts

; ---------------------------------------------------------------------------
; DRAW SPRITES: hero into sprite 0, enemies into sprites 2..7.
gk_draw_sprites:
            move.l  gk_sprbuf,d0
            beq     .out
            move.l  d0,a1
            move.l  gk_anim,d0              ; ---- hero ----
            beq.s   .nohero
            move.l  d0,a0
            move.w  gk_invuln,d1            ; blink while safe after a hit
            and.w   #4,d1
            bne.s   .hide
            move.w  gk_state,d1
            mulu    #12,d1
            lea     8(a0,d1.w),a2
            move.w  gk_frame,d2
            move.w  gk_face,d3
            move.w  gk_px,d0
            asr.w   #4,d0
            move.w  gk_py,d1
            asr.w   #4,d1
            bsr     gk_put_sprite
            bra.s   .nohero
.hide       clr.l   (a1)
.nohero
            lea     GK_SPRBUF*2(a1),a1      ; ---- enemies: sprites 2.. ----
            lea     gk_enemies_tab,a3
            moveq   #0,d7
.en         cmp.w   gk_en_count,d7
            bge.s   .clear
            move.l  8(a3),a0
            lea     8+12*1(a0),a2           ; run state
            move.w  12(a3),d2
            moveq   #0,d3
            tst.w   4(a3)
            bpl.s   .r
            moveq   #1,d3
.r          move.w  (a3),d0
            move.w  2(a3),d1
            bsr     gk_put_sprite
            lea     GK_SPRBUF(a1),a1
            lea     GK_EN_SIZE(a3),a3
            addq.w  #1,d7
            bra.s   .en
.clear      cmp.w   #GK_MAX_EN,d7           ; unused channels off
            bge.s   .out
            clr.l   (a1)
            lea     GK_SPRBUF(a1),a1
            addq.w  #1,d7
            bra.s   .clear
.out        rts

; a0 = animset, a1 = sprite buffer, a2 = state record, d2 = frame,
; d3 = 1 facing left, d0 = x, d1 = y (room pixels).
gk_put_sprite:
            movem.l d0-d7/a0-a3,-(sp)
            move.w  (a0),d4                 ; height
            move.l  4(a2),a3                ; right frames
            tst.w   d3
            beq.s   .rt
            move.l  8(a2),a3                ; left frames
.rt         move.w  d4,d5
            lsl.w   #2,d5                   ; bytes per frame
            mulu    d5,d2
            add.l   d2,a3
            add.w   #128,d0                 ; hstart
            add.w   #$2c,d1                 ; vstart
            move.w  d1,d2
            add.w   d4,d2                   ; vstop
            move.w  d1,d5                   ; POS: vstart low | hstart >> 1
            lsl.w   #8,d5
            move.w  d0,d6
            lsr.w   #1,d6
            and.w   #$ff,d6
            or.w    d6,d5
            move.w  d5,(a1)
            move.w  d2,d5                   ; CTL: vstop low | v8 bits | h0
            lsl.w   #8,d5
            btst    #8,d1
            beq.s   .v1
            bset    #2,d5
.v1         btst    #8,d2
            beq.s   .v2
            bset    #1,d5
.v2         btst    #0,d0
            beq.s   .h0
            bset    #0,d5
.h0         move.w  d5,2(a1)
            lea     4(a1),a2
            subq.w  #1,d4
.row        move.l  (a3)+,(a2)+
            dbf     d4,.row
            clr.l   (a2)                    ; end of sprite
            movem.l (sp)+,d0-d7/a0-a3
            rts

; ---------------------------------------------------------------------------
            cnop    0,4
gk_screen_ptr:  dc.l 0
gk_copper_ptr:  dc.l 0
gk_sprbuf:      dc.l 0
gk_map_ptr:     dc.l 0
gk_cells:       dc.l 0
gk_cells_size:  dc.l 0
gk_pristine:    dc.l 0
gk_flagtab:     dc.l 0
gk_gfx:         dc.l 0
gk_enemy_list:  dc.l 0
gk_anim:        dc.l 0
gk_sfx_jump:    dc.l 0
gk_sfx_collect: dc.l 0
gk_sfx_hurt:    dc.l 0
gk_T:           dc.w 16
gk_rowbytes:    dc.w 2
gk_tilebytes:   dc.w 128
gk_cols:        dc.w 20
gk_rows:        dc.w 16
gk_roomsx:      dc.w 1
gk_roomsy:      dc.w 1
gk_mw:          dc.w 20
gk_mh:          dc.w 16
gk_roomw:       dc.w 320
gk_roomh:       dc.w 256
gk_mapw_px:     dc.w 320
gk_maph_px:     dc.w 256
gk_room_x:      dc.w 0
gk_room_y:      dc.w 0
gk_spawn_rx:    dc.w 0
gk_spawn_ry:    dc.w 0
gk_spawn_x:     dc.w 32
gk_spawn_y:     dc.w 32
gk_left:        dc.w 0
gk_collected:   dc.w 0
gk_ph:          dc.w 16
gk_px:          dc.w 0
gk_py:          dc.w 0
gk_vx:          dc.w 0
gk_vy:          dc.w 0
gk_ground:      dc.w 0
gk_face:        dc.w 0
gk_coyote:      dc.w 0
gk_state:       dc.w 0
gk_frame:       dc.w 0
gk_acc:         dc.w 0
gk_invuln:      dc.w 0
gk_speed:       dc.w 24                 ; 1.5 px per frame
gk_jumpv:       dc.w 80                 ; 5 px per frame up
gk_grav:        dc.w 5
gk_maxfall:     dc.w 96
gk_joy:         dc.w 0
gk_joy_new:     dc.w 0
gk_exit_all:    dc.w 0
gk_tick:        dc.w 0
gk_vbl_line:    dc.w 303
gk_en_count:    dc.w 0
gk_palette:     ds.w 16
gk_enemies_tab: ds.b GK_EN_SIZE*GK_MAX_EN
            even
