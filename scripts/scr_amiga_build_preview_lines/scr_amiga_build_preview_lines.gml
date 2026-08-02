/// @desc scr_amiga_build_preview_lines()
/// Walks the real compiled program order and builds a flat array of
/// preview lines. Macro nodes collapse to one header line by default
/// (node.preview_collapsed == true) — click it to expand and see the
/// full generated instructions, indented, underneath. Regular nodes are
/// unaffected. Returns an array of structs:
/// { text, is_error, is_macro_header, node_id, indent }
function scr_amiga_build_preview_lines() {
    var _lines = [];
    var _preview_nodes = scr_amiga_collect_program_nodes();
    var _count = array_length(_preview_nodes);
    var _p = 0;

    while (_p < _count) {
        var _node = _preview_nodes[_p];
        var _emit_result = scr_emit_opcode_line(_node);

        if (_node.is_macro) {
            var _toggle_glyph = "[+]";

            if (!_node.preview_collapsed) {
                _toggle_glyph = "[-]";
            }

            var _header_text = _toggle_glyph + " MACRO: " + _node.macro_type;

            if (_node.node_label != "") {
                _header_text += " (" + _node.node_label + ")";
            }

            array_push(_lines, { text : _header_text, is_error : !_emit_result.is_valid, is_macro_header : true, node_id : _node, indent : false });

            if (!_node.preview_collapsed) {
                var _sub_lines = scr_split_lines(_emit_result.text);
                var _sub_count = array_length(_sub_lines);
                var _s = 0;

                while (_s < _sub_count) {
                    array_push(_lines, { text : _sub_lines[_s], is_error : !_emit_result.is_valid, is_macro_header : false, node_id : noone, indent : true });
                    _s += 1;
                }
            }
        } else {
            var _plain_lines = scr_split_lines(_emit_result.text);
            var _plain_count = array_length(_plain_lines);
            var _pl = 0;

            while (_pl < _plain_count) {
                array_push(_lines, { text : _plain_lines[_pl], is_error : !_emit_result.is_valid, is_macro_header : false, node_id : noone, indent : false });
                _pl += 1;
            }
        }

        _p += 1;
    }

    return _lines;
}
