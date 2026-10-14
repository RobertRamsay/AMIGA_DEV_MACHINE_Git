/// @desc Bringing a node into view: clicking a line in the compiled program
/// preview scrolls the workspace (smoothly) to the node that line came from,
/// unless it is already fully on screen, and flashes its outline.

global.focus_pan_active = false;
global.focus_pan_x = 0;
global.focus_pan_y = 0;
global.focus_node_uid = -1;
global.focus_node_time = -100000;

#macro FOCUS_FLASH_MS 1400

/// The part of the room where the node graph is visible (between the
/// palette and the preview panel, under the toolbar).
function scr_amiga_workspace_view_rect() {
    return [280, 70, room_width - 370, room_height - 10];
}

function scr_amiga_focus_node(_node) {
    if (_node == noone || !instance_exists(_node)) return;
    var _view = scr_amiga_workspace_view_rect();
    var _x1 = _node.node_x + global.pan_x;
    var _y1 = _node.node_y + global.pan_y;
    var _x2 = _x1 + _node.node_width;
    var _y2 = _y1 + _node.node_height;
    var _inside = _x1 >= _view[0] && _x2 <= _view[2] && _y1 >= _view[1] && _y2 <= _view[3];
    if (!_inside) {
        // Centre it across; down the screen put its top a little under the
        // toolbar, or centre it when it fits.
        var _vw = _view[2] - _view[0];
        var _vh = _view[3] - _view[1];
        global.focus_pan_x = round(_view[0] + (_vw - _node.node_width) * 0.5 - _node.node_x);
        var _top = (_node.node_height < _vh - 80) ? _view[1] + (_vh - _node.node_height) * 0.5 : _view[1] + 40;
        global.focus_pan_y = round(_top - _node.node_y);
        global.focus_pan_active = true;
    }
    global.focus_node_uid = _node.uid;
    global.focus_node_time = current_time;
}

/// Eases the pan towards the focus target (manager Step). Panning by hand cancels it.
function scr_amiga_focus_pan_step() {
    if (!global.focus_pan_active) return;
    if (global.pan_active) {
        global.focus_pan_active = false;
        return;
    }
    var _dx = global.focus_pan_x - global.pan_x;
    var _dy = global.focus_pan_y - global.pan_y;
    if (abs(_dx) < 1 && abs(_dy) < 1) {
        global.pan_x = global.focus_pan_x;
        global.pan_y = global.focus_pan_y;
        global.focus_pan_active = false;
        return;
    }
    global.pan_x += _dx * 0.25;
    global.pan_y += _dy * 0.25;
}

/// Outline flash on the focused node (node Draw); 0 when none.
function scr_amiga_focus_flash(_node) {
    if (_node.uid != global.focus_node_uid) return 0;
    var _age = current_time - global.focus_node_time;
    if (_age >= FOCUS_FLASH_MS) return 0;
    return (1 - _age / FOCUS_FLASH_MS) * (0.6 + 0.4 * sin(_age * 0.012));
}
