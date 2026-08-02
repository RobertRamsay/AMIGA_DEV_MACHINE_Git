/// @desc scr_emit_macro_copper_bar(_node)
/// Looks up _node.macro_asset_name in global.asset_list and expands into
/// the full CPU-construction sequence: write each WAIT/MOVE band pair into
/// a chip-RAM buffer, terminate the list, point COP1LC at it, then enable
/// Copper DMA. Returns a struct { text, is_valid }, same shape as
/// scr_emit_opcode_line — text may (and here, will) contain several lines.
function scr_emit_macro_copper_bar(_node) {
    var _asset = scr_asset_find_by_name(_node.macro_asset_name);

    if (_asset == undefined) {
        var _error_result = { text : "; ERROR: copper bar asset '" + _node.macro_asset_name + "' not found", is_valid : false };
        return _error_result;
    }

    // Spread each macro instance's buffer out by uid so multiple copper
    // bar macros on the same build don't collide in chip RAM.
    var _buffer_base = 131072 + ((_node.uid mod 1000) * 512);

    var _lines = "";

    if (_node.node_label != "") {
        _lines += _node.node_label + ":\n";
    }

    var _copper_offset = 0;
    var _band_count = array_length(_asset.bands);
    var _b = 0;

    while (_b < _band_count) {
        var _band = _asset.bands[_b];
        var _wait_longword = ((_band.vp * 256 + 1) * 65536) + 65280;
        var _move_longword = (384 * 65536) + _band.colour;

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
