/// @desc scr_m68k_selftest(): the 68000 simulator against hand-worked results.
/// Run by -admselftest and on its own by -admsimtest. Returns an array of
/// failure messages (empty = pass).
///
/// Each case: [ name, source, machine code, setup, expected ] (setup and
/// expected strings: see scr_m68k_spec)
///   source   assembly lines separated by "|" ("label: instr" allowed)
///   code     hex bytes assembled at $1000 by vasm -no-opt; filled in by
///            tools/m68k_sim_hex.py (run it after editing a source)
///   setup    registers, memory and flags before the run
///   expected registers, flags, memory, status and hardware after it
/// The program runs from $1000 in supervisor mode (SR $2700) until the PC
/// passes its last byte.

function scr_m68k_selftest_cases() {
    return [
        // --- MOVE and addressing modes
        ["MOVEQ -1", "moveq #-1,d0", "70FF", "", "d0=FFFFFFFF ccr=-N---"],
        ["MOVEQ 0 sets Z", "moveq #0,d0", "7000", "d0=12345678 ccr=---VC", "d0=0 ccr=--Z--"],
        ["MOVE.B keeps upper bytes", "move.b #$80,d0", "103C0080", "d0=12345678", "d0=12345680 ccr=-N---"],
        ["MOVE.W zero", "move.w d1,d0", "3001", "d0=FFFFFFFF d1=0", "d0=FFFF0000 ccr=--Z--"],
        ["MOVE keeps X", "move.w #1,d0", "303C0001", "ccr=X--VC", "d0=1 ccr=X----"],
        ["MOVE.L to (An)", "move.l #$12345678,(a0)", "20BC12345678", "a0=2000", "m2000.l=12345678 ccr=-----"],
        ["(An)+ long", "move.l (a0)+,d0|move.l (a0)+,d1", "20182218", "a0=2000 m2000.l=11223344 m2004.l=55667788", "d0=11223344 d1=55667788 a0=2008"],
        ["(A7)+ byte steps 2", "move.b (a7)+,d0", "101F", "a7=3000 m3000.w=AB00", "d0=AB a7=3002 ccr=-N---"],
        ["-(An) word", "move.w -(a0),d0", "3020", "a0=2002 m2000.w=BEEF", "d0=BEEF a0=2000 ccr=-N---"],
        ["-(A7) byte steps 2", "move.b #$12,-(a7)", "1F3C0012", "a7=3000", "a7=2FFE m2FFE.b=12"],
        ["d16(An)", "move.w 4(a0),d0", "30280004", "a0=2000 m2004.w=1234", "d0=1234"],
        ["d8(An,Dn.W)", "move.w -2(a0,d1.w),d0", "303010FE", "a0=2000 d1=6 m2004.w=5678", "d0=5678"],
        ["d8(An,Dn.W) negative index", "move.w 4(a0,d1.w),d0", "30301004", "a0=2000 d1=1FFFE m2002.w=4321", "d0=4321"],
        ["d8(An,Dn.L)", "move.w 0(a0,d1.l),d0", "30301800", "a0=2000 d1=FFFFFFFE m1FFE.w=0BAD", "d0=BAD"],
        ["d8(An,An.W)", "move.w 2(a0,a1.w),d0", "30309002", "a0=2000 a1=10 m2012.w=7777", "d0=7777"],
        ["abs.W", "move.w $2000.w,d0", "30382000", "m2000.w=4321", "d0=4321"],
        ["abs.L", "move.w $00002000,d0", "303900002000", "m2000.w=8765", "d0=8765 ccr=-N---"],
        ["d16(PC)", "lea data(pc),a0|move.w data(pc),d0|bra.s skip|data: dc.w $CAFE|skip:", "41FA0008303A00046002CAFE", "", "d0=CAFE a0=100A"],
        ["d8(PC,Dn)", "moveq #2,d1|move.w tab(pc,d1.w),d0|bra.s skip|tab: dc.w 1,2,3|skip:", "7202303B10046006000100020003", "", "d0=2"],
        ["MOVEA.W sign-extends, flags kept", "movea.w #$8000,a0", "307C8000", "ccr=XNZVC", "a0=FFFF8000 ccr=XNZVC"],
        ["MOVEA.L", "movea.l #$12345678,a1", "227C12345678", "", "a1=12345678"],
        ["EXG", "exg d0,a0|exg d1,d2|exg a1,a2", "C188C342C34A", "d0=1 a0=2 d1=3 d2=4 a1=5 a2=6", "d0=2 a0=1 d1=4 d2=3 a1=6 a2=5"],
        ["SWAP", "swap d0", "4840", "d0=12345678", "d0=56781234 ccr=-----"],
        ["SWAP negative", "swap d0", "4840", "d0=8000", "d0=80000000 ccr=-N---"],
        ["EXT.W", "ext.w d0", "4880", "d0=123456F0", "d0=1234FFF0 ccr=-N---"],
        ["EXT.L", "ext.l d0", "48C0", "d0=12348000", "d0=FFFF8000 ccr=-N---"],
        ["CLR.W", "clr.w d0", "4240", "d0=FFFFFFFF ccr=XN-VC", "d0=FFFF0000 ccr=X-Z--"],
        ["CLR.L memory", "clr.l (a0)", "4290", "a0=2000 m2000.l=FFFFFFFF", "m2000.l=0"],
        ["LEA d16(An)", "lea 8(a0),a1", "43E80008", "a0=1000", "a1=1008"],
        ["LEA indexed", "lea 0(a0,d0.w),a1", "43F00000", "a0=1000 d0=FFF0", "a1=FF0"],
        ["PEA", "pea $1234.w", "48781234", "a7=3000", "a7=2FFC m2FFC.l=1234"],
        ["MOVEP.W write", "movep.w d0,0(a0)", "01880000", "d0=1234 a0=2000", "m2000.l=12003400"],
        ["MOVEP.L read", "movep.l 0(a0),d1", "03480000", "a0=2000 m2000.l=11223344 m2004.l=55667788", "d1=11335577"],
        ["MOVEM.L to -(A7)", "movem.l d0-d2/a0,-(a7)", "48E7E080", "a7=3000 d0=1 d1=2 d2=3 a0=4", "a7=2FF0 m2FF0.l=1 m2FF4.l=2 m2FF8.l=3 m2FFC.l=4"],
        ["MOVEM.L from (A7)+", "movem.l (a7)+,d0-d2/a0", "4CDF0107", "a7=2FF0 m2FF0.l=11 m2FF4.l=22 m2FF8.l=33 m2FFC.l=44", "a7=3000 d0=11 d1=22 d2=33 a0=44"],
        ["MOVEM.W sign-extends", "movem.w (a0),d0/a1", "4C900201", "a0=2000 m2000.w=8000 m2002.w=5", "d0=FFFF8000 a1=5 a0=2000"],
        ["MOVEM.L to d16(An)", "movem.l d3/d4,8(a0)", "48E800180008", "a0=2000 d3=AAAA d4=BBBB", "m2008.l=AAAA m200C.l=BBBB"],

        // --- arithmetic and flags
        ["ADD.W overflow", "add.w d1,d0", "D041", "d0=7FFF d1=1", "d0=8000 ccr=-N-V-"],
        ["ADD.B carry", "add.b d1,d0", "D001", "d0=FF d1=1", "d0=0 ccr=X-Z-C"],
        ["ADD.L carry", "add.l #1,d0", "D0BC00000001", "d0=FFFFFFFF", "d0=0 ccr=X-Z-C"],
        ["ADD.L to memory", "add.l d0,(a0)", "D190", "a0=2000 m2000.l=1 d0=2", "m2000.l=3 ccr=-----"],
        ["ADDQ.W", "addq.w #8,d0", "5040", "d0=1234FFF8", "d0=12340000 ccr=X-Z-C"],
        ["ADDQ to An: no flags", "addq.l #1,a0", "5288", "a0=FFFFFFFF ccr=-N---", "a0=0 ccr=-N---"],
        ["ADDQ.W to An: whole register", "addq.w #1,a0", "5248", "a0=FFFF", "a0=10000"],
        ["ADDA.W sign-extends", "adda.w d0,a0", "D0C0", "d0=FFFF a0=1000", "a0=FFF"],
        ["ADDI.B", "addi.b #$80,d0", "06000080", "d0=80", "d0=0 ccr=X-ZVC"],
        ["SUB.W borrow", "sub.w d1,d0", "9041", "d0=0 d1=1", "d0=FFFF ccr=XN--C"],
        ["SUB.B overflow", "sub.b d1,d0", "9001", "d0=80 d1=1", "d0=7F ccr=---V-"],
        ["SUBQ.L to zero", "subq.l #1,d0", "5380", "d0=1 ccr=X----", "d0=0 ccr=--Z--"],
        ["SUBA.L", "suba.l d0,a0", "91C0", "a0=1000 d0=1", "a0=FFF"],
        ["SUBI.W memory", "subi.w #$10,(a0)", "04500010", "a0=2000 m2000.w=5", "m2000.w=FFF5 ccr=XN--C"],
        ["NEG.W", "neg.w d0", "4440", "d0=1", "d0=FFFF ccr=XN--C"],
        ["NEG zero", "neg.l d0", "4480", "d0=0 ccr=X---C", "d0=0 ccr=--Z--"],
        ["NEG.B $80", "neg.b d0", "4400", "d0=80", "d0=80 ccr=XN-VC"],
        ["NEGX with X", "negx.b d0", "4000", "d0=0 ccr=X----", "d0=FF ccr=XN--C"],
        ["NEGX zero keeps Z", "negx.b d0", "4000", "d0=0 ccr=--Z--", "d0=0 ccr=--Z--"],
        ["ADDX keeps Z on zero", "addx.l d1,d0", "D181", "d0=FFFFFFFF d1=0 ccr=X-Z--", "d0=0 ccr=X-Z-C"],
        ["64-bit add", "add.l d1,d3|addx.l d0,d2", "D681D580", "d2=0 d3=FFFFFFFF d0=0 d1=1", "d3=0 d2=1 ccr=-----"],
        ["SUBX memory", "subx.b -(a0),-(a1)", "9308", "a0=2001 a1=3001 m2000.b=1 m3000.b=0", "m3000.b=FF a0=2000 a1=3000 ccr=XN--C"],
        ["CMP equal keeps X", "cmp.w d1,d0", "B041", "d0=5 d1=5 ccr=X----", "ccr=X-Z--"],
        ["CMP.B lower", "cmp.b d1,d0", "B001", "d0=0 d1=1", "ccr=-N--C d0=0"],
        ["CMP.L overflow", "cmp.l #$80000000,d0", "B0BC80000000", "d0=0", "ccr=-N-VC"],
        ["CMPA.W sign-extends", "cmpa.w d0,a0", "B0C0", "d0=FFFF a0=FFFFFFFF", "ccr=--Z--"],
        ["CMPM.W", "cmpm.w (a0)+,(a1)+", "B348", "a0=2000 a1=3000 m2000.w=1 m3000.w=2", "ccr=----- a0=2002 a1=3002"],
        ["CMPI.B overflow", "cmpi.b #$7F,d0", "0C00007F", "d0=80", "ccr=---V-"],
        ["TST.L", "tst.l d0", "4A80", "d0=80000000 ccr=---VC", "ccr=-N---"],
        ["TST.B zero", "tst.b d0", "4A00", "d0=FFFFFF00", "ccr=--Z--"],
        ["MULU.W", "mulu.w d1,d0", "C0C1", "d0=FFFF d1=FFFF", "d0=FFFE0001 ccr=-N---"],
        ["MULU ignores upper words", "mulu.w d1,d0", "C0C1", "d0=12340002 d1=56780003", "d0=6"],
        ["MULS.W", "muls.w d1,d0", "C1C1", "d0=FFFF d1=2", "d0=FFFFFFFE ccr=-N---"],
        ["MULS.W immediate", "muls.w #-2,d0", "C1FCFFFE", "d0=3", "d0=FFFFFFFA"],
        ["DIVU.W", "divu.w #3,d0", "80FC0003", "d0=A", "d0=10003 ccr=-----"],
        ["DIVU.W overflow", "divu.w #1,d0", "80FC0001", "d0=100000", "d0=100000 ccr=-??V-"],
        ["DIVS.W negative", "divs.w #2,d0", "81FC0002", "d0=FFFFFFF9", "d0=FFFFFFFD ccr=-N---"],
        ["DIVS.W remainder sign", "divs.w #-2,d0", "81FCFFFE", "d0=7", "d0=1FFFD ccr=-N---"],
        ["DIVU by zero", "divu.w d1,d0", "80C1", "d0=5 d1=0", "status=exception vector=5"],
        ["CHK in range", "chk.w d1,d0", "4181", "d0=5 d1=A", "status=done"],
        ["CHK negative", "chk.w d1,d0", "4181", "d0=FFFF d1=A", "status=exception vector=6"],
        ["CHK above", "chk.w d1,d0", "4181", "d0=B d1=A", "status=exception vector=6"],
        ["ABCD", "abcd d1,d0", "C101", "d0=15 d1=27 ccr=--Z--", "d0=42 ccr=-?-?-"],
        ["ABCD carry", "abcd d1,d0", "C101", "d0=99 d1=1 ccr=--Z--", "d0=0 ccr=X?Z?C"],
        ["ABCD with X", "abcd d1,d0", "C101", "d0=19 d1=0 ccr=X----", "d0=20 ccr=-?-?-"],
        ["SBCD", "sbcd d1,d0", "8101", "d0=42 d1=15", "d0=27 ccr=-?-?-"],
        ["SBCD borrow", "sbcd d1,d0", "8101", "d0=0 d1=1", "d0=99 ccr=X?-?C"],
        ["NBCD", "nbcd d0", "4800", "d0=1", "d0=99 ccr=X?-?C"],
        ["NBCD zero", "nbcd d0", "4800", "d0=0 ccr=--Z--", "d0=0 ccr=-?Z?-"],
        ["ABCD memory", "abcd -(a0),-(a1)", "C308", "a0=2001 a1=3001 m2000.b=5 m3000.b=5", "m3000.b=10 a0=2000 a1=3000"],

        // --- logic, CCR and SR
        ["AND.W", "and.w d1,d0", "C041", "d0=FFFF0F0F d1=FF", "d0=FFFF000F ccr=-----"],
        ["OR.B immediate", "or.b #$80,d0", "803C0080", "d0=0", "d0=80 ccr=-N---"],
        ["EOR.L", "eor.l d1,d0", "B380", "d0=FFFFFFFF d1=FFFFFFFF", "d0=0 ccr=--Z--"],
        ["NOT.W", "not.w d0", "4640", "d0=12340000", "d0=1234FFFF ccr=-N---"],
        ["ANDI.B memory", "andi.b #$0F,(a0)", "0210000F", "a0=2000 m2000.b=FF", "m2000.b=F"],
        ["EORI.W", "eori.w #$FFFF,d0", "0A40FFFF", "d0=12345678", "d0=1234A987 ccr=-N---"],
        ["ORI to CCR", "ori.b #$11,ccr", "003C0011", "", "ccr=X---C"],
        ["ANDI to CCR", "andi.b #$FE,ccr", "023C00FE", "ccr=XNZVC", "ccr=XNZV-"],
        ["EORI to CCR", "eori.b #$1F,ccr", "0A3C001F", "ccr=X-Z-C", "ccr=-N-V-"],
        ["ANDI to SR", "andi.w #$F8FF,sr", "027CF8FF", "", "sr=2000"],
        ["ORI to SR", "ori.w #$0700,sr", "007C0700", "sr=2000", "sr=2700"],
        ["ORI to SR from user mode", "ori.w #$0700,sr", "007C0700", "sr=0", "status=exception vector=8 pc=1000"],
        ["MOVE to SR", "move.w #$2300,sr", "46FC2300", "", "sr=2300"],
        ["MOVE from SR", "move.w sr,d0", "40C0", "sr=2715", "d0=2715"],
        ["MOVE from SR in user mode (68000)", "move.w sr,d0", "40C0", "sr=4", "d0=4 status=done"],
        ["MOVE to CCR", "move.w #$1F,ccr", "44FC001F", "", "sr=271F"],
        ["MOVE USP and user mode", "lea $2800,a0|move.l a0,usp|move.w #0,sr|move.l a7,d0", "41F9000028004E6046FC0000200F", "", "d0=2800 sr=0 ssp=80000"],
        ["TAS", "tas (a0)", "4AD0", "a0=2000 m2000.b=0", "m2000.b=80 ccr=--Z--"],
        ["TAS already set", "tas (a0)", "4AD0", "a0=2000 m2000.b=80", "m2000.b=80 ccr=-N---"],

        // --- bits
        ["BTST #3", "btst #3,d0", "08000003", "d0=8 ccr=--Z--", "ccr=-----"],
        ["BTST #31", "btst #31,d0", "0800001F", "d0=0", "ccr=--Z--"],
        ["BTST Dn mod 32", "btst d1,d0", "0300", "d0=2 d1=21", "ccr=-----"],
        ["BSET memory", "bset #7,(a0)", "08D00007", "a0=2000", "m2000.b=80 ccr=--Z--"],
        ["BSET memory mod 8", "bset #9,(a0)", "08D00009", "a0=2000", "m2000.b=2"],
        ["BCLR", "bclr #0,d0", "08800000", "d0=FFFFFFFF", "d0=FFFFFFFE ccr=-----"],
        ["BCHG", "bchg d1,d0", "0340", "d0=0 d1=4", "d0=10 ccr=--Z--"],

        // --- shifts and rotates
        ["ASL.W overflow", "asl.w #1,d0", "E340", "d0=4000", "d0=8000 ccr=-N-V-"],
        ["ASL.B carry out", "asl.b #2,d0", "E500", "d0=C0", "d0=0 ccr=X-ZVC"],
        ["ASR.W keeps sign", "asr.w #1,d0", "E240", "d0=8001", "d0=C000 ccr=XN--C"],
        ["LSR.L", "lsr.l #4,d0", "E888", "d0=8000000F", "d0=8000000 ccr=X---C"],
        ["LSL by 0 clears C, keeps X", "lsl.l d1,d0", "E3A8", "d0=1 d1=0 ccr=X---C", "d0=1 ccr=X----"],
        ["LSR.W by 20", "lsr.w d1,d0", "E268", "d0=FFFF d1=14", "d0=0 ccr=--Z--"],
        ["LSR.W by 16", "lsr.w d1,d0", "E268", "d0=FFFF d1=10", "d0=0 ccr=X-Z-C"],
        ["ROL.W", "rol.w #4,d0", "E958", "d0=1234", "d0=2341 ccr=----C"],
        ["ROR.B", "ror.b #1,d0", "E218", "d0=1", "d0=80 ccr=-N--C"],
        ["ROR keeps X", "ror.b #1,d0", "E218", "d0=2 ccr=X----", "d0=1 ccr=X----"],
        ["ROXL.B", "roxl.b #1,d0", "E310", "d0=80", "d0=0 ccr=X-Z-C"],
        ["ROXL.B shifts X in", "roxl.b #1,d0", "E310", "d0=0 ccr=X----", "d0=1 ccr=-----"],
        ["ROXR.W", "roxr.w #1,d0", "E250", "d0=1 ccr=X----", "d0=8000 ccr=XN--C"],
        ["ROXL by 0: C = X", "roxl.l d1,d0", "E3B0", "d0=0 d1=0 ccr=X----", "d0=0 ccr=X-Z-C"],
        ["ASL memory", "asl.w (a0)", "E1D0", "a0=2000 m2000.w=8000", "m2000.w=0 ccr=X-ZVC"],
        ["LSR memory", "lsr.w (a0)", "E2D0", "a0=2000 m2000.w=3", "m2000.w=1 ccr=X---C"],
        ["ASL.L #8", "asl.l #8,d0", "E180", "d0=800000", "d0=80000000 ccr=-N-V-"],
        ["ASR.L by 40", "asr.l d1,d0", "E2A0", "d0=80000000 d1=28", "d0=FFFFFFFF ccr=XN--C"],

        // --- program flow
        ["Bcc taken", "moveq #0,d0|cmp.w #5,d1|blt.s less|moveq #1,d0|bra.s done|less: moveq #2,d0|done:", "7000B27C00056D04700160027002", "d1=3", "d0=2"],
        ["Bcc not taken", "moveq #0,d0|cmp.w #5,d1|blt.s less|moveq #1,d0|bra.s done|less: moveq #2,d0|done:", "7000B27C00056D04700160027002", "d1=7", "d0=1"],
        ["BRA.W", "bra.w over|moveq #1,d0|over: moveq #2,d1", "6000000470017202", "", "d0=0 d1=2"],
        ["BSR / RTS", "bsr.s sub|moveq #1,d0|bra.s done|sub: moveq #5,d1|rts|done:", "61047001600472054E75", "a7=3000", "d0=1 d1=5 a7=3000"],
        ["JSR (An)", "lea sub(pc),a0|jsr (a0)|bra.s done|sub: moveq #9,d2|rts|done:", "41FA00064E90600474094E75", "", "d2=9"],
        ["JMP d16(PC)", "jmp skip(pc)|moveq #1,d0|skip:", "4EFA00047001", "", "d0=0"],
        ["DBRA loop", "moveq #9,d0|moveq #0,d1|loop: addq.w #1,d1|dbra d0,loop", "70097200524151C8FFFC", "", "d1=A d0=FFFF"],
        ["DBEQ exits on condition", "moveq #5,d0|moveq #3,d1|loop: subq.w #1,d1|dbeq d0,loop", "70057203534157C8FFFC", "", "d0=3 d1=0"],
        ["Scc", "seq d0|sne d1|shi d2|sls d3", "57C056C152C253C3", "d0=0 d1=FFFFFFFF d2=0 d3=0 ccr=--Z--", "d0=FF d1=FFFFFF00 d2=0 d3=FF"],
        ["Scc signed", "slt d0|sgt d1|sge d2|sle d3", "5DC05EC15CC25FC3", "ccr=-N-V-", "d0=0 d1=FF d2=FF d3=0"],
        ["LINK / UNLK", "link a6,#-8|move.l a7,d0|unlk a6", "4E56FFF8200F4E5E", "a6=AAAA a7=3000", "d0=2FF4 a6=AAAA a7=3000 m2FFC.l=AAAA"],
        ["RTR", "pea done(pc)|move.w #$1F,-(a7)|rtr|moveq #1,d0|done:", "487A000A3F3C001F4E777001", "", "d0=0 ccr=XNZVC"],

        // --- exceptions
        ["ILLEGAL unhandled", "illegal", "4AFC", "", "status=exception vector=4 pc=1000"],
        ["ILLEGAL handled", "lea h(pc),a0|move.l a0,$10.w|illegal|moveq #1,d0|bra.s done|h: moveq #7,d1|addq.l #2,2(a7)|rte|done:", "41FA000C21C800104AFC70016008720754AF00024E73", "", "d0=1 d1=7 sr=2700"],
        ["TRAP #3", "lea h(pc),a0|move.l a0,$8C.w|trap #3|moveq #1,d0|bra.s done|h: moveq #7,d1|rte|done:", "41FA000C21C8008C4E437001600472074E73", "", "d0=1 d1=7 sr=2700"],
        ["TRAP from user mode", "lea h(pc),a0|move.l a0,$80.w|move.w #0,sr|trap #0|moveq #1,d0|bra.s done|h: moveq #7,d1|move.l a7,d2|rte|done:", "41FA001021C8008046FC00004E40700160067207240F4E73", "ssp=4000 usp=3000", "d0=1 d1=7 d2=3FFA sr=0 a7=3000 m3FFA.w=0 m3FFC.l=100E"],
        ["Address error unhandled", "move.w (a0),d0", "3010", "a0=2001", "status=exception vector=3"],
        ["Address error frame", "lea h(pc),a0|move.l a0,$C.w|move.l #$2001,a1|move.w (a1),d0|moveq #1,d1|h: move.l a7,d7|move.w (a7),d5|move.l 2(a7),d6|move.w 6(a7),d4|move.w 8(a7),d3", "41FA001021C8000C227C00002001301172012E0F3A172C2F0002382F0006362F0008", "a7=3000", "d7=2FF2 d5=1D d6=2001 d4=3011 d3=2700 d1=0"],
        ["Bus error", "move.w $00E00000,d0", "303900E00000", "", "status=exception vector=2"],
        ["Privilege violation", "move.w #$2700,sr", "46FC2700", "sr=0", "status=exception vector=8 pc=1000"],
        ["Line A", "dc.w $A000", "A000", "", "status=exception vector=10"],
        ["Line F", "dc.w $F000", "F000", "", "status=exception vector=11"],
        ["TRAPV", "trapv", "4E76", "ccr=---V-", "status=exception vector=7"],
        ["TRAPV clear", "trapv", "4E76", "", "status=done"],
        ["RTE in user mode", "rte", "4E73", "sr=0", "status=exception vector=8"],
        ["Trace", "lea h(pc),a0|move.l a0,$24.w|ori.w #$8000,sr|nop|nop|andi.w #$7FFF,sr|bra.s done|h: addq.l #1,d7|rte|done:", "41FA001421C80024007C80004E714E71027C7FFF600452874E73", "", "d7=3 sr=2700"],
        ["VERTB interrupt", "lea h(pc),a0|move.l a0,$6C.w|move.w #$C020,$DFF09A|move.w #$2000,sr|wait: cmp.w #2,d7|bne.s wait|move.w #$2700,sr|bra.s done|h: addq.w #1,d7|move.w #$0020,$DFF09C|rte|done:", "41FA001E21C8006C33FCC02000DFF09A46FC2000BE7C000266FA46FC2700600C524733FC002000DFF09C4E73", "", "d7=2 hw09A=C020 hw09C=20"],
        ["Interrupt with no handler", "move.w #$C020,$DFF09A|move.w #$2000,sr|wait: bra.s wait", "33FCC02000DFF09A46FC200060FE", "", "status=exception vector=27"],
        ["STOP waits for VERTB", "lea h(pc),a0|move.l a0,$6C.w|move.w #$C020,$DFF09A|stop #$2000|moveq #1,d0|bra.s done|h: move.w #$0020,$DFF09C|rte|done:", "41FA001621C8006C33FCC02000DFF09A4E7220007001600A33FC002000DFF09C4E73", "", "d0=1 status=done"],
        ["STOP with nothing to wake it", "stop #$2700", "4E722700", "", "status=stopped"],
        ["Endless loop times out", "loop: bra.s loop", "60FE", "max=1000", "status=timeout"],

        // --- custom chips, CIAs, timing
        ["VBL wait on VPOSR", "wait: move.l $DFF004,d0|and.l #$1FF00,d0|cmp.l #$12C00,d0|bne.s wait", "203900DFF004C0BC0001FF00B0BC00012C0066EC", "", "vpos=12C"],
        ["DMACON set and clear", "move.w #$8380,$DFF096|move.w #$0100,$DFF096|move.w $DFF002,d0", "33FC838000DFF09633FC010000DFF096303900DFF002", "", "d0=2280"],
        ["INTENAR", "move.w #$C028,$DFF09A|move.w $DFF01C,d0", "33FCC02800DFF09A303900DFF01C", "", "d0=4028"],
        ["Byte write to a custom register", "move.b #$12,$DFF180", "13FC001200DFF180", "", "hw180=1212"],
        ["Long write to a pointer pair", "move.l #$20000,$DFF080", "23FC0002000000DFF080", "", "hw080=2 hw082=0 hwlong080=20000"],
        ["Joystick right + fire", "move.w $DFF00C,d0|move.b $BFE001,d1", "303900DFF00C123900BFE001", "joy=right+fire", "d0=3 d1=7F"],
        ["Joystick left + up", "move.w $DFF00C,d0", "303900DFF00C", "joy=left+up", "d0=200"],
        ["CIA-A write", "move.b #3,$BFE201", "13FC000300BFE201", "", "ciaa2=3"],
        ["Cycles", "moveq #1,d0|nop|add.l (a0),d0", "70014E71D090", "a0=2000", "cyc=22"],
        ["DBRA cycles", "moveq #3,d0|loop: dbra d0,loop", "700351C8FFFE", "", "cyc=48"],

        // --- blitter
        ["Blitter copy", "move.w #$09F0,$DFF040|move.w #0,$DFF042|move.w #$FFFF,$DFF044|move.w #$FFFF,$DFF046|move.l #$2000,$DFF050|move.l #$3000,$DFF054|move.w #0,$DFF064|move.w #0,$DFF066|move.w #(2<<6)+1,$DFF058", "33FC09F000DFF04033FC000000DFF04233FCFFFF00DFF04433FCFFFF00DFF04623FC0000200000DFF05023FC0000300000DFF05433FC000000DFF06433FC000000DFF06633FC008100DFF058", "m2000.l=12345678", "m3000.l=12345678"],
        ["Blitter shift", "move.w #$19F0,$DFF040|move.w #0,$DFF042|move.w #$FFFF,$DFF044|move.w #$FFFF,$DFF046|move.l #$2000,$DFF050|move.l #$3000,$DFF054|move.w #(1<<6)+2,$DFF058", "33FC19F000DFF04033FC000000DFF04233FCFFFF00DFF04433FCFFFF00DFF04623FC0000200000DFF05023FC0000300000DFF05433FC004200DFF058", "m2000.l=18000", "m3000.l=C000"],
        ["Blitter inclusive fill", "move.w #$09F0,$DFF040|move.w #$000A,$DFF042|move.w #$FFFF,$DFF044|move.w #$FFFF,$DFF046|move.l #$2000,$DFF050|move.l #$3000,$DFF054|move.w #(1<<6)+1,$DFF058", "33FC09F000DFF04033FC000A00DFF04233FCFFFF00DFF04433FCFFFF00DFF04623FC0000200000DFF05023FC0000300000DFF05433FC004100DFF058", "m2000.w=0810", "m3000.w=FF0"],
        ["Blitter exclusive fill", "move.w #$09F0,$DFF040|move.w #$0012,$DFF042|move.w #$FFFF,$DFF044|move.w #$FFFF,$DFF046|move.l #$2000,$DFF050|move.l #$3000,$DFF054|move.w #(1<<6)+1,$DFF058", "33FC09F000DFF04033FC001200DFF04233FCFFFF00DFF04433FCFFFF00DFF04623FC0000200000DFF05023FC0000300000DFF05433FC004100DFF058", "m2000.w=0810", "m3000.w=7F0"],
        ["Blitter clear and BZERO", "move.w #$0100,$DFF040|move.w #0,$DFF042|move.l #$3000,$DFF054|move.w #(1<<6)+2,$DFF058|move.w $DFF002,d0", "33FC010000DFF04033FC000000DFF04223FC0000300000DFF05433FC004200DFF058303900DFF002", "m3000.l=FFFFFFFF", "m3000.l=0 d0=2000"],
    ];
}

function scr_m68k_selftest() {
    var _fail = [];
    var _cases = scr_m68k_selftest_cases();
    var _cpu = scr_m68k_new($80000, 0);
    for (var _i = 0; _i < array_length(_cases); _i += 1) {
        var _t = _cases[_i];
        var _name = _t[0];
        if (_t[2] == "") {
            array_push(_fail, _name + ": no machine code (run tools/m68k_sim_hex.py)");
            continue;
        }
        scr_m68k_reset(_cpu);
        var _len = scr_m68k_load_hex(_cpu, $1000, _t[2]);
        var _max = scr_m68k_spec_setup(_cpu, _t[3], $1000, $1000 + _len, 200000);
        scr_m68k_run(_cpu, _max);
        var _problems = scr_m68k_spec_check(_cpu, _t[4]);
        if (array_length(_problems) > 0) array_push(_fail, _name + ": " + string_join_ext("; ", _problems) + " [" + _cpu.status + " " + _cpu.message + "]");
    }
    scr_m68k_free(_cpu);
    return _fail;
}
