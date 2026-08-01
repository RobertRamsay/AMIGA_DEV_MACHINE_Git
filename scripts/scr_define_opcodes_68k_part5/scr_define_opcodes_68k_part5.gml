function scr_define_opcodes_68k_part5() {
    global.opcode_map[$ "MOVE_USP"] = {
        mnemonic : "MOVE", sizes : ["L"], operand_count : 2,
        src_modes : global.AM_AN + global.AM_IMM, dst_modes : global.AM_AN,
        category : "privileged"
    };

    global.opcode_map[$ "MOVE_SR"] = {
        mnemonic : "MOVE", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_DATA_ALTERABLE, dst_modes : global.AM_DATA_ALTERABLE,
        category : "privileged"
    };

    global.opcode_map[$ "MOVE_CCR"] = {
        mnemonic : "MOVE", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_DATA, dst_modes : global.AM_DATA_ALTERABLE,
        category : "privileged"
    };

    global.opcode_map[$ "ANDI_SR"] = {
        mnemonic : "ANDI", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "EORI_SR"] = {
        mnemonic : "EORI", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ORI_SR"] = {
        mnemonic : "ORI", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ANDI_CCR"] = {
        mnemonic : "ANDI", sizes : ["B"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "EORI_CCR"] = {
        mnemonic : "EORI", sizes : ["B"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ORI_CCR"] = {
        mnemonic : "ORI", sizes : ["B"], operand_count : 2,
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };
}