function scr_define_opcodes_68k_part1() {
    global.opcode_map = {};

    global.opcode_map[$ "MOVE"] = {
        mnemonic : "MOVE",
        sizes : ["B", "W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_DATA_ALTERABLE,
        category : "data_movement"
    };

    global.opcode_map[$ "MOVEA"] = {
        mnemonic : "MOVEA",
        sizes : ["W", "L"],
        operand_count : 2,
        src_modes : global.AM_DATA,
        dst_modes : global.AM_AN,
        category : "data_movement"
    };

    global.opcode_map[$ "MOVEQ"] = {
        mnemonic : "MOVEQ",
        sizes : ["L"],
        operand_count : 2,
        src_modes : global.AM_IMM,
        dst_modes : global.AM_DN,
        category : "data_movement"
    };

    global.opcode_map[$ "MOVEM"] = {
        mnemonic : "MOVEM",
        sizes : ["W", "L"],
        operand_count : 2,
        src_modes : global.AM_CONTROL + global.AM_AN_POSTINC,
        dst_modes : global.AM_CONTROL + global.AM_AN_PREDEC,
        category : "data_movement"
    };

    global.opcode_map[$ "MOVEP"] = {
        mnemonic : "MOVEP",
        sizes : ["W", "L"],
        operand_count : 2,
        src_modes : global.AM_DN + global.AM_AN_DISP,
        dst_modes : global.AM_DN + global.AM_AN_DISP,
        category : "data_movement"
    };

    global.opcode_map[$ "LEA"] = {
        mnemonic : "LEA",
        sizes : ["L"],
        operand_count : 2,
        src_modes : global.AM_CONTROL,
        dst_modes : global.AM_AN,
        category : "data_movement"
    };

    global.opcode_map[$ "PEA"] = {
        mnemonic : "PEA",
        sizes : ["L"],
        operand_count : 1,
        src_modes : global.AM_CONTROL,
        dst_modes : 0,
        category : "data_movement"
    };

    global.opcode_map[$ "CLR"] = {
        mnemonic : "CLR",
        sizes : ["B", "W", "L"],
        operand_count : 1,
        src_modes : global.AM_DATA_ALTERABLE,
        dst_modes : 0,
        category : "data_movement"
    };

    global.opcode_map[$ "EXG"] = {
        mnemonic : "EXG",
        sizes : ["L"],
        operand_count : 2,
        src_modes : global.AM_DN + global.AM_AN,
        dst_modes : global.AM_DN + global.AM_AN,
        category : "data_movement"
    };

    global.opcode_map[$ "SWAP"] = {
        mnemonic : "SWAP",
        sizes : ["W"],
        operand_count : 1,
        src_modes : global.AM_DN,
        dst_modes : 0,
        category : "data_movement"
    };

    global.opcode_map[$ "EXT"] = {
        mnemonic : "EXT",
        sizes : ["W", "L"],
        operand_count : 1,
        src_modes : global.AM_DN,
        dst_modes : 0,
        category : "data_movement"
    };
}