/// Status-register and USP instructions. Their second operand is always the
/// same register, so the node has one operand row and fixed_dst names the
/// register scr_emit_opcode_line appends ("MOVE.W D0,SR").
function scr_define_opcodes_68k_part5() {
    global.opcode_map[$ "MOVE_USP"] = {
        mnemonic : "MOVE", sizes : ["L"], operand_count : 1, fixed_dst : "USP",
        src_modes : global.AM_AN, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "MOVE_SR"] = {
        mnemonic : "MOVE", sizes : ["W"], operand_count : 1, fixed_dst : "SR",
        src_modes : global.AM_DATA, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "MOVE_CCR"] = {
        mnemonic : "MOVE", sizes : ["W"], operand_count : 1, fixed_dst : "CCR",
        src_modes : global.AM_DATA, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ANDI_SR"] = {
        mnemonic : "ANDI", sizes : ["W"], operand_count : 1, fixed_dst : "SR",
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "EORI_SR"] = {
        mnemonic : "EORI", sizes : ["W"], operand_count : 1, fixed_dst : "SR",
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ORI_SR"] = {
        mnemonic : "ORI", sizes : ["W"], operand_count : 1, fixed_dst : "SR",
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ANDI_CCR"] = {
        mnemonic : "ANDI", sizes : ["B"], operand_count : 1, fixed_dst : "CCR",
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "EORI_CCR"] = {
        mnemonic : "EORI", sizes : ["B"], operand_count : 1, fixed_dst : "CCR",
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };

    global.opcode_map[$ "ORI_CCR"] = {
        mnemonic : "ORI", sizes : ["B"], operand_count : 1, fixed_dst : "CCR",
        src_modes : global.AM_IMM, dst_modes : 0,
        category : "privileged"
    };
}
