// obj_code_editor - full-screen modal 68000 / vasm source editor for one
// CODE node. Created by scr_code_editor_open(_node). All positions are
// 0-based (line, col); the text is an array of line strings with tabs
// expanded to spaces.

depth = -400000;

// ---- node binding ----
// Course mode (scr_code_editor_open_course): no node; the text belongs to a
// 68K course lesson, the panel ends at course_x2 (obj_course draws the lesson
// beside it), F5 runs the lesson's tests and CLOSE goes back to the map.
course_mode = false;
course_x2 = room_width - 40;
editor_node = noone;
editor_node_uid = -1;
editor_title = "CODE";
// The block's name (macro_code_name), edited in the title bar field.
name_text = "";
name_field_rect = [0, 0, 0, 0];
committed_text = "";

// ---- text model ----
lines = [""];
caret_line = 0;
caret_col = 0;
anchor_line = 0;
anchor_col = 0;
desired_col = 0;
tab_width = 8;
text_revision = 0;
max_line_len = 0;
max_len_revision = -1;
ensure_visible = true;

// ---- view ----
scroll_line = 0;
scroll_col = 0;
font_size = global.code_editor_font_pref_size;
code_font = scr_code_editor_font_ensure(font_size);
font_is_mono = global.code_editor_font_is_mono;
char_w = 8;
line_h = 16;
ui_h = 16;
blink_timer = 0;

// ---- layout (recomputed every step by ed_layout) ----
panel_x1 = 40;
panel_y1 = 24;
panel_x2 = room_width - 40;
panel_y2 = room_height - 24;
title_y1 = 0;
title_y2 = 0;
toolbar_y1 = 0;
toolbar_y2 = 0;
findbar_y1 = 0;
findbar_y2 = 0;
text_top = 0;
text_bottom = 0;
text_x = 0;
text_right = 0;
gutter_x = 0;
gutter_w = 0;
vis_lines = 1;
vis_cols = 1;
vbar_x1 = 0;
vbar_x2 = 0;
hbar_y1 = 0;
hbar_y2 = 0;
status_y1 = 0;
buttons = [];
find_field_rect = [0, 0, 0, 0];
replace_field_rect = [0, 0, 0, 0];
goto_field_rect = [0, 0, 0, 0];

// ---- undo ----
undo_stack = [];
redo_stack = [];
undo_max = 400;
undo_group_kind = "";
undo_group_time = 0;
undo_group_line = -1;

// ---- analysis / diagnostics ----
analysis = scr_asm_analyse_lines([""], []);
analysed_revision = -1;
analysis_due = 0;
known_symbols = {};
global_symbol_list = [];
completion_locals = [];
diag_all = [];
diag_by_line = {};
diag_error_count = 0;
diag_warning_count = 0;
build_err_ref = undefined;
build_err_len = -1;

// ---- input ----
repeat_delay = 20;
repeat_rate = 2;
rep_keys = [vk_left, vk_right, vk_up, vk_down, vk_backspace, vk_delete, vk_enter, vk_pageup, vk_pagedown, vk_tab,
    ord("Z"), ord("Y"), ord("D"), vk_f3, vk_f8];
key_hold = array_create(256, 0);
mouse_block = true;
mouse_selecting = false;
mouse_select_mode = "char";
sel_word_l = 0;
sel_word_c1 = 0;
sel_word_c2 = 0;
click_count = 0;
last_click_time = -10000;
last_click_x = -100;
last_click_y = -100;
vbar_drag = false;
vbar_drag_off = 0;
hbar_drag = false;
hbar_drag_off = 0;
clipboard_line_text = "";

// Input injection hook (used by automated tests; inert otherwise). Keys in
// sim_pressed count as pressed for one step, sim_down as held. With
// sim_mouse_active the sim_m* values replace the real mouse.
sim_active = false;
sim_pressed = array_create(256, false);
sim_down = array_create(256, false);
sim_mouse_active = false;
sim_mx = 0;
sim_my = 0;
sim_mp = false;
sim_mh = false;
sim_wheel = 0;

ed_kp = function(_k) {
    return keyboard_check_pressed(_k) || (sim_active && sim_pressed[_k]);
};

ed_kd = function(_k) {
    return keyboard_check(_k) || (sim_active && (sim_down[_k] || sim_pressed[_k]));
};

// ---- find / replace / goto ----
focus = "text";
find_open = false;
replace_open = false;
goto_open = false;
find_text = "";
replace_text = "";
goto_text = "";
find_case = false;
find_matches = [];
find_by_line = {};
find_key = "";
find_origin_line = 0;
find_origin_col = 0;
field_fresh = false; // bar field shows as "all selected": first keystroke replaces it

// ---- autocomplete ----
ac_open = false;
ac_items = [];
ac_index = 0;
ac_scroll = 0;
ac_rows = 10;
ac_context = "";
ac_prefix = "";
ac_start_col = 0;
ac_line = 0;
ac_mnemonic = "";
ac_rect = [0, 0, 0, 0];
ac_row_h = 18;

// ---- hover tooltip ----
hover_key = "";
hover_since = 0;
hover_text = "";
hover_x = 0;
hover_y = 0;

// ---- status ----
status_note = "";
status_note_colour = c_white;
status_note_time = -100000;

// ---- snippets ({n} is replaced with a number that keeps labels unique) ----
snippets = [
    { label : "VBL WAIT", probe : ".vbl", lines : [
        "; -- wait for the vertical blank (line 303), A6 = CUSTOM --",
        ".vbl{n}:",
        "\tmove.l\tVPOSR(a6),d0",
        "\tand.l\t#$1ff00,d0",
        "\tcmp.l\t#303<<8,d0",
        "\tbne.s\t.vbl{n}"
    ] },
    { label : "BLIT WAIT", probe : ".blt", lines : [
        "; -- wait for the blitter to finish, A6 = CUSTOM --",
        "\ttst.w\tDMACONR(a6)\t\t; A1000 Agnus workaround",
        ".blt{n}:",
        "\tbtst\t#6,DMACONR(a6)\t; BBUSY (DMACONR bit 14)",
        "\tbne.s\t.blt{n}"
    ] },
    { label : "TAKE SYSTEM", probe : "take_system", lines : [
        "; -- take over / restore the system: bsr take_system{n} ... bsr restore_system{n} --",
        "take_system{n}:",
        "\tmove.l\t4.w,a6\t\t\t; ExecBase",
        "\tlea\tgfxname{n}(pc),a1",
        "\tjsr\t_LVOOldOpenLibrary(a6)",
        "\tmove.l\td0,gfxbase{n}",
        "\tmove.l\td0,a6",
        "\tmove.l\tgb_ActiView(a6),oldview{n}",
        "\tmove.l\tgb_copinit(a6),oldcopper{n}",
        "\tsub.l\ta1,a1",
        "\tjsr\t_LVOLoadView(a6)\t; blank view",
        "\tjsr\t_LVOWaitTOF(a6)",
        "\tjsr\t_LVOWaitTOF(a6)",
        "\tjsr\t_LVOOwnBlitter(a6)",
        "\tjsr\t_LVOWaitBlit(a6)",
        "\tmove.l\t4.w,a6",
        "\tjsr\t_LVOForbid(a6)",
        "\tlea\tCUSTOM,a6",
        "\tmove.w\tDMACONR(a6),olddma{n}",
        "\tmove.w\tINTENAR(a6),oldintena{n}",
        "\tmove.w\tINTREQR(a6),oldintreq{n}",
        "\tmove.w\tADKCONR(a6),oldadkcon{n}",
        "\tmove.w\t#$7fff,INTENA(a6)\t; all interrupts off",
        "\tmove.w\t#$7fff,INTREQ(a6)",
        "\tmove.w\t#$7fff,DMACON(a6)\t; all DMA off",
        "\trts",
        "",
        "restore_system{n}:",
        "\tlea\tCUSTOM,a6",
        "\tmove.w\t#$7fff,DMACON(a6)",
        "\tmove.w\t#$7fff,INTENA(a6)",
        "\tmove.w\t#$7fff,INTREQ(a6)",
        "\tmove.w\t#$7fff,ADKCON(a6)",
        "\tmove.l\toldcopper{n},COP1LC(a6)",
        "\tmove.w\tolddma{n},d0",
        "\tor.w\t#$8000,d0",
        "\tmove.w\td0,DMACON(a6)",
        "\tmove.w\toldintreq{n},d0",
        "\tor.w\t#$8000,d0",
        "\tmove.w\td0,INTREQ(a6)",
        "\tmove.w\toldadkcon{n},d0",
        "\tor.w\t#$8000,d0",
        "\tmove.w\td0,ADKCON(a6)",
        "\tmove.w\toldintena{n},d0",
        "\tor.w\t#$c000,d0",
        "\tmove.w\td0,INTENA(a6)",
        "\tmove.l\tgfxbase{n},a6",
        "\tmove.l\toldview{n},a1",
        "\tjsr\t_LVOLoadView(a6)",
        "\tjsr\t_LVOWaitTOF(a6)",
        "\tjsr\t_LVOWaitTOF(a6)",
        "\tjsr\t_LVODisownBlitter(a6)",
        "\tmove.l\t4.w,a6",
        "\tjsr\t_LVOPermit(a6)",
        "\tmove.l\tgfxbase{n},a1",
        "\tjsr\t_LVOCloseLibrary(a6)",
        "\trts",
        "",
        "gfxname{n}:\tdc.b\t\"graphics.library\",0",
        "\teven",
        "gfxbase{n}:\tdc.l\t0",
        "oldview{n}:\tdc.l\t0",
        "oldcopper{n}:\tdc.l\t0",
        "olddma{n}:\tdc.w\t0",
        "oldintena{n}:\tdc.w\t0",
        "oldintreq{n}:\tdc.w\t0",
        "oldadkcon{n}:\tdc.w\t0"
    ] },
    { label : "COPPER LIST", probe : "copperlist", lines : [
        "; -- install a copper list (copperlist must be in chip RAM) --",
        "\tlea\tCUSTOM,a6",
        "\tmove.l\t#copperlist{n},COP1LC(a6)",
        "\tmove.w\td0,COPJMP1(a6)\t\t; strobe: restart the copper",
        "\tmove.w\t#$8280,DMACON(a6)\t; SET | DMAEN | COPEN",
        "\tbra.w\tcopper_done{n}",
        "\tcnop\t0,4",
        "copperlist{n}:",
        "\tdc.w\tCOLOR00,$0000",
        "\tdc.w\t$6407,$fffe\t\t; wait for line $64",
        "\tdc.w\tCOLOR00,$0f00\t\t; red",
        "\tdc.w\t$a007,$fffe\t\t; wait for line $a0",
        "\tdc.w\tCOLOR00,$000f\t\t; blue",
        "\tdc.w\t$ffff,$fffe\t\t; end of copper list",
        "copper_done{n}:"
    ] },
    { label : "MAIN LOOP", probe : "mainloop", lines : [
        "; -- main loop: once per frame until the left mouse button is pressed --",
        "\tlea\tCUSTOM,a6",
        "mainloop{n}:",
        ".wait:",
        "\tmove.l\tVPOSR(a6),d0",
        "\tand.l\t#$1ff00,d0",
        "\tcmp.l\t#303<<8,d0",
        "\tbne.s\t.wait",
        "\t; ---- per-frame work goes here ----",
        "",
        "\tbtst\t#CIAB_GAMEPORT0,CIAA+CIAPRA\t; left mouse button (0 = pressed)",
        "\tbne.s\tmainloop{n}"
    ] },
    { label : "JOYSTICK", probe : "", lines : [
        "; -- read the joystick in port 2, A6 = CUSTOM --",
        "\tmove.w\tJOY1DAT(a6),d0\t\t; d0: bit 1 = right, bit 9 = left",
        "\tmove.w\td0,d1",
        "\tlsr.w\t#1,d1",
        "\teor.w\td0,d1\t\t\t; d1: bit 0 = down, bit 8 = up",
        "\tbtst\t#CIAB_GAMEPORT1,CIAA+CIAPRA\t; fire button (0 = pressed)",
        "\tseq\td2\t\t\t; d2.b = $ff while fire is held"
    ] }
];

#region helpers: text model

ed_text = function() {
    return string_join_ext("\n", lines);
};

ed_expand_tabs = function(_s, _start_col) {
    if (string_pos("\t", _s) == 0) return _s;
    var _out = "";
    var _col = _start_col;
    var _n = string_length(_s);
    var _i = 1;
    while (_i <= _n) {
        var _ch = string_char_at(_s, _i);
        if (_ch == "\t") {
            var _pad = tab_width - (_col mod tab_width);
            _out += string_repeat(" ", _pad);
            _col += _pad;
        } else {
            _out += _ch;
            _col += 1;
        }
        _i += 1;
    }
    return _out;
};

ed_text_to_lines = function(_text) {
    if (!is_string(_text)) _text = string(_text);
    _text = string_replace_all(_text, "\r\n", "\n");
    _text = string_replace_all(_text, "\r", "\n");
    var _arr = string_split(_text, "\n");
    if (array_length(_arr) == 0) _arr = [""];
    var _i = 0;
    while (_i < array_length(_arr)) {
        _arr[_i] = ed_expand_tabs(_arr[_i], 0);
        _i += 1;
    }
    return _arr;
};

ed_line_len = function(_l) {
    return string_length(lines[_l]);
};

ed_clamp_caret = function() {
    var _n = array_length(lines);
    if (_n == 0) {
        lines = [""];
        _n = 1;
    }
    caret_line = clamp(caret_line, 0, _n - 1);
    anchor_line = clamp(anchor_line, 0, _n - 1);
    caret_col = clamp(caret_col, 0, string_length(lines[caret_line]));
    anchor_col = clamp(anchor_col, 0, string_length(lines[anchor_line]));
};

ed_has_sel = function() {
    return caret_line != anchor_line || caret_col != anchor_col;
};

ed_sel_range = function() {
    if (anchor_line < caret_line || (anchor_line == caret_line && anchor_col <= caret_col)) {
        return [anchor_line, anchor_col, caret_line, caret_col];
    }
    return [caret_line, caret_col, anchor_line, anchor_col];
};

// Lines touched by the selection (a selection ending at col 0 excludes that line).
ed_sel_line_span = function() {
    var _r = ed_sel_range();
    var _l1 = _r[0];
    var _l2 = _r[2];
    if (_l2 > _l1 && _r[3] == 0) _l2 -= 1;
    return [_l1, _l2];
};

ed_range_text = function(_l1, _c1, _l2, _c2) {
    if (_l1 == _l2) return string_copy(lines[_l1], _c1 + 1, _c2 - _c1);
    var _out = string_delete(lines[_l1], 1, _c1);
    var _l = _l1 + 1;
    while (_l < _l2) {
        _out += "\n" + lines[_l];
        _l += 1;
    }
    _out += "\n" + string_copy(lines[_l2], 1, _c2);
    return _out;
};

ed_splice_lines = function(_at, _remove, _new) {
    var _n = array_length(lines);
    var _nn = array_length(_new);
    var _out = array_create(_n - _remove + _nn, "");
    array_copy(_out, 0, lines, 0, _at);
    array_copy(_out, _at, _new, 0, _nn);
    array_copy(_out, _at + _nn, lines, _at + _remove, _n - _at - _remove);
    if (array_length(_out) == 0) _out = [""];
    lines = _out;
};

ed_set_caret = function(_l, _c, _extend) {
    caret_line = _l;
    caret_col = _c;
    ed_clamp_caret();
    if (!_extend) {
        anchor_line = caret_line;
        anchor_col = caret_col;
    }
    desired_col = caret_col;
    blink_timer = 0;
    ensure_visible = true;
};

ed_modified = function() {
    text_revision += 1;
    analysis_due = 12;
    ed_clamp_caret();
    desired_col = caret_col;
    blink_timer = 0;
    ensure_visible = true;
};

ed_delete_range = function(_l1, _c1, _l2, _c2) {
    var _left = string_copy(lines[_l1], 1, _c1);
    var _right = string_delete(lines[_l2], 1, _c2);
    if (_l1 == _l2) {
        lines[_l1] = _left + _right;
    } else {
        ed_splice_lines(_l1, _l2 - _l1 + 1, [_left + _right]);
    }
    caret_line = _l1;
    caret_col = _c1;
    anchor_line = _l1;
    anchor_col = _c1;
};

ed_delete_selection = function() {
    if (!ed_has_sel()) return;
    var _r = ed_sel_range();
    ed_delete_range(_r[0], _r[1], _r[2], _r[3]);
};

// Inserts text at the caret (selection must already be removed).
ed_insert_raw = function(_s) {
    _s = string_replace_all(_s, "\r\n", "\n");
    _s = string_replace_all(_s, "\r", "\n");
    var _parts = string_split(_s, "\n");
    var _pc = array_length(_parts);
    if (_pc == 0) return;

    var _line = lines[caret_line];
    var _left = string_copy(_line, 1, caret_col);
    var _right = string_delete(_line, 1, caret_col);

    if (_pc == 1) {
        var _piece = ed_expand_tabs(_parts[0], caret_col);
        lines[caret_line] = _left + _piece + _right;
        caret_col += string_length(_piece);
    } else {
        var _new = array_create(_pc, "");
        _new[0] = _left + ed_expand_tabs(_parts[0], caret_col);
        var _i = 1;
        while (_i < _pc - 1) {
            _new[_i] = ed_expand_tabs(_parts[_i], 0);
            _i += 1;
        }
        var _last = ed_expand_tabs(_parts[_pc - 1], 0);
        _new[_pc - 1] = _last + _right;
        ed_splice_lines(caret_line, 1, _new);
        caret_line += _pc - 1;
        caret_col = string_length(_last);
    }
    anchor_line = caret_line;
    anchor_col = caret_col;
};

ed_replace_selection = function(_s) {
    ed_delete_selection();
    ed_insert_raw(_s);
};

ed_leading_spaces = function(_s) {
    var _n = string_length(_s);
    var _i = 1;
    while (_i <= _n && string_char_at(_s, _i) == " ") _i += 1;
    return _i - 1;
};

ed_is_word_code = function(_o) {
    return (_o >= 65 && _o <= 90) || (_o >= 97 && _o <= 122) || (_o >= 48 && _o <= 57) || _o == 95 || _o == 36 || _o == 64;
};

ed_char_code = function(_l, _c) {
    // code of the char at 0-based col _c on line _l, or -1
    var _s = lines[_l];
    if (_c < 0 || _c >= string_length(_s)) return -1;
    return ord(string_char_at(_s, _c + 1));
};

// Returns [start, end) of the word at/around col _c, or [_c, _c].
ed_word_bounds = function(_l, _c) {
    var _s = lines[_l];
    var _n = string_length(_s);
    var _a = _c;
    var _b = _c;
    if (!(_c < _n && ed_is_word_code(ord(string_char_at(_s, _c + 1))))) {
        if (_c > 0 && ed_is_word_code(ord(string_char_at(_s, _c)))) {
            _a = _c - 1;
            _b = _c;
        } else {
            return [_c, _c];
        }
    }
    while (_a > 0 && ed_is_word_code(ord(string_char_at(_s, _a)))) _a -= 1;
    while (_b < _n && ed_is_word_code(ord(string_char_at(_s, _b + 1)))) _b += 1;
    // include a leading '.' (local label) when it is not a size separator
    if (_a > 0 && string_char_at(_s, _a) == ".") {
        if (_a == 1 || !ed_is_word_code(ord(string_char_at(_s, _a - 1)))) _a -= 1;
    }
    return [_a, _b];
};

ed_word_at = function(_l, _c) {
    var _wb = ed_word_bounds(_l, _c);
    return string_copy(lines[_l], _wb[0] + 1, _wb[1] - _wb[0]);
};

ed_word_left = function(_l, _c) {
    if (_c == 0) {
        if (_l > 0) return [_l - 1, string_length(lines[_l - 1])];
        return [0, 0];
    }
    var _s = lines[_l];
    var _p = _c;
    while (_p > 0 && string_char_at(_s, _p) == " ") _p -= 1;
    if (_p > 0 && ed_is_word_code(ord(string_char_at(_s, _p)))) {
        while (_p > 0 && ed_is_word_code(ord(string_char_at(_s, _p)))) _p -= 1;
    } else {
        while (_p > 0 && string_char_at(_s, _p) != " " && !ed_is_word_code(ord(string_char_at(_s, _p)))) _p -= 1;
    }
    return [_l, _p];
};

ed_word_right = function(_l, _c) {
    var _s = lines[_l];
    var _n = string_length(_s);
    if (_c >= _n) {
        if (_l < array_length(lines) - 1) return [_l + 1, 0];
        return [_l, _n];
    }
    var _p = _c;
    if (ed_is_word_code(ord(string_char_at(_s, _p + 1)))) {
        while (_p < _n && ed_is_word_code(ord(string_char_at(_s, _p + 1)))) _p += 1;
    } else if (string_char_at(_s, _p + 1) != " ") {
        while (_p < _n && string_char_at(_s, _p + 1) != " " && !ed_is_word_code(ord(string_char_at(_s, _p + 1)))) _p += 1;
    }
    while (_p < _n && string_char_at(_s, _p + 1) == " ") _p += 1;
    return [_l, _p];
};

#endregion

#region helpers: undo

ed_snapshot = function() {
    var _n = array_length(lines);
    var _copy = array_create(_n, "");
    array_copy(_copy, 0, lines, 0, _n);
    return { lines : _copy, cl : caret_line, cc : caret_col, al : anchor_line, ac : anchor_col };
};

ed_restore = function(_snap) {
    lines = _snap.lines;
    caret_line = _snap.cl;
    caret_col = _snap.cc;
    anchor_line = _snap.al;
    anchor_col = _snap.ac;
    ed_modified();
    ac_close();
};

// _kind "type"/"delete" group consecutive edits on the same line.
ed_undo_push = function(_kind) {
    var _now = current_time;
    if ((_kind == "type" || _kind == "delete") && undo_group_kind == _kind && undo_group_line == caret_line
        && _now - undo_group_time < 2000 && !ed_has_sel()) {
        undo_group_time = _now;
        return;
    }
    array_push(undo_stack, ed_snapshot());
    if (array_length(undo_stack) > undo_max) array_delete(undo_stack, 0, 1);
    redo_stack = [];
    undo_group_kind = _kind;
    undo_group_time = _now;
    undo_group_line = caret_line;
};

ed_undo_break = function() {
    undo_group_kind = "";
};

ed_undo = function() {
    if (array_length(undo_stack) == 0) {
        ed_note("Nothing to undo", c_ltgray);
        return;
    }
    array_push(redo_stack, ed_snapshot());
    ed_restore(array_pop(undo_stack));
    undo_group_kind = "";
};

ed_redo = function() {
    if (array_length(redo_stack) == 0) {
        ed_note("Nothing to redo", c_ltgray);
        return;
    }
    array_push(undo_stack, ed_snapshot());
    ed_restore(array_pop(redo_stack));
    undo_group_kind = "";
};

#endregion

#region helpers: editing commands

ed_note = function(_text, _colour) {
    status_note = _text;
    status_note_colour = _colour;
    status_note_time = current_time;
};

ed_type_text = function(_s) {
    ed_undo_push(ed_has_sel() ? "edit" : "type");
    ed_replace_selection(_s);
    ed_modified();
};

/// True when col _c of line _l is inside a ; comment (outside quotes).
ed_in_comment = function(_l, _c) {
    var _s = lines[_l];
    if (string_char_at(_s, 1) == "*") return true;
    var _quote = "";
    var _i = 1;
    while (_i <= min(_c, string_length(_s))) {
        var _ch = string_char_at(_s, _i);
        if (_quote != "") {
            if (_ch == _quote) _quote = "";
        } else if (_ch == "\"" || _ch == "'") {
            _quote = _ch;
        } else if (_ch == ";") {
            return true;
        }
        _i += 1;
    }
    return false;
};

/// Typing one character with auto-close on: ( and quotes get their partner,
/// a closing char already under the caret is typed over, and a selection is
/// wrapped. Returns false when the plain insert should happen instead.
ed_type_autoclose = function(_ch) {
    if (!global.code_editor_autoclose) return false;
    var _open = (_ch == "(" || _ch == "\"" || _ch == "'");
    var _close_ch = (_ch == "(") ? ")" : _ch;
    if (ed_in_comment(caret_line, caret_col)) return false;
    var _next = string_char_at(lines[caret_line], caret_col + 1);

    if (ed_has_sel()) {
        if (!_open) return false;
        var _r = ed_sel_range();
        if (_r[0] != _r[2]) return false;
        var _inner = ed_range_text(_r[0], _r[1], _r[2], _r[3]);
        ed_type_text(_ch + _inner + _close_ch);
        caret_line = _r[0];
        caret_col = _r[1] + 1 + string_length(_inner);
        anchor_line = _r[0];
        anchor_col = _r[1] + 1;
        return true;
    }
    // Type over the closer that auto-close put there.
    if ((_ch == ")" || _ch == "\"" || _ch == "'") && _next == _ch) {
        ed_undo_break();
        ed_set_caret(caret_line, caret_col + 1, false);
        return true;
    }
    if (!_open) return false;
    // Only before whitespace / end / a closer / a comma, so typing in front of a word stays plain.
    if (!(_next == "" || _next == " " || _next == ")" || _next == ",")) return false;
    // A quote straight after a word character is an apostrophe, not a string.
    if (_ch != "(" && caret_col > 0 && ed_is_word_code(ord(string_char_at(lines[caret_line], caret_col)))) return false;
    ed_type_text(_ch + _close_ch);
    ed_set_caret(caret_line, caret_col - 1, false);
    return true;
};

/// Backspace between an empty auto-closed pair removes both halves.
ed_backspace_pair = function() {
    if (!global.code_editor_autoclose || ed_has_sel() || caret_col == 0) return false;
    var _s = lines[caret_line];
    var _a = string_char_at(_s, caret_col);
    var _b = string_char_at(_s, caret_col + 1);
    if (!((_a == "(" && _b == ")") || (_a == "\"" && _b == "\"") || (_a == "'" && _b == "'"))) return false;
    ed_undo_push("edit");
    ed_delete_range(caret_line, caret_col - 1, caret_line, caret_col + 1);
    ed_modified();
    return true;
};

ed_is_label_only = function(_s) {
    var _tk = scr_asm_tokenize_line(_s);
    var _has_label = false;
    var _i = 0;
    while (_i < array_length(_tk)) {
        var _t = _tk[_i];
        if (_t.kind == "label") {
            _has_label = true;
        } else if (_t.kind != "whitespace" && _t.kind != "comment") {
            return false;
        }
        _i += 1;
    }
    return _has_label;
};

ed_newline = function() {
    ed_undo_push("edit");
    ed_delete_selection();
    var _line = lines[caret_line];
    var _before = string_copy(_line, 1, caret_col);
    var _after = string_trim_start(string_delete(_line, 1, caret_col));
    var _indent = min(ed_leading_spaces(_line), caret_col);

    if (ed_is_label_only(_before)) {
        _indent = (floor(_indent / tab_width) + 1) * tab_width;
    }

    lines[caret_line] = (string_trim(_before) == "") ? "" : string_trim_end(_before);
    array_insert(lines, caret_line + 1, string_repeat(" ", _indent) + _after);
    caret_line += 1;
    caret_col = _indent;
    anchor_line = caret_line;
    anchor_col = caret_col;
    ed_modified();
};

ed_backspace = function(_word) {
    if (ed_has_sel()) {
        ed_undo_push("edit");
        ed_delete_selection();
        ed_modified();
        return;
    }
    if (caret_col == 0 && caret_line == 0) return;

    if (_word) {
        var _wl = ed_word_left(caret_line, caret_col);
        ed_undo_push("edit");
        ed_delete_range(_wl[0], _wl[1], caret_line, caret_col);
        ed_modified();
        return;
    }

    ed_undo_push("delete");

    if (caret_col == 0) {
        var _prev_len = string_length(lines[caret_line - 1]);
        ed_delete_range(caret_line - 1, _prev_len, caret_line, 0);
    } else {
        var _before = string_copy(lines[caret_line], 1, caret_col);
        var _n = 1;
        if (string_trim(_before) == "") {
            _n = caret_col mod tab_width;
            if (_n == 0) _n = tab_width;
        }
        ed_delete_range(caret_line, caret_col - _n, caret_line, caret_col);
    }
    ed_modified();
};

ed_delete_forward = function(_word) {
    if (ed_has_sel()) {
        ed_undo_push("edit");
        ed_delete_selection();
        ed_modified();
        return;
    }
    var _len = string_length(lines[caret_line]);
    var _last = array_length(lines) - 1;
    if (caret_col >= _len && caret_line >= _last) return;

    if (_word) {
        var _wr = ed_word_right(caret_line, caret_col);
        ed_undo_push("edit");
        ed_delete_range(caret_line, caret_col, _wr[0], _wr[1]);
        ed_modified();
        return;
    }

    ed_undo_push("delete");
    if (caret_col >= _len) {
        ed_delete_range(caret_line, caret_col, caret_line + 1, 0);
    } else {
        ed_delete_range(caret_line, caret_col, caret_line, caret_col + 1);
    }
    ed_modified();
};

ed_indent_lines = function(_outdent) {
    var _span = ed_sel_line_span();
    ed_undo_push("edit");
    var _l = _span[0];
    while (_l <= _span[1]) {
        var _s = lines[_l];
        var _lead = ed_leading_spaces(_s);
        var _delta = 0;
        if (_outdent) {
            var _rem = _lead mod tab_width;
            _delta = -min(_lead, (_rem == 0) ? tab_width : _rem);
            if (_delta != 0) lines[_l] = string_delete(_s, 1, -_delta);
        } else if (string_length(_s) > 0) {
            _delta = tab_width - (_lead mod tab_width);
            lines[_l] = string_repeat(" ", _delta) + _s;
        }
        if (_l == caret_line) caret_col = max(0, caret_col + _delta);
        if (_l == anchor_line) anchor_col = max(0, anchor_col + _delta);
        _l += 1;
    }
    var _keep_al = anchor_line;
    var _keep_ac = anchor_col;
    ed_modified();
    anchor_line = _keep_al;
    anchor_col = _keep_ac;
    ed_clamp_caret();
};

ed_tab = function(_shift) {
    if (_shift) {
        ed_indent_lines(true);
        return;
    }
    if (ed_has_sel() && caret_line != anchor_line) {
        ed_indent_lines(false);
        return;
    }
    var _col = ed_has_sel() ? ed_sel_range()[1] : caret_col;
    var _pad = tab_width - (_col mod tab_width);
    ed_type_text(string_repeat(" ", _pad));
};

ed_toggle_comment = function() {
    var _span = ed_sel_line_span();
    var _all_commented = true;
    var _min_indent = 100000;
    var _l = _span[0];
    while (_l <= _span[1]) {
        var _t = string_trim(lines[_l]);
        if (_t != "") {
            _min_indent = min(_min_indent, ed_leading_spaces(lines[_l]));
            // ";" anywhere, or "*" in column 1 (vasm Motorola syntax).
            if (string_char_at(_t, 1) != ";" && string_char_at(lines[_l], 1) != "*") _all_commented = false;
        }
        _l += 1;
    }
    if (_min_indent == 100000) return;

    ed_undo_push("edit");
    var _keep_al = anchor_line;
    _l = _span[0];
    while (_l <= _span[1]) {
        var _s = lines[_l];
        if (string_trim(_s) != "") {
            var _delta = 0;
            if (_all_commented) {
                var _p = (string_char_at(_s, 1) == "*") ? 1 : ed_leading_spaces(_s) + 1;
                var _cut = (string_char_at(_s, _p + 1) == " ") ? 2 : 1;
                lines[_l] = string_delete(_s, _p, _cut);
                _delta = -_cut;
            } else {
                lines[_l] = string_copy(_s, 1, _min_indent) + "; " + string_delete(_s, 1, _min_indent);
                _delta = 2;
            }
            if (_l == caret_line) caret_col = max(0, caret_col + _delta);
            if (_l == anchor_line) anchor_col = max(0, anchor_col + _delta);
        }
        _l += 1;
    }
    var _keep_ac = anchor_col;
    ed_modified();
    anchor_line = _keep_al;
    anchor_col = _keep_ac;
    ed_clamp_caret();
};

ed_duplicate = function() {
    ed_undo_push("edit");
    if (ed_has_sel()) {
        var _r = ed_sel_range();
        var _txt = ed_range_text(_r[0], _r[1], _r[2], _r[3]);
        caret_line = _r[2];
        caret_col = _r[3];
        anchor_line = _r[2];
        anchor_col = _r[3];
        var _sl = caret_line;
        var _sc = caret_col;
        ed_insert_raw(_txt);
        var _el = caret_line;
        var _ec = caret_col;
        ed_modified();
        anchor_line = _sl;
        anchor_col = _sc;
        caret_line = _el;
        caret_col = _ec;
    } else {
        array_insert(lines, caret_line + 1, lines[caret_line]);
        caret_line += 1;
        anchor_line = caret_line;
        anchor_col = caret_col;
        ed_modified();
    }
};

ed_move_lines = function(_dir) {
    var _span = ed_sel_line_span();
    var _l1 = _span[0];
    var _l2 = _span[1];
    if (_dir < 0 && _l1 == 0) return;
    if (_dir > 0 && _l2 >= array_length(lines) - 1) return;

    ed_undo_push("edit");
    if (_dir < 0) {
        var _above = lines[_l1 - 1];
        array_delete(lines, _l1 - 1, 1);
        array_insert(lines, _l2, _above);
    } else {
        var _below = lines[_l2 + 1];
        array_delete(lines, _l2 + 1, 1);
        array_insert(lines, _l1, _below);
    }
    caret_line += _dir;
    anchor_line += _dir;
    var _keep_al = anchor_line;
    var _keep_ac = anchor_col;
    ed_modified();
    anchor_line = _keep_al;
    anchor_col = _keep_ac;
    ed_clamp_caret();
};

ed_delete_lines = function() {
    var _span = ed_sel_line_span();
    ed_undo_push("edit");
    var _count = _span[1] - _span[0] + 1;
    if (_count >= array_length(lines)) {
        lines = [""];
    } else {
        array_delete(lines, _span[0], _count);
    }
    caret_line = min(_span[0], array_length(lines) - 1);
    caret_col = min(desired_col, string_length(lines[caret_line]));
    anchor_line = caret_line;
    anchor_col = caret_col;
    ed_modified();
};

ed_copy = function(_cut) {
    if (ed_has_sel()) {
        var _r = ed_sel_range();
        clipboard_set_text(ed_range_text(_r[0], _r[1], _r[2], _r[3]));
        clipboard_line_text = "";
        if (_cut) {
            ed_undo_push("edit");
            ed_delete_selection();
            ed_modified();
        }
    } else {
        var _t = lines[caret_line] + "\n";
        clipboard_set_text(_t);
        clipboard_line_text = _t;
        if (_cut) {
            ed_undo_push("edit");
            if (array_length(lines) == 1) {
                lines[0] = "";
            } else {
                array_delete(lines, caret_line, 1);
            }
            caret_line = min(caret_line, array_length(lines) - 1);
            caret_col = min(caret_col, string_length(lines[caret_line]));
            anchor_line = caret_line;
            anchor_col = caret_col;
            ed_modified();
        }
    }
};

ed_paste = function() {
    if (!clipboard_has_text()) return;
    var _t = clipboard_get_text();
    _t = string_replace_all(_t, "\r\n", "\n");
    _t = string_replace_all(_t, "\r", "\n");
    if (_t == "") return;
    ed_undo_push("edit");
    if (_t == clipboard_line_text && !ed_has_sel()) {
        // whole-line copy: paste above the current line
        var _keep = caret_col;
        caret_col = 0;
        anchor_col = 0;
        anchor_line = caret_line;
        ed_insert_raw(_t);
        caret_col = min(_keep, string_length(lines[caret_line]));
        anchor_col = caret_col;
    } else {
        ed_replace_selection(_t);
    }
    ed_modified();
};

ed_select_all = function() {
    anchor_line = 0;
    anchor_col = 0;
    caret_line = array_length(lines) - 1;
    caret_col = string_length(lines[caret_line]);
    ensure_visible = true;
};

ed_insert_snippet = function(_snip) {
    var _n = 1;
    if (_snip.probe != "") {
        while (_n < 1000) {
            var _name = _snip.probe + string(_n);
            if (!variable_struct_exists(analysis.labels, _name) && !variable_struct_exists(analysis.locals, _name)
                && string_pos(_name, ed_text()) == 0) break;
            _n += 1;
        }
    }
    var _new = [];
    var _i = 0;
    while (_i < array_length(_snip.lines)) {
        var _s = string_replace_all(_snip.lines[_i], "{n}", string(_n));
        array_push(_new, ed_expand_tabs(_s, 0));
        _i += 1;
    }

    ed_undo_push("edit");
    ed_delete_selection();
    if (string_trim(lines[caret_line]) == "") {
        ed_splice_lines(caret_line, 1, _new);
    } else {
        ed_splice_lines(caret_line + 1, 0, _new);
        caret_line += 1;
    }
    caret_line += array_length(_new) - 1;
    caret_col = string_length(lines[caret_line]);
    anchor_line = caret_line;
    anchor_col = caret_col;
    ed_modified();
    ed_note("Inserted snippet: " + _snip.label, make_colour_rgb(120, 220, 255));
};

#endregion

#region helpers: navigation

ed_ensure_caret_visible = function() {
    if (caret_line < scroll_line) scroll_line = caret_line;
    if (caret_line >= scroll_line + vis_lines) scroll_line = caret_line - vis_lines + 1;
    if (caret_col < scroll_col) scroll_col = max(0, caret_col - 4);
    if (caret_col >= scroll_col + vis_cols - 1) scroll_col = caret_col - vis_cols + 5;
    ed_clamp_scroll();
};

ed_max_scroll_line = function() {
    return max(0, array_length(lines) - vis_lines + 3);
};

ed_max_scroll_col = function() {
    return max(0, max_line_len + 4 - vis_cols);
};

ed_clamp_scroll = function() {
    scroll_line = clamp(scroll_line, 0, ed_max_scroll_line());
    scroll_col = clamp(scroll_col, 0, ed_max_scroll_col());
};

ed_goto_line = function(_l) {
    _l = clamp(_l, 0, array_length(lines) - 1);
    ed_set_caret(_l, ed_leading_spaces(lines[_l]), false);
    scroll_line = max(0, _l - floor(vis_lines / 3));
    ed_clamp_scroll();
    ensure_visible = true;
};

ed_find_label_line = function(_name, _from_line) {
    if (_name == "") return -1;
    var _l = analysis.labels[$ _name];
    if (_l != undefined) return _l;
    _l = analysis.macros[$ _name];
    if (_l != undefined) return _l;
    if (string_char_at(_name, 1) == "." || string_char_at(_name, string_length(_name)) == "$") {
        // nearest preceding definition, then following
        var _best = -1;
        var _i = 0;
        var _n = array_length(lines);
        while (_i < _n) {
            var _tk = scr_asm_tokenize_line(lines[_i]);
            var _k = 0;
            while (_k < array_length(_tk)) {
                var _t = _tk[_k];
                if (_t.kind == "label") {
                    var _nm = _t.text;
                    while (string_length(_nm) > 0 && string_char_at(_nm, string_length(_nm)) == ":") _nm = string_copy(_nm, 1, string_length(_nm) - 1);
                    if (_nm == _name) {
                        if (_i <= _from_line || _best == -1) _best = _i;
                        if (_i > _from_line) return _best;
                    }
                    break;
                }
                if (_t.kind != "whitespace") break;
                _k += 1;
            }
            _i += 1;
        }
        return _best;
    }
    return -1;
};

ed_goto_definition = function(_l, _c) {
    var _name = ed_word_at(_l, _c);
    if (_name == "") return;
    var _target = ed_find_label_line(_name, _l);
    if (_target >= 0) {
        ed_goto_line(_target);
        ed_note("Definition of '" + _name + "' (line " + string(_target + 1) + ")", make_colour_rgb(120, 220, 255));
    } else if (array_contains(global_symbol_list, _name)) {
        ed_note("'" + _name + "' is defined in another node", make_colour_rgb(240, 200, 80));
    } else {
        var _help = scr_asm_symbol_help(_name);
        ed_note((_help != "") ? _help : "No definition found for '" + _name + "'", (_help != "") ? c_white : make_colour_rgb(255, 140, 120));
    }
};

ed_next_diagnostic = function() {
    var _n = array_length(diag_all);
    if (_n == 0) {
        ed_note("No problems found", make_colour_rgb(120, 220, 120));
        return;
    }
    var _i = 0;
    var _pick = diag_all[0];
    while (_i < _n) {
        var _d = diag_all[_i];
        if (_d.line > caret_line || (_d.line == caret_line && _d.col > caret_col)) {
            _pick = _d;
            break;
        }
        _i += 1;
    }
    var _l = clamp(_pick.line, 0, array_length(lines) - 1);
    ed_set_caret(_l, _pick.col, false);
    ed_note(_pick.message, (_pick.severity == "error") ? make_colour_rgb(255, 110, 110) : make_colour_rgb(255, 190, 80));
};

#endregion

#region helpers: find / replace

ed_find_refresh = function() {
    var _key = find_text + chr(1) + string(find_case) + chr(1) + string(text_revision);
    if (_key == find_key) return;
    find_key = _key;
    find_matches = [];
    find_by_line = {};
    if (find_text == "") return;

    var _needle = find_case ? find_text : string_lower(find_text);
    var _nl = string_length(_needle);
    var _i = 0;
    var _n = array_length(lines);
    while (_i < _n && array_length(find_matches) < 20000) {
        var _hay = find_case ? lines[_i] : string_lower(lines[_i]);
        var _offset = 0;
        var _pos = string_pos(_needle, _hay);
        while (_pos > 0) {
            var _col = _offset + _pos - 1;
            array_push(find_matches, [_i, _col]);
            var _key_l = string(_i);
            if (!variable_struct_exists(find_by_line, _key_l)) find_by_line[$ _key_l] = [];
            array_push(find_by_line[$ _key_l], _col);
            _offset = _col + _nl;
            _hay = string_delete(_hay, 1, _pos + _nl - 1);
            _pos = string_pos(_needle, _hay);
        }
        _i += 1;
    }
};

ed_select_match = function(_m) {
    anchor_line = _m[0];
    anchor_col = _m[1];
    caret_line = _m[0];
    caret_col = _m[1] + string_length(find_text);
    ed_clamp_caret();
    desired_col = caret_col;
    ensure_visible = true;
};

// Finds the first match at/after (_l,_c) (inclusive) or strictly before it.
ed_find_from = function(_l, _c, _forward, _inclusive) {
    ed_find_refresh();
    var _n = array_length(find_matches);
    if (_n == 0) {
        if (find_text != "") ed_note("No matches for '" + find_text + "'", make_colour_rgb(255, 140, 120));
        return false;
    }
    var _pick = -1;
    var _i;
    if (_forward) {
        _i = 0;
        while (_i < _n) {
            var _m = find_matches[_i];
            if (_m[0] > _l || (_m[0] == _l && (_m[1] > _c || (_inclusive && _m[1] == _c)))) {
                _pick = _i;
                break;
            }
            _i += 1;
        }
        if (_pick == -1) _pick = 0;
    } else {
        _i = _n - 1;
        while (_i >= 0) {
            var _mb = find_matches[_i];
            if (_mb[0] < _l || (_mb[0] == _l && _mb[1] < _c)) {
                _pick = _i;
                break;
            }
            _i -= 1;
        }
        if (_pick == -1) _pick = _n - 1;
    }
    ed_select_match(find_matches[_pick]);
    ed_note("Match " + string(_pick + 1) + " of " + string(_n), c_white);
    return true;
};

ed_find_next = function(_forward) {
    if (find_text == "") {
        ed_open_find(false);
        return;
    }
    var _r = ed_sel_range();
    if (_forward) {
        ed_find_from(_r[0], _r[1], true, false);
    } else {
        ed_find_from(_r[0], _r[1], false, false);
    }
};

ed_sel_matches_find = function() {
    if (!ed_has_sel() || find_text == "") return false;
    var _r = ed_sel_range();
    if (_r[0] != _r[2]) return false;
    var _t = ed_range_text(_r[0], _r[1], _r[2], _r[3]);
    return find_case ? (_t == find_text) : (string_lower(_t) == string_lower(find_text));
};

ed_replace_one = function() {
    if (find_text == "") return;
    if (ed_sel_matches_find()) {
        ed_undo_push("edit");
        ed_replace_selection(replace_text);
        ed_modified();
    }
    ed_find_from(caret_line, caret_col, true, true);
};

ed_replace_all = function() {
    if (find_text == "") return;
    ed_find_refresh();
    var _count = array_length(find_matches);
    if (_count == 0) {
        ed_note("No matches for '" + find_text + "'", make_colour_rgb(255, 140, 120));
        return;
    }
    ed_undo_push("edit");
    var _nl = string_length(find_text);
    var _i = _count - 1;
    while (_i >= 0) {
        var _m = find_matches[_i];
        var _s = lines[_m[0]];
        lines[_m[0]] = string_copy(_s, 1, _m[1]) + replace_text + string_delete(_s, 1, _m[1] + _nl);
        _i -= 1;
    }
    ed_modified();
    ed_note("Replaced " + string(_count) + " occurrence" + ((_count == 1) ? "" : "s"), make_colour_rgb(120, 220, 120));
};

ed_open_find = function(_replace) {
    find_open = true;
    goto_open = false;
    if (_replace) replace_open = true;
    if (ed_has_sel() && caret_line == anchor_line) {
        var _r = ed_sel_range();
        find_text = ed_range_text(_r[0], _r[1], _r[2], _r[3]);
    }
    var _r2 = ed_sel_range();
    find_origin_line = _r2[0];
    find_origin_col = _r2[1];
    focus = _replace ? "replace" : "find";
    if (_replace && find_text == "") focus = "find";
    field_fresh = true;
    find_key = "";
    keyboard_string = "";
};

ed_close_bars = function() {
    find_open = false;
    replace_open = false;
    goto_open = false;
    focus = "text";
};

#endregion

#region helpers: analysis

ed_refresh_build_errors = function() {
    var _src = global.code_editor_build_errors;
    if (!is_array(_src)) _src = [];
    build_err_ref = _src;
    build_err_len = array_length(_src);

    diag_all = [];
    diag_by_line = {};
    diag_error_count = 0;
    diag_warning_count = 0;

    var _merge = function(_d) {
        array_push(diag_all, _d);
        var _key = string(_d.line);
        if (!variable_struct_exists(diag_by_line, _key)) diag_by_line[$ _key] = [];
        array_push(diag_by_line[$ _key], _d);
        if (_d.severity == "error") diag_error_count += 1; else diag_warning_count += 1;
    };

    var _i = 0;
    while (_i < array_length(analysis.diagnostics)) {
        _merge(analysis.diagnostics[_i]);
        _i += 1;
    }

    _i = 0;
    while (_i < array_length(_src)) {
        var _e = _src[_i];
        _i += 1;
        if (!is_struct(_e) || !variable_struct_exists(_e, "node_uid") || _e.node_uid != editor_node_uid) continue;
        var _ln = variable_struct_exists(_e, "line") ? real(_e.line) : 0;
        _ln = clamp(_ln, 0, array_length(lines) - 1);
        var _msg = variable_struct_exists(_e, "message") ? string(_e.message) : "build error";
        _merge({ line : _ln, col : 0, len : max(1, string_length(lines[_ln])), message : "vasm: " + _msg, severity : "error", build : true });
    }

    array_sort(diag_all, function(_a, _b) {
        if (_a.line != _b.line) return _a.line - _b.line;
        return _a.col - _b.col;
    });
};

ed_run_analysis = function() {
    global_symbol_list = course_mode ? [] : scr_asm_global_symbols(editor_node);
    analysis = scr_asm_analyse_lines(lines, global_symbol_list);
    analysed_revision = text_revision;

    known_symbols = {};
    var _names = variable_struct_get_names(analysis.defined);
    var _i = 0;
    while (_i < array_length(_names)) {
        known_symbols[$ _names[_i]] = true;
        _i += 1;
    }
    var _locals = variable_struct_get_names(analysis.locals);
    _i = 0;
    while (_i < array_length(_locals)) {
        known_symbols[$ _locals[_i]] = true;
        _i += 1;
    }
    _i = 0;
    while (_i < array_length(global_symbol_list)) {
        known_symbols[$ global_symbol_list[_i]] = true;
        _i += 1;
    }
    var _builtins = variable_struct_get_names(scr_asm_lang_data().builtin_symbols);
    _i = 0;
    while (_i < array_length(_builtins)) {
        known_symbols[$ _builtins[_i]] = true;
        _i += 1;
    }

    completion_locals = array_concat(analysis.label_names, _locals);
    ed_refresh_build_errors();
};

ed_update_max_len = function() {
    if (max_len_revision == text_revision) return;
    max_len_revision = text_revision;
    var _m = 0;
    var _i = 0;
    var _n = array_length(lines);
    while (_i < _n) {
        _m = max(_m, string_length(lines[_i]));
        _i += 1;
    }
    max_line_len = _m;
};

#endregion

#region helpers: autocomplete

ac_close = function() {
    ac_open = false;
    ac_items = [];
};

// Works out what is being typed at the caret.
ed_ac_context = function() {
    var _line = lines[caret_line];
    var _s = caret_col;
    while (_s > 0 && ed_is_word_code(ord(string_char_at(_line, _s)))) _s -= 1;

    var _prefix = string_copy(_line, _s + 1, caret_col - _s);
    if (_prefix != "") {
        var _f = ord(string_char_at(_prefix, 1));
        if ((_f >= 48 && _f <= 57) || _f == 36 || _f == 64) return undefined;
    }

    var _start = _s;
    var _ctx = "";
    var _mn = "";

    if (_s > 0 && string_char_at(_line, _s) == ".") {
        var _pre_dot = string_copy(_line, 1, _s - 1);
        var _tkd = scr_asm_tokenize_line(_pre_dot);
        var _last = undefined;
        var _k = array_length(_tkd) - 1;
        if (_k >= 0) _last = _tkd[_k];

        if (_last != undefined && _last.field == "op" && (_last.kind == "mnemonic" || _last.kind == "directive")
            && _last.start_col + string_length(_last.text) == _s - 1) {
            return { context : "size", prefix : _prefix, start_col : _s, mnemonic : _last.text };
        }
        if (_s - 1 == 0 || !ed_is_word_code(ord(string_char_at(_line, _s - 1)))) {
            // local label reference ".name"
            _start = _s - 1;
            _prefix = "." + _prefix;
        } else {
            return undefined;
        }
    }

    var _pre = string_copy(_line, 1, _start);
    var _tk = scr_asm_tokenize_line(_pre);
    var _has_op = false;
    var _i = 0;
    while (_i < array_length(_tk)) {
        var _t = _tk[_i];
        if (_t.kind == "comment") return undefined;
        if (_t.kind == "string" && variable_struct_exists(_t, "closed") && !_t.closed) return undefined;
        if (_t.field == "op" && _t.kind != "whitespace" && _t.kind != "size") {
            _has_op = true;
            _mn = _t.text;
        }
        _i += 1;
    }

    if (_has_op) {
        _ctx = "operand";
    } else if (_start == 0) {
        _ctx = "label";
    } else {
        _ctx = "mnemonic";
    }

    return { context : _ctx, prefix : _prefix, start_col : _start, mnemonic : _mn };
};

ed_ac_update = function(_force) {
    var _c = ed_ac_context();
    if (_c == undefined) {
        ac_close();
        return;
    }
    var _ctx = _c.context;
    // An empty operand (after the gap, a typed space or a comma): the
    // addressing forms of this instruction.
    if (_ctx == "operand" && _c.prefix == "" && (_force || global.code_editor_autocomplete)) {
        if (ed_form_open()) return;
        if (!_force) {
            ac_close();
            return;
        }
    }
    if (_ctx == "label") {
        if (!_force) {
            ac_close();
            return;
        }
        _ctx = "mnemonic";
    }
    var _plen = string_length(_c.prefix);
    var _auto = global.code_editor_autocomplete && ((_ctx == "mnemonic" && _plen >= 1) || (_ctx == "operand" && _plen >= 2) || (_ctx == "size"));
    if (!_force && !_auto) {
        if (ac_open && _plen > 0 && _c.start_col == ac_start_col) {
            // keep filtering an open list
        } else {
            ac_close();
            return;
        }
    }

    var _items = scr_asm_completions(_c.prefix, _ctx, _c.mnemonic, completion_locals, global_symbol_list);
    if (array_length(_items) == 0) {
        ac_close();
        return;
    }
    // A word that is already complete (e.g. "d1", "rts") does not need a
    // popup - and an open popup would capture the next Enter.
    if (!_force && _ctx != "size" && string_upper(_items[0].text) == string_upper(_c.prefix)) {
        ac_close();
        return;
    }

    ac_open = true;
    ac_items = _items;
    ac_index = 0;
    ac_scroll = 0;
    ac_context = _ctx;
    ac_prefix = _c.prefix;
    ac_start_col = _c.start_col;
    ac_line = caret_line;
    ac_mnemonic = _c.mnemonic;
};

ed_insert_operand_gap = function() {
    var _s = lines[caret_line];
    if (caret_col < string_length(_s) && string_char_at(_s, caret_col + 1) == " ") return;
    var _pad = tab_width - (caret_col mod tab_width);
    if (_pad < 1) _pad = tab_width;
    ed_insert_raw(string_repeat(" ", _pad));
};

// ---- addressing forms ----
// After an instruction (and after each comma) the popup lists the
// addressing forms that operand accepts, each with a ready example: Up / Down
// picks one (shown as ghost text at the caret), Tab or Enter types it in.
// Forms come from the opcode table (global.opcode_map src_modes / dst_modes).

// The instruction on the caret line and which operand the caret is in:
// { mnemonic, index, lower } or undefined.
ed_form_slot = function() {
    var _line = lines[caret_line];
    var _pre = string_copy(_line, 1, caret_col);
    var _tk = scr_asm_tokenize_line(_pre);
    var _mn = "";
    var _op_end = -1;
    var _i = 0;
    while (_i < array_length(_tk)) {
        var _t = _tk[_i];
        if (_t.kind == "comment") return undefined;
        if (_t.field == "op" && _t.kind != "whitespace") {
            if (_t.kind == "mnemonic") _mn = _t.text;
            _op_end = _t.start_col + string_length(_t.text);
        }
        _i += 1;
    }
    if (_mn == "" || _op_end < 0 || _op_end >= caret_col) return undefined;
    // Commas outside brackets before the caret = the operand index.
    var _index = 0;
    var _depth = 0;
    var _c = _op_end + 1;
    while (_c <= caret_col) {
        var _ch = string_char_at(_line, _c);
        if (_ch == "(") _depth += 1;
        if (_ch == ")") _depth = max(0, _depth - 1);
        if (_ch == "," && _depth == 0) _index += 1;
        _c += 1;
    }
    return { mnemonic : _mn, index : _index, lower : string_lower(_mn) == _mn };
};

// True when the caret sits at an empty operand: after the gap or a comma,
// with nothing but spaces or a comment after it.
ed_form_slot_empty = function() {
    var _line = lines[caret_line];
    if (caret_col == 0) return false;
    var _before = string_char_at(_line, caret_col);
    if (_before != " " && _before != "\t" && _before != ",") return false;
    var _after = string_trim(string_delete(_line, 1, caret_col));
    return _after == "" || string_char_at(_after, 1) == ";";
};

// The form items for operand _index of _mnemonic ({ text, kind : "form", detail }).
ed_form_items = function(_mnemonic, _index, _lower) {
    var _key = string_upper(_mnemonic);
    if (_key == "DBF") _key = "DBRA";
    var _entry = global.opcode_map[$ _key];
    if (_entry == undefined || _index >= _entry.operand_count) return [];
    var _modes = _index == 0 ? _entry.src_modes : _entry.dst_modes;
    var _out = [];
    var _r = function(_s, _lower) { return _lower ? string_lower(_s) : _s; };
    var _label = array_length(completion_locals) > 0 ? completion_locals[0] : "loop";

    // Branches and loop ends jump to a label: offer this block's labels.
    if (_entry.category == "branch" && _modes == global.AM_CONTROL) {
        var _l = 0;
        while (_l < array_length(completion_locals)) {
            array_push(_out, { text : completion_locals[_l], kind : "form", detail : "label: jump to " + completion_locals[_l] });
            _l += 1;
        }
        if (array_length(_out) == 0) array_push(_out, { text : "loop", kind : "form", detail : "label: put the label's name here (a label: line marks the target)" });
        return _out;
    }

    var _imm = (_key == "ADDQ" || _key == "SUBQ" || _key == "ASL" || _key == "ASR" || _key == "LSL" || _key == "LSR"
        || _key == "ROL" || _key == "ROR" || _key == "ROXL" || _key == "ROXR") ? "#1" : "#0";
    var _forms = [
        [global.AM_DN, _r("D0", _lower), "Dn  data register: a 32-bit working register (fast)"],
        [global.AM_IMM, _imm, "#imm  immediate: the number is stored in the instruction ($ = hex)"],
        [global.AM_AN, _r("A0", _lower), "An  address register: holds a pointer"],
        [global.AM_AN_IND, _r("(A0)", _lower), "(An)  the memory A0 points to"],
        [global.AM_AN_POSTINC, _r("(A0)+", _lower), "(An)+  the memory at A0, then A0 moves on to the next item"],
        [global.AM_AN_PREDEC, _r("-(A7)", _lower), "-(An)  A7 moves back first, then the memory there (push on the stack)"],
        [global.AM_AN_DISP, _r("4(A0)", _lower), "d16(An)  the memory at A0 + 4 (a field of a structure)"],
        [global.AM_AN_INDEX, _r("0(A0,D1.W)", _lower), "d8(An,Xn)  the memory at A0 + D1 (entry D1 of a table)"],
        [global.AM_ABS_L, "$DFF180", "abs.L  a fixed address (here COLOR00, the background colour)"],
        [global.AM_ABS_L, _label, "label  the address of a label in your code"],
        [global.AM_ABS_W, "$0400.W", "abs.W  a fixed address in the first 32K, stored in one word"],
        [global.AM_PC_DISP, _label + _r("(PC)", _lower), "d16(PC)  a label near this code, PC relative (works wherever it loads)"],
        [global.AM_PC_INDEX, _label + _r("(PC,D0.W)", _lower), "d8(PC,Xn)  entry D0 of a table at a label, PC relative"],
        [global.AM_REGLIST, _r("D0-D7/A0-A6", _lower), "register list: save or load many registers in one go"]
    ];
    var _f = 0;
    while (_f < array_length(_forms)) {
        if (_modes & _forms[_f][0]) array_push(_out, { text : _forms[_f][1], kind : "form", detail : _forms[_f][2] });
        _f += 1;
    }
    return _out;
};

// Opens the addressing-form popup at the caret if this operand slot has forms.
ed_form_open = function() {
    if (!ed_form_slot_empty()) return false;
    var _slot = ed_form_slot();
    if (_slot == undefined) return false;
    var _items = ed_form_items(_slot.mnemonic, _slot.index, _slot.lower);
    if (array_length(_items) == 0) return false;
    ac_open = true;
    ac_items = _items;
    ac_index = 0;
    ac_scroll = 0;
    ac_context = "form";
    ac_prefix = "";
    ac_start_col = caret_col;
    ac_line = caret_line;
    ac_mnemonic = _slot.mnemonic;
    return true;
};

ed_ac_accept = function(_idx) {
    if (!ac_open || _idx < 0 || _idx >= array_length(ac_items)) return;
    var _item = ac_items[_idx];
    var _text = _item.text;
    var _kind = _item.kind;

    var _case_src = (ac_context == "size" && ac_prefix == "") ? ac_mnemonic : ac_prefix;
    if ((_kind == "mnemonic" || _kind == "directive" || _kind == "size" || _kind == "register")
        && string_lower(_case_src) == _case_src && string_upper(_case_src) != _case_src) {
        _text = string_lower(_text);
    }

    var _line_i = caret_line;
    var _s = lines[_line_i];
    var _start = clamp(ac_start_col, 0, caret_col);
    ed_undo_push("edit");
    lines[_line_i] = string_copy(_s, 1, _start) + _text + string_delete(_s, 1, caret_col);
    caret_col = _start + string_length(_text);
    anchor_line = caret_line;
    anchor_col = caret_col;
    ac_close();

    var _lang = scr_asm_lang_data();
    var _next = (caret_col < string_length(lines[_line_i])) ? string_char_at(lines[_line_i], caret_col + 1) : "";
    var _reopen = false;
    var _forms = false;

    if (_kind == "mnemonic" || _kind == "directive") {
        var _u = string_upper(_text);
        var _info = (_kind == "mnemonic") ? _lang.mnemonics[$ _u] : _lang.directives[$ _u];
        if (_info != undefined) {
            if (array_length(_info.sizes) > 1 && _next != ".") {
                ed_insert_raw(".");
                _reopen = true;
            } else if (_info.max_ops != 0 && _next != ".") {
                ed_insert_operand_gap();
                _forms = _kind == "mnemonic";
            }
        }
    } else if (_kind == "size") {
        ed_insert_operand_gap();
        _forms = true;
    } else if (_kind == "form") {
        // The first of two operands: add the comma and offer the second.
        var _slot = ed_form_slot();
        if (_slot != undefined && _next != ",") {
            var _key = string_upper(_slot.mnemonic);
            if (_key == "DBF") _key = "DBRA";
            var _entry = global.opcode_map[$ _key];
            if (_entry != undefined && _slot.index + 1 < _entry.operand_count) {
                ed_insert_raw(",");
                _forms = true;
            }
        }
    }

    ed_modified();
    ed_undo_break();
    if (_reopen) ed_ac_update(true);
    if (_forms) ed_form_open();
};

#endregion

#region helpers: close / commit

ed_commit = function() {
    if (course_mode) {
        var _ctext = ed_text();
        if (_ctext == committed_text) return false;
        committed_text = _ctext;
        dirty_check_rev = -1;
        with (obj_course) lesson_save_code(_ctext);
        return true;
    }
    if (!instance_exists(editor_node)) return false;
    var _text = ed_text();
    if (_text == committed_text) return false;
    scr_push_undo_snapshot();
    editor_node.macro_code_text = _text;
    committed_text = _text;
    dirty_check_rev = -1;
    scr_mark_workspace_dirty();
    return true;
};

/// Writes the title-bar name to the node (one undo step when it changed).
ed_commit_name = function() {
    if (course_mode || !instance_exists(editor_node)) return false;
    var _name = string_trim(name_text);
    name_text = _name;
    if (_name == scr_code_block_name(editor_node)) return false;
    scr_push_undo_snapshot();
    editor_node.macro_code_name = _name;
    scr_mark_workspace_dirty();
    ed_note(_name == "" ? "Block name cleared" : "Block named \"" + _name + "\"", make_colour_rgb(120, 220, 120));
    return true;
};

ed_close = function(_commit) {
    if (closing) return;
    closing = true;
    if (_commit) ed_commit_name();
    if (_commit) ed_commit();
    keyboard_string = "";
    io_clear();
    instance_destroy();
};

ed_load = function(_node) {
    editor_node = _node;
    editor_node_uid = variable_instance_exists(_node, "uid") ? _node.uid : -1;
    var _text = variable_instance_exists(_node, "macro_code_text") ? _node.macro_code_text : "";
    if (!is_string(_text)) _text = string(_text);

    lines = ed_text_to_lines(_text);
    // Compare against the tab-expanded form so merely opening and closing a
    // block that used tabs / CRLF never rewrites the node or pushes undo.
    committed_text = ed_text();

    editor_title = "CODE BLOCK";
    name_text = scr_code_block_name(_node);

    caret_line = 0;
    caret_col = 0;
    anchor_line = 0;
    anchor_col = 0;
    scroll_line = 0;
    scroll_col = 0;
    undo_stack = [];
    redo_stack = [];
    text_revision += 1;
    analysis_due = 0;
    ed_run_analysis();
    keyboard_string = "";
};

/// Course mode: edits _text for a lesson (obj_course saves it and runs the tests).
ed_load_course = function(_text, _title) {
    course_mode = true;
    editor_node = noone;
    editor_node_uid = COURSE_EDITOR_UID;
    lines = ed_text_to_lines(_text);
    committed_text = ed_text();
    editor_title = _title;
    name_text = "";
    caret_line = 0;
    caret_col = 0;
    anchor_line = 0;
    anchor_col = 0;
    scroll_line = 0;
    scroll_col = 0;
    undo_stack = [];
    redo_stack = [];
    text_revision += 1;
    analysis_due = 0;
    ed_run_analysis();
    keyboard_string = "";
};

#endregion

#region helpers: layout

ed_apply_font = function() {
    code_font = scr_code_editor_font_ensure(font_size);
    font_is_mono = global.code_editor_font_is_mono;
    global.code_editor_font_pref_size = font_size;
    draw_set_font(code_font);
    if (font_is_mono) {
        char_w = max(1, string_width("M"));
    } else {
        char_w = max(1, max(string_width("M"), string_width("W"), string_width("0")));
    }
    line_h = max(8, ceil(string_height("Mg|")) + 2);
    draw_set_font(UI_FONT);
    ui_h = max(12, string_height("Ag"));
};

ed_change_font_size = function(_delta) {
    var _new = clamp(font_size + _delta, 8, 32);
    if (_new == font_size) return;
    font_size = _new;
    ed_apply_font();
    ensure_visible = true;
    ed_note("Font size " + string(font_size), c_white);
    scr_code_editor_prefs_save();
};

ed_add_button = function(_id, _label, _x1, _y1, _y2, _active) {
    draw_set_font(UI_FONT);
    var _w = string_width(_label) + 18;
    array_push(buttons, { id : _id, label : _label, x1 : _x1, y1 : _y1, x2 : _x1 + _w, y2 : _y2, active : _active });
    return _x1 + _w + 6;
};

ed_layout = function() {
    panel_x1 = 40;
    panel_y1 = 24;
    panel_x2 = course_mode ? course_x2 : room_width - 40;
    panel_y2 = room_height - 24;
    buttons = [];

    title_y1 = panel_y1;
    title_y2 = panel_y1 + ui_h + 12;

    // title-bar buttons (right aligned): measure first
    draw_set_font(UI_FONT);
    var _right_labels = course_mode ? ["FIND", "REPLACE", "GO TO", "RUN TESTS (F5)", "MAP"] : ["FIND", "REPLACE", "GO TO", "BUILD (F5)", "CLOSE"];
    var _right_ids = ["find", "replace", "goto", "build", "close"];
    var _total = 0;
    var _i = 0;
    while (_i < array_length(_right_labels)) {
        _total += string_width(_right_labels[_i]) + 18 + 6;
        _i += 1;
    }
    var _bx = panel_x2 - 8 - _total + 6;
    _i = 0;
    while (_i < array_length(_right_labels)) {
        _bx = ed_add_button(_right_ids[_i], _right_labels[_i], _bx, title_y1 + 4, title_y2 - 4, false);
        _i += 1;
    }

    // NAME field after the title.
    var _nx = panel_x1 + 16 + string_width(editor_title + "  *") + 14 + string_width("NAME:") + 8;
    name_field_rect = course_mode ? [0, 0, 0, 0] : [_nx, title_y1 + 4, _nx + 300, title_y2 - 4];

    toolbar_y1 = title_y2 + 6;
    toolbar_y2 = toolbar_y1 + ui_h + 8;
    _bx = panel_x1 + 16;
    draw_set_font(UI_FONT);
    _bx += string_width("INSERT:") + 10;
    _i = 0;
    while (_i < array_length(snippets)) {
        _bx = ed_add_button("snip" + string(_i), snippets[_i].label, _bx, toolbar_y1, toolbar_y2, false);
        _i += 1;
    }

    // Typing aids (right aligned): lit when on.
    var _opt_labels = ["AUTO-COMPLETE", "AUTO-CLOSE ( ) \" '"];
    var _opt_ids = ["opt_autocomplete", "opt_autoclose"];
    var _opt_on = [global.code_editor_autocomplete, global.code_editor_autoclose];
    var _opt_total = 0;
    _i = 0;
    while (_i < 2) {
        _opt_total += string_width(_opt_labels[_i]) + 18 + 6;
        _i += 1;
    }
    var _ox = panel_x2 - 8 - _opt_total + 6;
    _i = 0;
    while (_i < 2) {
        _ox = ed_add_button(_opt_ids[_i], _opt_labels[_i], _ox, toolbar_y1, toolbar_y2, _opt_on[_i]);
        _i += 1;
    }

    var _y = toolbar_y2 + 6;
    findbar_y1 = _y;
    findbar_y2 = _y;
    find_field_rect = [0, 0, 0, 0];
    replace_field_rect = [0, 0, 0, 0];
    goto_field_rect = [0, 0, 0, 0];

    if (find_open || goto_open) {
        findbar_y1 = _y;
        findbar_y2 = _y + ui_h + 10;
        var _fx = panel_x1 + 16;
        draw_set_font(UI_FONT);
        if (goto_open) {
            _fx += string_width("GO TO LINE:") + 10;
            goto_field_rect = [_fx, findbar_y1, _fx + 160, findbar_y2];
            _fx += 170;
            _fx = ed_add_button("goto_go", "GO", _fx, findbar_y1, findbar_y2, false);
            ed_add_button("bar_close", "X", _fx, findbar_y1, findbar_y2, false);
        } else {
            _fx += string_width("FIND:") + 10;
            find_field_rect = [_fx, findbar_y1, _fx + 360, findbar_y2];
            _fx += 370;
            _fx = ed_add_button("find_case", "Aa", _fx, findbar_y1, findbar_y2, find_case);
            _fx = ed_add_button("find_prev", "PREV", _fx, findbar_y1, findbar_y2, false);
            _fx = ed_add_button("find_next", "NEXT", _fx, findbar_y1, findbar_y2, false);
            if (replace_open) {
                _fx += string_width("REPLACE:") + 16;
                replace_field_rect = [_fx, findbar_y1, _fx + 300, findbar_y2];
                _fx += 310;
                _fx = ed_add_button("replace_one", "REPLACE", _fx, findbar_y1, findbar_y2, false);
                _fx = ed_add_button("replace_all", "ALL", _fx, findbar_y1, findbar_y2, false);
            }
            ed_add_button("bar_close", "X", _fx, findbar_y1, findbar_y2, false);
        }
        _y = findbar_y2 + 6;
    }

    status_y1 = panel_y2 - (ui_h * 2 + 18);
    text_top = _y + 2;
    hbar_y2 = status_y1 - 6;
    hbar_y1 = hbar_y2 - 12;
    text_bottom = hbar_y1 - 2;

    var _digits = max(4, string_length(string(array_length(lines))) + 1);
    gutter_x = panel_x1 + 8;
    gutter_w = _digits * char_w + 18;
    text_x = gutter_x + gutter_w + 8;
    vbar_x2 = panel_x2 - 8;
    vbar_x1 = vbar_x2 - 12;
    text_right = vbar_x1 - 4;

    vis_lines = max(1, floor((text_bottom - text_top) / line_h));
    vis_cols = max(1, floor((text_right - text_x) / char_w));
};

ed_point_in = function(_x, _y, _r) {
    return _x >= _r[0] && _x < _r[2] && _y >= _r[1] && _y < _r[3];
};

ed_mouse_pos = function(_mx, _my) {
    var _l = scroll_line + floor((_my - text_top) / line_h);
    _l = clamp(_l, 0, array_length(lines) - 1);
    var _c = scroll_col + round((_mx - text_x) / char_w);
    _c = clamp(_c, 0, string_length(lines[_l]));
    return [_l, _c];
};

ed_vbar_metrics = function() {
    var _track = text_bottom - text_top;
    var _max = ed_max_scroll_line();
    var _thumb = (_max <= 0) ? _track : max(24, _track * vis_lines / (_max + vis_lines));
    var _ty = text_top + ((_max <= 0) ? 0 : (_track - _thumb) * (scroll_line / _max));
    return [_ty, _thumb, _track, _max];
};

ed_hbar_metrics = function() {
    var _track = text_right - text_x;
    var _max = ed_max_scroll_col();
    var _thumb = (_max <= 0) ? _track : max(24, _track * vis_cols / (_max + vis_cols));
    var _tx = text_x + ((_max <= 0) ? 0 : (_track - _thumb) * (scroll_col / _max));
    return [_tx, _thumb, _track, _max];
};

#endregion

#region helpers: buttons

ed_button_action = function(_id) {
    switch (_id) {
        case "find": ed_open_find(false); break;
        case "replace": ed_open_find(true); break;
        case "goto":
            goto_open = true;
            find_open = false;
            replace_open = false;
            goto_text = "";
            focus = "goto";
            field_fresh = false;
            break;
        case "build":
            if (course_mode) {
                ed_commit();
                with (obj_course) lesson_run_tests();
                break;
            }
            ed_commit_name();
            ed_commit();
            scr_amiga_trigger_build();
            ed_note("Build started (F5)", make_colour_rgb(120, 220, 255));
            break;
        case "close": ed_close(true); break;
        case "find_case":
            find_case = !find_case;
            find_key = "";
            break;
        case "find_prev": ed_find_next(false); break;
        case "find_next": ed_find_next(true); break;
        case "replace_one": ed_replace_one(); break;
        case "replace_all": ed_replace_all(); break;
        case "goto_go":
            if (goto_text != "") ed_goto_line(real(goto_text) - 1);
            ed_close_bars();
            break;
        case "bar_close": ed_close_bars(); break;
        case "opt_autocomplete":
            global.code_editor_autocomplete = !global.code_editor_autocomplete;
            scr_code_editor_prefs_save();
            if (!global.code_editor_autocomplete) ac_close();
            ed_note(global.code_editor_autocomplete ? "Autocomplete pops up as you type" : "Autocomplete off - Ctrl+Space still completes", c_white);
            focus = "text";
            break;
        case "opt_autoclose":
            global.code_editor_autoclose = !global.code_editor_autoclose;
            scr_code_editor_prefs_save();
            ed_note(global.code_editor_autoclose ? "Brackets and quotes close themselves" : "Auto-close off", c_white);
            focus = "text";
            break;
        default:
            if (string_copy(_id, 1, 4) == "snip") {
                var _si = real(string_delete(_id, 1, 4));
                if (_si >= 0 && _si < array_length(snippets)) ed_insert_snippet(snippets[_si]);
                focus = "text";
            }
            break;
    }
};

#endregion

#region helpers: drawing / hover

closing = false;
is_dirty = false;
dirty_check_rev = -1;

col_bg = make_colour_rgb(14, 18, 30);
col_gutter_bg = make_colour_rgb(11, 14, 24);
col_panel_edge = make_colour_rgb(70, 90, 140);
col_text = make_colour_rgb(220, 222, 232);
col_comment = make_colour_rgb(96, 176, 96);
col_mnemonic = make_colour_rgb(130, 185, 255);
col_size = make_colour_rgb(95, 125, 195);
col_directive = make_colour_rgb(90, 220, 230);
col_register = make_colour_rgb(255, 165, 75);
col_number = make_colour_rgb(240, 220, 100);
col_immediate = make_colour_rgb(255, 135, 195);
col_label = make_colour_rgb(240, 200, 80);
col_symbol_known = make_colour_rgb(135, 220, 135);
col_symbol_unknown = make_colour_rgb(255, 95, 95);
col_hwreg = make_colour_rgb(70, 205, 185);
col_string = make_colour_rgb(225, 175, 125);
col_operator = make_colour_rgb(185, 188, 205);
col_unknown = make_colour_rgb(255, 95, 95);
col_macro = make_colour_rgb(205, 155, 255);
col_error = make_colour_rgb(255, 80, 80);
col_warning = make_colour_rgb(255, 185, 60);
col_selection = make_colour_rgb(45, 72, 135);
col_current_line = make_colour_rgb(24, 31, 52);
col_find = make_colour_rgb(110, 90, 30);

ed_token_colour = function(_t) {
    switch (_t.kind) {
        case "comment": return col_comment;
        case "mnemonic": return col_mnemonic;
        case "size": return col_size;
        case "directive": return col_directive;
        case "register": return col_register;
        case "number": return col_number;
        case "immediate_prefix": return col_immediate;
        case "label": return col_label;
        case "hwreg": return col_hwreg;
        case "string": return col_string;
        case "operator": return col_operator;
        case "symbol":
            if (string_pos("\\", _t.text) > 0 || variable_struct_exists(known_symbols, _t.text)) return col_symbol_known;
            return col_symbol_unknown;
        case "unknown":
            if (_t.field == "op" && (variable_struct_exists(analysis.macros, _t.text) || string_pos("\\", _t.text) > 0)) return col_macro;
            return col_unknown;
    }
    return col_text;
};

// Draws code text; falls back to fixed cells when no monospace font loaded.
ed_draw_code = function(_x, _y, _s) {
    if (font_is_mono) {
        draw_text(_x, _y, _s);
        return;
    }
    var _n = string_length(_s);
    var _i = 1;
    while (_i <= _n) {
        var _ch = string_char_at(_s, _i);
        if (_ch != " ") draw_text(_x + (_i - 1) * char_w + (char_w - string_width(_ch)) * 0.5, _y, _ch);
        _i += 1;
    }
};

ed_line_end_pos = function(_l) {
    if (_l < array_length(lines) - 1) return [_l + 1, 0];
    return [_l, string_length(lines[_l])];
};

ed_token_at = function(_l, _c) {
    var _tk = scr_asm_tokenize_line(lines[_l]);
    var _i = 0;
    while (_i < array_length(_tk)) {
        var _t = _tk[_i];
        if (_c >= _t.start_col && _c < _t.start_col + string_length(_t.text)) return _t;
        _i += 1;
    }
    return undefined;
};

ed_number_info = function(_text) {
    var _v = undefined;
    var _first = string_char_at(_text, 1);
    try {
        if (_first == "$") {
            _v = 0;
            var _i = 2;
            while (_i <= string_length(_text)) {
                _v = _v * 16 + (string_pos(string_lower(string_char_at(_text, _i)), "0123456789abcdef") - 1);
                _i += 1;
            }
        } else if (_first == "%") {
            _v = 0;
            var _j = 2;
            while (_j <= string_length(_text)) {
                _v = _v * 2 + ((string_char_at(_text, _j) == "1") ? 1 : 0);
                _j += 1;
            }
        } else if (_first == "@") {
            _v = 0;
            var _k = 2;
            while (_k <= string_length(_text)) {
                _v = _v * 8 + real(string_char_at(_text, _k));
                _k += 1;
            }
        } else {
            _v = real(_text);
        }
    } catch (_err) {
        return "";
    }
    if (_v == undefined) return "";
    var _hex = "";
    var _h = _v;
    do {
        _hex = string_char_at("0123456789ABCDEF", (_h mod 16) + 1) + _hex;
        _h = _h div 16;
    } until (_h <= 0);
    return _text + " = " + string(_v) + " = $" + _hex;
};

ed_hover_help = function(_l, _c) {
    var _t = ed_token_at(_l, _c);
    if (_t == undefined) return "";
    var _help = "";
    switch (_t.kind) {
        case "mnemonic":
        case "directive":
        case "register":
        case "hwreg":
            _help = scr_asm_symbol_help(_t.text);
            break;
        case "size":
            var _sz = string_upper(string_delete(_t.text, 1, 1));
            _help = _t.text + " = " + ((_sz == "B") ? "byte (8-bit)" : ((_sz == "W") ? "word (16-bit)" : ((_sz == "L") ? "long (32-bit)" : ((_sz == "S") ? "short branch" : "size"))));
            break;
        case "number":
            _help = ed_number_info(_t.text);
            break;
        case "label":
            var _nm = _t.text;
            while (string_length(_nm) > 0 && string_char_at(_nm, string_length(_nm)) == ":") _nm = string_copy(_nm, 1, string_length(_nm) - 1);
            _help = (variable_struct_exists(analysis.macros, _nm) ? "Macro '" : "Label '") + _nm + "' (line " + string(_l + 1) + ")";
            break;
        case "symbol":
        case "unknown":
            var _def = ed_find_label_line(_t.text, _l);
            if (_def >= 0) {
                _help = "'" + _t.text + "' defined on line " + string(_def + 1) + ":  " + string_trim(lines[_def]);
            } else if (array_contains(global_symbol_list, _t.text)) {
                _help = "'" + _t.text + "' - global symbol defined in another node";
            } else if (_t.kind == "symbol" && variable_struct_exists(known_symbols, _t.text)) {
                _help = "'" + _t.text + "' - external / XREF symbol";
            }
            break;
    }
    var _dl = diag_by_line[$ string(_l)];
    if (_dl != undefined) {
        var _i = 0;
        while (_i < array_length(_dl)) {
            var _d = _dl[_i];
            if (_c >= _d.col && _c < _d.col + _d.len) {
                _help += ((_help != "") ? "\n" : "") + ((_d.severity == "error") ? "ERROR: " : "WARNING: ") + _d.message;
            }
            _i += 1;
        }
    }
    return _help;
};

ed_draw_wave = function(_x1, _x2, _y, _colour) {
    draw_set_colour(_colour);
    var _x = _x1;
    var _up = true;
    while (_x < _x2) {
        var _nx = min(_x + 3, _x2);
        draw_line(_x, _y + (_up ? 0 : 2), _nx, _y + (_up ? 2 : 0));
        _up = !_up;
        _x = _nx;
    }
};

#endregion

// Measure fonts once the methods exist.
ed_apply_font();
ed_layout();
keyboard_string = "";
