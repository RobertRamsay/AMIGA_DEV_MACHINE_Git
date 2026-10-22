// obj_course Draw - room coordinates. The editor (course mode) draws itself
// over the left part in the lesson view.

draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// backdrop over the workspace
draw_set_alpha(0.92);
draw_set_colour(make_colour_rgb(4, 6, 12));
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

var _mx = mouse_x;
var _my = mouse_y;

// ================================================================= map
if (view == "map") {
    scr_ui_box(panel_x1, panel_y1, panel_x2, panel_y2, col_bg, col_edge);
    scr_ui_header_band(panel_x1, panel_y1, panel_x2, panel_y2, panel_y1 + title_h, col_band);
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(c_white);
    scr_ui_text_mid(panel_x1 + 24, panel_y1, panel_y1 + title_h, "68K COURSE");
    var _done = scr_course_done_count();
    draw_set_font(UI_FONT);
    draw_set_colour(col_dim);
    scr_ui_text_mid(panel_x1 + 24 + 220, panel_y1, panel_y1 + title_h, string(_done) + " of " + string(array_length(items)) + " passed - each lesson opens the next, an exam closes every 20");
    for (var _b = 0; _b < array_length(map_buttons); _b += 1) {
        var _mb = map_buttons[_b];
        scr_ui_button(_mb.x1, _mb.y1, _mb.x2, _mb.y2, _mb.label, _mb.colour, _mx >= _mb.x1 && _mx < _mb.x2 && _my >= _mb.y1 && _my < _mb.y2);
    }

    // five rows: 20 lessons and their exam
    for (var _i = 0; _i < array_length(items); _i += 1) {
        var _it = items[_i];
        var _row = _i div 21;
        var _col = _i mod 21;
        var _tx = map_x0 + _col * (tile_w + tile_gap);
        var _ty = map_y0 + _row * map_row_h + 26;
        if (_col == 0 || (_col > 0 && items[_i - 1].unit != _it.unit && _it.kind == "lesson")) {
            draw_set_font(UI_FONT_SMALL);
            draw_set_colour(col_head);
            draw_text(_tx, _ty - 22, string_upper(_it.unit));
        }
        var _is_done = scr_course_is_done(_it);
        var _open = scr_course_unlocked(_i);
        var _fill = _is_done ? col_done : (_open ? (_it.kind == "exam" ? col_exam : col_open) : col_locked);
        var _hover = map_hover == _i;
        if (_hover && _open) _fill = merge_colour(_fill, c_white, 0.18);
        var _next = _open && !_is_done;
        scr_ui_box(_tx, _ty, _tx + tile_w, _ty + tile_h, _fill, _next ? c_yellow : (_hover ? c_white : merge_colour(_fill, c_white, 0.35)));
        draw_set_font(UI_FONT_TITLE);
        draw_set_colour(_open ? c_white : make_colour_rgb(90, 96, 120));
        scr_ui_text_centred(_tx + tile_w * 0.5, _ty + tile_h * 0.42, _it.kind == "exam" ? "EXAM" : string(_it.number));
        draw_set_font(UI_FONT_SMALL);
        if (_it.kind == "exam") {
            draw_set_colour(_open ? make_colour_rgb(255, 220, 140) : make_colour_rgb(90, 96, 120));
            scr_ui_text_centred(_tx + tile_w * 0.5, _ty + tile_h * 0.78, string(_it.number));
        }
        if (_is_done) {
            scr_tutorial_ui_draw_tick(_tx + tile_w - 22, _ty + tile_h - 22, 16, col_ok);
        } else if (!_open) {
            // padlock
            var _lx = _tx + tile_w - 20;
            var _ly = _ty + tile_h - 18;
            draw_set_colour(make_colour_rgb(110, 116, 140));
            draw_rectangle(_lx - 7, _ly, _lx + 7, _ly + 10, false);
            draw_circle(_lx, _ly, 5, true);
            draw_set_colour(_fill);
            draw_rectangle(_lx - 3, _ly - 1, _lx + 3, _ly - 1, false);
        }
    }

    // details of the tile under the mouse (else the next one)
    var _info_y1 = map_y0 + 5 * map_row_h + 10;
    var _info_y2 = panel_y2 - 16;
    scr_ui_box(panel_x1 + 20, _info_y1, panel_x2 - 20, _info_y2, make_colour_rgb(18, 23, 38), make_colour_rgb(50, 62, 95));
    var _show = map_hover >= 0 ? map_hover : scr_course_next_index();
    var _si = items[_show];
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(c_white);
    draw_text(panel_x1 + 44, _info_y1 + 18, scr_course_item_label(_si) + ": " + string_upper(_si.title));
    draw_set_font(UI_FONT_GUIDE);
    draw_set_colour(col_dim);
    draw_text(panel_x1 + 44, _info_y1 + 58, "UNIT: " + _si.unit + (_si.kind == "exam" ? "   -   " + string(array_length(_si.quiz)) + " questions, pass mark " + string(_si.pass) + "%" : ""));
    draw_set_colour(col_text);
    draw_text_ext(panel_x1 + 44, _info_y1 + 88, _si.summary, -1, panel_x2 - panel_x1 - 140);
    var _state = scr_course_is_done(_si) ? "PASSED" : (scr_course_unlocked(_show) ? "OPEN - click it (or press Enter for the next one)" : "LOCKED - pass " + scr_course_item_label(items[max(0, _show - 1)]) + " first");
    draw_set_colour(scr_course_is_done(_si) ? col_ok : (scr_course_unlocked(_show) ? c_yellow : col_dim));
    draw_text(panel_x1 + 44, _info_y2 - 44, _state);

    // the finish line
    var _date = scr_course_complete_date();
    if (_date != "") {
        draw_set_font(UI_FONT_TITLE);
        draw_set_colour(col_ok);
        draw_set_halign(fa_right);
        draw_text(panel_x2 - 44, _info_y1 + 18, "COURSE COMPLETE");
        draw_set_font(UI_FONT_GUIDE);
        draw_text(panel_x2 - 44, _info_y1 + 58, "68000 assembler for the Amiga - finished " + _date);
        draw_set_halign(fa_left);
    }
}

// ================================================================= lesson
if (view == "lesson" && current >= 0) {
    var _item = items[current];
    scr_ui_box(col_x1, panel_y1, col_x2, panel_y2, col_bg, col_edge);
    scr_ui_header_band(col_x1, panel_y1, col_x2, panel_y2, col_head_y2, col_band);
    draw_set_font(UI_FONT_SMALL);
    draw_set_colour(col_dim);
    draw_text(col_x1 + 20, panel_y1 + 10, scr_course_item_label(_item) + " OF 100   -   " + string_upper(_item.unit));
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(c_white);
    draw_text(col_x1 + 20, panel_y1 + 32, scr_ui_fit_label(string_upper(_item.title), col_x2 - col_x1 - 120));
    if (scr_course_is_done(_item)) scr_tutorial_ui_draw_tick(col_x2 - 50, panel_y1 + 30, 24, col_ok);

    // content
    gpu_set_scissor(col_x1 + 4, content_y1, col_x2 - col_x1 - 8, content_y2 - content_y1);
    var _code_font = scr_code_editor_font_ensure(global.code_editor_font_pref_size);
    var _y = content_y1 + 8 - content_scroll;
    for (var _r = 0; _r < array_length(content_rows); _r += 1) {
        var _row = content_rows[_r];
        if (_y + _row.h >= content_y1 && _y <= content_y2) {
            switch (_row.kind) {
                case "head":
                    draw_set_font(UI_FONT);
                    draw_set_colour(_row.colour);
                    draw_text(col_x1 + 22, _y + 4, _row.text);
                    break;
                case "text":
                    draw_set_font(UI_FONT_GUIDE);
                    draw_set_colour(_row.colour);
                    draw_text(col_x1 + 22, _y, _row.text);
                    break;
                case "code":
                    draw_set_colour(col_code_bg);
                    draw_rectangle(col_x1 + 16, _y, col_x2 - 16, _y + _row.h - 1, false);
                    draw_set_font(_code_font);
                    draw_set_colour(make_colour_rgb(150, 210, 255));
                    draw_text(col_x1 + 26, _y + 1, _row.text);
                    break;
                case "option":
                    var _qq = _item.quiz[_row.q];
                    var _chosen = quiz_choice[_row.q] == _row.o;
                    var _right = _chosen && _row.o == _qq.answer;
                    var _wrong = variable_struct_exists(quiz_tried[_row.q], string(_row.o));
                    var _ofill = _right ? make_colour_rgb(30, 90, 50) : (_wrong ? make_colour_rgb(90, 30, 36) : make_colour_rgb(26, 32, 52));
                    var _ohover = quiz_choice[_row.q] != _qq.answer && _mx >= col_x1 + 16 && _mx < col_x2 - 16 && _my >= _y && _my < _y + _row.h && _my >= content_y1 && _my < content_y2;
                    if (_ohover) _ofill = merge_colour(_ofill, c_white, 0.12);
                    scr_ui_box(col_x1 + 16, _y, col_x2 - 16, _y + _row.h - 2, _ofill, _right ? col_ok : (_wrong ? col_bad : make_colour_rgb(60, 72, 105)));
                    draw_set_font(UI_FONT_GUIDE);
                    draw_set_colour(_wrong ? make_colour_rgb(255, 170, 170) : c_white);
                    var _oy = _y + 5;
                    for (var _ol = 0; _ol < array_length(_row.text); _ol += 1) {
                        draw_text(col_x1 + 30, _oy, _row.text[_ol]);
                        _oy += string_height("Ag") + 3;
                    }
                    if (_right) scr_tutorial_ui_draw_tick(col_x2 - 44, _y + 6, 16, col_ok);
                    break;
            }
        }
        _y += _row.h;
    }
    gpu_set_scissor(0, 0, room_width, room_height);
    // scroll hint
    if (content_h > content_y2 - content_y1 - 16) {
        var _track = content_y2 - content_y1 - 8;
        var _thumb = max(30, _track * (content_y2 - content_y1) / content_h);
        var _max = max(1, content_h - (content_y2 - content_y1 - 16));
        var _ty2 = content_y1 + 4 + (_track - _thumb) * (content_scroll / _max);
        draw_set_colour(make_colour_rgb(30, 38, 60));
        draw_rectangle(col_x2 - 12, content_y1 + 4, col_x2 - 8, content_y2 - 4, false);
        draw_set_colour(make_colour_rgb(90, 110, 160));
        draw_rectangle(col_x2 - 12, _ty2, col_x2 - 8, _ty2 + _thumb, false);
    }

    // results
    scr_ui_box(col_x1 + 8, results_y1, col_x2 - 8, results_y2, make_colour_rgb(18, 23, 38), make_colour_rgb(50, 62, 95));
    draw_set_font(UI_FONT);
    draw_set_colour(lesson_message_colour);
    var _msg = lesson_message;
    if (_msg == "") _msg = array_length(_item.tests) > 0 ? "Write your code on the left, then press RUN TESTS (F5)." : "Answer the questions above to pass this lesson.";
    scr_ui_text_mid(col_x1 + 22, results_y1 + 4, results_y1 + 30, scr_ui_fit_label(_msg, col_x2 - col_x1 - 50));
    var _rows_vis = max(1, floor((results_y2 - results_y1 - 34 - 70) / 22));
    draw_set_font(UI_FONT_GUIDE);
    for (var _k = 0; _k < _rows_vis; _k += 1) {
        var _ri = results_scroll + _k;
        if (_ri >= array_length(results_rows)) break;
        var _rr = results_rows[_ri];
        var _ry = results_y1 + 34 + _k * 22;
        if (_rr.test >= 0 && _rr.test == result_selected && _rr.mark != "") {
            draw_set_colour(make_colour_rgb(30, 40, 66));
            draw_rectangle(col_x1 + 14, _ry - 1, col_x2 - 14, _ry + 20, false);
        }
        if (_rr.mark == "tick") scr_tutorial_ui_draw_tick(col_x1 + 22, _ry + 2, 14, col_ok);
        if (_rr.mark == "x") {
            draw_set_colour(col_bad);
            draw_line_width(col_x1 + 23, _ry + 3, col_x1 + 35, _ry + 15, 2);
            draw_line_width(col_x1 + 35, _ry + 3, col_x1 + 23, _ry + 15, 2);
        }
        draw_set_colour(_rr.colour);
        draw_text(col_x1 + 44, _ry, _rr.text);
    }
    // registers of the selected test
    if (job != undefined && result_selected >= 0 && result_selected < array_length(job.results)) {
        var _res = job.results[result_selected];
        draw_set_font(_code_font);
        draw_set_colour(col_dim);
        var _gy = results_y2 - 66;
        var _rx = col_x1 + 22;
        var _cw = (col_x2 - col_x1 - 44) / 4;
        for (var _g = 0; _g < 8; _g += 1) {
            draw_text(_rx + (_g mod 4) * _cw, _gy + (_g div 4) * 16, "D" + string(_g) + " " + scr_m68k_hex(_res.d[_g], 8));
        }
        draw_set_colour(merge_colour(col_dim, c_white, 0.2));
        draw_text(_rx, _gy + 34, "A0 " + scr_m68k_hex(_res.a[0], 8) + "  A7 " + scr_m68k_hex(_res.a[7], 8) + "  SR " + scr_m68k_hex(_res.sr, 4) + "  " + string(_res.cycles) + " CYCLES");
    }

    // buttons
    for (var _lb = 0; _lb < array_length(lesson_buttons); _lb += 1) {
        var _bt = lesson_buttons[_lb];
        draw_set_font(UI_FONT_SMALL);
        scr_ui_button(_bt.x1, _bt.y1, _bt.x2, _bt.y2, _bt.label, _bt.colour, lesson_hover == _bt.id && _bt.on, _bt.on);
    }
}

// ================================================================= exam
if (view == "exam" && current >= 0) {
    var _ex = items[current];
    scr_ui_box(panel_x1, panel_y1, panel_x2, panel_y2, col_bg, col_edge);
    scr_ui_header_band(panel_x1, panel_y1, panel_x2, panel_y2, panel_y1 + title_h, col_band);
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(col_head);
    scr_ui_text_mid(panel_x1 + 24, panel_y1, panel_y1 + title_h, "EXAM " + string(_ex.number) + ": " + string_upper(_ex.title));
    var _bx1 = panel_x1 + 60;
    var _bx2 = panel_x2 - 60;
    if (!exam_finished) {
        var _n = array_length(exam_order);
        draw_set_font(UI_FONT);
        draw_set_colour(col_dim);
        draw_set_halign(fa_right);
        scr_ui_text_mid(panel_x2 - 24, panel_y1, panel_y1 + title_h, "QUESTION " + string(exam_pos + 1) + " OF " + string(_n) + "   -   PASS MARK " + string(_ex.pass) + "%");
        draw_set_halign(fa_left);
        var _q = _ex.quiz[exam_order[exam_pos]];
        draw_set_font(UI_FONT_TITLE);
        draw_set_colour(c_white);
        var _ql = scr_tutorial_ui_wrap_lines(_q.question, _bx2 - _bx1);
        var _qy = 130;
        for (var _l = 0; _l < array_length(_ql); _l += 1) {
            draw_text(_bx1, _qy, _ql[_l]);
            _qy += string_height("Ag") + 6;
        }
        if (array_length(_q.code) > 0) {
            // the code under the question, between it and the options
            var _cf = scr_code_editor_font_ensure(global.code_editor_font_pref_size + 3);
            draw_set_font(_cf);
            var _clh = string_height("Ag") + 2;
            _qy += 6;
            draw_set_colour(col_code_bg);
            draw_rectangle(_bx1, _qy - 4, _bx2, _qy + array_length(_q.code) * _clh + 4, false);
            draw_set_colour(make_colour_rgb(150, 210, 255));
            for (var _c = 0; _c < array_length(_q.code); _c += 1) draw_text(_bx1 + 16, _qy + _c * _clh, _q.code[_c]);
        }
        var _oo = exam_option_order[exam_pos];
        for (var _o = 0; _o < array_length(exam_buttons); _o += 1) {
            var _eb = exam_buttons[_o];
            var _hover = exam_hover == _eb.id && _eb.on;
            if (string_copy(_eb.id, 1, 3) == "opt") {
                var _si = real(string_delete(_eb.id, 1, 3));
                var _sel = exam_answers[exam_pos] == _si;
                var _f = _sel ? make_colour_rgb(40, 90, 160) : make_colour_rgb(26, 32, 52);
                if (_hover) _f = merge_colour(_f, c_white, 0.12);
                scr_ui_box(_eb.x1, _eb.y1, _eb.x2, _eb.y2, _f, _sel ? c_yellow : make_colour_rgb(60, 72, 105));
                draw_set_font(UI_FONT_TITLE);
                draw_set_colour(_sel ? c_yellow : col_dim);
                scr_ui_text_mid(_eb.x1 + 24, _eb.y1, _eb.y2, chr(ord("A") + _si));
                draw_set_font(UI_FONT_GUIDE);
                draw_set_colour(c_white);
                var _ot = scr_tutorial_ui_wrap_lines(_q.options[_oo[_si]], _eb.x2 - _eb.x1 - 100);
                var _lh = string_height("Ag") + 3;
                var _oy = (_eb.y1 + _eb.y2) * 0.5 - array_length(_ot) * _lh * 0.5;
                for (var _t = 0; _t < array_length(_ot); _t += 1) draw_text(_eb.x1 + 70, _oy + _t * _lh, _ot[_t]);
            } else if (string_copy(_eb.id, 1, 3) == "dot") {
                var _di = real(string_delete(_eb.id, 1, 3));
                var _df = exam_answers[_di] >= 0 ? make_colour_rgb(40, 90, 160) : make_colour_rgb(32, 36, 50);
                draw_set_colour(_hover ? merge_colour(_df, c_white, 0.3) : _df);
                draw_rectangle(_eb.x1, _eb.y1, _eb.x2, _eb.y2, false);
                if (_di == exam_pos) {
                    draw_set_colour(c_yellow);
                    draw_rectangle(_eb.x1, _eb.y1, _eb.x2, _eb.y2, true);
                }
            } else {
                draw_set_font(UI_FONT);
                var _bf = _eb.id == "finish" ? make_colour_rgb(35, 95, 58) : (_eb.id == "map" ? make_colour_rgb(110, 42, 48) : make_colour_rgb(40, 60, 100));
                scr_ui_button(_eb.x1, _eb.y1, _eb.x2, _eb.y2, _eb.label, _bf, _hover, _eb.on);
            }
        }
        draw_set_font(UI_FONT_GUIDE);
        draw_set_colour(col_dim);
        draw_text(_bx1, 850, "Keys: A-D or 1-4 choose, Left / Right move, Enter next. Every question must be answered before FINISH.");
    } else {
        var _passed = exam_score >= _ex.pass;
        draw_set_font(UI_FONT_TITLE);
        draw_set_colour(_passed ? col_ok : col_bad);
        draw_text(_bx1, 110, (_passed ? "PASSED - " : "NOT YET - ") + string(exam_score) + "%   (pass mark " + string(_ex.pass) + "%)");
        draw_set_font(UI_FONT_GUIDE);
        draw_set_colour(col_text);
        draw_text(_bx1, 160, _passed ? (current + 1 < array_length(items) ? scr_course_item_label(items[current + 1]) + " is open." : "That was the final exam: the 68K course is complete!") : "Look over the answers below, then take the exam again (the questions come in a new order).");
        // review of the wrong answers
        var _ry1 = 200;
        var _ry2 = 960;
        gpu_set_scissor(_bx1, _ry1, _bx2 - _bx1, _ry2 - _ry1);
        var _yy = _ry1 - exam_review_scroll;
        var _lh2 = string_height("Ag") + 3;
        var _wrong_n = 0;
        for (var _i = 0; _i < array_length(exam_order); _i += 1) {
            var _qq = _ex.quiz[exam_order[_i]];
            var _picked = exam_answers[_i] >= 0 ? exam_option_order[_i][exam_answers[_i]] : -1;
            if (_picked == _qq.answer) continue;
            _wrong_n += 1;
            var _qtext = _qq.question;
            for (var _qc = 0; _qc < array_length(_qq.code); _qc += 1) _qtext += "\n    " + _qq.code[_qc];
            var _parts = [[_qtext, c_white], ["Your answer: " + (_picked >= 0 ? _qq.options[_picked] : "-"), col_bad], ["Right answer: " + _qq.options[_qq.answer], col_ok]];
            if (_qq.why != "") array_push(_parts, [_qq.why, col_dim]);
            for (var _p = 0; _p < array_length(_parts); _p += 1) {
                var _wl = scr_tutorial_ui_wrap_lines(_parts[_p][0], _bx2 - _bx1 - 20);
                draw_set_colour(_parts[_p][1]);
                for (var _w = 0; _w < array_length(_wl); _w += 1) {
                    draw_text(_bx1 + (_p == 0 ? 0 : 20), _yy, _wl[_w]);
                    _yy += _lh2;
                }
            }
            _yy += 14;
        }
        if (_wrong_n == 0) {
            draw_set_colour(col_ok);
            draw_text(_bx1, _yy, "Every answer right!");
        }
        exam_review_scroll = min(exam_review_scroll, max(0, _yy + exam_review_scroll - _ry2 + 20));
        gpu_set_scissor(0, 0, room_width, room_height);
        for (var _e = 0; _e < array_length(exam_buttons); _e += 1) {
            var _b2 = exam_buttons[_e];
            draw_set_font(UI_FONT);
            scr_ui_button(_b2.x1, _b2.y1, _b2.x2, _b2.y2, _b2.label, _b2.id == "continue" ? make_colour_rgb(35, 95, 58) : (_b2.id == "map" ? make_colour_rgb(110, 42, 48) : make_colour_rgb(40, 60, 100)), exam_hover == _b2.id, _b2.on);
        }
    }
}

draw_set_font(UI_FONT);
draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
