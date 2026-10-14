/// @desc Game Kit node rows: input (from obj_opcode_node Step) and drawing
/// (from obj_opcode_node Draw). Rows are 20 px under the header; a row's left
/// half steps down / cycles back, the right half steps up / cycles on.

/// Cycles _current through _names plus "" (none) when _allow_none.
function scr_gk_cycle_name(_names, _current, _delta, _allow_none) {
    var _list = [];
    if (_allow_none) array_push(_list, "");
    var _i = 0;
    while (_i < array_length(_names)) {
        array_push(_list, _names[_i]);
        _i += 1;
    }
    if (array_length(_list) == 0) return _current;
    var _index = -1;
    _i = 0;
    while (_i < array_length(_list)) {
        if (_list[_i] == _current) _index = _i;
        _i += 1;
    }
    _index = (_index + _delta + array_length(_list)) mod array_length(_list);
    return _list[max(0, _index)];
}

/// Handles a left click on a Game Kit node; _wx/_wy are world mouse coords.
/// Returns true when the click was used.
function scr_gk_node_click(_node, _wx, _wy) {
    if (!point_in_rectangle(_wx, _wy, _node.node_x, _node.node_y + 20, _node.node_x + _node.node_width, _node.node_y + _node.node_height)) return false;
    var _row = (_wy - _node.node_y - 20) div 20;
    var _delta = _wx < _node.node_x + _node.node_width * 0.5 ? -1 : 1;
    var _type = _node.macro_type;

    if (_type == "GK_MAP" && _row == 0) {
        scr_push_undo_snapshot();
        _node.macro_asset_name = scr_gk_cycle_name(scr_gk_asset_names("TILEMAP"), _node.macro_asset_name, _delta, false);
        if (_node.macro_asset_name == "") scr_set_status_message("No maps yet - make one in TILE-EDIT.", c_orange);
        return true;
    }
    if (_type == "GK_PLAYER" && _row == 0) {
        scr_push_undo_snapshot();
        _node.macro_asset_name = scr_gk_cycle_name(scr_gk_asset_names("ANIMSET"), _node.macro_asset_name, _delta, false);
        if (_node.macro_asset_name == "") scr_set_status_message("No animation sets yet - make one in TILE-EDIT (Animations).", c_orange);
        return true;
    }
    // The second row of DRAW MAP / PLAYER is their EDIT button (TILE-EDIT).
    if ((_type == "GK_MAP" || _type == "GK_PLAYER") && _row == 1) {
        scr_node_edit_open(_node);
        return true;
    }
    if (_type == "GK_PHYSICS") {
        scr_push_undo_snapshot();
        if (_row == 0) _node.macro_param_a = clamp(_node.macro_param_a + _delta * 4, 4, 96);
        if (_row == 1) _node.macro_param_b = clamp(_node.macro_param_b + _delta * 8, 16, 160);
        if (_row == 2) _node.macro_param_c = clamp(_node.macro_param_c + _delta, 1, 16);
        if (_row == 3) _node.macro_param_text_a = scr_gk_cycle_name(scr_audio_list("SAMPLE"), _node.macro_param_text_a, _delta, true);
        return true;
    }
    if (_type == "GK_EVENTS") {
        scr_push_undo_snapshot();
        if (_row == 0) _node.macro_param_text_a = scr_gk_cycle_name(scr_audio_list("SAMPLE"), _node.macro_param_text_a, _delta, true);
        if (_row == 1) _node.macro_param_text_b = scr_gk_cycle_name(scr_audio_list("SAMPLE"), _node.macro_param_text_b, _delta, true);
        if (_row == 2) _node.macro_param_a = _node.macro_param_a != 0 ? 0 : 1;
        return true;
    }
    return false;
}

/// True when a Game Kit node's settings resolve (for the validity dots).
function scr_gk_node_ok(_node) {
    var _type = _node.macro_type;
    if (_type == "GK_MAP") return scr_gk_map_problem(scr_asset_find_by_name(_node.macro_asset_name)) == "";
    if (_type == "GK_PLAYER") return scr_gk_animset_problem(scr_asset_find_by_name(_node.macro_asset_name)) == "";
    if (_type == "GK_PHYSICS") return scr_gk_sample_ok(_node.macro_param_text_a);
    if (_type == "GK_EVENTS") return scr_gk_sample_ok(_node.macro_param_text_a) && scr_gk_sample_ok(_node.macro_param_text_b);
    return true;
}

/// Speed values are 1/16 px per frame; shown as pixels.
function scr_gk_px_text(_sixteenths) {
    var _whole = _sixteenths div 16;
    var _frac = _sixteenths mod 16;
    if (_frac == 0) return string(_whole);
    return string_format(_sixteenths / 16, 1, 2);
}

/// Draws the rows of a Game Kit node; _dx/_dy = screen position of the node.
function scr_gk_node_draw(_node, _dx, _dy) {
    var _type = _node.macro_type;
    var _w = _node.node_width;
    var _rows = [];
    var _info = "";

    switch (_type) {
        case "GK_SCREEN": _info = "320x256, 16 colours"; break;
        case "GK_WAIT": _info = "sync to 50 Hz display"; break;
        case "GK_INPUT": _info = "stick + fire, port 2"; break;
        case "GK_ENEMIES": _info = "walk, turn, hurt hero"; break;
        case "GK_ANIMATE": _info = "idle/run/jump/fall"; break;
        case "GK_DRAW": _info = "draws hero + enemies"; break;
        case "GK_MAP":
            array_push(_rows, "<  " + (_node.macro_asset_name == "" ? "(no map)" : _node.macro_asset_name) + "  >");
            var _map = scr_asset_find_by_name(_node.macro_asset_name);
            var _tileset = _map != undefined && _map.type == "TILEMAP" ? scr_asset_find_by_name(_map.tileset) : undefined;
            if (_tileset != undefined && _tileset.type == "TILESET") {
                array_push(_rows, "EDIT MAP: " + string(_tileset.tile_size) + "px, " + string(_map.rooms_x) + "x" + string(_map.rooms_y) + " rooms");
            } else {
                array_push(_rows, "EDIT MAP (not found)");
            }
            break;
        case "GK_PLAYER":
            array_push(_rows, "<  " + (_node.macro_asset_name == "" ? "(no hero)" : _node.macro_asset_name) + "  >");
            var _set = scr_asset_find_by_name(_node.macro_asset_name);
            if (_set != undefined && _set.type == "ANIMSET") {
                array_push(_rows, "EDIT HERO: 16x" + string(_set.height) + ", " + string(array_length(_set.states.idle.frames)) + "/" + string(array_length(_set.states.run.frames)) + "/" + string(array_length(_set.states.jump.frames)) + "/" + string(array_length(_set.states.fall.frames)));
            } else {
                array_push(_rows, "EDIT HERO (not found)");
            }
            break;
        case "GK_PHYSICS":
            array_push(_rows, "<  RUN: " + scr_gk_px_text(_node.macro_param_a) + " px  >");
            array_push(_rows, "<  JUMP: " + scr_gk_px_text(_node.macro_param_b) + " px  >");
            array_push(_rows, "<  GRAVITY: " + string(_node.macro_param_c) + "  >");
            array_push(_rows, "<  JUMP SFX: " + (_node.macro_param_text_a == "" ? "none" : _node.macro_param_text_a) + "  >");
            break;
        case "GK_EVENTS":
            array_push(_rows, "<  PICKUP SFX: " + (_node.macro_param_text_a == "" ? "none" : _node.macro_param_text_a) + "  >");
            array_push(_rows, "<  HURT SFX: " + (_node.macro_param_text_b == "" ? "none" : _node.macro_param_text_b) + "  >");
            array_push(_rows, "EXIT: " + (_node.macro_param_a != 0 ? "after all pickups" : "any time"));
            break;
    }

    var _i = 0;
    while (_i < array_length(_rows)) {
        var _text = _rows[_i];
        // "<  value  >" rows step / cycle: draw them as stepper rows.
        var _stepper = string_copy(_text, 1, 3) == "<  " && string_copy(_text, string_length(_text) - 2, 3) == "  >";
        if (_stepper) _text = string_copy(_text, 4, string_length(_text) - 6);
        var _fill = c_dkgray;
        if (_i == 1 && (_type == "GK_MAP" || _type == "GK_PLAYER")) {
            // EDIT button row (opens TILE-EDIT, scr_gk_node_click).
            var _ry = _dy + 20 + _i * 20;
            var _hover = point_in_rectangle(mouse_x, mouse_y, _dx, _ry, _dx + _w, _ry + 20) && !scr_amiga_modal_open();
            _fill = _hover ? make_colour_rgb(35, 125, 130) : make_colour_rgb(25, 95, 100);
        }
        scr_node_row(_dx, _w, _dy + 20 + _i * 20, _text, _fill, c_white, _stepper);
        _i += 1;
    }
    if (_info != "") {
        draw_set_colour(make_colour_rgb(200, 230, 210));
        scr_ui_text_mid(_dx + NODE_TEXT_PAD, _dy + 20, _dy + 40, scr_ui_fit_label(_info, _w - 2 * NODE_TEXT_PAD));
        draw_set_colour(c_white);
    }
}

// ---------------------------------------------------------------------------
// Shared node row drawing (obj_opcode_node Draw and the Game Kit rows above).
// Node rows are 20 px slots under the 20 px header. Each is drawn as an inset
// bevelled field; the insets keep the last row inside the node's own
// bevelled bottom-right corner.

#macro NODE_ROW_INSET_L 9
#macro NODE_ROW_INSET_R 10
#macro NODE_TEXT_PAD 15

/// One row card in the 20 px slot at _ry of a node at _dx, _w wide.
/// _stepper: "<" at the left, ">" at the right, _text centred between them
/// (the left half of the row steps down, the right half up).
function scr_node_row(_dx, _w, _ry, _text, _fill, _text_colour, _stepper) {
    var _x1 = _dx + NODE_ROW_INSET_L;
    var _x2 = _dx + _w - NODE_ROW_INSET_R;
    var _y1 = _ry + 1;
    var _y2 = _ry + 18;
    scr_ui_box(_x1, _y1, _x2, _y2, _fill, merge_colour(_fill, c_white, 0.22));
    draw_set_colour(_text_colour);
    if (_stepper) {
        scr_ui_text_mid(_x1 + 6, _y1, _y2 + 1, "<");
        draw_set_halign(fa_right);
        scr_ui_text_mid(_x2 - 6, _y1, _y2 + 1, ">");
        draw_set_halign(fa_left);
        scr_ui_text_centred((_x1 + _x2) * 0.5, (_y1 + _y2 + 1) * 0.5, scr_ui_fit_label(_text, _x2 - _x1 - 36));
    } else {
        scr_ui_text_mid(_x1 + 6, _y1, _y2 + 1, scr_ui_fit_label(_text, _x2 - _x1 - 12));
    }
    draw_set_colour(c_white);
}

/// Hover help for a Game Kit node.
function scr_gk_node_help(_node) {
    switch (_node.macro_type) {
        case "GK_SCREEN": return "GAME SCREEN takes over the display for the Game Kit: 320 x 256 pixels, 4 bitplanes (16 colours from the tileset), the 8 hardware sprites in front, and its own Copper list. OS interrupts stop; music keeps playing.";
        case "GK_MAP": return "DRAW MAP loads the tile map '" + _node.macro_asset_name + "' and its tileset, sets the palette and draws the room the player starts in. Rooms are whole screens: walking off an edge flips to the next one. Edit maps in TILE-EDIT.";
        case "GK_PLAYER": return "PLAYER makes '" + _node.macro_asset_name + "' the hero: a 16 px wide hardware sprite (sprite 0) with idle, run, jump and fall animations, placed at the map's start point.";
        case "GK_WAIT": return "WAIT FRAME waits for the video beam to pass the bottom of the display, so the game loop runs once per frame (50 times a second on a PAL Amiga).";
        case "GK_INPUT": return "READ JOYSTICK reads the stick and fire button in port 2. In FS-UAE the cursor keys are the stick and right Ctrl is fire.";
        case "GK_PHYSICS": return "PHYSICS moves the hero: left/right runs, fire or up jumps (release early for a small hop), gravity pulls down, Solid tiles block, Platform tiles carry from above. Run " + scr_gk_px_text(_node.macro_param_a) + " px, jump " + scr_gk_px_text(_node.macro_param_b) + " px per frame, gravity " + string(_node.macro_param_c) + "/16.";
        case "GK_EVENTS": return "TILE EVENTS reacts to the tiles the hero touches: Collect tiles disappear (pickup sound), Hazard tiles send it back to the start (hurt sound), Exit tiles finish the level" + (_node.macro_param_a != 0 ? " once every pickup is collected." : ".");
        case "GK_ENEMIES": return "ENEMIES moves the enemies of the current room (placed in TILE-EDIT's map): they walk, turn at walls, ledges and the room edge, animate with their run frames and hurt the hero on contact. Up to 6 per room, sprites 2-7.";
        case "GK_ANIMATE": return "ANIMATE chooses the hero's state - idle, run, jump (going up) or fall - and steps through that state's frames at its speed.";
        case "GK_DRAW": return "DRAW SPRITES copies the current frames into the hardware sprites and positions them: the hero (mirrored when facing left) and every enemy. Put it last in the loop, after WAIT FRAME.";
    }
    return "";
}
