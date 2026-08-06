/// @desc scr_opcode_helper_68k_part3(_key)
/// Third bank of tooltip data — the remaining system/misc mnemonics with no entry yet.
function scr_opcode_helper_68k_part3(_key) {
    static _map = {
        "rtr":     { hex:"—", bytes:2, cycles:20, format:"RTR",        mode:"Pops CCR then the return address, restoring flags and returning.", use:"Return from a routine that also needs to restore condition flags." },
        "chk":     { hex:"—", bytes:2, cycles:10, format:"CHK.W src,Dn", mode:"Traps if Dn is negative or greater than src (bounds check).",      use:"Array/index bounds checking — traps on out-of-range access." },
        "trapv":   { hex:"—", bytes:2, cycles:4,  format:"TRAPV",       mode:"Traps if the V (overflow) flag is set.",                            use:"Catch signed arithmetic overflow right after an ADD/SUB." },
        "reset":   { hex:"—", bytes:2, cycles:132,format:"RESET",       mode:"Asserts the RESET line, resetting external hardware. Privileged.",  use:"Rare — resets peripheral hardware, not the CPU itself." },
        "stop":    { hex:"—", bytes:4, cycles:4,  format:"STOP #data",  mode:"Loads SR with #data then halts until an interrupt occurs. Privileged.", use:"Low-power wait state until the next interrupt." },
        "illegal": { hex:"—", bytes:2, cycles:34, format:"ILLEGAL",     mode:"Forces an illegal instruction trap deliberately.",                  use:"Deliberately trigger a trap — debugging or reserved-opcode marking." },
        "dbra":    { hex:"—", bytes:4, cycles:10, format:"DBRA Dn,label", mode:"Branches back to label while Dn (as counter) hasn't hit -1 — unconditional, no flag test.", use:"The plain counted-loop form of DBcc — decrement Dn, loop until it wraps." }
    };

    var _found = variable_struct_exists(_map, _key);

    if (_found) {
        return _map[$ _key];
    } else {
        return undefined;
    }
}