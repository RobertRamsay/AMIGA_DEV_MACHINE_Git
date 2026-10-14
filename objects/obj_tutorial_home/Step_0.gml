// Scrolling the tutorial list (only when it does not fit).
if (home_scroll_max > 0 && point_in_rectangle(mouse_x, mouse_y, home_list_x, home_list_top, home_list_x + home_list_w, home_list_bottom)) {
    if (mouse_wheel_down()) home_scroll += home_card_h div 2;
    if (mouse_wheel_up()) home_scroll -= home_card_h div 2;
}

home_layout();

// Hover: cards only inside the list viewport.
home_hover = -1;
var _c = 0;
while (_c < array_length(home_controls)) {
    var _ctl = home_controls[_c];
    if (point_in_rectangle(mouse_x, mouse_y, _ctl.x1, _ctl.y1, _ctl.x2, _ctl.y2)) {
        if (_ctl.kind != "card" || (mouse_y >= home_list_top && mouse_y <= home_list_bottom)) {
            home_hover = _c;
            break;
        }
    }
    _c += 1;
}

if (home_input_delay > 0) {
    home_input_delay -= 1;
    exit;
}

if (keyboard_check_pressed(vk_escape)) {
    // Esc just closes: at startup the workspace is still the default empty
    // one, later it is whatever the user was working on.
    home_close();
    exit;
}

if (mouse_check_button_pressed(mb_left) && home_hover >= 0) {
    var _hit = home_controls[home_hover];
    switch (_hit.action) {
        case "continue": home_action_continue(); break;
        case "close": home_close(); break;
        case "new": home_action_new(); break;
        case "open": home_action_open(); break;
        case "show_home": scr_tutorial_home_set_show_at_startup(!scr_tutorial_home_show_at_startup()); break;
        case "tutorial": home_action_tutorial(_hit.index); break;
    }
}
