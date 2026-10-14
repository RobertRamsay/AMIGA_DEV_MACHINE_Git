if (instance_exists(obj_tutorial_home)) exit;
guide_layout();
if (!guide_visible) exit;

draw_set_font(font_CyberVerse);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);

var _level_col = scr_tutorial_level_colour(guide_def.level);

// --- pulsing outline round the nodes the current step talks about ----------
if (!global.tutorial_guide_collapsed && array_length(guide_node_keys) > 0 && !scr_amiga_modal_open()) {
    var _pulse = 0.45 + 0.55 * abs(sin(current_time / 260));
    var _keys = guide_node_keys;
    draw_set_colour(c_yellow);
    draw_set_alpha(_pulse);
    with (obj_opcode_node) {
        var _match = is_macro ? array_contains(_keys, macro_type) : array_contains(_keys, opcode_mnemonic);
        if (_match) {
            var _nx = node_x + global.pan_x;
            var _ny = node_y + global.pan_y;
            if (_nx + node_width >= 0 && _nx <= room_width && _ny + node_height >= 0 && _ny <= room_height) {
                draw_rectangle(_nx - 4, _ny - 4, _nx + node_width + 4, _ny + node_height + 4, true);
                draw_rectangle(_nx - 5, _ny - 5, _nx + node_width + 5, _ny + node_height + 5, true);
                draw_rectangle(_nx - 6, _ny - 6, _nx + node_width + 6, _ny + node_height + 6, true);
            }
        }
    }
    draw_set_alpha(1);
}

if (global.tutorial_guide_collapsed) {
    var _tab = guide_controls[0];
    scr_tutorial_ui_draw_button(_tab.x1, _tab.y1, _tab.x2, _tab.y2, _tab.label, _tab.colour, guide_hover == 0, true);
    exit;
}

// --- panel -----------------------------------------------------------------------
draw_set_alpha(0.96);
draw_set_colour(make_colour_rgb(14, 18, 30));
draw_rectangle(guide_x1, guide_y1, guide_x2, guide_y2, false);
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(40, 90, 150));
draw_rectangle(guide_x1, guide_y1, guide_x2, guide_y1 + 28, false);
draw_set_colour(_level_col);
draw_rectangle(guide_x1, guide_y1 + 28, guide_x2, guide_y1 + 30, false);
draw_set_colour(c_white);
draw_rectangle(guide_x1, guide_y1, guide_x2, guide_y2, true);
draw_text(guide_x1 + 8, guide_y1 + 6, "TUTORIAL " + string(global.tutorial_current + 1) + " / " + string(array_length(scr_tutorial_defs())));

// Title.
draw_set_font(font_Future);
draw_set_colour(c_yellow);
var _l = 0;
while (_l < array_length(guide_title_lines)) {
    draw_text(guide_x1 + 12, guide_title_y + _l * guide_title_line_h, guide_title_lines[_l]);
    _l += 1;
}
draw_set_font(font_CyberVerse);

// Level badge, step counter, done mark.
var _badge_w = string_width(guide_def.level) + 16;
draw_set_colour(_level_col);
draw_rectangle(guide_x1 + 12, guide_info_y, guide_x1 + 12 + _badge_w, guide_info_y + guide_line_h + 4, false);
draw_set_colour(c_white);
draw_text(guide_x1 + 20, guide_info_y + 2, guide_def.level);
draw_text(guide_x1 + 24 + _badge_w, guide_info_y + 2, "STEP " + string(global.tutorial_step + 1) + " / " + string(guide_step_count));
if (scr_tutorial_is_done(guide_def.id)) {
    scr_tutorial_ui_draw_tick(guide_x2 - 70, guide_info_y + 3, guide_line_h - 3, make_colour_rgb(120, 255, 150));
    draw_set_colour(make_colour_rgb(170, 255, 190));
    draw_text(guide_x2 - 50, guide_info_y + 2, "DONE");
}

// Step progress bar: one segment per step.
var _seg_gap = 4;
var _seg_w = (guide_x2 - guide_x1 - 24 - _seg_gap * (guide_step_count - 1)) / max(1, guide_step_count);
var _s = 0;
while (_s < guide_step_count) {
    var _sx = guide_x1 + 12 + _s * (_seg_w + _seg_gap);
    draw_set_colour(_s < global.tutorial_step ? make_colour_rgb(60, 140, 90) : (_s == global.tutorial_step ? c_aqua : make_colour_rgb(45, 55, 80)));
    draw_rectangle(_sx, guide_dots_y, _sx + _seg_w, guide_dots_y + 6, false);
    _s += 1;
}

// Step title.
draw_set_colour(c_aqua);
_l = 0;
while (_l < array_length(guide_step_title_lines)) {
    draw_text(guide_x1 + 12, guide_step_title_y + _l * guide_line_h, guide_step_title_lines[_l]);
    _l += 1;
}

// Step text (scrolls by whole lines).
draw_set_colour(make_colour_rgb(215, 222, 235));
var _row = 0;
while (_row < guide_text_rows && guide_text_scroll + _row < array_length(guide_text_lines)) {
    draw_text(guide_x1 + 12, guide_text_y1 + _row * guide_line_h, guide_text_lines[guide_text_scroll + _row]);
    _row += 1;
}
var _text_count = array_length(guide_text_lines);
if (_text_count > guide_text_rows) {
    var _track_x = guide_x2 - 12;
    var _track_h = guide_text_y2 - guide_text_y1;
    var _thumb_h = max(16, floor(_track_h * guide_text_rows / _text_count));
    var _thumb_y = guide_text_y1 + floor((_track_h - _thumb_h) * guide_text_scroll / max(1, _text_count - guide_text_rows));
    draw_set_colour(make_colour_rgb(25, 30, 45));
    draw_rectangle(_track_x, guide_text_y1, _track_x + 6, guide_text_y2, false);
    draw_set_colour(make_colour_rgb(105, 120, 165));
    draw_rectangle(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, false);
}

// Buttons.
var _c = 0;
while (_c < array_length(guide_controls)) {
    var _b = guide_controls[_c];
    scr_tutorial_ui_draw_button(_b.x1, _b.y1, _b.x2, _b.y2, _b.label, _b.colour, guide_hover == _c, _b.enabled);
    if (_b.action == "done" && !_b.enabled) {
        scr_tutorial_ui_draw_tick(_b.x1 + 10, _b.y1 + 6, 14, make_colour_rgb(120, 255, 150));
    }
    _c += 1;
}

draw_set_colour(c_white);
draw_set_alpha(1);
