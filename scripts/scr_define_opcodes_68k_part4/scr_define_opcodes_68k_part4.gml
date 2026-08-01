function scr_define_opcodes_68k_part4() {
    global.opcode_map[$ "BRA"] = {
        mnemonic : "BRA", sizes : ["B", "W"], operand_count : 1,
        src_modes : global.AM_CONTROL, dst_modes : 0, category : "branch"
    };

    global.opcode_map[$ "BSR"] = {
        mnemonic : "BSR", sizes : ["B", "W"], operand_count : 1,
        src_modes : global.AM_CONTROL, dst_modes : 0, category : "branch"
    };

    // Bcc covers BEQ, BNE, BCC, BCS, BGE, BGT, BLE, BLT, BHI, BLS, BMI, BPL, BVC, BVS
    global.branch_conditions = ["EQ", "NE", "CC", "CS", "GE", "GT", "LE", "LT", "HI", "LS", "MI", "PL", "VC", "VS"];

    var _bc_index = 0;
    var _bc_count = array_length(global.branch_conditions);

    while (_bc_index < _bc_count) {
        var _cond = global.branch_conditions[_bc_index];
        var _mnemonic_bcc = "B" + _cond;

        global.opcode_map[$ _mnemonic_bcc] = {
            mnemonic : _mnemonic_bcc, sizes : ["B", "W"], operand_count : 1,
            src_modes : global.AM_CONTROL, dst_modes : 0, category : "branch"
        };

        var _mnemonic_dbcc = "DB" + _cond;

        global.opcode_map[$ _mnemonic_dbcc] = {
            mnemonic : _mnemonic_dbcc, sizes : ["W"], operand_count : 2,
            src_modes : global.AM_DN, dst_modes : global.AM_CONTROL, category : "branch"
        };

        var _mnemonic_scc = "S" + _cond;

        global.opcode_map[$ _mnemonic_scc] = {
            mnemonic : _mnemonic_scc, sizes : ["B"], operand_count : 1,
            src_modes : global.AM_DATA_ALTERABLE, dst_modes : 0, category : "branch"
        };

        _bc_index += 1;
    }

    global.opcode_map[$ "DBRA"] = {
        mnemonic : "DBRA", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_DN, dst_modes : global.AM_CONTROL, category : "branch"
    };

    global.opcode_map[$ "JMP"] = {
        mnemonic : "JMP", sizes : ["L"], operand_count : 1,
        src_modes : global.AM_CONTROL, dst_modes : 0, category : "branch"
    };

    global.opcode_map[$ "JSR"] = {
        mnemonic : "JSR", sizes : ["L"], operand_count : 1,
        src_modes : global.AM_CONTROL, dst_modes : 0, category : "branch"
    };

    global.opcode_map[$ "RTS"] = {
        mnemonic : "RTS", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "branch"
    };

    global.opcode_map[$ "RTE"] = {
        mnemonic : "RTE", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "RTR"] = {
        mnemonic : "RTR", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "branch"
    };

    global.opcode_map[$ "CHK"] = {
        mnemonic : "CHK", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_DATA, dst_modes : global.AM_DN, category : "branch"
    };

    global.opcode_map[$ "TRAP"] = {
        mnemonic : "TRAP", sizes : [], operand_count : 1,
        src_modes : global.AM_IMM, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "TRAPV"] = {
        mnemonic : "TRAPV", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "LINK"] = {
        mnemonic : "LINK", sizes : ["W"], operand_count : 2,
        src_modes : global.AM_AN, dst_modes : global.AM_IMM, category : "system"
    };

    global.opcode_map[$ "UNLK"] = {
        mnemonic : "UNLK", sizes : [], operand_count : 1,
        src_modes : global.AM_AN, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "NOP"] = {
        mnemonic : "NOP", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "RESET"] = {
        mnemonic : "RESET", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "STOP"] = {
        mnemonic : "STOP", sizes : [], operand_count : 1,
        src_modes : global.AM_IMM, dst_modes : 0, category : "system"
    };

    global.opcode_map[$ "ILLEGAL"] = {
        mnemonic : "ILLEGAL", sizes : [], operand_count : 0,
        src_modes : 0, dst_modes : 0, category : "system"
    };
}