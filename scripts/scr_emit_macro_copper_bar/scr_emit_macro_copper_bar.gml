/// @desc scr_emit_macro_copper_bar(_node)
/// Fully self-contained now — no shared named asset. Reads the node's own
/// macro_cprbar_* fields (band count, target COLOR register, equidistant
/// full-height or an explicit VP range, and each band's own hex colour)
/// and expands into the full CPU-construction sequence: write each
/// WAIT/MOVE band pair into a chip-RAM buffer, terminate the list, point
/// COP1LC at it, then enable Copper DMA. Returns a struct { text, is_valid
/// }, same shape as scr_emit_opcode_line — text may (and here, will)
/// contain several lines.
function scr_emit_macro_copper_bar(_node) {
    var _band_count = _node.macro_cprbar_band_count;

    if (_band_count < 1 || _band_count > 16) {
        var _error_result = { text : "; ERROR: CPRBAR band count must be 1-16 (currently " + string(_band_count) + ")", is_valid : false };
        return _error_result;
    }

    var _vp_start = _node.macro_cprbar_vp_start;
    var _vp_end = _node.macro_cprbar_vp_end;

    if (_node.macro_cprbar_equidistant) {
        // Genuinely full height (0-256), not the old sky/water sub-range —
        // that was only ever half of a two-zone gradient, not "full height".
        _vp_start = 0;
        _vp_end = 256;
    } else if (_vp_start >= _vp_end) {
        var _error_result = { text : "; ERROR: CPRBAR VP start must be less than VP end (currently " + string(_vp_start) + " to " + string(_vp_end) + ")", is_valid : false };
        return _error_result;
    }

    var _band_index = 0;

    while (_band_index < _band_count) {
        if (!scr_is_valid_hex_colour(_node.macro_cprbar_bands[_band_index])) {
            var _error_result = { text : "; ERROR: CPRBAR band " + string(_band_index + 1) + " colour must be 1-3 hex digits (currently '" + _node.macro_cprbar_bands[_band_index] + "')", is_valid : false };
            return _error_result;
        }

        _band_index += 1;
    }

    // Spread each macro instance's buffer out by uid so multiple copper
    // bar macros on the same build don't collide in chip RAM.
    var _buffer_base = 131072 + ((_node.uid mod 1000) * 512);

    var _lines = "";

    if (_node.node_label != "") {
        _lines += _node.node_label + ":\n";
    }

    // Each COLORxx register is 2 bytes apart from COLOR00 ($DFF180 = offset
    // 384 decimal), so the target register just shifts the base offset.
    var _register_offset = 384 + (_node.macro_cprbar_target_register * 2);
    var _copper_offset = 0;
    var _b = 0;

    while (_b < _band_count) {
        // Each band starts at the beginning of its own equal zone — band i
        // of N starts at i/N through the range, not spread across N-1
        // intervals the way gradient control points would be.
        var _t = _b / _band_count;
        var _vp = floor(_vp_start + (_vp_end - _vp_start) * _t);
        var _colour = scr_hex_string_to_number(_node.macro_cprbar_bands[_b]);

        var _wait_longword = ((_vp * 256 + 1) * 65536) + 65280;
        var _move_longword = (_register_offset * 65536) + _colour;

        _lines += "\tMOVE.L #" + string(_wait_longword) + "," + string(_buffer_base + _copper_offset) + ".L\n";
        _copper_offset += 4;

        _lines += "\tMOVE.L #" + string(_move_longword) + "," + string(_buffer_base + _copper_offset) + ".L\n";
        _copper_offset += 4;

        _b += 1;
    }

    _lines += "\tMOVE.L #4294967294," + string(_buffer_base + _copper_offset) + ".L\n";
    _lines += "\tMOVE.L #" + string(_buffer_base) + ",14676096.L\n";
    _lines += "\tMOVE.W #33408,14676118.L";

    var _result = { text : _lines, is_valid : true };
    return _result;
}
