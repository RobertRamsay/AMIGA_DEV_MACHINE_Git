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
        // vp 0-44 is vertical blanking/border, not the visible picture — a
        // band's WAIT can fire there, but part of its zone burns up before
        // anything is actually on screen, which is what made band 1 read
        // as a thin sliver. 44 is the real DIWSTRT visible-area start, so
        // anchoring there keeps the clean 256-line span while starting it
        // where the picture genuinely begins.
        _vp_start = 44;
        _vp_end = 300;
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

    // Each copper bar macro gets its own list in a BSS_C (chip RAM) section,
    // placed by the loader - no fixed address to collide with other macros.
    var _buffer_base = "__cprbar_" + string(floor(_node.uid));

    var _lines = "";

    if (_node.node_label != "") {
        _lines += _node.node_label + ":\n";
    }

    // Each COLORxx register is 2 bytes apart from COLOR00 ($DFF180 = offset
    // 384 decimal), so the target register just shifts the base offset.
    var _register_offset = 384 + (_node.macro_cprbar_target_register * 2);
    var _copper_offset = 0;

    // What runs before this node: the background colour (last SETBKG) and
    // whether some other macro already owns the display.
    var _top_colour = 0;
    var _display_before = false;
    var _program = scr_amiga_collect_program_nodes();
    var _pi = 0;
    while (_pi < array_length(_program) && _program[_pi] != _node.id) {
        var _prev = _program[_pi];
        if (_prev.is_macro) {
            if (_prev.macro_type == "SETBKG" && scr_is_valid_hex_colour(_prev.macro_asset_name)) _top_colour = scr_hex_string_to_number(_prev.macro_asset_name);
            if (_prev.macro_type == "BITMAP_DISPLAY" || _prev.macro_type == "SPRITE_DISPLAY" || _prev.macro_type == "GK_SCREEN"
                || _prev.macro_type == "BOB_BITMAP_TEST" || _prev.macro_type == "SPRITE_BITMAP_TEST" || _prev.macro_type == "GET_BITMAP_BOB") _display_before = true;
        }
        _pi += 1;
    }
    if (_node.macro_cprbar_target_register != 0) _top_colour = 0;

    // Top of every frame: the register goes back to its colour above the
    // first band (otherwise the last band's colour fills the top). With no
    // display of our own, bitplanes are switched off so whatever screen was
    // up at boot does not show through.
    if (!_display_before) {
        _lines += "\tMOVE.L #" + string((256 * 65536) + 512) + "," + _buffer_base + "+" + string(_copper_offset) + "\n"; // BPLCON0 = $0200
        _copper_offset += 4;
    }
    _lines += "\tMOVE.L #" + string((_register_offset * 65536) + _top_colour) + "," + _buffer_base + "+" + string(_copper_offset) + "\n";
    _copper_offset += 4;
    var _wrapped = false;
    var _b = 0;

    while (_b < _band_count) {
        // Each band starts at the beginning of its own equal zone — band i
        // of N starts at i/N through the range, not spread across N-1
        // intervals the way gradient control points would be.
        var _t = _b / _band_count;
        var _vp = floor(_vp_start + (_vp_end - _vp_start) * _t);
        var _colour = scr_hex_string_to_number(_node.macro_cprbar_bands[_b]);

        // WAIT holds only the low 8 bits of the line: past line 255 the list
        // first waits for the end of line 255 ($FFDF), then counts from 0 again.
        if (_vp >= 256 && !_wrapped) {
            _wrapped = true;
            _lines += "\tMOVE.L #4292870142," + _buffer_base + "+" + string(_copper_offset) + "\n";
            _copper_offset += 4;
        }

        var _wait_longword = (((_vp mod 256) * 256 + 1) * 65536) + 65280;
        var _move_longword = (_register_offset * 65536) + _colour;

        _lines += "\tMOVE.L #" + string(_wait_longword) + "," + _buffer_base + "+" + string(_copper_offset) + "\n";
        _copper_offset += 4;

        _lines += "\tMOVE.L #" + string(_move_longword) + "," + _buffer_base + "+" + string(_copper_offset) + "\n";
        _copper_offset += 4;

        _b += 1;
    }

    _lines += "\tMOVE.L #4294967294," + _buffer_base + "+" + string(_copper_offset) + "\n";
    _lines += "\tMOVE.L #" + _buffer_base + ",14676096.L\n";
    if (!_display_before) _lines += "\tMOVE.W #288,14676118.L\n"; // DMACON clear BPLEN + SPREN
    _lines += "\tMOVE.W #33408,14676118.L\n";
    _lines += "\tSECTION adm_cprbar_" + string(floor(_node.uid)) + ",BSS_C\n";
    _lines += _buffer_base + ":\tDS.B " + string(_copper_offset + 4) + "\n";
    _lines += "\tSECTION code,CODE";

    var _result = { text : _lines, is_valid : true };
    return _result;
}
