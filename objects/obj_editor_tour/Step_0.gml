// Settling: the new demo graph gets a few normal frames (see scr_tour_init);
// no click may reach it meanwhile.
if (tour_settle > 0) {
    tour_settle -= 1;
    global.tour_settling = tour_settle > 0;
    mouse_clear(mb_left);
    mouse_clear(mb_right);
}
// No stale palette tooltip while the palette is frozen.
global.palette_hover_mnemonic = "";

tour_layout();

tour_hover = -1;
var _i = 0;
while (_i < array_length(tour_controls)) {
    var _c = tour_controls[_i];
    if (_c.enabled && _c.kind != "label" && point_in_rectangle(mouse_x, mouse_y, _c.x1, _c.y1, _c.x2, _c.y2)) tour_hover = _i;
    _i += 1;
}

if (tour_input_delay > 0) {
    tour_input_delay -= 1;
    exit;
}

if (mouse_check_button_pressed(mb_left)) {
    if (tour_hover >= 0) tour_action(tour_controls[tour_hover]);
    mouse_clear(mb_left);
    exit;
}

// Keyboard: Esc ends (or closes the picker), arrows / Space step, Tab skips a
// category, A toggles auto-play, + / - change its delay.
if (keyboard_check_pressed(vk_escape)) {
    keyboard_clear(vk_escape);
    tour_finish();
    exit;
}
if (keyboard_check_pressed(ord("A"))) tour_action({ action : "auto" });
if (keyboard_check_pressed(vk_add) || keyboard_check_pressed(187)) tour_action({ action : "slower" });
if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(189)) tour_action({ action : "faster" });

if (tour_state == "menu") {
    if (keyboard_check_pressed(vk_enter)) tour_begin();
} else if (tour_state == "run") {
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter)) {
        tour_next();
    } else if (keyboard_check_pressed(vk_left)) {
        tour_prev();
    } else if (keyboard_check_pressed(vk_tab)) {
        tour_skip_category();
    } else if (tour_auto && current_time - tour_step_started >= global.tour_delay_seconds * 1000) {
        tour_next();
    }
} else if (tour_state == "done") {
    if (keyboard_check_pressed(vk_enter)) tour_finish();
}
