/// @desc scr_tracker_selftest()
/// Round trip of the TRACKER song model: build a song, write it as an M.K.
/// module, read it back with the import code (scr_audio_mod_info /
/// scr_audio_mod_song) and compare every cell and instrument. Run by
/// -admselftest. Returns an array of failure messages (empty = pass).
function scr_tracker_selftest() {
    var _fail = [];

    // Every synth instrument has data in range; loops cover waveforms only.
    var _kinds = scr_tracker_synth_kinds();
    for (var _k = 0; _k < array_length(_kinds); _k += 1) {
        var _s = scr_tracker_synth(_kinds[_k]);
        if (_s.length < 32 || (_s.length mod 2) != 0) array_push(_fail, "synth " + _kinds[_k] + " length " + string(_s.length));
        for (var _i = 0; _i < _s.length; _i += 1) {
            if (_s.data[_i] < -128 || _s.data[_i] > 127 || _s.data[_i] != round(_s.data[_i])) {
                array_push(_fail, "synth " + _kinds[_k] + " value " + string(_s.data[_i]));
                break;
            }
        }
    }

    // A song: three patterns, pattern 1 not in the order list yet.
    var _song = scr_tracker_song_new();
    _song.title = "selftest tune";
    array_push(_song.patterns, scr_tracker_pattern_empty(), scr_tracker_pattern_empty());
    _song.order = [0, 2, 0];
    _song.restart = 1;
    var _periods = scr_audio_note_periods();
    var _p0 = _song.patterns[0];
    var _at = scr_tracker_cell_at(0, 0);
    _p0[@ _at] = _periods[12];          // C-2
    _p0[@ _at + 1] = 1;
    _p0[@ _at + 2] = 12;
    _p0[@ _at + 3] = 40;
    _at = scr_tracker_cell_at(63, 3);
    _p0[@ _at] = _periods[35];          // B-3
    _p0[@ _at + 1] = 31;
    _p0[@ _at + 2] = 15;
    _p0[@ _at + 3] = 125;
    var _p1 = _song.patterns[1];
    _at = scr_tracker_cell_at(17, 2);
    _p1[@ _at] = _periods[0];           // C-1
    _p1[@ _at + 1] = 17;
    _p1[@ _at + 2] = 14;
    _p1[@ _at + 3] = $C3;
    _song.samples[1].finetune = -3;
    _song.samples[30] = scr_tracker_synth("SAW");
    _song.samples[30].name = "slot thirty-one";
    _song.samples[30].volume = 33;

    var _out = scr_tracker_song_to_buffer(_song);
    var _info = scr_audio_mod_info(_out.buffer);
    var _back = scr_audio_mod_song(_out.buffer);
    buffer_delete(_out.buffer);
    if (!_info.ok) {
        array_push(_fail, "written module rejected: " + _info.err);
        return _fail;
    }
    if (_info.tag != "M.K.") array_push(_fail, "tag " + _info.tag);
    if (_info.positions != 3) array_push(_fail, "positions " + string(_info.positions));
    if (_info.patterns != 3) array_push(_fail, "patterns " + string(_info.patterns) + " (the unused pattern was lost)");
    if (_info.restart != 1) array_push(_fail, "restart " + string(_info.restart));
    if (string_trim(_info.title) != "selftest tune") array_push(_fail, "title [" + _info.title + "]");
    if (_info.expected_size != _out.size) array_push(_fail, "size " + string(_out.size) + " vs expected " + string(_info.expected_size));
    if (_back == undefined) {
        array_push(_fail, "written module did not parse");
        return _fail;
    }
    if (_back.order[1] != 2) array_push(_fail, "order[1] " + string(_back.order[1]));
    for (var _pi = 0; _pi < 3; _pi += 1) {
        var _a = _song.patterns[_pi];
        var _b = _back.patterns[_pi];
        for (var _c = 0; _c < array_length(_a); _c += 1) {
            if (_a[_c] != _b[_c]) {
                array_push(_fail, "pattern " + string(_pi) + " value " + string(_c) + ": " + string(_b[_c]) + " want " + string(_a[_c]));
                break;
            }
        }
    }
    var _slots = [0, 1, 3, 5, 30];
    for (var _j = 0; _j < array_length(_slots); _j += 1) {
        var _n = _slots[_j];
        var _want = _song.samples[_n];
        var _got = _back.samples[_n];
        if (_got.length != _want.length) array_push(_fail, "sample " + string(_n + 1) + " length " + string(_got.length) + " want " + string(_want.length));
        if (_got.volume != _want.volume) array_push(_fail, "sample " + string(_n + 1) + " volume");
        if (_got.finetune != _want.finetune) array_push(_fail, "sample " + string(_n + 1) + " finetune " + string(_got.finetune));
        if (_got.loop_length != _want.loop_length || _got.loop_start != _want.loop_start) array_push(_fail, "sample " + string(_n + 1) + " loop");
        for (var _d = 0; _d < _want.length; _d += 1) {
            if (_got.data[_d] != _want.data[_d]) {
                array_push(_fail, "sample " + string(_n + 1) + " byte " + string(_d));
                break;
            }
        }
        if (string_trim(_info.sample_names[_n]) != _want.name) array_push(_fail, "sample " + string(_n + 1) + " name [" + _info.sample_names[_n] + "]");
    }

    // Through a MOD asset and back into the editor's model.
    var _name = scr_audio_unique_name("trkselftest");
    var _error = scr_tracker_song_save(_song, _name);
    if (_error != "") {
        array_push(_fail, "save: " + _error);
    } else {
        var _loaded = scr_tracker_song_from_asset(scr_asset_find_by_name(_name));
        if (_loaded == undefined) array_push(_fail, "asset did not load");
        else if (_loaded.samples[30].name != "slot thirty-one" || array_length(_loaded.patterns) != 3) array_push(_fail, "asset round trip");
        scr_audio_delete(_name);
    }
    if (scr_tracker_note_text(_periods[13]) != "C#2") array_push(_fail, "note text " + scr_tracker_note_text(_periods[13]));
    if (scr_tracker_note_index(_periods[35]) != 35) array_push(_fail, "note index");

    // The editor's own operations.
    var _keep_last = variable_global_exists("tracker_last_name") ? global.tracker_last_name : "";
    var _ed = instance_create_depth(0, 0, -400000, obj_tracker_editor);
    with (_ed) {
        song_name = scr_audio_unique_name("trkedit");
        cur_pos = 0;
        cur_row = 5;
        cur_ch = 2;
        tracker_set_cell(_periods[12], 3, 10, $20);
        var _cells = tracker_pattern();
        var _at2 = scr_tracker_cell_at(5, 2);
        if (_cells[_at2] != _periods[12] || _cells[_at2 + 1] != 3 || _cells[_at2 + 2] != 10 || _cells[_at2 + 3] != $20) array_push(_fail, "set cell");
        tracker_transpose_track(12);
        if (_cells[_at2] != _periods[24]) array_push(_fail, "transpose +12: " + string(_cells[_at2]));
        tracker_undo_step(false);
        if (_cells[_at2] != _periods[12]) array_push(_fail, "undo transpose");
        tracker_undo_step(true);
        if (_cells[_at2] != _periods[24]) array_push(_fail, "redo transpose");
        tracker_tool("trk_copy");
        cur_ch = 0;
        tracker_tool("trk_paste");
        if (_cells[scr_tracker_cell_at(5, 0)] != _periods[24]) array_push(_fail, "track paste");
        tracker_tool("trk_clear");
        if (_cells[scr_tracker_cell_at(5, 0)] != 0) array_push(_fail, "track clear");
        tracker_set_start_value(true, 140);
        tracker_set_start_value(false, 4);
        if (tracker_start_value(true) != 140 || tracker_start_value(false) != 4) array_push(_fail, "speed / bpm " + string(tracker_start_value(false)) + " / " + string(tracker_start_value(true)));
        if (!tracker_save()) array_push(_fail, "editor save: " + message);
        var _saved_name = song_name;
        song = scr_tracker_song_new();
        if (!tracker_load(_saved_name)) array_push(_fail, "editor load");
        else if (song.patterns[0][scr_tracker_cell_at(5, 2)] != _periods[24]) array_push(_fail, "editor save / load cell");
        scr_audio_delete(_saved_name);
        instance_destroy();
    }
    // EDIT on a PLAY MUSIC node with no song: a new song, linked on save.
    var _node = instance_create_layer(-5000, -5000, "Instances", obj_opcode_node);
    scr_macro_node_init(_node, "PLAY_MOD");
    _node.macro_asset_name = "";
    var _ed2 = scr_tracker_open_for_node(_node);
    var _linked_name = "";
    with (_ed2) {
        tracker_save();
        _linked_name = song_name;
        instance_destroy();
    }
    if (_node.macro_asset_name != _linked_name || _linked_name == "") array_push(_fail, "node link: [" + _node.macro_asset_name + "] vs [" + _linked_name + "]");
    if (_linked_name != "") scr_audio_delete(_linked_name);
    with (_node) instance_destroy();

    global.tracker_last_name = _keep_last;
    return _fail;
}
