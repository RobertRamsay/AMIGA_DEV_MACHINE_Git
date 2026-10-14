/// scr_code_editor_open
/// Entry point for the CODE block editor (obj_code_editor) plus its shared
/// monospace font cache.

// Script-level globals run once at game start, before the first room.
// global.code_editor_build_errors: [{node_uid, line (0-based in the block), message}]
// filled by the build after vasm runs; drawn as errors in the matching block.
global.code_editor_build_errors = [];
global.code_editor_font = -1;
global.code_editor_font_size = 0;
global.code_editor_font_is_mono = false;
global.code_editor_font_pref_size = 13;

/// @desc scr_code_editor_open(_node)
/// Opens the full-screen code editor on _node (an obj_opcode_node CODE macro
/// whose source lives in macro_code_text). If an editor is already open on a
/// different node it is committed and closed first. Returns the editor instance.
function scr_code_editor_open(_node) {
    if (!instance_exists(_node)) return noone;

    var _existing = noone;

    with (obj_code_editor) {
        if (editor_node == _node) {
            _existing = id;
        } else {
            ed_close(true);
        }
    }

    if (_existing != noone) return _existing;

    var _editor = instance_create_depth(0, 0, -400000, obj_code_editor);
    _editor.ed_load(_node);
    return _editor;
}

/// @desc scr_code_editor_font_ensure(_size)
/// Creates (once per size) the monospace editor font: Consolas, then Courier
/// New, then Lucida Console. Falls back to font_CyberVerse (drawn in fixed
/// cells by the editor) when none can be loaded.
function scr_code_editor_font_ensure(_size) {
    _size = clamp(round(_size), 8, 32);

    if (global.code_editor_font_size == _size && global.code_editor_font != -1) {
        if (!global.code_editor_font_is_mono || font_exists(global.code_editor_font)) return global.code_editor_font;
    }

    if (global.code_editor_font_is_mono && global.code_editor_font != -1 && font_exists(global.code_editor_font)) {
        font_delete(global.code_editor_font);
    }

    global.code_editor_font = -1;
    global.code_editor_font_is_mono = false;
    global.code_editor_font_size = _size;

    var _paths = ["C:/Windows/Fonts/consola.ttf", "C:/Windows/Fonts/cour.ttf", "C:/Windows/Fonts/lucon.ttf"];
    var _i = 0;

    while (_i < array_length(_paths)) {
        var _path = _paths[_i];
        _i += 1;

        if (!file_exists(_path)) continue;

        var _font = -1;
        try {
            _font = font_add(_path, _size, false, false, 32, 255);
        } catch (_err) {
            _font = -1;
        }

        if (_font != -1 && font_exists(_font)) {
            global.code_editor_font = _font;
            global.code_editor_font_is_mono = true;
            return _font;
        }
    }

    global.code_editor_font = font_CyberVerse;
    global.code_editor_font_is_mono = false;
    return global.code_editor_font;
}
