/// @desc scr_emit_macro_sprite_display(_node)
/// Looks up _node.macro_asset_name and expands into the full sequence to
/// display a real hardware sprite: sets up a minimal 320x256 PAL display
/// window + a blank single bitplane (a sprite alone, with no display
/// window ever configured, has nothing to appear within — confirmed
/// against the AHRM's own canonical sprite_display.asm example, which
/// always sets DIWSTRT/DIWSTOP/DDFSTRT/DDFSTOP/BPLCON0 alongside a
/// sprite, never just the sprite by itself), sets the 3 colour registers
/// for this sprite's channel pair, writes the POS/CTL words + DATA/DATB
/// pairs per scanline + terminator into chip RAM at the asset's address,
/// points SPRxPTH/PTL at it, then enables bitplane + sprite DMA.
/// Returns { text, is_valid }.
///
/// Hardware format verified against the Amiga Hardware Reference Manual:
/// SPRxPOS  bits15-8 = VSTART low byte, bits7-0 = HSTART high byte
/// SPRxCTL  bits15-8 = VSTOP low byte, bit2 = VSTART bit8,
///          bit1 = VSTOP bit8, bit0 = HSTART bit0
/// Sprite pairs (0&1)/(2&3)/(4&5)/(6&7) share COLOR17-19/21-23/25-27/29-31.
/// DIWSTRT/DIWSTOP $2C81/$2CC1 and DDFSTRT/DDFSTOP $38/$D0 are the
/// standard 320x256 PAL low-res values, cross-confirmed against both the
/// AHRM's own example and independently published working demo code.
function scr_emit_macro_sprite_display(_node) {
    var _asset = scr_asset_find_by_name(_node.macro_asset_name);

    if (_asset == undefined) {
        var _error_result = { text : "; ERROR: sprite asset '" + _node.macro_asset_name + "' not found", is_valid : false };
        return _error_result;
    }

    var _channel = _asset.channel;
    var _height = _asset.height;
    var _address = _asset.address;
    var _pixels = _asset.pixels;

    var _pair_index = _channel div 2;
    var _base_colour_index = 17 + (_pair_index * 4);
    var _colour_reg_1 = 14676352 + (_base_colour_index * 2);
    var _colour_reg_2 = 14676352 + ((_base_colour_index + 1) * 2);
    var _colour_reg_3 = 14676352 + ((_base_colour_index + 2) * 2);

    var _sprxpth = 14676256 + (_channel * 4);

    // Blank bitplane buffer, offset well clear of the sprite's own data
    // (which only ever needs a few hundred bytes) so the two never collide.
    var _bitplane_address = _address + 8192;

    var _colour_1_value = (_asset.colour_r[0] * 256) + (_asset.colour_g[0] * 16) + _asset.colour_b[0];
    var _colour_2_value = (_asset.colour_r[1] * 256) + (_asset.colour_g[1] * 16) + _asset.colour_b[1];
    var _colour_3_value = (_asset.colour_r[2] * 256) + (_asset.colour_g[2] * 16) + _asset.colour_b[2];

    var _vstart = 150;
    var _hstart = 160;
    var _vstop = _vstart + _height;

    var _vstart_lo = _vstart & 255;
    var _vstart_hi = (_vstart >> 8) & 1;
    var _hstart_lo = _hstart & 1;
    var _hstart_hi = (_hstart >> 1) & 255;
    var _vstop_lo = _vstop & 255;
    var _vstop_hi = (_vstop >> 8) & 1;

    var _pos_word = (_vstart_lo << 8) | _hstart_hi;
    var _ctl_word = (_vstop_lo << 8) | (_vstart_hi << 2) | (_vstop_hi << 1) | _hstart_lo;

    var _lines = "";

    if (_node.node_label != "") {
        _lines += _node.node_label + ":\n";
    }

    // Minimal 320x256 PAL display: 1 bitplane, standard window/fetch timing,
    // pointed at a blank buffer — just enough for the sprite to have
    // somewhere to appear within.
    _lines += "\tMOVE.L #" + string(_bitplane_address) + ",14676192.L\n";
    _lines += "\tMOVE.W #4608,14676224.L\n";
    _lines += "\tMOVE.W #0,14676226.L\n";
    _lines += "\tMOVE.W #0,14676232.L\n";
    _lines += "\tMOVE.W #56,14676114.L\n";
    _lines += "\tMOVE.W #208,14676116.L\n";
    _lines += "\tMOVE.W #11393,14676110.L\n";
    _lines += "\tMOVE.W #11457,14676112.L\n";
    _lines += "\tMOVE.W #0,14676352.L\n";

    _lines += "\tMOVE.W #" + string(_colour_1_value) + "," + string(_colour_reg_1) + ".L\n";
    _lines += "\tMOVE.W #" + string(_colour_2_value) + "," + string(_colour_reg_2) + ".L\n";
    _lines += "\tMOVE.W #" + string(_colour_3_value) + "," + string(_colour_reg_3) + ".L\n";

    var _write_offset = _address;

    _lines += "\tMOVE.L #" + string((_pos_word * 65536) + _ctl_word) + "," + string(_write_offset) + ".L\n";
    _write_offset += 4;

    var _row = 0;

    while (_row < _height) {
        var _data_word = 0;
        var _datb_word = 0;
        var _col = 0;

        while (_col < 16) {
            var _pixel_index = _pixels[(_row * 16) + _col];
            var _bit_position = 15 - _col;
            var _low_bit = _pixel_index & 1;
            var _high_bit = (_pixel_index >> 1) & 1;

            _data_word += (_low_bit << _bit_position);
            _datb_word += (_high_bit << _bit_position);

            _col += 1;
        }

        _lines += "\tMOVE.L #" + string((_data_word * 65536) + _datb_word) + "," + string(_write_offset) + ".L\n";
        _write_offset += 4;

        _row += 1;
    }

    // Two zero words (end-of-data), written as one longword
    _lines += "\tMOVE.L #0," + string(_write_offset) + ".L\n";
    _write_offset += 4;

    _lines += "\tMOVE.L #" + string(_address) + "," + string(_sprxpth) + ".L\n";
    _lines += "\tMOVE.W #33568,14676118.L";

    var _result = { text : _lines, is_valid : true };
    return _result;
}
