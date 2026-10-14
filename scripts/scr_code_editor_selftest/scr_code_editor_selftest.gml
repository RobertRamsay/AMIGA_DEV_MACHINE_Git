/// @desc Checks of the code editor's typing aids and CODE block names, run by
/// -admselftest. Opens the editor on a throwaway CODE node, drives its
/// methods directly and returns an array of failure strings (empty = pass).
function scr_code_editor_selftest() {
    var _fail = [];
    var _keep_autoclose = global.code_editor_autoclose;
    global.code_editor_autoclose = true;

    var _node = instance_create_layer(-5000, -5000, "Instances", obj_opcode_node);
    scr_macro_node_init(_node, "CODE");
    var _ed = scr_code_editor_open(_node);

    with (_ed) {

        // ( gets its partner, the caret sits between them.
        lines = ["\tmove.w\t"];
        ed_set_caret(0, 8, false);
        if (!ed_type_autoclose("(")) array_push(_fail, "autoclose ( not applied");
        scr_code_editor_selftest_check(_fail, "autoclose (", lines[0], "\tmove.w\t()");
        scr_code_editor_selftest_check(_fail, "autoclose ( caret", caret_col, 9);

        // Typing the closer steps over it.
        ed_type_text("a0");
        ed_type_autoclose(")");
        scr_code_editor_selftest_check(_fail, "overtype )", lines[0], "\tmove.w\t(a0)");
        scr_code_editor_selftest_check(_fail, "overtype ) caret", caret_col, 12);

        // Backspace in an empty pair removes both.
        lines = ["x()"];
        ed_set_caret(0, 2, false);
        if (!ed_backspace_pair()) array_push(_fail, "backspace pair not applied");
        scr_code_editor_selftest_check(_fail, "backspace pair", lines[0], "x");

        // A quote after a word character stays a single apostrophe.
        lines = ["it"];
        ed_set_caret(0, 2, false);
        if (ed_type_autoclose("'")) array_push(_fail, "apostrophe was paired");

        // Nothing pairs inside a comment.
        lines = ["; note "];
        ed_set_caret(0, 7, false);
        if (ed_type_autoclose("(")) array_push(_fail, "paired inside a comment");

        // A selection is wrapped.
        lines = ["\tdc.b\thello"];
        ed_set_caret(0, 6, false);
        ed_set_caret(0, 11, true);
        ed_type_autoclose("\"");
        scr_code_editor_selftest_check(_fail, "wrap selection", lines[0], "\tdc.b\t\"hello\"");

        // Ctrl+/ treats a column-1 * line as a comment and uncomments it.
        lines = ["* old style", "; new style"];
        ed_set_caret(0, 0, false);
        ed_set_caret(1, 3, true);
        ed_toggle_comment();
        scr_code_editor_selftest_check(_fail, "uncomment *", lines[0], "old style");
        scr_code_editor_selftest_check(_fail, "uncomment ;", lines[1], "new style");

        // The name reaches the node, the preview title and main.s.
        name_text = "  Screen setup ";
        ed_commit_name();
        scr_code_editor_selftest_check(_fail, "name on node", editor_node.macro_code_name, "Screen setup");
        ed_close(false);
    }

    scr_code_editor_selftest_check(_fail, "preview title", scr_macro_preview_title(_node), "Screen setup");
    scr_code_editor_selftest_check(_fail, "describe", scr_amiga_describe_node(_node), "CODE: Screen setup");
    var _emit = scr_emit_macro_code(_node).text;
    scr_code_editor_selftest_check(_fail, "main.s name comment", string_copy(_emit, 1, string_pos("\n", _emit) - 1), "\t; ---- CODE: Screen setup ----");

    with (_node) instance_destroy();
    global.code_editor_autoclose = _keep_autoclose;
    return _fail;
}

function scr_code_editor_selftest_check(_fail, _name, _got, _want) {
    if (_got != _want) array_push(_fail, _name + ": got [" + string(_got) + "] want [" + string(_want) + "]");
}

/// Opcode nodes that the mode table alone used to get wrong: the emitted
/// text, or the validator's verdict. Returns failure strings.
function scr_opcode_rules_selftest() {
    var _fail = [];
    var _node = instance_create_layer(-5000, -5000, "Instances", obj_opcode_node);
    var _cases = [
        // mnemonic, size, src mode, src value, dst mode, dst value, src text, dst text, expected text ("" = invalid)
        ["MOVE_SR", "W", "Dn", 0, "", 0, "", "", "\tMOVE.W D0,SR"],
        ["ANDI_SR", "W", "#imm", 63743, "", 0, "", "", "\tANDI.W #63743,SR"],
        ["ORI_CCR", "B", "#imm", 4, "", 0, "", "", "\tORI.B #4,CCR"],
        ["MOVE_USP", "L", "An", 1, "", 0, "", "", "\tMOVE.L A1,USP"],
        ["MOVEM", "L", "regs", 0, "-(An)", 7, "d0-d7/a0-a6", "", "\tMOVEM.L d0-d7/a0-a6,-(A7)"],
        ["MOVEM", "L", "(An)+", 7, "regs", 0, "", "d0/d2-d3", "\tMOVEM.L (A7)+,d0/d2-d3"],
        ["MOVEM", "L", "regs", 0, "-(An)", 7, "d0-d9", "", ""],
        ["MOVEM", "L", "(An)+", 7, "-(An)", 6, "", "", ""],
        ["MOVEQ", "L", "#imm", 127, "Dn", 0, "", "", "\tMOVEQ.L #127,D0"],
        ["MOVEQ", "L", "#imm", 200, "Dn", 0, "", "", ""],
        ["ADDQ", "W", "#imm", 8, "Dn", 1, "", "", "\tADDQ.W #8,D1"],
        ["ADDQ", "W", "#imm", 9, "Dn", 1, "", "", ""],
        ["SUBQ", "B", "#imm", 1, "An", 0, "", "", ""],
        ["ASL", "W", "#imm", 1, "(An)", 0, "", "", "\tASL.W (A0)"],
        ["ASL", "L", "#imm", 1, "(An)", 0, "", "", ""],
        ["LSR", "W", "#imm", 9, "Dn", 0, "", "", ""],
        ["JMP", "L", "(An)", 0, "", 0, "", "", "\tJMP (A0)"]
    ];
    var _i = 0;
    while (_i < array_length(_cases)) {
        var _c = _cases[_i];
        _node.is_macro = false;
        _node.node_label = "";
        _node.opcode_mnemonic = _c[0];
        _node.opcode_size = _c[1];
        _node.addressing_mode_src = _c[2];
        _node.operand_src = _c[3];
        _node.addressing_mode_dst = _c[4];
        _node.operand_dst = _c[5];
        _node.operand_label_src = _c[6];
        _node.operand_label_dst = _c[7];
        var _out = scr_emit_opcode_line(_node);
        var _got = _out.is_valid ? _out.text : "";
        if (_got != _c[8]) array_push(_fail, _c[0] + " case " + string(_i) + ": got [" + _out.text + "] want [" + _c[8] + "]");
        _i += 1;
    }
    with (_node) instance_destroy();
    return _fail;
}
