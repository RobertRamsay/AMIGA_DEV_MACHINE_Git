var _shade = make_colour_rgb(4, 6, 14);
var _accent = make_colour_rgb(255, 210, 60);

// Dim everything except the highlighted region.
draw_set_colour(_shade);
draw_set_alpha(tour_state == "run" ? 0.55 : 0.72);
if (tour_rect == undefined) {
    draw_rectangle(0, 0, room_width, room_height, false);
} else {
    var _r = tour_rect;
    draw_rectangle(0, 0, room_width, _r[1] - 1, false);
    draw_rectangle(0, _r[3] + 1, room_width, room_height, false);
    draw_rectangle(0, _r[1], _r[0] - 1, _r[3], false);
    draw_rectangle(_r[2] + 1, _r[1], room_width, _r[3], false);
}
draw_set_alpha(1);

var _p = tour_panel;

// Pulsing outline and a leader line from the panel.
if (tour_rect != undefined) {
    var _r2 = tour_rect;
    var _pulse = 0.5 + 0.5 * sin(current_time / 180);
    scr_ui_box_outline(_r2[0] - 6, _r2[1] - 6, _r2[2] + 6, _r2[3] + 6, merge_colour(_accent, c_white, _pulse * 0.6), 3);
    var _cx = clamp((_r2[0] + _r2[2]) / 2, _p[0], _p[2]);
    var _cy = clamp((_r2[1] + _r2[3]) / 2, _p[1], _p[3]);
    var _tx = clamp(_cx, _r2[0] - 4, _r2[2] + 4);
    var _ty = clamp(_cy, _r2[1] - 4, _r2[3] + 4);
    draw_set_colour(_accent);
    draw_line_width(_cx, _cy, _tx, _ty, 2);
}

// Panel.
scr_ui_box_fill(_p[0], _p[1], _p[2], _p[3], make_colour_rgb(20, 25, 40));
scr_ui_box_outline(_p[0], _p[1], _p[2], _p[3], _accent, 2);

draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (tour_state == "menu") {
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(_accent);
    draw_text(_p[0] + 20, _p[1] + 18, "EDITOR TOUR");
    draw_set_font(UI_FONT_GUIDE);
    draw_set_colour(c_white);
    draw_text(_p[0] + 20, _p[1] + 52, "A guided walk through every panel of the editor. Tick the categories you want (or ALL),");
    draw_text(_p[0] + 20, _p[1] + 72, "then START. During the tour: NEXT / PREV, SKIP CATEGORY, or AUTO-PLAY with a delay per step.");
    draw_set_colour(make_colour_rgb(160, 170, 200));
    draw_text(_p[0] + 20, _p[1] + 96, "The tour runs on a demo project; your own workspace is put back when it ends.");
} else {
    draw_set_font(UI_FONT_GUIDE);
    draw_set_colour(make_colour_rgb(150, 170, 220));
    draw_text(_p[0] + 20, _p[1] + 14, tour_header);
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(_accent);
    draw_text(_p[0] + 20, _p[1] + 42, tour_title);
    draw_set_font(UI_FONT_GUIDE);
    draw_set_colour(c_white);
    var _l = 0;
    while (_l < array_length(tour_lines)) {
        draw_text(_p[0] + 20, _p[1] + 78 + _l * tour_line_h, tour_lines[_l]);
        _l += 1;
    }
    // Auto-play progress.
    if (tour_state == "run" && tour_auto) {
        var _t = clamp((current_time - tour_step_started) / (global.tour_delay_seconds * 1000), 0, 1);
        draw_set_colour(make_colour_rgb(40, 46, 66));
        draw_rectangle(_p[0] + 2, _p[3] - 8, _p[2] - 2, _p[3] - 3, false);
        draw_set_colour(make_colour_rgb(60, 200, 110));
        draw_rectangle(_p[0] + 2, _p[3] - 8, _p[0] + 2 + (_p[2] - _p[0] - 4) * _t, _p[3] - 3, false);
    }
}

// Controls.
var _i = 0;
while (_i < array_length(tour_controls)) {
    var _c = tour_controls[_i];
    var _hover = _i == tour_hover;
    if (_c.kind == "row") {
        var _cat = tour_categories[_c.value];
        var _on = tour_selected[_c.value];
        scr_ui_box(_c.x1, _c.y1, _c.x2, _c.y2, _hover ? make_colour_rgb(44, 52, 80) : make_colour_rgb(28, 33, 52), _hover ? c_yellow : make_colour_rgb(70, 80, 110));
        // Check box.
        var _bx = _c.x1 + 10;
        var _by = (_c.y1 + _c.y2) div 2 - 9;
        draw_set_colour(c_white);
        draw_rectangle(_bx, _by, _bx + 18, _by + 18, true);
        if (_on) scr_tutorial_ui_draw_tick(_bx + 2, _by + 2, 14, make_colour_rgb(80, 230, 120));
        draw_set_colour(_on ? c_white : make_colour_rgb(140, 145, 160));
        draw_text(_c.x1 + 40, _c.y1 + 5, string(_c.value + 1) + ". " + _cat.title + "   (" + string(array_length(_cat.steps)) + " steps)");
        draw_set_colour(make_colour_rgb(150, 160, 190));
        var _summary = _cat.summary;
        while (string_length(_summary) > 4 && string_width(_summary) > _c.x2 - _c.x1 - 60) _summary = string_copy(_summary, 1, string_length(_summary) - 4) + "...";
        draw_text(_c.x1 + 40, _c.y1 + 27, _summary);
    } else {
        scr_tutorial_ui_draw_button(_c.x1, _c.y1, _c.x2, _c.y2, _c.label, _c.colour, _hover, _c.enabled || _c.kind == "label");
    }
    _i += 1;
}

draw_set_colour(c_white);
