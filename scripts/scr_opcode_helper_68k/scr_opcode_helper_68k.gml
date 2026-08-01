/// @desc scr_opcode_helper_68k(_key)
/// Returns a struct with tooltip info for a given opcode key.
/// Fields: hex, bytes, cycles, format, mode, use
function scr_opcode_helper_68k(_key) {
    static _map = {
        "move":   { hex:"—", bytes:2, cycles:4,  format:"MOVE.size src,dst", mode:"Copies data from src to dst. Sets N,Z,V,C from result.",                 use:"General purpose data transfer between registers and memory." },
        "movea":  { hex:"—", bytes:2, cycles:4,  format:"MOVEA.size src,An", mode:"Copies data into an address register. No flags affected.",               use:"Load a pointer into An without disturbing CCR flags." },
        "moveq":  { hex:"—", bytes:2, cycles:4,  format:"MOVEQ #data,Dn",    mode:"Loads an 8-bit signed immediate into Dn, sign-extended to 32 bits.",      use:"Fast, compact way to load small constants (-128..127) into a register." },
        "movem":  { hex:"—", bytes:4, cycles:8,  format:"MOVEM.size list,dst / src,list", mode:"Moves multiple registers to/from memory using a bitmask list.", use:"Save/restore registers on entry/exit of a subroutine or interrupt." },
        "movep":  { hex:"—", bytes:2, cycles:16, format:"MOVEP.size Dn,d16(An)", mode:"Moves data between Dn and alternate bytes of memory.",                use:"Rare — talking to 8-bit peripherals mapped on alternate byte lanes." },
        "lea":    { hex:"—", bytes:2, cycles:4,  format:"LEA src,An",        mode:"Loads the effective address of src (not its contents) into An.",         use:"Set up a pointer to a table, buffer, or hardware register block." },
        "pea":    { hex:"—", bytes:2, cycles:8,  format:"PEA src",           mode:"Pushes the effective address of src onto the stack.",                     use:"Push an address as a function argument before a JSR/BSR." },
        "clr":    { hex:"—", bytes:2, cycles:4,  format:"CLR.size dst",      mode:"Sets dst to zero. Clears N,V,C, sets Z.",                                 use:"Zero out a variable or buffer cell quickly." },
        "exg":    { hex:"—", bytes:2, cycles:6,  format:"EXG Rx,Ry",         mode:"Swaps the full 32-bit contents of two registers.",                        use:"Swap two register values without a temp register or memory." },
        "swap":   { hex:"—", bytes:2, cycles:4,  format:"SWAP Dn",           mode:"Exchanges the upper and lower 16-bit words of Dn.",                       use:"Quickly access the high word of a 32-bit value, or build one." },
        "ext":    { hex:"—", bytes:2, cycles:4,  format:"EXT.size Dn",       mode:"Sign-extends a byte to word, or word to long, in Dn.",                    use:"Widen a small signed value before arithmetic that needs full width." },

        "add":    { hex:"—", bytes:2, cycles:4,  format:"ADD.size src,dst",  mode:"Adds src to dst, result in dst. Sets all condition codes.",              use:"Standard addition between a register and memory/another register." },
        "adda":   { hex:"—", bytes:2, cycles:8,  format:"ADDA.size src,An",  mode:"Adds src to address register An. No flags affected.",                     use:"Advance a pointer by a variable amount (array/table walking)." },
        "addi":   { hex:"—", bytes:4, cycles:8,  format:"ADDI.size #data,dst", mode:"Adds an immediate constant to dst.",                                   use:"Add a fixed known value to a variable in memory." },
        "addq":   { hex:"—", bytes:2, cycles:4,  format:"ADDQ.size #1-8,dst", mode:"Adds a small immediate (1-8) to dst. Compact encoding.",                use:"Increment loop counters or pointers by a small fixed step." },
        "addx":   { hex:"—", bytes:2, cycles:4,  format:"ADDX.size Dx,Dy",   mode:"Adds two operands plus the extend (X) flag.",                            use:"Chain together multi-word (32/64-bit+) addition across registers." },

        "sub":    { hex:"—", bytes:2, cycles:4,  format:"SUB.size src,dst",  mode:"Subtracts src from dst, result in dst. Sets all condition codes.",       use:"Standard subtraction between a register and memory/another register." },
        "suba":   { hex:"—", bytes:2, cycles:8,  format:"SUBA.size src,An",  mode:"Subtracts src from address register An. No flags affected.",             use:"Move a pointer backwards by a variable amount." },
        "subi":   { hex:"—", bytes:4, cycles:8,  format:"SUBI.size #data,dst", mode:"Subtracts an immediate constant from dst.",                            use:"Subtract a fixed known value from a variable in memory." },
        "subq":   { hex:"—", bytes:2, cycles:4,  format:"SUBQ.size #1-8,dst", mode:"Subtracts a small immediate (1-8) from dst. Compact encoding.",         use:"Decrement loop counters or pointers by a small fixed step." },
        "subx":   { hex:"—", bytes:2, cycles:4,  format:"SUBX.size Dx,Dy",   mode:"Subtracts two operands and the extend (X) flag.",                        use:"Chain together multi-word subtraction across registers." },

        "muls":   { hex:"—", bytes:2, cycles:38, format:"MULS.W src,Dn",     mode:"Signed 16x16 multiply, 32-bit result in Dn.",                             use:"Multiply signed values — coordinates, deltas, scaling factors." },
        "mulu":   { hex:"—", bytes:2, cycles:38, format:"MULU.W src,Dn",     mode:"Unsigned 16x16 multiply, 32-bit result in Dn.",                           use:"Multiply unsigned values — table indices, offsets, sizes." },
        "divs":   { hex:"—", bytes:2, cycles:158,format:"DIVS.W src,Dn",     mode:"Signed 32/16 divide. Quotient in low word, remainder in high word.",     use:"Signed division — beware divide-by-zero traps on real hardware." },
        "divu":   { hex:"—", bytes:2, cycles:140,format:"DIVU.W src,Dn",     mode:"Unsigned 32/16 divide. Quotient in low word, remainder in high word.",   use:"Unsigned division — same divide-by-zero caveat as DIVS." },

        "neg":    { hex:"—", bytes:2, cycles:4,  format:"NEG.size dst",      mode:"Negates dst (two's complement). Sets all condition codes.",              use:"Flip the sign of a value in place." },
        "negx":   { hex:"—", bytes:2, cycles:4,  format:"NEGX.size dst",     mode:"Negates dst including the extend (X) flag.",                             use:"Sign-flip as part of a multi-word negate chain." },

        "cmp":    { hex:"—", bytes:2, cycles:4,  format:"CMP.size src,Dn",   mode:"Compares src against Dn, sets flags only — Dn unchanged.",               use:"Check equality/ordering before a conditional branch (Bcc)." },
        "cmpa":   { hex:"—", bytes:2, cycles:6,  format:"CMPA.size src,An",  mode:"Compares src against An, sets flags only — An unchanged.",               use:"Check a pointer against a limit (e.g. end-of-buffer test)." },
        "cmpi":   { hex:"—", bytes:4, cycles:8,  format:"CMPI.size #data,dst", mode:"Compares an immediate constant against dst.",                          use:"Check a memory variable against a known fixed value." },
        "cmpm":   { hex:"—", bytes:2, cycles:12, format:"CMPM.size (Ay)+,(Ax)+", mode:"Compares two memory locations, both post-incremented.",              use:"Compare two buffers byte-by-byte, e.g. string/array equality." },
        "tst":    { hex:"—", bytes:2, cycles:4,  format:"TST.size dst",      mode:"Compares dst against zero, sets N and Z flags only.",                    use:"Quick zero/non-zero or sign check without altering dst." }
    };

    var _found = variable_struct_exists(_map, _key);

    if (_found) {
        return _map[$ _key];
    } else {
        return undefined;
    }
}