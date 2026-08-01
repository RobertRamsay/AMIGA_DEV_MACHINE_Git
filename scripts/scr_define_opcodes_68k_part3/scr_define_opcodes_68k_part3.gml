function scr_define_opcodes_68k_part3() {
    global.opcode_map[$ "AND"] = {
        mnemonic : "AND", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DATA, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "logic"
    };

    global.opcode_map[$ "ANDI"] = {
        mnemonic : "ANDI", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "logic"
    };

    global.opcode_map[$ "OR"] = {
        mnemonic : "OR", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DATA, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "logic"
    };

    global.opcode_map[$ "ORI"] = {
        mnemonic : "ORI", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "logic"
    };

    global.opcode_map[$ "EOR"] = {
        mnemonic : "EOR", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN, dst_modes : global.AM_DATA_ALTERABLE,
        category : "logic"
    };

    global.opcode_map[$ "EORI"] = {
        mnemonic : "EORI", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "logic"
    };

    global.opcode_map[$ "NOT"] = {
        mnemonic : "NOT", sizes : ["B", "W", "L"], operand_count : 1,
        src_modes : global.AM_DATA_ALTERABLE, dst_modes : 0,
        category : "logic"
    };

    global.opcode_map[$ "ASL"] = {
        mnemonic : "ASL", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "ASR"] = {
        mnemonic : "ASR", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "LSL"] = {
        mnemonic : "LSL", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "LSR"] = {
        mnemonic : "LSR", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "ROL"] = {
        mnemonic : "ROL", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "ROR"] = {
        mnemonic : "ROR", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "ROXL"] = {
        mnemonic : "ROXL", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "ROXR"] = {
        mnemonic : "ROXR", sizes : ["B", "W", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "shift"
    };

    global.opcode_map[$ "BTST"] = {
        mnemonic : "BTST", sizes : ["B", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "bit"
    };

    global.opcode_map[$ "BCHG"] = {
        mnemonic : "BCHG", sizes : ["B", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "bit"
    };

    global.opcode_map[$ "BCLR"] = {
        mnemonic : "BCLR", sizes : ["B", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "bit"
    };

    global.opcode_map[$ "BSET"] = {
        mnemonic : "BSET", sizes : ["B", "L"], operand_count : 2,
        src_modes : global.AM_DN + global.AM_IMM, dst_modes : global.AM_DATA_ALTERABLE,
        category : "bit"
    };

    global.opcode_map[$ "TAS"] = {
        mnemonic : "TAS", sizes : ["B"], operand_count : 1,
        src_modes : global.AM_DATA_ALTERABLE, dst_modes : 0,
        category : "bit"
    };
}