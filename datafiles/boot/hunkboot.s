; ============================================================================
;  Amiga Dev Machine bootblock - loads the program's Hunk executable straight
;  from the disk with trackdisk.device (no AmigaDOS, no Startup-Sequence), so
;  every build auto-runs on any Kickstart, including FS-UAE's AROS ROM.
;
;  This is the same idea as ADAM's bootblock, but instead of a fixed engine it
;  loads whatever vasm built: the disk holds [bootblock][main.bin hunk file].
;  The file is streamed through a 512 byte sector buffer: every hunk is
;  allocated (always chip RAM and cleared, so code hunks may hold copper
;  lists, bitplanes and samples), CODE/DATA are read straight into place (whole
;  sectors by DMA, the odd ends through the buffer), HUNK_RELOC32 is applied
;  and the first hunk is entered with
;     a6 = ExecBase, a1 = trackdisk IOStdReq (as a plain bootblock gets them)
;  so a program needs only its own size in chip RAM, plus 512 bytes.
;
;  Amiga Dev Machine patches the fields after the "ADMB" tag and the checksum
;  when it writes the ADF:
;     readsize  - bytes of the hunk file on disk (informational)
;     resv_addr - chip RAM the program pokes directly. It is AllocAbs'd and
;     resv_size   never freed, so the loader's own allocations stay out of
;                 its way (best effort; 0 = none)
;
;  If anything fails (no memory, read error, bad hunk file) the screen turns
;  solid red and the machine stops, as ADAM's does.
;
;  Assemble:  vasmm68k_mot -Fbin -pic -m68000 -o hunkboot.bin hunkboot.s
;  Registers while loading:
;     a2 IO request, a3 sector buffer, a4 hunk address table, a6 ExecBase
;     d3 disk offset of the next sector, d4 bytes used in the buffer (512 = empty)
;     d5 current hunk x 4, d6 counts, d7 number of hunks
; ============================================================================
MEMF_CHIP   equ 2
MEMF_CLEAR  equ $10000
MEMF_REVERSE equ $40000

            dc.b    "DOS",0
            dc.l    0                       ; checksum (patched)
            dc.l    880                     ; root block
boot:
            move.l  a1,a2                   ; a2 = trackdisk IO request

            move.l  resv_size(pc),d0        ; keep the program's fixed chip area free
            beq     .noresv
            move.l  resv_addr(pc),a1
            jsr     -204(a6)                ; AllocAbs - best effort, result ignored
.noresv
            move.l  #MEMF_CHIP|MEMF_CLEAR,d0
            cmp.w   #36,20(a6)              ; Kickstart 2.0+ (and AROS): from the top
            blo     .flags
            or.l    #MEMF_REVERSE,d0
.flags      lea     memflags(pc),a0
            move.l  d0,(a0)

            move.l  #512,d0                 ; sector buffer
            bsr     alloc
            move.l  d0,a3
            move.l  #1024,d3                ; the file starts after the bootblock
            move.w  #512,d4                 ; buffer empty

            bsr     getlong                 ; ---- HUNK_HEADER ----
            cmp.l   #$3f3,d0
            bne     bootfail
            bsr     getlong                 ; no resident library names
            tst.l   d0
            bne     bootfail
            bsr     getlong
            move.l  d0,d7                   ; d7 = number of hunks
            beq     bootfail
            bsr     getlong                 ; first
            bsr     getlong                 ; last
            move.l  d7,d0
            lsl.l   #2,d0
            bsr     alloc
            move.l  d0,a4                   ; a4 = hunk address table
            moveq   #0,d5
.alloc      bsr     getlong
            and.l   #$3fffffff,d0
            lsl.l   #2,d0
            addq.l  #8,d0                   ; never ask for 0 bytes (empty BSS)
            bsr     alloc
            move.l  d0,0(a4,d5.l)
            addq.l  #4,d5
            move.l  d5,d0
            lsr.l   #2,d0
            cmp.l   d7,d0
            blo     .alloc

            moveq   #0,d5                   ; ---- hunk bodies ----
.next       bsr     getlong
            and.l   #$3fffffff,d0
            cmp.l   #$3e9,d0                ; HUNK_CODE
            beq     .data
            cmp.l   #$3ea,d0                ; HUNK_DATA
            beq     .data
            cmp.l   #$3eb,d0                ; HUNK_BSS (already cleared)
            beq     .bss
            cmp.l   #$3ec,d0                ; HUNK_RELOC32
            beq     .reloc
            cmp.l   #$3f0,d0                ; HUNK_SYMBOL
            beq     .symbol
            cmp.l   #$3f1,d0                ; HUNK_DEBUG
            beq     .debug
            cmp.l   #$3f2,d0                ; HUNK_END
            beq     .end
            bra     bootfail

.data       bsr     getlong
            move.l  d0,d6                   ; longs
            move.l  0(a4,d5.l),a5
            bsr     readlongs
            bra     .next

.bss        bsr     getlong
            bra     .next

.reloc      bsr     getlong                 ; offsets in this group (0 = done)
            move.l  d0,d6
            beq     .next
            bsr     getlong                 ; hunk they point into
            lsl.l   #2,d0
            move.l  0(a4,d0.l),a5
.rl         bsr     getlong
            move.l  0(a4,d5.l),a0
            move.l  a5,d1
            add.l   d1,0(a0,d0.l)
            subq.l  #1,d6
            bne     .rl
            bra     .reloc

.symbol     bsr     getlong                 ; name length in longs (0 = done)
            tst.l   d0
            beq     .next
            move.l  d0,d6
            addq.l  #1,d6                   ; + value
            bsr     skiplongs
            bra     .symbol

.debug      bsr     getlong
            move.l  d0,d6
            bsr     skiplongs
            bra     .next

.end        addq.l  #4,d5
            move.l  d5,d0
            lsr.l   #2,d0
            cmp.l   d7,d0
            blo     .next

            move.l  a2,a1                   ; ---- run ----
            move.w  #9,28(a1)               ; TD_MOTOR off
            clr.l   36(a1)
            jsr     -456(a6)                ; DoIO
            move.l  (a4),a5                 ; entry = first hunk
            move.l  a4,a1
            move.l  d7,d0
            lsl.l   #2,d0
            jsr     -210(a6)                ; FreeMem - the table
            move.l  a3,a1
            move.l  #512,d0
            jsr     -210(a6)                ; FreeMem - the sector buffer
            cmp.w   #37,20(a6)              ; Kickstart 2.0+ : flush caches (it is code)
            blo     .nocc
            jsr     -636(a6)                ; CacheClearU
.nocc       move.l  a2,a1
            jmp     (a5)

; d0 = bytes -> d0 = chip RAM (cleared); fails the boot when there is none
alloc:      move.l  memflags(pc),d1
            jsr     -198(a6)                ; AllocMem
            tst.l   d0
            beq     bootfail
            rts

; a0 = destination, d0 = bytes (whole sectors) read from disk offset d3
readdisk:   move.l  a2,a1
            move.w  #2,28(a1)               ; CMD_READ
            move.l  a0,40(a1)               ; io_Data
            move.l  d0,36(a1)               ; io_Length
            move.l  d3,44(a1)               ; io_Offset
            add.l   d0,d3
            jsr     -456(a6)                ; DoIO
            tst.b   d0
            bne     bootfail
            rts

; -> d0 = next long of the file (longs never straddle a sector)
getlong:    cmp.w   #512,d4
            blo     .have
            move.l  a3,a0
            move.l  #512,d0
            bsr     readdisk
            moveq   #0,d4
.have       move.l  0(a3,d4.w),d0
            addq.w  #4,d4
            rts

; d6 longs of the file -> (a5)+ ; whole sectors go straight in by DMA
readlongs:  tst.l   d6
            beq     .done
            cmp.w   #512,d4
            blo     .one
            move.l  d6,d0
            lsl.l   #2,d0
            and.l   #-512,d0
            beq     .one
            move.l  d0,d2
            move.l  a5,a0
            bsr     readdisk
            add.l   d2,a5
            lsr.l   #2,d2
            sub.l   d2,d6
            bra     readlongs
.one        bsr     getlong
            move.l  d0,(a5)+
            subq.l  #1,d6
            bra     readlongs
.done       rts

; skips d6 longs of the file
skiplongs:  tst.l   d6
            beq     .done
            bsr     getlong
            subq.l  #1,d6
            bra     skiplongs
.done       rts

; Not enough memory, a read error or a bad file: a solid red screen, for ever.
bootfail:   lea     $dff000,a5
            move.w  #$7fff,$9a(a5)          ; INTENA - all interrupts off
            move.w  #$7fff,$96(a5)          ; DMACON - all DMA off
            move.w  #$0200,$100(a5)         ; BPLCON0 - no bitplanes
            move.w  #0,$106(a5)
.red        move.w  #$0f00,$180(a5)
            bra     .red

            cnop    0,4
memflags:   dc.l    0
            dc.b    "ADMB"                  ; tag Amiga Dev Machine looks for
readsize:   dc.l    0
resv_addr:  dc.l    0
resv_size:  dc.l    0
