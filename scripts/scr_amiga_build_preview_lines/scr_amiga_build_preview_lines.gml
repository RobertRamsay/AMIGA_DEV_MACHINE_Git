/// @desc scr_amiga_build_preview_lines()
/// Walks the real compiled program order and builds a flat array of
/// preview lines. Macro nodes collapse to one header line by default
/// (node.preview_collapsed == true) — click it to expand and see the
/// full generated instructions, indented, underneath. Regular nodes are
/// unaffected. Returns an array of structs:
/// { text, is_error, is_macro_header, node_id, indent }
function scr_amiga_wrap_preview_text(_text, _max_width) {
    var _wrapped = [];
    var _remaining = _text;

    if (_remaining == "") return [""];

    while (string_width(_remaining) > _max_width) {
        var _length = string_length(_remaining);
        var _fit = 1;

        while (_fit < _length && string_width(string_copy(_remaining, 1, _fit + 1)) <= _max_width) {
            _fit += 1;
        }

        // Prefer the last complete word that fits. A single assembler label
        // can itself exceed the panel, so fall back to a hard character break.
        var _break_at = 0;
        var _scan = _fit;
        while (_scan > 1) {
            if (string_char_at(_remaining, _scan) == " ") {
                _break_at = _scan;
                break;
            }
            _scan -= 1;
        }

        if (_break_at > 0) {
            array_push(_wrapped, string_copy(_remaining, 1, _break_at - 1));
            _remaining = string_trim(string_copy(_remaining, _break_at + 1, _length - _break_at));
        } else {
            array_push(_wrapped, string_copy(_remaining, 1, _fit));
            _remaining = string_copy(_remaining, _fit + 1, _length - _fit);
        }
    }

    array_push(_wrapped, _remaining);
    return _wrapped;
}

function scr_amiga_build_preview_lines() {
    var _lines = [];
    var _preview_nodes = scr_amiga_collect_program_nodes();
    var _count = array_length(_preview_nodes);
    var _p = 0;

    while (_p < _count) {
        var _node = _preview_nodes[_p];
        var _emit_result;

        // The real bitmap emitter creates 25,600 DC.W values. Keep the live
        // preview lightweight and perform that conversion only for an F5 build.
        if (_node.is_macro && _node.macro_type == "GET_BITMAP_BOB") {
            var _bob_preview_asset = scr_asset_find_by_name(_node.macro_asset_name);
            var _bob_preview_valid = _bob_preview_asset != undefined && _bob_preview_asset.type == "BOB";
            _emit_result = {
                text : _bob_preview_valid
                    ? "; GetBitmap (BOB)\n; allocate 51,200-byte displayed bitmap in Chip RAM\n; derive BOB width, height and padded word width\n; allocate five-plane rectangular save-under buffer\n; allocate/copy BOB transparency mask plus five image planes\n; enable bitplane, Copper and Blitter DMA"
                    : "; ERROR: BOB asset '" + _node.macro_asset_name + "' not found",
                is_valid : _bob_preview_valid
            };
        } else if (_node.is_macro && (_node.macro_type == "BITMAP_DISPLAY" || _node.macro_type == "BOB_BITMAP_TEST" || _node.macro_type == "SPRITE_BITMAP_TEST")) {
            var _bitmap_asset = scr_asset_find_by_name("TestBitmap");
            if (_node.macro_type == "BITMAP_DISPLAY") _bitmap_asset = scr_asset_find_by_name(_node.macro_asset_name);
            var _bitmap_valid = _bitmap_asset != undefined && _bitmap_asset.type == "BITMAP";
            _emit_result = {
                text : _bitmap_valid
                    ? "; 320x256 bitmap motion test: five planes, shared 32-colour palette, one pixel per frame"
                    : "; ERROR: TestBitmap not found",
                is_valid : _bitmap_valid
            };
        } else {
            _emit_result = scr_emit_opcode_line(_node);
        }

        if (_node.is_macro) {
            var _toggle_glyph = "[+]";

            if (!_node.preview_collapsed) {
                _toggle_glyph = "[-]";
            }

            var _header_text = _toggle_glyph + " MACRO: " + _node.macro_type;

            if (_node.node_label != "") {
                _header_text += " (" + _node.node_label + ")";
            }

            var _wrapped_header = scr_amiga_wrap_preview_text(_header_text, 326);
            for (var _wh = 0; _wh < array_length(_wrapped_header); _wh += 1) {
                array_push(_lines, { text : _wrapped_header[_wh], is_error : !_emit_result.is_valid, is_macro_header : true, node_id : _node, indent : false });
            }

            if (!_node.preview_collapsed) {
                var _sub_lines = scr_split_lines(_emit_result.text);
                var _sub_count = array_length(_sub_lines);
                var _s = 0;

                while (_s < _sub_count) {
                    var _wrapped_sub = scr_amiga_wrap_preview_text(_sub_lines[_s], 314);
                    for (var _ws = 0; _ws < array_length(_wrapped_sub); _ws += 1) {
                        array_push(_lines, { text : _wrapped_sub[_ws], is_error : !_emit_result.is_valid, is_macro_header : false, node_id : noone, indent : true });
                    }
                    _s += 1;
                }
            }
        } else {
            var _plain_lines = scr_split_lines(_emit_result.text);
            var _plain_count = array_length(_plain_lines);
            var _pl = 0;

            while (_pl < _plain_count) {
                var _wrapped_plain = scr_amiga_wrap_preview_text(_plain_lines[_pl], 326);
                for (var _wp = 0; _wp < array_length(_wrapped_plain); _wp += 1) {
                    array_push(_lines, { text : _wrapped_plain[_wp], is_error : !_emit_result.is_valid, is_macro_header : false, node_id : noone, indent : false });
                }
                _pl += 1;
            }
        }

        _p += 1;
    }

    return _lines;
}
