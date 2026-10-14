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
