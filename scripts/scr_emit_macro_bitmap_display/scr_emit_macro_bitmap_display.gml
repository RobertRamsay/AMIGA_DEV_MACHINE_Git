/// @desc scr_emit_macro_bitmap_display(_node)
/// Converts a 320x256 indexed bitmap to five interleaved-by-plane Amiga
/// bitplanes, embeds them in a Hunk executable, allocates real chip RAM and
/// programs a standard PAL low-resolution 32-colour display.
function scr_emit_macro_bitmap_display(_node) {
    var _asset = scr_asset_find_by_name(_node.macro_asset_name);

    if (_asset == undefined || _asset.type != "BITMAP") {
        return { text : "; ERROR: bitmap asset '" + _node.macro_asset_name + "' not found", is_valid : false };
    }

    var _uid_text = string(floor(_node.uid));
    var _data_label = "__bitmap_data_" + _uid_text;
    var _ready_label = "__bitmap_ready_" + _uid_text;
    var _fail_label = "__bitmap_alloc_fail_" + _uid_text;
    var _copy_label = "__bitmap_copy_" + _uid_text;
    var _lines = "";

    if (_node.node_label != "") _lines += _node.node_label + ":\n";

    // Ask Exec for the bitmap plus a 48-byte Copper list. The Hunk may load in
    // Fast RAM on expanded machines, so bitplane data is explicitly copied.
    _lines += "\tMOVEA.L 4.W,A6\n";
    _lines += "\tMOVE.L #51248,D0\n";
    _lines += "\tMOVE.L #65538,D1\n"; // MEMF_CHIP | MEMF_CLEAR
    _lines += "\tJSR -198(A6)\n";     // exec.library AllocMem
    _lines += "\tTST.L D0\n";
    _lines += "\tBEQ.W " + _fail_label + "\n";
    _lines += "\tMOVEA.L D0,A2\n";
    _lines += "\tMOVEA.L D0,A1\n";
    _lines += "\tLEA " + _data_label + "(PC),A0\n";
    _lines += "\tMOVE.W #12799,D0\n";
    _lines += _copy_label + ":\n";
    _lines += "\tMOVE.L (A0)+,(A1)+\n";
    _lines += "\tDBRA D0," + _copy_label + "\n";

    // Take over display DMA only after allocation/copying is complete.
    _lines += "\tMOVE.W #32767,14676122.L\n";
    _lines += "\tMOVE.W #32767,14676118.L\n";
    _lines += "\tMOVE.W #56,14676114.L\n";
    _lines += "\tMOVE.W #208,14676116.L\n";
    _lines += "\tMOVE.W #11393,14676110.L\n";
    _lines += "\tMOVE.W #11457,14676112.L\n";
    _lines += "\tMOVE.W #20992,14676224.L\n"; // BPU=5, colour burst on
    _lines += "\tMOVE.W #0,14676226.L\n";
    _lines += "\tMOVE.W #0,14676228.L\n";
    _lines += "\tMOVE.W #0,14676230.L\n";
    _lines += "\tMOVE.W #0,14676232.L\n";
    _lines += "\tMOVE.W #0,14676476.L\n";

    var _plane = 0;
    while (_plane < 5) {
        var _plane_pointer_register = 14676192 + (_plane * 4);
        _lines += "\tMOVE.L A2,D0\n";
        if (_plane > 0) _lines += "\tADD.L #" + string(_plane * 10240) + ",D0\n";
        _lines += "\tMOVE.L D0," + string(_plane_pointer_register) + ".L\n";
        _plane += 1;
    }

    // Bitplane DMA advances its fetch pointers. Build a Copper list directly
    // after the image so all five pointers are restored every video frame.
    _lines += "\tMOVEA.L A2,A3\n";
    _lines += "\tADDA.L #51200,A3\n";
    _plane = 0;
    while (_plane < 5) {
        var _copper_pointer_offset = 224 + (_plane * 4);
        _lines += "\tMOVE.L A2,D0\n";
        if (_plane > 0) _lines += "\tADD.L #" + string(_plane * 10240) + ",D0\n";
        _lines += "\tMOVE.W #" + string(_copper_pointer_offset) + ",(A3)+\n";
        _lines += "\tSWAP D0\n";
        _lines += "\tMOVE.W D0,(A3)+\n";
        _lines += "\tMOVE.W #" + string(_copper_pointer_offset + 2) + ",(A3)+\n";
        _lines += "\tSWAP D0\n";
        _lines += "\tMOVE.W D0,(A3)+\n";
        _plane += 1;
    }
    _lines += "\tMOVE.L #4294967294,(A3)+\n";
    _lines += "\tMOVE.L A2,D0\n";
    _lines += "\tADD.L #51200,D0\n";
    _lines += "\tMOVE.L D0,14676096.L\n";
    _lines += "\tMOVE.W #0,14676104.L\n";

    var _colour = 0;
    while (_colour < 32) {
        var _colour_value = (_asset.colour_r[_colour] * 256) + (_asset.colour_g[_colour] * 16) + _asset.colour_b[_colour];
        _lines += "\tMOVE.W #" + string(_colour_value) + "," + string(14676352 + (_colour * 2)) + ".L\n";
        _colour += 1;
    }

    _lines += "\tMOVE.W #33664,14676118.L\n"; // SET, DMAEN, BPLEN, COPEN
    _lines += "\tJMP " + _ready_label + "\n";
    _lines += _fail_label + ":\n";
    _lines += "\tBRA.W " + _fail_label + "\n";
    _lines += "\tEVEN\n";
    _lines += _data_label + ":\n";

    // Plane-major layout: 20 big-endian words per row, 256 rows per plane.
    _plane = 0;
    var _words_on_line = 0;
    while (_plane < 5) {
        var _row = 0;
        while (_row < 256) {
            var _word_column = 0;
            while (_word_column < 20) {
                var _word_value = 0;
                var _bit = 0;
                while (_bit < 16) {
                    var _pixel_x = (_word_column * 16) + _bit;
                    var _pixel_index = _asset.pixels[(_row * 320) + _pixel_x];
                    if ((_pixel_index & (1 << _plane)) != 0) _word_value |= (1 << (15 - _bit));
                    _bit += 1;
                }

                if (_words_on_line == 0) _lines += "\tDC.W "; else _lines += ",";
                _lines += string(_word_value);
                _words_on_line += 1;
                if (_words_on_line >= 8) {
                    _lines += "\n";
                    _words_on_line = 0;
                }
                _word_column += 1;
            }
            _row += 1;
        }
        _plane += 1;
    }
    if (_words_on_line != 0) _lines += "\n";
    _lines += _ready_label + ":";

    return { text : _lines, is_valid : true };
}
