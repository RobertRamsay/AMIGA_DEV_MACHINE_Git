function scr_define_opcodes_68k_part2() {
    global.opcode_map[$ "ADD"] = {
        mnemonic : "ADD",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "arithmetic"
    };

    global.opcode_map[$ "ADDA"] = {
        mnemonic : "ADDA",
        sizes : ["W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_AN,
        category : "arithmetic"
    };

    global.opcode_map[$ "ADDI"] = {
        mnemonic : "ADDI",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_IMM,
        dst_modes : global.AM_DATA_ALTERABLE,
        category : "arithmetic"
    };

    global.opcode_map[$ "ADDQ"] = {
        mnemonic : "ADDQ",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_IMM,
        dst_modes : global.AM_DATA_ALTERABLE + global.AM_AN,
        category : "arithmetic"
    };

    global.opcode_map[$ "ADDX"] = {
        mnemonic : "ADDX",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_DN + global.AM_AN_PREDEC,
        dst_modes : global.AM_DN + global.AM_AN_PREDEC,
        category : "arithmetic"
    };

    global.opcode_map[$ "SUB"] = {
        mnemonic : "SUB",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN + global.AM_MEMORY_ALTERABLE,
        category : "arithmetic"
    };

    global.opcode_map[$ "SUBA"] = {
        mnemonic : "SUBA",
        sizes : ["W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_AN,
        category : "arithmetic"
    };

    global.opcode_map[$ "SUBI"] = {
        mnemonic : "SUBI",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_IMM,
        dst_modes : global.AM_DATA_ALTERABLE,
        category : "arithmetic"
    };

    global.opcode_map[$ "SUBQ"] = {
        mnemonic : "SUBQ",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_IMM,
        dst_modes : global.AM_DATA_ALTERABLE + global.AM_AN,
        category : "arithmetic"
    };

    global.opcode_map[$ "SUBX"] = {
        mnemonic : "SUBX",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_DN + global.AM_AN_PREDEC,
        dst_modes : global.AM_DN + global.AM_AN_PREDEC,
        category : "arithmetic"
    };

    global.opcode_map[$ "MULS"] = {
        mnemonic : "MULS",
        sizes : ["W"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN,
        category : "arithmetic"
    };

    global.opcode_map[$ "MULU"] = {
        mnemonic : "MULU",
        sizes : ["W"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN,
        category : "arithmetic"
    };

    global.opcode_map[$ "DIVS"] = {
        mnemonic : "DIVS",
        sizes : ["W"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN,
        category : "arithmetic"
    };

    global.opcode_map[$ "DIVU"] = {
        mnemonic : "DIVU",
        sizes : ["W"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN,
        category : "arithmetic"
    };

    global.opcode_map[$ "NEG"] = {
        mnemonic : "NEG",
        sizes : ["B", "W", "L"],
        operand_count : 1,
        src_modes : global.AM_DATA_ALTERABLE,
        dst_modes : 0,
        category : "arithmetic"
    };

    global.opcode_map[$ "NEGX"] = {
        mnemonic : "NEGX",
        sizes : ["B", "W", "L"],
        operand_count : 1,
        src_modes : global.AM_DATA_ALTERABLE,
        dst_modes : 0,
        category : "arithmetic"
    };

    global.opcode_map[$ "CMP"] = {
        mnemonic : "CMP",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DN,
        category : "arithmetic"
    };

    global.opcode_map[$ "CMPA"] = {
        mnemonic : "CMPA",
        sizes : ["W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_AN,
        category : "arithmetic"
    };

    global.opcode_map[$ "CMPI"] = {
        mnemonic : "CMPI",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_IMM,
        dst_modes : global.AM_DATA_ALTERABLE,
        category : "arithmetic"
    };

    global.opcode_map[$ "CMPM"] = {
        mnemonic : "CMPM",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_AN_POSTINC,
        dst_modes : global.AM_AN_POSTINC,
        category : "arithmetic"
    };

    global.opcode_map[$ "TST"] = {
        mnemonic : "TST",
        sizes : ["B", "W", "L"],
        operand_count : 1,
        src_modes : global.AM_DATA_ALTERABLE,
        dst_modes : 0,
        category : "arithmetic"
    };
}