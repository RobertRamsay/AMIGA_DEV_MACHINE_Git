/// Plain-English hover help for an opcode node on the workspace: the
/// assembled instruction (title), what it does with the node's real values,
/// what each operand's addressing mode means, size / cost and what any
/// hardware register it writes does (scr_amiga_explain_hw_write).
/// scr_opcode_explain_node(node) -> { title, body }.

/// "4660 ($1234)"; small numbers stay plain.
function scr_opcode_explain_number(_value) {
    var _v = floor(_value);
    if (_v >= -9 && _v <= 9) return string(_v);
    if (_v < 0) return string(_v) + " (-$" + scr_number_to_hex_string(-_v) + ")";
    return string(_v) + " ($" + scr_number_to_hex_string(_v) + ")";
}

/// Address -> "COLOR00 (custom chip: Color table 00)" / "CIA-A PRA" / "" for
/// anything ADM has no name for. The table is built once from scr_asm_lang.
function scr_opcode_explain_address_name(_address) {
    if (!variable_global_exists("__explain_hw_names") || global.__explain_hw_names == undefined) {
        var _names = {};
        var _lang = scr_asm_lang_data();
        var _i = 0;
        while (_i < array_length(_lang.hw_order)) {
            var _hw = _lang.hw[$ _lang.hw_order[_i]];
            var _desc = _hw.desc;
            var _gap = string_pos("  ", _desc);
            if (_gap > 0) _desc = string_delete(_desc, 1, _gap + 1);
            if (_hw.kind == "custom") {
                var _key = string($DFF000 + _hw.value);
                if (!variable_struct_exists(_names, _key)) _names[$ _key] = _hw.name + " (custom chip: " + _desc + ")";
            } else if (_hw.kind == "cia") {
                var _ka = string($BFE001 + _hw.value);
                var _kb = string($BFD000 + _hw.value);
                if (!variable_struct_exists(_names, _ka)) _names[$ _ka] = "CIA-A " + _hw.name + " (" + _desc + ")";
                if (!variable_struct_exists(_names, _kb)) _names[$ _kb] = "CIA-B " + _hw.name + " (" + _desc + ")";
            }
            _i += 1;
        }
        global.__explain_hw_names = _names;
    }
    var _k = string(floor(_address));
    if (variable_struct_exists(global.__explain_hw_names, _k)) return global.__explain_hw_names[$ _k];
    if (_address >= 0 && _address < $200000) return "chip RAM";
    if (_address >= $C00000 && _address < $DC0000) return "slow RAM";
    if (_address >= $F80000 && _address <= $FFFFFF) return "Kickstart ROM";
    return "";
}

/// An operand as the node rows show it: addresses and big numbers in hex.
function scr_opcode_explain_operand_text(_node, _side) {
    var _mode = _side == "src" ? _node.addressing_mode_src : _node.addressing_mode_dst;
    var _value = _side == "src" ? _node.operand_src : _node.operand_dst;
    if (_mode == "abs.W") return "$" + scr_number_to_hex_string(_value) + ".W";
    if (_mode == "abs.L") return "$" + scr_number_to_hex_string(_value);
    if (_mode == "#imm") {
        var _v = floor(_value);
        if (_v >= -9 && _v <= 9) return "#" + string(_v);
        return _v < 0 ? "#-$" + scr_number_to_hex_string(-_v) : "#$" + scr_number_to_hex_string(_v);
    }
    if (scr_operand_mode_is_text(_mode)) return scr_format_operand(_mode, _side == "src" ? _node.operand_label_src : _node.operand_label_dst, undefined);
    return scr_format_operand(_mode, _value, _side == "src" ? _node.operand_extra_src : _node.operand_extra_dst);
}

/// "byte" / "word" / "long word" for a size letter.
function scr_opcode_explain_size_word(_size) {
    switch (_size) {
        case "B": return "byte";
        case "W": return "word";
        case "L": return "long word";
    }
    return "";
}

/// Bytes an (An)+ / -(An) step moves for a size (A7 keeps the stack even).
function scr_opcode_explain_step(_size, _reg) {
    if (_size == "L") return 4;
    if (_size == "W") return 2;
    return _reg == 7 ? 2 : 1;
}

function scr_opcode_explain_reg(_mode_letter, _reg) {
    if (_mode_letter == "A" && _reg == 7) return "A7 (the stack pointer)";
    return _mode_letter + string(_reg);
}

/// Short noun for the English sentence ("D3", "the memory A0 points to", "the number 5").
function scr_opcode_explain_noun(_node, _side) {
    var _mode = _side == "src" ? _node.addressing_mode_src : _node.addressing_mode_dst;
    var _value = _side == "src" ? _node.operand_src : _node.operand_dst;
    var _label = _side == "src" ? _node.operand_label_src : _node.operand_label_dst;
    var _extra = _side == "src" ? _node.operand_extra_src : _node.operand_extra_dst;
    var _ix = "";
    if (_mode == "d8(An,Xn)" || _mode == "d8(PC,Xn)") {
        _ix = (_extra.index_register_is_address ? "A" : "D") + string(_extra.index_register);
    }
    switch (_mode) {
        case "Dn": return "D" + string(_value);
        case "An": return scr_opcode_explain_reg("A", _value);
        case "(An)": return "the memory A" + string(_value) + " points to";
        case "(An)+": return "the memory A" + string(_value) + " points to";
        case "-(An)": return "the memory just below A" + string(_value);
        case "d16(An)": return "the memory at A" + string(_value) + (_extra.displacement < 0 ? " - " + string(-_extra.displacement) : " + " + string(_extra.displacement));
        case "d8(An,Xn)": return "the memory at A" + string(_value) + " + " + _ix + (_extra.displacement < 0 ? " - " + string(-_extra.displacement) : " + " + string(_extra.displacement));
        case "abs.W":
        case "abs.L":
            var _name = scr_opcode_explain_address_name(_value);
            var _first = string_pos(" (", _name);
            if (_name != "" && _name != "chip RAM" && _name != "slow RAM" && _name != "Kickstart ROM") {
                return (_first > 0 ? string_copy(_name, 1, _first - 1) : _name) + " ($" + scr_number_to_hex_string(_value) + ")";
            }
            return "address $" + scr_number_to_hex_string(_value);
        case "d16(PC)": return "the memory " + string(_extra.displacement) + " bytes from this instruction";
        case "d8(PC,Xn)": return "the memory at PC + " + _ix + " + " + string(_extra.displacement);
        case "#imm": return "the number " + scr_opcode_explain_number(_value);
        case "LABEL": return "'" + _label + "'";
        case "regs": return "registers " + _label;
    }
    return "?";
}

/// One line saying what the addressing mode does with this operand.
function scr_opcode_explain_mode(_node, _side) {
    var _mode = _side == "src" ? _node.addressing_mode_src : _node.addressing_mode_dst;
    var _value = _side == "src" ? _node.operand_src : _node.operand_dst;
    var _label = _side == "src" ? _node.operand_label_src : _node.operand_label_dst;
    var _extra = _side == "src" ? _node.operand_extra_src : _node.operand_extra_dst;
    var _size = _node.opcode_size;
    var _a = "A" + string(_value);
    switch (_mode) {
        case "Dn": return "Dn, data register direct: works on data register D" + string(_value) + " itself (fast, no memory access).";
        case "An": return "An, address register direct: works on " + scr_opcode_explain_reg("A", _value) + " itself, the register that holds a pointer.";
        case "(An)": return "(An), address register indirect: " + _a + " holds an address; the instruction uses the memory at that address.";
        case "(An)+": return "(An)+, postincrement: uses the memory at the address in " + _a + ", then adds "
            + string(scr_opcode_explain_step(_size, _value)) + " to " + _a + " so it points at the next item (walks forward through a table).";
        case "-(An)": return "-(An), predecrement: first subtracts " + string(scr_opcode_explain_step(_size, _value)) + " from " + _a
            + ", then uses the memory it now points to (pushes onto a stack that grows downwards).";
        case "d16(An)": return "d16(An), address with displacement: the memory at " + _a + " " + (_extra.displacement < 0 ? "minus " + string(-_extra.displacement) : "plus " + string(_extra.displacement))
            + " (-32768 to 32767). " + _a + " itself does not change: handy for fields of a structure, like CUSTOM+offset.";
        case "d8(An,Xn)":
            var _ix = (_extra.index_register_is_address ? "A" : "D") + string(_extra.index_register);
            return "d8(An,Xn), address with index: the memory at " + _a + " + " + _ix + " (its low word, sign-extended) + " + string(_extra.displacement)
                + " (-128 to 127). Good for looking up entry " + _ix + " of a table.";
        case "abs.W": return "abs.W, absolute short: the fixed address $" + scr_number_to_hex_string(_value)
            + " stored as one word (only $0000-$7FFF and the top 32K are reachable). " + scr_opcode_explain_where(_value);
        case "abs.L": return "abs.L, absolute long: the fixed 32-bit address $" + scr_number_to_hex_string(_value) + ". " + scr_opcode_explain_where(_value);
        case "d16(PC)": return "d16(PC), PC relative: the memory " + string(_extra.displacement) + " bytes from this instruction, so the code works wherever it is loaded.";
        case "d8(PC,Xn)": return "d8(PC,Xn), PC relative with index: a table near this instruction, entry chosen by "
            + (_extra.index_register_is_address ? "A" : "D") + string(_extra.index_register) + ".";
        case "#imm": return "#imm, immediate: the number " + scr_opcode_explain_number(_value) + " is stored inside the instruction itself.";
        case "LABEL": return "label: '" + _label + "', the node (or code) carrying that label; vasm works out its address.";
        case "regs": return "register list: " + _label + " (Dn-Dm ranges joined with /), copied as a group.";
    }
    return _mode + ".";
}

function scr_opcode_explain_where(_address) {
    var _name = scr_opcode_explain_address_name(_address);
    if (_name == "") return "";
    if (_name == "chip RAM" || _name == "slow RAM" || _name == "Kickstart ROM") return "That is in " + _name + ".";
    return "That is " + _name + ".";
}

/// Words for a Bcc / DBcc / Scc condition.
function scr_opcode_explain_condition(_cond) {
    switch (_cond) {
        case "EQ": return "the last result was zero (or the compared values were equal)";
        case "NE": return "the last result was not zero (the values were different)";
        case "CC": return "carry is clear (unsigned: higher or same)";
        case "CS": return "carry is set (unsigned: lower)";
        case "GE": return "it was greater or equal (signed)";
        case "GT": return "it was greater (signed)";
        case "LE": return "it was less or equal (signed)";
        case "LT": return "it was less (signed)";
        case "HI": return "it was higher (unsigned)";
        case "LS": return "it was lower or the same (unsigned)";
        case "MI": return "the result was negative";
        case "PL": return "the result was positive or zero";
        case "VC": return "there was no overflow";
        case "VS": return "there was an overflow";
    }
    return "the condition " + _cond + " holds";
}

/// The English sentence: what this instruction does with these operands.
function scr_opcode_explain_action(_node) {
    var _mn = _node.opcode_mnemonic;
    var _s = scr_opcode_explain_noun(_node, "src");
    var _d = scr_opcode_explain_noun(_node, "dst");
    var _z = scr_opcode_explain_size_word(_node.opcode_size);
    var _src_imm = _node.addressing_mode_src == "#imm";

    // Condition families: Bcc, DBcc, Scc.
    var _cc = global.branch_conditions;
    var _i = 0;
    while (_i < array_length(_cc)) {
        var _c = _cc[_i];
        if (_mn == "B" + _c) return "If " + scr_opcode_explain_condition(_c) + ", jumps to " + _s + "; otherwise carries on with the next node. Put it after a CMP, TST or arithmetic node that sets the flags.";
        if (_mn == "DB" + _c) return "Loop end: unless " + scr_opcode_explain_condition(_c) + ", subtracts 1 from the low word of " + _s
            + " and jumps back to " + _d + " until it reaches -1.";
        if (_mn == "S" + _c) return "Sets the byte " + _s + " to $FF if " + scr_opcode_explain_condition(_c) + ", otherwise to $00.";
        _i += 1;
    }

    switch (_mn) {
        case "MOVE":
            if (_src_imm) return "Puts " + _s + " into " + _d + " (one " + _z + ").";
            return "Copies one " + _z + " from " + _s + " into " + _d + ".";
        case "MOVEA": return "Loads " + _s + " into " + _d + (_node.opcode_size == "W" ? " (the word is sign-extended to 32 bits)." : ".") + " Flags are not changed.";
        case "MOVEQ": return "Quickly puts " + _s + " into all 32 bits of " + _d + " (sign-extended; only -128 to 127 fit).";
        case "MOVEM":
            if (_node.addressing_mode_src == "regs") return "Saves " + _s + " to " + _d + " in one go (" + _z + " each).";
            return "Loads " + _d + " from " + _s + " in one go (" + _z + " each).";
        case "MOVEP": return "Copies " + _s + " to " + _d + " one byte at a time to every other address (for 8-bit chips like the CIAs).";
        case "LEA": return "Puts the address of " + _s + " into " + _d + " (nothing is read from memory).";
        case "PEA": return "Pushes the address of " + _s + " onto the stack.";
        case "CLR": return "Sets " + _s + " to zero (one " + _z + ").";
        case "EXG": return "Swaps the contents of " + _s + " and " + _d + ".";
        case "SWAP": return "Swaps the upper and lower 16-bit halves of " + _s + ".";
        case "EXT": return "Sign-extends " + _s + (_node.opcode_size == "W" ? ": its low byte becomes a word." : ": its low word becomes a long word.");
        case "ADD": case "ADDA": case "ADDI": case "ADDQ":
            return "Adds " + _s + " to " + _d + " (one " + _z + ")." + (_mn == "ADDA" ? " Flags are not changed." : "");
        case "ADDX": return "Adds " + _s + " and the X (extend) flag to " + _d + ": the next part of a number wider than 32 bits.";
        case "SUB": case "SUBA": case "SUBI": case "SUBQ":
            return "Subtracts " + _s + " from " + _d + " (one " + _z + ").";
        case "SUBX": return "Subtracts " + _s + " and the X (extend) flag from " + _d + ": the next part of a number wider than 32 bits.";
        case "MULS": return "Multiplies the low word of " + _d + " by " + _s + " (signed); the 32-bit result goes into " + _d + ".";
        case "MULU": return "Multiplies the low word of " + _d + " by " + _s + " (unsigned); the 32-bit result goes into " + _d + ".";
        case "DIVS": return "Divides all 32 bits of " + _d + " by " + _s + " (signed): the answer goes in the low word of " + _d + ", the remainder in its high word.";
        case "DIVU": return "Divides all 32 bits of " + _d + " by " + _s + " (unsigned): the answer goes in the low word of " + _d + ", the remainder in its high word.";
        case "NEG": return "Negates " + _s + " (it becomes 0 minus itself).";
        case "NEGX": return "Negates " + _s + " including the X flag (for numbers wider than 32 bits).";
        case "CMP": case "CMPA": case "CMPI": case "CMPM":
            return "Compares " + _d + " with " + _s + " (works out " + _d + " minus it) and only sets the flags; nothing changes. A Bcc node after it acts on the result.";
        case "TST": return "Tests " + _s + ": sets the flags as if comparing it with zero (Z when zero, N when negative). Nothing changes.";
        case "AND": case "ANDI": return "Keeps only the bits of " + _d + " that are also set in " + _s + " (" + _d + " AND it).";
        case "OR": case "ORI": return "Turns on in " + _d + " every bit that is set in " + _s + " (" + _d + " OR it).";
        case "EOR": case "EORI": return "Flips in " + _d + " every bit that is set in " + _s + " (" + _d + " XOR it).";
        case "NOT": return "Flips every bit of " + _s + ".";
        case "BTST": return "Tests bit " + (_src_imm ? string(_node.operand_src) : "(" + _s + ")") + " of " + _d + ": Z is set when that bit is 0. Nothing changes.";
        case "BCHG": return "Flips bit " + (_src_imm ? string(_node.operand_src) : "(" + _s + ")") + " of " + _d + " (Z shows its old value).";
        case "BCLR": return "Clears bit " + (_src_imm ? string(_node.operand_src) : "(" + _s + ")") + " of " + _d + " to 0 (Z shows its old value).";
        case "BSET": return "Sets bit " + (_src_imm ? string(_node.operand_src) : "(" + _s + ")") + " of " + _d + " to 1 (Z shows its old value).";
        case "TAS": return "Tests the byte " + _s + " and sets its top bit in one uninterruptible step.";
        case "BRA": return "Always jumps to " + _s + ". Pointing it back up the program makes a loop that runs forever.";
        case "BSR": return "Calls the subroutine " + _s + ": pushes the return address, and its RTS comes back to the node after this one.";
        case "DBRA": return "Loop end: subtracts 1 from the low word of " + _s + " and jumps back to " + _d + " until it reaches -1, so the loop runs " + _s + " + 1 times.";
        case "JMP": return "Jumps to " + _s + ".";
        case "JSR": return "Calls the subroutine at " + _s + "; its RTS comes back to the node after this one.";
        case "RTS": return "Returns from a subroutine to the node after the BSR / JSR that called it.";
        case "RTE": return "Returns from an interrupt or exception (restores SR and PC; supervisor mode only).";
        case "RTR": return "Restores the flags from the stack, then returns from a subroutine.";
        case "CHK": return "Raises exception 6 if " + _d + " is below 0 or above " + _s + " (an array bounds check).";
        case "TRAP": return "Calls trap vector " + string(_node.operand_src) + ": a software interrupt into supervisor mode.";
        case "TRAPV": return "Raises the TRAPV exception if the V (overflow) flag is set.";
        case "LINK": return "Makes a stack frame: pushes " + _s + ", copies the stack pointer into it, then adds " + string(_node.operand_dst) + " to the stack pointer (negative reserves room for locals).";
        case "UNLK": return "Removes the stack frame made by LINK: the stack pointer comes back from " + _s + ", then " + _s + " is restored.";
        case "NOP": return "Does nothing for one instruction (4 cycles)." + (_node.node_label != "" ? " Its label '" + _node.node_label + "' gives branches a safe place to land." : "");
        case "RESET": return "Resets the external hardware, not the CPU (supervisor mode only).";
        case "STOP": return "Loads " + _s + " into the status register and waits for an interrupt (supervisor mode only).";
        case "ILLEGAL": return "Raises the illegal-instruction exception on purpose (a breakpoint / crash marker).";
        case "MOVE_SR": return "Copies " + _s + " into the status register: the interrupt level and the flags (supervisor mode only).";
        case "MOVE_CCR": return "Copies the low byte of " + _s + " into the flags (X N Z V C).";
        case "MOVE_USP": return "Copies " + _s + " into the user stack pointer (supervisor mode only).";
        case "ANDI_SR": return "ANDs " + _s + " into the status register: clears bits there, such as raising the interrupt mask (supervisor mode only).";
        case "ORI_SR": return "ORs " + _s + " into the status register: sets bits there, such as the interrupt mask (supervisor mode only).";
        case "EORI_SR": return "Flips the status register bits set in " + _s + " (supervisor mode only).";
        case "ANDI_CCR": return "ANDs " + _s + " into the flags: clears the flags whose bits are 0.";
        case "ORI_CCR": return "ORs " + _s + " into the flags: sets the flags whose bits are 1.";
        case "EORI_CCR": return "Flips the flags whose bits are set in " + _s + ".";
    }

    // Shifts and rotates.
    var _memory = scr_opcode_is_memory_shift(_node);
    var _by = _memory ? "1 bit" : (_src_imm ? string(_node.operand_src) + " bit" + (_node.operand_src == 1 ? "" : "s") : "the count in " + _s + " (0-63)");
    var _target = _memory ? "the word " + _d : _d;
    switch (_mn) {
        case "ASL": return "Shifts " + _target + " left by " + _by + "; each step doubles it (signed).";
        case "LSL": return "Shifts " + _target + " left by " + _by + ", filling with zeros; each step doubles it.";
        case "ASR": return "Shifts " + _target + " right by " + _by + ", keeping the sign; each step halves a signed number.";
        case "LSR": return "Shifts " + _target + " right by " + _by + ", filling with zeros; each step halves an unsigned number.";
        case "ROL": return "Rotates " + _target + " left by " + _by + "; bits leaving the top come back in at the bottom.";
        case "ROR": return "Rotates " + _target + " right by " + _by + "; bits leaving the bottom come back in at the top.";
        case "ROXL": return "Rotates " + _target + " left by " + _by + " through the X flag (a 33-bit rotate).";
        case "ROXR": return "Rotates " + _target + " right by " + _by + " through the X flag (a 33-bit rotate).";
    }
    return "";
}

function scr_opcode_explain_node(_node) {
    var _entry = global.opcode_map[$ _node.opcode_mnemonic];
    var _emit = scr_emit_opcode_line(_node);
    // The title is the instruction as the node rows show it (addresses in hex).
    var _memory_shift = scr_opcode_is_memory_shift(_node);
    var _count = _entry == undefined ? 0 : _entry.operand_count;
    var _title = _entry == undefined ? _node.opcode_mnemonic : _entry.mnemonic;
    if (_entry != undefined && array_length(_entry.sizes) > 0) _title += "." + _node.opcode_size;
    if (_count >= 1 && !_memory_shift) _title += " " + scr_opcode_explain_operand_text(_node, "src");
    if (_count >= 2) _title += (_memory_shift ? " " : ",") + scr_opcode_explain_operand_text(_node, "dst");
    if (_entry != undefined && variable_struct_exists(_entry, "fixed_dst")) _title += "," + _entry.fixed_dst;
    if (_node.node_label != "") _title = _node.node_label + ":  " + _title;

    var _body = "";
    if (!_emit.is_valid) {
        _body = "NOT VALID YET: " + string_replace(_emit.text, "; ERROR: ", "") + "\n";
        _title = _node.opcode_mnemonic;
    } else {
        _body = scr_opcode_explain_action(_node) + "\n";
    }

    if (_count >= 1 && !_memory_shift) _body += (_count >= 2 ? "SOURCE: " : "OPERAND: ") + scr_opcode_explain_mode(_node, "src") + "\n";
    if (_count >= 2) _body += "DESTINATION: " + scr_opcode_explain_mode(_node, "dst") + "\n";

    var _facts = "";
    if (_entry != undefined && array_length(_entry.sizes) > 0) {
        var _bits = _node.opcode_size == "B" ? 8 : (_node.opcode_size == "W" ? 16 : 32);
        _facts = "SIZE: ." + _node.opcode_size + " = " + scr_opcode_explain_size_word(_node.opcode_size) + " (" + string(_bits) + " bits)";
    }
    var _help = scr_opcode_lookup(_node.opcode_mnemonic);
    if (_help != undefined) {
        _facts += (_facts == "" ? "" : "     ") + "COST: about " + string(_help.cycles) + " cycles, " + string(_help.bytes) + "+ bytes";
    }
    if (_facts != "") _body += _facts + "\n";

    var _hw = scr_amiga_explain_hw_write(_node);
    if (_hw != "") _body += "HARDWARE: " + _hw + "\n";

    if (!_node.is_connected) {
        _body += "Not in the program yet: drop it under INIT/BUILD (or an ORG column) and it runs in order from top to bottom.";
    }
    return { title : _title, body : string_trim(_body) };
}
