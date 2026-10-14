/// @desc Macro node sizes and starting values, in one place so the palette,
/// workspace loading and test setups all agree.

/// Height in pixels of a macro node of _macro_type.
function scr_macro_node_height(_macro_type) {
    switch (_macro_type) {
        case "ANIM_BOB":
        case "ANIM_SPR":
            return 120;
        case "STOP_MOD":
            return 40;
        case "PLAY_MOD":
            return 80;
        case "PLAY_SFX":
            return 80;
        case "CODE":
            return 120;
    }
    return 100;
}

/// Starting values for a freshly dropped audio / CODE node.
function scr_macro_node_init(_node, _macro_type) {
    _node.is_macro = true;
    _node.macro_type = _macro_type;
    _node.node_height = scr_macro_node_height(_macro_type);

    if (_macro_type == "PLAY_MOD" || _macro_type == "PLAY_SFX") {
        var _names = scr_audio_list(_macro_type == "PLAY_MOD" ? "MOD" : "SAMPLE");
        _node.macro_asset_name = array_length(_names) > 0 ? _names[0] : "";
        _node.macro_music_pos = 0;
        _node.macro_sfx_channel = -1;
        _node.macro_sfx_volume = -1;
    } else if (_macro_type == "CODE") {
        _node.macro_code_text = "; Custom 68000 code - Motorola syntax (vasm).\n"
            + "; Ctrl+Space completes, hover a word for help, F5 builds and runs.\n"
            + "; a6 is free to use; CUSTOM, DMACON, COLOR00 ... are predefined.\n"
            + "\tlea\tCUSTOM,a6\n"
            + "\tmove.w\t#$0F80,COLOR00(a6)\n";
    }
}

/// Cycles a PLAY_MOD / PLAY_SFX node's asset through the assets of its type.
function scr_macro_node_cycle_asset(_node, _delta) {
    var _names = scr_audio_list(_node.macro_type == "PLAY_MOD" ? "MOD" : "SAMPLE");
    var _count = array_length(_names);
    if (_count == 0) {
        scr_set_status_message("No " + (_node.macro_type == "PLAY_MOD" ? "music" : "samples") + " yet - import some in SND-EDIT.", c_orange);
        return;
    }
    var _index = -1;
    var _i = 0;
    while (_i < _count) {
        if (_names[_i] == _node.macro_asset_name) _index = _i;
        _i += 1;
    }
    _index = (_index + _delta + _count) mod _count;
    if (_index < 0) _index = 0;
    _node.macro_asset_name = _names[_index];
}
