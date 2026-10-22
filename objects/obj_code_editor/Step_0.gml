// obj_code_editor Step - owns all keyboard and mouse input while open.

if (closing) exit;

if (!course_mode && !instance_exists(editor_node)) {
    scr_set_status_message("Code editor closed: its node no longer exists.", c_red);
    closing = true;
    keyboard_string = "";
    io_clear();
    instance_destroy();
    exit;
}

ed_layout();
ac_row_h = max(line_h, ui_h) + 2;

// The editor tour is presenting this screen: its input belongs to the tour.
if (instance_exists(obj_editor_tour)) exit;

var _ctrl = ed_kd(vk_control);
var _shift = ed_kd(vk_shift);
var _alt = ed_kd(vk_alt);
// AltGr arrives as Ctrl+Alt: treat it as plain typing, not a shortcut.
var _cmd = _ctrl && !_alt;

// ---- typed characters ----
var _typed_raw = keyboard_string;
keyboard_string = "";
var _typed = "";

if (!_cmd && _typed_raw != "") {
    var _tn = string_length(_typed_raw);
    var _ti = 1;
    while (_ti <= _tn) {
        var _tch = string_char_at(_typed_raw, _ti);
        var _to = ord(_tch);
        if (_to >= 32 && _to != 127) _typed += _tch;
        _ti += 1;
    }
}

// ---- key repeat bookkeeping ----
var _rk = 0;
while (_rk < array_length(rep_keys)) {
    var _code = rep_keys[_rk];
    key_hold[_code] = ed_kd(_code) ? key_hold[_code] + 1 : 0;
    _rk += 1;
}

var _key = function(_k) {
    if (ed_kp(_k)) return true;
    var _h = key_hold[_k];
    return _h > repeat_delay && ((_h - repeat_delay) mod repeat_rate) == 0;
};

blink_timer += 1;

var _ac_refresh = false;
var _ac_force = false;

// =====================================================================
// Global keys
// =====================================================================
if (ed_kp(vk_escape)) {
    if (ac_open) {
        ac_close();
    } else if (find_open || goto_open) {
        ed_close_bars();
    } else {
        ed_close(true);
        exit;
    }
}

if (_cmd && ed_kp(vk_enter)) {
    ed_close(true);
    exit;
}

if (ed_kp(vk_f5)) {
    ed_button_action("build");
}

if (_cmd && ed_kp(ord("S"))) {
    if (ed_commit()) {
        ed_note(course_mode ? "Code saved" : "Code applied to the node", make_colour_rgb(120, 220, 120));
    } else {
        ed_note("No changes to apply", c_ltgray);
    }
}

if (_cmd && ed_kp(ord("F"))) ed_open_find(false);
if (_cmd && ed_kp(ord("H"))) ed_open_find(true);
if (_cmd && ed_kp(ord("G"))) ed_button_action("goto");
if (_key(vk_f3)) ed_find_next(!_shift);
if (_key(vk_f8)) ed_next_diagnostic();
if (ed_kp(vk_f12)) {
    ed_undo_break();
    ed_goto_definition(caret_line, caret_col);
}

if (_cmd) {
    if (ed_kp(187) || ed_kp(vk_add)) ed_change_font_size(1);
    if (ed_kp(189) || ed_kp(vk_subtract)) ed_change_font_size(-1);
    if (ed_kp(ord("0")) || ed_kp(vk_numpad0)) ed_change_font_size(13 - font_size);
}

// =====================================================================
// Bar fields (find / replace / go to)
// =====================================================================
if (focus == "name") {
    // The block's name: any text, one line, up to 40 characters.
    if (_typed != "") name_text = string_copy(name_text + _typed, 1, 40);
    if (_key(vk_backspace)) name_text = _cmd ? "" : string_copy(name_text, 1, max(0, string_length(name_text) - 1));
    if (_cmd && ed_kp(ord("V")) && clipboard_has_text()) {
        var _name_clip = string_replace_all(clipboard_get_text(), "\r", "");
        var _name_nl = string_pos("\n", _name_clip);
        if (_name_nl > 0) _name_clip = string_copy(_name_clip, 1, _name_nl - 1);
        name_text = string_copy(name_text + _name_clip, 1, 40);
    }
    if ((ed_kp(vk_enter) && !_cmd) || ed_kp(vk_tab)) {
        ed_commit_name();
        focus = "text";
    }
} else if (focus != "text") {
    var _val = (focus == "find") ? find_text : ((focus == "replace") ? replace_text : goto_text);
    var _before_val = _val;
    var _bs = _key(vk_backspace);
    var _paste = _cmd && ed_kp(ord("V")) && clipboard_has_text();

    // A freshly opened field behaves as fully selected.
    if (field_fresh && (_typed != "" || _bs || _paste)) {
        _val = "";
        _bs = false;
    }
    if (_typed != "" || _paste || ed_kp(vk_enter) || ed_kp(vk_tab) || ed_kp(vk_backspace)) field_fresh = false;

    if (_typed != "") {
        if (focus == "goto") {
            var _gi = 1;
            while (_gi <= string_length(_typed)) {
                var _gch = string_char_at(_typed, _gi);
                if (ord(_gch) >= 48 && ord(_gch) <= 57) _val += _gch;
                _gi += 1;
            }
        } else {
            _val += _typed;
        }
    }

    if (_bs) {
        _val = _cmd ? "" : string_copy(_val, 1, max(0, string_length(_val) - 1));
    }

    if (_paste) {
        var _clip = string_replace_all(clipboard_get_text(), "\r", "");
        var _nlp = string_pos("\n", _clip);
        if (_nlp > 0) _clip = string_copy(_clip, 1, _nlp - 1);
        _val += _clip;
    }

    if (focus == "find") {
        find_text = _val;
    } else if (focus == "replace") {
        replace_text = _val;
    } else {
        goto_text = _val;
    }

    if (focus == "find" && _val != _before_val) {
        find_key = "";
        if (find_text != "") ed_find_from(find_origin_line, find_origin_col, true, true);
    }

    if (ed_kp(vk_enter) && !_cmd) {
        if (focus == "find") {
            ed_find_next(!_shift);
        } else if (focus == "replace") {
            if (_alt) ed_replace_all(); else ed_replace_one();
        } else {
            ed_button_action("goto_go");
        }
    }

    if (ed_kp(vk_tab) && find_open && replace_open) {
        focus = (focus == "find") ? "replace" : "find";
        field_fresh = true;
    }
} else {
    // =================================================================
    // Text editing
    // =================================================================
    var _skip_updown = false;
    var _skip_enter = false;
    var _skip_tab = false;
    var _skip_page = false;

    if (ac_open) {
        var _count = array_length(ac_items);
        if (_key(vk_down)) {
            ac_index = (ac_index + 1) mod _count;
            _skip_updown = true;
        }
        if (_key(vk_up)) {
            ac_index = (ac_index - 1 + _count) mod _count;
            _skip_updown = true;
        }
        if (_key(vk_pagedown)) {
            ac_index = min(_count - 1, ac_index + ac_rows);
            _skip_page = true;
        }
        if (_key(vk_pageup)) {
            ac_index = max(0, ac_index - ac_rows);
            _skip_page = true;
        }
        var _sel_item_text = (ac_index < _count) ? ac_items[ac_index].text : "";
        var _typed_prefix = string_copy(lines[caret_line], ac_start_col + 1, caret_col - ac_start_col);
        if (!_cmd && ed_kp(vk_enter) && string_upper(_sel_item_text) == string_upper(_typed_prefix) && ac_context != "size") {
            // nothing to complete: let Enter make a new line
            ac_close();
        } else if (!_cmd && ed_kp(vk_enter)) {
            ed_ac_accept(ac_index);
            _skip_enter = true;
        } else if (!_cmd && !_shift && ed_kp(vk_tab)) {
            ed_ac_accept(ac_index);
            _skip_tab = true;
        }
        if (ac_open) {
            if (ac_index < ac_scroll) ac_scroll = ac_index;
            if (ac_index >= ac_scroll + ac_rows) ac_scroll = ac_index - ac_rows + 1;
        }
    }

    // ---- shortcuts ----
    if (_cmd) {
        if (ed_kp(ord("A"))) ed_select_all();
        if (ed_kp(ord("C"))) ed_copy(false);
        if (ed_kp(ord("X"))) {
            ed_copy(true);
            ac_close();
        }
        if (ed_kp(ord("V"))) {
            ed_paste();
            ac_close();
        }
        if (_key(ord("Z"))) {
            if (_shift) ed_redo(); else ed_undo();
        }
        if (_key(ord("Y"))) ed_redo();
        if (_key(ord("D"))) ed_duplicate();
        if (ed_kp(191) || ed_kp(186) || ed_kp(vk_divide)) ed_toggle_comment();
        if (_shift && ed_kp(ord("K"))) {
            ed_delete_lines();
            ac_close();
        }
        if (ed_kp(vk_space)) _ac_force = true;
    }

    if (_alt && !_ctrl && !_skip_updown) {
        if (_key(vk_up)) {
            ed_move_lines(-1);
            _skip_updown = true;
        } else if (_key(vk_down)) {
            ed_move_lines(1);
            _skip_updown = true;
        }
    }

    // ---- caret navigation ----
    var _nav = false;

    if (_key(vk_left)) {
        _nav = true;
        if (!_shift && ed_has_sel() && !_cmd) {
            var _rl = ed_sel_range();
            ed_set_caret(_rl[0], _rl[1], false);
        } else if (_cmd) {
            var _wl = ed_word_left(caret_line, caret_col);
            ed_set_caret(_wl[0], _wl[1], _shift);
        } else if (caret_col > 0) {
            ed_set_caret(caret_line, caret_col - 1, _shift);
        } else if (caret_line > 0) {
            ed_set_caret(caret_line - 1, string_length(lines[caret_line - 1]), _shift);
        } else {
            ed_set_caret(0, 0, _shift);
        }
    }

    if (_key(vk_right)) {
        _nav = true;
        if (!_shift && ed_has_sel() && !_cmd) {
            var _rr = ed_sel_range();
            ed_set_caret(_rr[2], _rr[3], false);
        } else if (_cmd) {
            var _wr = ed_word_right(caret_line, caret_col);
            ed_set_caret(_wr[0], _wr[1], _shift);
        } else if (caret_col < string_length(lines[caret_line])) {
            ed_set_caret(caret_line, caret_col + 1, _shift);
        } else if (caret_line < array_length(lines) - 1) {
            ed_set_caret(caret_line + 1, 0, _shift);
        } else {
            ed_set_caret(caret_line, caret_col, _shift);
        }
    }

    if (!_skip_updown && !_alt) {
        var _vdir = 0;
        if (_key(vk_up)) _vdir = -1;
        if (_key(vk_down)) _vdir = 1;
        if (_vdir != 0) {
            _nav = true;
            if (_cmd) {
                // Ctrl+Up/Down scrolls the view without moving the caret
                scroll_line += _vdir;
                ed_clamp_scroll();
            } else {
                var _keep_desired = desired_col;
                var _target = caret_line + _vdir;
                if (_target < 0) {
                    ed_set_caret(0, 0, _shift);
                } else if (_target >= array_length(lines)) {
                    ed_set_caret(caret_line, string_length(lines[caret_line]), _shift);
                } else {
                    ed_set_caret(_target, min(_keep_desired, string_length(lines[_target])), _shift);
                    desired_col = _keep_desired;
                }
            }
        }
    }

    if (!_skip_page) {
        var _pdir = 0;
        if (_key(vk_pageup)) _pdir = -1;
        if (_key(vk_pagedown)) _pdir = 1;
        if (_pdir != 0) {
            _nav = true;
            var _keep_dc = desired_col;
            var _pt = clamp(caret_line + _pdir * vis_lines, 0, array_length(lines) - 1);
            scroll_line += _pdir * vis_lines;
            ed_clamp_scroll();
            ed_set_caret(_pt, min(_keep_dc, string_length(lines[_pt])), _shift);
            desired_col = _keep_dc;
        }
    }

    if (ed_kp(vk_home)) {
        _nav = true;
        if (_cmd) {
            ed_set_caret(0, 0, _shift);
        } else {
            var _lead = ed_leading_spaces(lines[caret_line]);
            if (_lead >= string_length(lines[caret_line])) _lead = 0;
            ed_set_caret(caret_line, (caret_col == _lead) ? 0 : _lead, _shift);
        }
    }

    if (ed_kp(vk_end)) {
        _nav = true;
        if (_cmd) {
            var _ll = array_length(lines) - 1;
            ed_set_caret(_ll, string_length(lines[_ll]), _shift);
        } else {
            ed_set_caret(caret_line, string_length(lines[caret_line]), _shift);
        }
    }

    if (_nav) {
        ed_undo_break();
        ac_close();
    }

    // ---- editing keys ----
    if (!_skip_enter && !_cmd && _key(vk_enter)) {
        ed_newline();
        ac_close();
    }

    if (!_skip_tab && !_cmd && ed_kp(vk_tab)) {
        ed_tab(_shift);
        ac_close();
        // Tab after a typed instruction: offer its addressing forms.
        if (!_shift && global.code_editor_autocomplete) ed_form_open();
    }

    if (_key(vk_backspace)) {
        if (_cmd || !ed_backspace_pair()) ed_backspace(_cmd);
        if (ac_open) _ac_refresh = true;
    }

    if (_key(vk_delete)) {
        ed_delete_forward(_cmd);
        ac_close();
    }

    if (_typed != "") {
        if (string_length(_typed) != 1 || !ed_type_autoclose(_typed)) ed_type_text(_typed);
        var _last_o = ord(string_char_at(_typed, string_length(_typed)));
        // A space or comma may start an empty operand: the addressing forms.
        if (ed_is_word_code(_last_o) || _last_o == 46 || _last_o == 32 || _last_o == 44) {
            _ac_refresh = true;
        } else {
            ac_close();
        }
    }
}

// =====================================================================
// Mouse
// =====================================================================
var _mx = sim_mouse_active ? sim_mx : mouse_x;
var _my = sim_mouse_active ? sim_my : mouse_y;
var _mp = sim_mouse_active ? sim_mp : mouse_check_button_pressed(mb_left);
var _mh = sim_mouse_active ? sim_mh : mouse_check_button(mb_left);

if (mouse_block) {
    if (!_mh) mouse_block = false;
    _mp = false;
    _mh = false;
}

var _handled = false;

if (_mp && ac_open) {
    if (ed_point_in(_mx, _my, ac_rect)) {
        var _row = floor((_my - ac_rect[1] - 2) / ac_row_h) + ac_scroll;
        if (_row >= 0 && _row < array_length(ac_items)) ed_ac_accept(_row);
        _handled = true;
    } else {
        ac_close();
    }
}

if (_mp && !_handled) {
    var _bi = 0;
    while (_bi < array_length(buttons)) {
        var _b = buttons[_bi];
        if (_mx >= _b.x1 && _mx < _b.x2 && _my >= _b.y1 && _my < _b.y2) {
            ed_button_action(_b.id);
            _handled = true;
            break;
        }
        _bi += 1;
    }
    if (closing) exit;
}

// Clicking anywhere but the name field commits the name.
if (_mp && focus == "name" && !ed_point_in(_mx, _my, name_field_rect)) {
    ed_commit_name();
    focus = "text";
}

if (_mp && !_handled) {
    if (ed_point_in(_mx, _my, name_field_rect)) {
        focus = "name";
        ac_close();
        _handled = true;
    } else if (find_open && ed_point_in(_mx, _my, find_field_rect)) {
        focus = "find";
        field_fresh = false;
        _handled = true;
    } else if (replace_open && ed_point_in(_mx, _my, replace_field_rect)) {
        focus = "replace";
        field_fresh = false;
        _handled = true;
    } else if (goto_open && ed_point_in(_mx, _my, goto_field_rect)) {
        focus = "goto";
        field_fresh = false;
        _handled = true;
    }
}

// ---- scrollbars ----
if (_mp && !_handled && _mx >= vbar_x1 && _mx < vbar_x2 && _my >= text_top && _my < text_bottom) {
    var _vm = ed_vbar_metrics();
    if (_my >= _vm[0] && _my < _vm[0] + _vm[1]) {
        vbar_drag = true;
        vbar_drag_off = _my - _vm[0];
    } else {
        scroll_line += (_my < _vm[0]) ? -vis_lines : vis_lines;
        ed_clamp_scroll();
    }
    _handled = true;
}

if (_mp && !_handled && _mx >= text_x && _mx < text_right && _my >= hbar_y1 && _my < hbar_y2) {
    var _hm = ed_hbar_metrics();
    if (_mx >= _hm[0] && _mx < _hm[0] + _hm[1]) {
        hbar_drag = true;
        hbar_drag_off = _mx - _hm[0];
    } else {
        scroll_col += (_mx < _hm[0]) ? -vis_cols : vis_cols;
        ed_clamp_scroll();
    }
    _handled = true;
}

if (vbar_drag) {
    if (_mh) {
        var _vm2 = ed_vbar_metrics();
        var _span_v = _vm2[2] - _vm2[1];
        if (_vm2[3] > 0 && _span_v > 0) {
            scroll_line = round((_my - vbar_drag_off - text_top) / _span_v * _vm2[3]);
            ed_clamp_scroll();
        }
    } else {
        vbar_drag = false;
    }
}

if (hbar_drag) {
    if (_mh) {
        var _hm2 = ed_hbar_metrics();
        var _span_h = _hm2[2] - _hm2[1];
        if (_hm2[3] > 0 && _span_h > 0) {
            scroll_col = round((_mx - hbar_drag_off - text_x) / _span_h * _hm2[3]);
            ed_clamp_scroll();
        }
    } else {
        hbar_drag = false;
    }
}

// ---- text area clicks ----
if (_mp && !_handled && _mx >= gutter_x && _mx < text_right && _my >= text_top && _my < text_bottom) {
    focus = "text";
    var _pos = ed_mouse_pos(_mx, _my);

    if (current_time - last_click_time < 450 && point_distance(_mx, _my, last_click_x, last_click_y) < 6) {
        click_count = min(click_count + 1, 3);
    } else {
        click_count = 1;
    }
    last_click_time = current_time;
    last_click_x = _mx;
    last_click_y = _my;
    ed_undo_break();
    ac_close();
    mouse_selecting = true;

    if (_mx < text_x - 4) {
        // gutter: select whole line
        var _le = ed_line_end_pos(_pos[0]);
        anchor_line = _pos[0];
        anchor_col = 0;
        caret_line = _le[0];
        caret_col = _le[1];
        mouse_select_mode = "line";
        sel_word_l = _pos[0];
    } else if (click_count == 1) {
        if (_cmd) {
            ed_set_caret(_pos[0], _pos[1], false);
            ed_goto_definition(_pos[0], _pos[1]);
            mouse_selecting = false;
        } else {
            ed_set_caret(_pos[0], _pos[1], _shift);
            mouse_select_mode = "char";
        }
    } else if (click_count == 2) {
        var _wb = ed_word_bounds(_pos[0], _pos[1]);
        sel_word_l = _pos[0];
        sel_word_c1 = _wb[0];
        sel_word_c2 = _wb[1];
        anchor_line = _pos[0];
        anchor_col = _wb[0];
        caret_line = _pos[0];
        caret_col = _wb[1];
        mouse_select_mode = "word";
    } else {
        var _le3 = ed_line_end_pos(_pos[0]);
        anchor_line = _pos[0];
        anchor_col = 0;
        caret_line = _le3[0];
        caret_col = _le3[1];
        mouse_select_mode = "line";
        sel_word_l = _pos[0];
    }
    desired_col = caret_col;
    blink_timer = 0;
    _handled = true;
}

if (mouse_selecting) {
    if (_mh) {
        if (_my < text_top) scroll_line -= 1;
        if (_my >= text_bottom) scroll_line += 1;
        if (_mx < text_x && mouse_select_mode != "line") scroll_col -= 2;
        if (_mx >= text_right) scroll_col += 2;
        ed_clamp_scroll();

        var _dp = ed_mouse_pos(clamp(_mx, text_x, text_right), clamp(_my, text_top, text_bottom - 1));

        if (mouse_select_mode == "char") {
            caret_line = _dp[0];
            caret_col = _dp[1];
        } else if (mouse_select_mode == "word") {
            var _dwb = ed_word_bounds(_dp[0], _dp[1]);
            if (_dp[0] < sel_word_l || (_dp[0] == sel_word_l && _dp[1] < sel_word_c1)) {
                anchor_line = sel_word_l;
                anchor_col = sel_word_c2;
                caret_line = _dp[0];
                caret_col = _dwb[0];
            } else {
                anchor_line = sel_word_l;
                anchor_col = sel_word_c1;
                caret_line = _dp[0];
                caret_col = max(_dwb[1], _dp[1]);
            }
        } else {
            if (_dp[0] < sel_word_l) {
                var _ae = ed_line_end_pos(sel_word_l);
                anchor_line = _ae[0];
                anchor_col = _ae[1];
                caret_line = _dp[0];
                caret_col = 0;
            } else {
                var _ce = ed_line_end_pos(_dp[0]);
                anchor_line = sel_word_l;
                anchor_col = 0;
                caret_line = _ce[0];
                caret_col = _ce[1];
            }
        }
        ed_clamp_caret();
        desired_col = caret_col;
        blink_timer = 0;
    } else {
        mouse_selecting = false;
    }
}

// ---- wheel ----
var _wheel = sim_mouse_active ? sim_wheel : (mouse_wheel_down() - mouse_wheel_up());
// In course mode the wheel over the lesson column belongs to obj_course.
if (course_mode && _mx >= panel_x2) _wheel = 0;
if (_wheel != 0) {
    if (ac_open && ed_point_in(_mx, _my, ac_rect)) {
        ac_scroll = clamp(ac_scroll + _wheel, 0, max(0, array_length(ac_items) - ac_rows));
    } else if (_ctrl) {
        ed_change_font_size(-_wheel);
    } else if (_shift) {
        scroll_col += _wheel * 8;
    } else {
        scroll_line += _wheel * 3;
    }
    ed_clamp_scroll();
    hover_key = "";
    hover_text = "";
}

// =====================================================================
// Analysis, autocomplete, view upkeep
// =====================================================================
ed_update_max_len();

if (analysed_revision != text_revision) {
    analysis_due -= 1;
    if (analysis_due <= 0) ed_run_analysis();
} else {
    var _be = global.code_editor_build_errors;
    var _bl = is_array(_be) ? array_length(_be) : 0;
    if (_be != build_err_ref || _bl != build_err_len) ed_refresh_build_errors();
}

if (_ac_refresh || _ac_force) {
    ed_ac_update(_ac_force);
}

if (ac_open && (caret_line != ac_line || caret_col < ac_start_col)) {
    ac_close();
}

if (dirty_check_rev != text_revision) {
    dirty_check_rev = text_revision;
    is_dirty = (ed_text() != committed_text);
}

if (find_open) ed_find_refresh();

if (ensure_visible) {
    ensure_visible = false;
    ed_ensure_caret_visible();
}
ed_clamp_scroll();

// ---- hover tooltip ----
if (!mouse_selecting && !vbar_drag && !hbar_drag && _mx >= text_x && _mx < text_right && _my >= text_top && _my < text_bottom
    && !(ac_open && ed_point_in(_mx, _my, ac_rect))) {
    var _hl = scroll_line + floor((_my - text_top) / line_h);
    var _hc = scroll_col + floor((_mx - text_x) / char_w);
    var _hkey = "";
    if (_hl >= 0 && _hl < array_length(lines) && _hc >= 0 && _hc < string_length(lines[_hl])) {
        var _ht = ed_token_at(_hl, _hc);
        if (_ht != undefined && _ht.kind != "whitespace") _hkey = string(_hl) + ":" + string(_ht.start_col) + ":" + string(text_revision);
    }
    if (_hkey != hover_key) {
        hover_key = _hkey;
        hover_since = current_time;
        hover_text = "";
    } else if (_hkey != "" && hover_text == "" && current_time - hover_since >= 500) {
        hover_text = ed_hover_help(_hl, _hc);
        hover_x = _mx;
        hover_y = _my;
        if (hover_text == "") hover_since = current_time + 1000000;
    }
} else {
    hover_key = "";
    hover_text = "";
}

// Injected (test) presses last a single step.
if (sim_active) {
    sim_pressed = array_create(256, false);
    sim_mp = false;
    sim_wheel = 0;
}
