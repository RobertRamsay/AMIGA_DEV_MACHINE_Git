guide_layout();

// No tutorial loaded any more (another workspace replaced it): go away.
if (!guide_visible) {
    instance_destroy();
    exit;
}

guide_hover = -1;
var _blocked = scr_amiga_modal_open() || instance_exists(obj_tutorial_home);
if (_blocked) {
    guide_input_delay = max(guide_input_delay, 1);
    exit;
}

var _c = 0;
while (_c < array_length(guide_controls)) {
    var _ctl = guide_controls[_c];
    if (point_in_rectangle(mouse_x, mouse_y, _ctl.x1, _ctl.y1, _ctl.x2, _ctl.y2)) {
        guide_hover = _c;
        break;
    }
    _c += 1;
}

if (guide_input_delay > 0) {
    guide_input_delay -= 1;
    exit;
}

// Wheel scrolls a long step text.
if (!global.tutorial_guide_collapsed
    && point_in_rectangle(mouse_x, mouse_y, guide_x1, guide_text_y1, guide_x2, guide_text_y2)) {
    if (mouse_wheel_down()) guide_text_scroll += 2;
    if (mouse_wheel_up()) guide_text_scroll -= 2;
    guide_text_scroll = clamp(guide_text_scroll, 0, max(0, array_length(guide_text_lines) - guide_text_rows));
}

if (!mouse_check_button_pressed(mb_left)) exit;
if (!point_in_rectangle(mouse_x, mouse_y, guide_hit_x1, guide_hit_y1, guide_hit_x2, guide_hit_y2)) exit;

// Any click on the panel belongs to the panel.
mouse_clear(mb_left);
if (guide_hover < 0) exit;
var _hit = guide_controls[guide_hover];
if (!_hit.enabled) exit;

switch (_hit.action) {
    case "expand":
        global.tutorial_guide_collapsed = false;
        break;
    case "collapse":
        global.tutorial_guide_collapsed = true;
        break;
    case "close":
        instance_destroy();
        break;
    case "prev":
        global.tutorial_step = max(0, global.tutorial_step - 1);
        break;
    case "next":
        global.tutorial_step = min(guide_step_count - 1, global.tutorial_step + 1);
        break;
    case "finish":
        guide_mark_done();
        break;
    case "done":
        guide_mark_done();
        break;
    case "next_tutorial":
        scr_tutorial_load(global.tutorial_current + 1);
        break;
    case "build":
        scr_amiga_trigger_build();
        break;
    case "all":
        scr_tutorial_home_open(false);
        break;
}
