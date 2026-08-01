/// @desc scr_opcode_helper_68k_part2(_key)
/// Second bank of tooltip data — merged into the same lookup by scr_opcode_lookup.
function scr_opcode_helper_68k_part2(_key) {
    static _map = {
        "and":  { hex:"—", bytes:2, cycles:4, format:"AND.size src,dst",  mode:"Bitwise AND, result in dst. Sets N,Z, clears V,C.",              use:"Mask off unwanted bits in a value." },
        "andi": { hex:"—", bytes:4, cycles:8, format:"ANDI.size #data,dst", mode:"Bitwise AND with an immediate constant.",                     use:"Mask a memory variable against a fixed bit pattern." },
        "or":   { hex:"—", bytes:2, cycles:4, format:"OR.size src,dst",   mode:"Bitwise OR, result in dst. Sets N,Z, clears V,C.",               use:"Set specific bits in a value." },
        "ori":  { hex:"—", bytes:4, cycles:8, format:"ORI.size #data,dst", mode:"Bitwise OR with an immediate constant.",                        use:"Set fixed bits in a memory variable." },
        "eor":  { hex:"—", bytes:2, cycles:4, format:"EOR.size Dn,dst",   mode:"Bitwise XOR, result in dst. Sets N,Z, clears V,C.",              use:"Toggle specific bits, or fast-clear a register (EOR Dn,Dn)." },
        "eori": { hex:"—", bytes:4, cycles:8, format:"EORI.size #data,dst", mode:"Bitwise XOR with an immediate constant.",                      use:"Toggle fixed bits in a memory variable." },
        "not":  { hex:"—", bytes:2, cycles:4, format:"NOT.size dst",      mode:"Inverts every bit of dst (one's complement).",                   use:"Flip a bitmask entirely, e.g. building an inverse mask." },

        "asl":  { hex:"—", bytes:2, cycles:6, format:"ASL.size #n/Dn,dst", mode:"Arithmetic shift left. Bit shifted out goes to C and X.",       use:"Multiply by 2 per shift, or pack bits into position." },
        "asr":  { hex:"—", bytes:2, cycles:6, format:"ASR.size #n/Dn,dst", mode:"Arithmetic shift right, sign bit preserved.",                    use:"Signed divide by 2 per shift." },
        "lsl":  { hex:"—", bytes:2, cycles:6, format:"LSL.size #n/Dn,dst", mode:"Logical shift left. Zero fills from the right.",                use:"Unsigned multiply by 2, or bit-position packing." },
        "lsr":  { hex:"—", bytes:2, cycles:6, format:"LSR.size #n/Dn,dst", mode:"Logical shift right. Zero fills from the left.",                use:"Unsigned divide by 2, or extract high bits." },
        "rol":  { hex:"—", bytes:2, cycles:6, format:"ROL.size #n/Dn,dst", mode:"Rotates bits left, wrapping around (not through X).",           use:"Circular bit rotation, e.g. colour-cycling a bit pattern." },
        "ror":  { hex:"—", bytes:2, cycles:6, format:"ROR.size #n/Dn,dst", mode:"Rotates bits right, wrapping around (not through X).",          use:"Circular bit rotation the other direction." },
        "roxl": { hex:"—", bytes:2, cycles:6, format:"ROXL.size #n/Dn,dst", mode:"Rotates left through the X flag.",                             use:"Multi-word rotate chains across registers." },
        "roxr": { hex:"—", bytes:2, cycles:6, format:"ROXR.size #n/Dn,dst", mode:"Rotates right through the X flag.",                            use:"Multi-word rotate chains, opposite direction." },

        "btst": { hex:"—", bytes:2, cycles:4, format:"BTST #n/Dn,dst",    mode:"Tests one bit of dst, result in Z flag. dst unchanged.",         use:"Check a single flag bit without modifying it." },
        "bchg": { hex:"—", bytes:2, cycles:8, format:"BCHG #n/Dn,dst",    mode:"Tests then toggles one bit of dst.",                             use:"Flip a single flag/state bit, e.g. toggling a mode." },
        "bclr": { hex:"—", bytes:2, cycles:10,format:"BCLR #n/Dn,dst",    mode:"Tests then clears one bit of dst.",                              use:"Turn off a single flag bit." },
        "bset": { hex:"—", bytes:2, cycles:8, format:"BSET #n/Dn,dst",    mode:"Tests then sets one bit of dst.",                                use:"Turn on a single flag bit." },
        "tas":  { hex:"—", bytes:2, cycles:4, format:"TAS dst",           mode:"Tests dst then sets its top bit — indivisible (bus-locked) op.", use:"Simple semaphore/lock flag between routines." },

        "bra":  { hex:"—", bytes:2, cycles:10,format:"BRA label",         mode:"Unconditional relative branch.",                                 use:"Goto — jump to a label, short/long range." },
        "bsr":  { hex:"—", bytes:2, cycles:18,format:"BSR label",         mode:"Relative branch that pushes a return address first.",            use:"Call a nearby subroutine, cheaper than JSR for local calls." },
        "bcc":  { hex:"—", bytes:2, cycles:10,format:"Bcc label",         mode:"Conditional relative branch — cc is one of 14 condition codes.", use:"Branch after a CMP/TST based on flags (EQ, NE, GT, LT, etc.)." },
        "dbcc": { hex:"—", bytes:4, cycles:10,format:"DBcc Dn,label",     mode:"Branches while cc is false AND Dn (as counter) hasn't hit -1.", use:"Compact counted loop — decrement-and-branch in one instruction." },
        "scc":  { hex:"—", bytes:2, cycles:4, format:"Scc dst",           mode:"Sets dst to all 1s or all 0s based on condition cc.",            use:"Turn a flag test into a boolean byte value in memory." },
        "jmp":  { hex:"—", bytes:2, cycles:8, format:"JMP dst",           mode:"Unconditional jump to an absolute/indirect effective address.", use:"Jump tables, far jumps beyond branch range." },
        "jsr":  { hex:"—", bytes:2, cycles:16,format:"JSR dst",           mode:"Calls a subroutine at an absolute/indirect address.",            use:"Standard far function call — pair with RTS." },
        "rts":  { hex:"—", bytes:2, cycles:16,format:"RTS",               mode:"Pops the return address and returns from subroutine.",           use:"End of any routine entered via JSR/BSR." },
        "rte":  { hex:"—", bytes:2, cycles:20,format:"RTE",               mode:"Returns from exception — restores SR and PC from stack.",        use:"End of an interrupt/exception handler. Privileged instruction." },

        "trap":  { hex:"—", bytes:2, cycles:34, format:"TRAP #n",        mode:"Software interrupt — vectors to exception handler n (0-15).",   use:"Call AmigaOS/exec functions or custom OS-level services." },
        "link":  { hex:"—", bytes:4, cycles:16, format:"LINK An,#disp",  mode:"Pushes An, sets An=SP, then adjusts SP by disp for locals.",     use:"Set up a stack frame at the start of a subroutine." },
        "unlk":  { hex:"—", bytes:2, cycles:12, format:"UNLK An",        mode:"Restores SP from An, then pops An — undoes LINK.",               use:"Tear down a stack frame before RTS." },
        "nop":   { hex:"—", bytes:2, cycles:4,  format:"NOP",            mode:"No operation — consumes one instruction cycle.",                 use:"Timing padding, or a placeholder while sketching a routine." }
    };

    var _found = variable_struct_exists(_map, _key);

    if (_found) {
        return _map[$ _key];
    } else {
        return undefined;
    }
}