/// Shared five-bitplane display followed by a masked, Blitter-driven BOB.
function scr_emit_macro_bob_bitmap_test(_node) {
    var _bob = scr_asset_find_by_name(_node.macro_asset_name);
    var _bitmap = scr_asset_find_by_name("TestBitmap");
    if (_bob == undefined || _bob.type != "BOB" || _bob.width != 32 || _bob.height != 32)
        return { text : "; ERROR: BOB asset must be 32x32", is_valid : false };
    if (_bitmap == undefined || _bitmap.type != "BITMAP")
        return { text : "; ERROR: TestBitmap not found", is_valid : false };

    var _saved_name = _node.macro_asset_name;
    _node.macro_asset_name = "TestBitmap";
    var _base = scr_emit_macro_bitmap_display(_node);
    _node.macro_asset_name = _saved_name;
    if (!_base.is_valid) return _base;

    var _u = string(floor(_node.uid));
    var _bobdata = "__bob_data_" + _u;
    var _loop = "__bob_frame_" + _u;
    var _vb1 = "__bob_vb1_" + _u;
    var _vb2 = "__bob_vb2_" + _u;
    var _restore_wait = "__bob_restore_wait_" + _u;
    var _draw_wait = "__bob_draw_wait_" + _u;
    var _fail = "__bob_mem_fail_" + _u;
    var _s = _base.text + "\n";

    // A2 is the display allocation left by BITMAP_DISPLAY. Keep a pristine
    // Chip-RAM background in A4 and mask+five BOB planes in A3.
    _s += "\tMOVEA.L 4.W,A6\n\tMOVE.L #51200,D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A4\n\tMOVEA.L D0,A1\n";
    _s += "\tMOVEA.L A2,A0\n\tMOVE.W #12799,D0\n";
    _s += "__bob_bg_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__bob_bg_copy_" + _u + "\n";
    _s += "\tMOVE.L #1152,D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVEA.L D0,A1\n";
    _s += "\tLEA " + _bobdata + "(PC),A0\n\tMOVE.W #287,D0\n__bob_data_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__bob_data_copy_" + _u + "\n";
    _s += "\tMOVEA.L #14675968,A5\n\tMOVE.W #33728,150(A5)\n\tMOVEQ #0,D7\n";
    _s += _loop + ":\n";
    // One update per PAL frame.
    _s += _vb1 + ":\n\tCMPI.B #255,6(A5)\n\tBNE.S " + _vb1 + "\n" + _vb2 + ":\n\tCMPI.B #255,6(A5)\n\tBEQ.S " + _vb2 + "\n";
    // Restore the complete pristine bitmap (A -> D), ensuring no BOB trails.
    _s += _restore_wait + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _restore_wait + "\n";
    _s += "\tMOVE.W #2544,64(A5)\n\tCLR.W 66(A5)\n\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n";
    _s += "\tMOVE.L A4,80(A5)\n\tMOVE.L A2,84(A5)\n\tCLR.W 100(A5)\n\tCLR.W 102(A5)\n\tMOVE.W #16404,88(A5)\n";
    // Horizontal shift and screen word offset for the 32-pixel cookie-cut.
    _s += _draw_wait + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _draw_wait + "\n\tMOVE.W D7,D6\n\tANDI.W #15,D6\n\tLSL.W #8,D6\n\tLSL.W #4,D6\n\tMOVE.W D6,D5\n\tORI.W #4042,D5\n\tMOVE.W D5,64(A5)\n\tMOVE.W D6,66(A5)\n";
    _s += "\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n\tCLR.W 100(A5)\n\tCLR.W 98(A5)\n\tMOVE.W #34,96(A5)\n\tMOVE.W #34,102(A5)\n";
    _s += "\tMOVE.L A3,80(A5)\n\tMOVE.W D7,D4\n\tLSR.W #4,D4\n\tADD.W D4,D4\n\tMOVEA.L A2,A0\n\tADDA.L #4480,A0\n\tADDA.W D4,A0\n";
    for (var _p = 0; _p < 5; _p += 1) {
        _s += "\tMOVE.L A3,D0\n\tADD.L #" + string(192 + _p * 192) + ",D0\n\tMOVE.L D0,76(A5)\n";
        _s += "\tMOVE.L A0,72(A5)\n\tMOVE.L A0,84(A5)\n\tMOVE.W #2051,88(A5)\n";
        if (_p < 4) _s += "__bob_plane_wait_" + _u + "_" + string(_p) + ":\n\tBTST #6,2(A5)\n\tBNE.S __bob_plane_wait_" + _u + "_" + string(_p) + "\n\tADDA.L #10240,A0\n";
    }
    _s += "\tADDQ.W #1,D7\n\tCMPI.W #288,D7\n\tBLE.W " + _loop + "\n\tMOVEQ #0,D7\n\tBRA.W " + _loop + "\n";
    _s += _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _bobdata + ":\n";

    // 3 words per row. First plane is the transparency mask; remaining five
    // are the indexed BOB bits. Padding word makes every horizontal shift safe.
    for (var _plane = -1; _plane < 5; _plane += 1) {
        for (var _y = 0; _y < 32; _y += 1) {
            _s += "\tDC.W ";
            for (var _wc = 0; _wc < 3; _wc += 1) {
                var _word = 0;
                if (_wc < 2) for (var _bit = 0; _bit < 16; _bit += 1) {
                    var _pix = _bob.pixels[_y * 32 + _wc * 16 + _bit];
                    var _set = _plane < 0 ? (_pix != 0) : ((_pix & (1 << _plane)) != 0);
                    if (_set) _word |= 1 << (15 - _bit);
                }
                if (_wc > 0) _s += ",";
                _s += string(_word);
            }
            _s += "\n";
        }
    }
    return { text : _s, is_valid : true };
}

/// GetBitmap (BOB): establish the five-plane display. A4 is the rectangular
/// save-under buffer; A3 holds the mask plus five BOB image planes.
function scr_emit_macro_get_bitmap_bob(_node) {
    var _bob = scr_asset_find_by_name(_node.macro_asset_name);
    var _bitmap = scr_asset_find_by_name("TestBitmap");
    if (_bob == undefined || _bob.type != "BOB") return { text : "; ERROR: BOB asset not found", is_valid : false };
    if (_bitmap == undefined || _bitmap.type != "BITMAP") return { text : "; ERROR: TestBitmap not found", is_valid : false };
    var _saved = _node.macro_asset_name; _node.macro_asset_name = "TestBitmap";
    var _base = scr_emit_macro_bitmap_display(_node); _node.macro_asset_name = _saved;
    if (!_base.is_valid) return _base;
    var _u = string(floor(_node.uid));
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _state = "__bob_state_" + _id;
    var _data = "__getbob_data_" + _u;
    var _after = "__getbob_after_data_" + _u;
    var _fail = "__getbob_fail_" + _u;
    var _row_words = ceil(_bob.width / 16) + 1;
    // The shift padding word must still fit inside the 40-byte scanline.
    // Without this, the rightmost BOB position spills into the next row and,
    // near the bottom, into the following bitplane.
    var _safe_max_x = min(320 - _bob.width, ((20 - _row_words) * 16) + 15);
    var _plane_bytes = _row_words * 2 * _bob.height;
    var _save_bytes = _plane_bytes * 5;
    var _bob_bytes = _plane_bytes * 6;
    var _s = _base.text + "\n";
    // A4 is a save-under buffer for precisely the word-aligned rectangle
    // touched by this BOB, across all five screen planes.
    _s += "\tMOVEA.L 4.W,A6\n\tMOVE.L #" + string(_save_bytes) + ",D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A4\n";
    _s += "\tMOVE.L #" + string(_bob_bytes) + ",D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVEA.L A3,A1\n\tLEA " + _data + "(PC),A0\n\tMOVE.W #" + string((_bob_bytes div 4) - 1) + ",D0\n__getbob_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__getbob_copy_" + _u + "\n";
    _s += "\tMOVEA.L #14675968,A5\n\tMOVE.W #33728,150(A5)\n\tMOVE.L A4," + _state + "_save\n\tMOVE.L A3," + _state + "_data\n\tCLR.W " + _state + "_x\n\tMOVE.W #112," + _state + "_y\n\tBRA.W " + _after + "\n" + _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _data + ":\n";
    for (var _plane = -1; _plane < 5; _plane += 1) {
        for (var _y = 0; _y < _bob.height; _y += 1) {
            _s += "\tDC.W ";
            for (var _wc = 0; _wc < _row_words; _wc += 1) {
                var _word = 0;
                if ((_wc * 16) < _bob.width) for (var _bit = 0; _bit < 16; _bit += 1) {
                    var _pixel_x = _wc * 16 + _bit;
                    var _pix = _pixel_x < _bob.width ? _bob.pixels[_y * _bob.width + _pixel_x] : 0;
                    var _set = _plane < 0 ? (_pix != 0) : ((_pix & (1 << _plane)) != 0);
                    if (_set) _word |= 1 << (15 - _bit);
                }
                if (_wc > 0) _s += ",";
                _s += string(_word);
            }
            _s += "\n";
        }
    }
    _s += "\tEVEN\n" + _state + "_save:\tDC.L 0\n" + _state + "_data:\tDC.L 0\n";
    _s += _state + "_x:\tDC.W 0\n" + _state + "_y:\tDC.W 112\n";
    _s += _state + "_old_x:\tDC.W 0\n" + _state + "_old_y:\tDC.W 112\n";
    _s += _state + "_max_x:\tDC.W " + string(_safe_max_x) + "\n" + _state + "_max_y:\tDC.W " + string(256 - _bob.height) + "\n";
    _s += _after + ":";
    return { text : _s, is_valid : true };
}

/// ReplaceBitmap (BOB): wait for the next frame, then restore the full clean
/// image from A4 into displayed A2 before DrawBOB touches it.
function scr_emit_macro_replace_bitmap_bob(_node) {
    var _bob = scr_asset_find_by_name(_node.macro_asset_name);
    if (_bob == undefined || _bob.type != "BOB") return { text : "; ERROR: BOB asset not found", is_valid : false };
    var _u = string(floor(_node.uid));
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _state = "__bob_state_" + _id;
    var _vb1 = "__replace_vb1_" + _u;
    var _vb2 = "__replace_vb2_" + _u;
    var _wait = "__replace_wait_" + _u;
    var _done = "__replace_done_" + _u;
    var _row_words = ceil(_bob.width / 16) + 1;
    var _plane_bytes = _row_words * 2 * _bob.height;
    var _screen_modulo = 40 - (_row_words * 2);
    var _blit_size = (_bob.height << 6) | _row_words;
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += "\tMOVEA.L " + _state + "_save,A4\n\tMOVE.W " + _state + "_old_x,D3\n\tMOVE.W " + _state + "_old_y,D2\n";
    _s += _vb1 + ":\n\tCMPI.B #255,6(A5)\n\tBNE.S " + _vb1 + "\n" + _vb2 + ":\n\tCMPI.B #255,6(A5)\n\tBEQ.S " + _vb2 + "\n";
    _s += _wait + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _wait + "\n\tMOVE.W #2544,64(A5)\n\tCLR.W 66(A5)\n\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n\tCLR.W 100(A5)\n\tMOVE.W #" + string(_screen_modulo) + ",102(A5)\n";
    // D3 is the X used by the preceding DrawBOB. Restore the same aligned
    // word rectangle at Y=112, plane by plane, from A4 save-under memory.
    _s += "\tMOVE.W D3,D4\n\tLSR.W #4,D4\n\tADD.W D4,D4\n\tMOVEA.L A2,A0\n\tMOVE.W D2,D1\n\tMULU.W #40,D1\n\tADDA.L D1,A0\n\tADDA.W D4,A0\n";
    for (var _p = 0; _p < 5; _p += 1) {
        _s += "\tMOVE.L A4,D0\n";
        if (_p > 0) _s += "\tADD.L #" + string(_p * _plane_bytes) + ",D0\n";
        _s += "\tMOVE.L D0,80(A5)\n\tMOVE.L A0,84(A5)\n\tMOVE.W #" + string(_blit_size) + ",88(A5)\n";
        _s += "__replace_plane_wait_" + _u + "_" + string(_p) + ":\n\tBTST #6,2(A5)\n\tBNE.S __replace_plane_wait_" + _u + "_" + string(_p) + "\n";
        if (_p < 4) _s += "\tADDA.L #10240,A0\n";
    }
    _s += _done + ":";
    return { text : _s, is_valid : true };
}

/// DrawBOB (X,Y): D7 is X in the moving test; Y is 112. The BOB uses the
/// canonical $0FCA cookie-cut: D = (mask AND image) OR (!mask AND background).
function scr_emit_macro_draw_bob(_node) {
    var _bob = scr_asset_find_by_name(_node.macro_asset_name);
    if (_bob == undefined || _bob.type != "BOB") return { text : "; ERROR: BOB asset not found", is_valid : false };
    var _u = string(floor(_node.uid));
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _state = "__bob_state_" + _id;
    var _wait = "__drawbob_wait_" + _u;
    var _row_words = ceil(_bob.width / 16) + 1;
    var _plane_bytes = _row_words * 2 * _bob.height;
    var _screen_modulo = 40 - (_row_words * 2);
    var _blit_size = (_bob.height << 6) | _row_words;
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    // Preserve the position used for this draw. ReplaceBitmap must restore
    // this exact rectangle even after the live X coordinate changes.
    _s += "\tMOVEA.L " + _state + "_save,A4\n\tMOVEA.L " + _state + "_data,A3\n";
    _s += "\tMOVE.W " + _state + "_x,D7\n\tMOVE.W " + _state + "_y,D2\n";
    _s += "\tMOVE.W D7,D3\n\tMOVE.W D7," + _state + "_old_x\n\tMOVE.W D2," + _state + "_old_y\n";
    _s += _wait + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _wait + "\n\tMOVE.W D7,D4\n\tLSR.W #4,D4\n\tADD.W D4,D4\n\tMOVEA.L A2,A0\n\tMOVE.W D2,D1\n\tMULU.W #40,D1\n\tADDA.L D1,A0\n\tADDA.W D4,A0\n";
    // Grab the complete word-aligned rectangle that the shifted BOB can
    // touch. Five planes are stored consecutively in the A4 save-under.
    _s += "\tMOVE.W #2544,64(A5)\n\tCLR.W 66(A5)\n\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n\tMOVE.W #" + string(_screen_modulo) + ",100(A5)\n\tCLR.W 102(A5)\n";
    for (var _grab_plane = 0; _grab_plane < 5; _grab_plane += 1) {
        _s += "\tMOVE.L A4,D0\n";
        if (_grab_plane > 0) _s += "\tADD.L #" + string(_grab_plane * _plane_bytes) + ",D0\n";
        _s += "\tMOVE.L A0,80(A5)\n\tMOVE.L D0,84(A5)\n\tMOVE.W #" + string(_blit_size) + ",88(A5)\n";
        _s += "__grab_plane_wait_" + _u + "_" + string(_grab_plane) + ":\n\tBTST #6,2(A5)\n\tBNE.S __grab_plane_wait_" + _u + "_" + string(_grab_plane) + "\n";
        if (_grab_plane < 4) _s += "\tADDA.L #10240,A0\n";
    }
    // Return A0 to plane zero and perform the masked cookie-cut draw.
    _s += "\tSUBA.L #40960,A0\n\tMOVE.W D7,D6\n\tANDI.W #15,D6\n\tLSL.W #8,D6\n\tLSL.W #4,D6\n\tMOVE.W D6,D5\n\tORI.W #4042,D5\n\tMOVE.W D5,64(A5)\n\tMOVE.W D6,66(A5)\n\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n\tCLR.W 100(A5)\n\tCLR.W 98(A5)\n\tMOVE.W #" + string(_screen_modulo) + ",96(A5)\n\tMOVE.W #" + string(_screen_modulo) + ",102(A5)\n\tMOVE.L A3,80(A5)\n";
    for (var _p = 0; _p < 5; _p += 1) {
        // The Blitter advances BLTAPT. Reload the original mask for every
        // bitplane; otherwise plane data becomes the next plane's mask and
        // produces the black rectangular clobber seen in the first version.
        _s += "\tMOVE.L A3,80(A5)\n\tMOVE.L A3,D0\n\tADD.L #" + string(_plane_bytes + _p * _plane_bytes) + ",D0\n\tMOVE.L D0,76(A5)\n\tMOVE.L A0,72(A5)\n\tMOVE.L A0,84(A5)\n\tMOVE.W #" + string(_blit_size) + ",88(A5)\n";
        _s += "__drawbob_plane_wait_" + _u + "_" + string(_p) + ":\n\tBTST #6,2(A5)\n\tBNE.S __drawbob_plane_wait_" + _u + "_" + string(_p) + "\n";
        if (_p < 4) _s += "\tADDA.L #10240,A0\n";
    }
    return { text : _s, is_valid : true };
}

/// MOVE_BOB: update one of the 64 independent BOB positions using signed
/// literal speeds. Crossing an edge wraps to the opposite edge.
function scr_emit_macro_move_bob(_node) {
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _sx = clamp(floor(_node.macro_speed_x), -16, 16);
    var _sy = clamp(floor(_node.macro_speed_y), -16, 16);
    var _state = "__bob_state_" + _id;
    var _u = string(floor(_node.uid));
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += "\tMOVE.W " + _state + "_x,D0\n\tADD.W #" + string(_sx) + ",D0\n";
    _s += "\tBPL.S __movebob_x_nonneg_" + _u + "\n\tMOVE.W " + _state + "_max_x,D0\n__movebob_x_nonneg_" + _u + ":\n\tCMP.W " + _state + "_max_x,D0\n\tBLE.S __movebob_x_ok_" + _u + "\n\tCLR.W D0\n__movebob_x_ok_" + _u + ":\n\tMOVE.W D0," + _state + "_x\n";
    _s += "\tMOVE.W " + _state + "_y,D0\n\tADD.W #" + string(_sy) + ",D0\n";
    _s += "\tBPL.S __movebob_y_nonneg_" + _u + "\n\tMOVE.W " + _state + "_max_y,D0\n__movebob_y_nonneg_" + _u + ":\n\tCMP.W " + _state + "_max_y,D0\n\tBLE.S __movebob_y_ok_" + _u + "\n\tCLR.W D0\n__movebob_y_ok_" + _u + ":\n\tMOVE.W D0," + _state + "_y";
    return { text : _s, is_valid : true };
}

/// Five-bitplane bitmap plus a genuine hardware sprite whose POS/CTL words
/// are changed once per video frame. Its colours come from the bitmap palette.
function scr_emit_macro_sprite_bitmap_test(_node) {
    var _sprite = scr_asset_find_by_name(_node.macro_asset_name);
    var _bitmap = scr_asset_find_by_name("TestBitmap");
    if (_sprite == undefined || _sprite.type != "SPRITE") return { text : "; ERROR: TestSprite not found", is_valid : false };
    if (_bitmap == undefined || _bitmap.type != "BITMAP") return { text : "; ERROR: TestBitmap not found", is_valid : false };
    var _saved = _node.macro_asset_name; _node.macro_asset_name = "TestBitmap";
    var _base = scr_emit_macro_bitmap_display(_node); _node.macro_asset_name = _saved;
    if (!_base.is_valid) return _base;
    var _u = string(floor(_node.uid));
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _state = "__spr_state_" + _id;
    var _data = "__sprbmp_data_" + _u;
    var _after = "__sprbmp_after_" + _u;
    var _fail = "__sprbmp_fail_" + _u;
    var _height = clamp(_sprite.height, 1, 64);
    var _bytes = 4 + _height * 4 + 4;
    var _s = _base.text + "\n\tMOVEA.L 4.W,A6\n\tMOVE.L #" + string(_bytes) + ",D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVEA.L D0,A1\n\tLEA " + _data + "(PC),A0\n";
    _s += "\tMOVE.W #" + string((_bytes div 4) - 1) + ",D0\n__sprbmp_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__sprbmp_copy_" + _u + "\n";
    var _sprptr = 14675968 + 288 + clamp(_sprite.channel, 0, 7) * 4;
    _s += "\tMOVE.L A3," + string(_sprptr) + ".L\n\tMOVE.W #33760,14676118.L\n\tMOVEA.L #14675968,A5\n";
    _s += "\tMOVE.L A3," + _state + "_ptr\n\tCLR.W " + _state + "_x\n\tCLR.W " + _state + "_y\n\tBRA.W " + _after + "\n" + _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _data + ":\n";
    _s += "\tDC.W 32768,0\n";
    for (var _y = 0; _y < _height; _y += 1) {
        var _a = 0, _b = 0;
        for (var _x = 0; _x < 16; _x += 1) {
            var _pix = _sprite.pixels[_y * 16 + _x];
            if ((_pix & 1) != 0) _a |= 1 << (15 - _x);
            if ((_pix & 2) != 0) _b |= 1 << (15 - _x);
        }
        _s += "\tDC.W " + string(_a) + "," + string(_b) + "\n";
    }
    _s += "\tDC.W 0,0\n";
    _s += "\tEVEN\n" + _state + "_ptr:\tDC.L 0\n" + _state + "_x:\tDC.W 0\n" + _state + "_y:\tDC.W 0\n";
    _s += _state + "_max_x:\tDC.W 304\n" + _state + "_max_y:\tDC.W " + string(256 - _height) + "\n";
    _s += _state + "_height:\tDC.W " + string(_height) + "\n" + _state + "_ptrreg:\tDC.L " + string(_sprptr) + "\n" + _after + ":";
    return { text : _s, is_valid : true };
}

/// MOVE_SPR: draw and advance one of 64 hardware-sprite state slots.
function scr_emit_macro_move_spr(_node) {
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _sx = clamp(floor(_node.macro_speed_x), -16, 16);
    var _sy = clamp(floor(_node.macro_speed_y), -16, 16);
    var _state = "__spr_state_" + _id;
    var _u = string(floor(_node.uid));
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += "__movespr_vb1_" + _u + ":\n\tCMPI.B #255,6(A5)\n\tBNE.S __movespr_vb1_" + _u + "\n__movespr_vb2_" + _u + ":\n\tCMPI.B #255,6(A5)\n\tBEQ.S __movespr_vb2_" + _u + "\n";
    _s += "\tMOVEA.L " + _state + "_ptr,A3\n\tMOVEA.L " + _state + "_ptrreg,A0\n\tMOVE.L A3,(A0)\n";
    _s += "\tMOVE.W " + _state + "_x,D0\n\tADDI.W #128,D0\n\tMOVE.W D0,D4\n\tLSR.W #1,D4\n\tANDI.W #255,D4\n";
    _s += "\tMOVE.W " + _state + "_y,D2\n\tADDI.W #128,D2\n\tMOVE.W D2,D1\n\tANDI.W #255,D1\n\tLSL.W #8,D1\n\tOR.W D4,D1\n\tMOVE.W D1,(A3)\n";
    _s += "\tMOVE.W D2,D3\n\tADD.W " + _state + "_height,D3\n\tMOVE.W D3,D5\n\tANDI.W #255,D5\n\tLSL.W #8,D5\n\tANDI.W #1,D0\n\tOR.W D0,D5\n\tBTST #8,D2\n\tBEQ.S __movespr_no_vs_hi_" + _u + "\n\tORI.W #4,D5\n__movespr_no_vs_hi_" + _u + ":\n\tBTST #8,D3\n\tBEQ.S __movespr_no_ve_hi_" + _u + "\n\tORI.W #2,D5\n__movespr_no_ve_hi_" + _u + ":\n\tMOVE.W D5,2(A3)\n";
    _s += "\tMOVE.W " + _state + "_x,D0\n\tADD.W #" + string(_sx) + ",D0\n\tBPL.S __movespr_x_nonneg_" + _u + "\n\tMOVE.W " + _state + "_max_x,D0\n__movespr_x_nonneg_" + _u + ":\n\tCMP.W " + _state + "_max_x,D0\n\tBLE.S __movespr_x_ok_" + _u + "\n\tCLR.W D0\n__movespr_x_ok_" + _u + ":\n\tMOVE.W D0," + _state + "_x\n";
    _s += "\tMOVE.W " + _state + "_y,D0\n\tADD.W #" + string(_sy) + ",D0\n\tBPL.S __movespr_y_nonneg_" + _u + "\n\tMOVE.W " + _state + "_max_y,D0\n__movespr_y_nonneg_" + _u + ":\n\tCMP.W " + _state + "_max_y,D0\n\tBLE.S __movespr_y_ok_" + _u + "\n\tCLR.W D0\n__movespr_y_ok_" + _u + ":\n\tMOVE.W D0," + _state + "_y";
    return { text : _s, is_valid : true };
}

/// ANIM_BOB: lazily copies the selected BOB-frame range into Chip RAM, then
/// advances the chosen runtime slot using a PAL 50 Hz fractional accumulator.
function scr_emit_macro_anim_bob(_node) {
    var _frames = [];
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == "BOB") array_push(_frames, global.asset_list[_i]);
        _i += 1;
    }
    if (array_length(_frames) == 0) return { text : "; ERROR: ANIM_BOB has no BOB frames", is_valid : false };
    var _start = clamp(floor(_node.macro_anim_start), 0, array_length(_frames) - 1);
    var _end = clamp(floor(_node.macro_anim_end), _start, array_length(_frames) - 1);
    var _first = _frames[_start];
    var _f = _start;
    while (_f <= _end) {
        if (_frames[_f].width != _first.width || _frames[_f].height != _first.height)
            return { text : "; ERROR: ANIM_BOB frames must share width and height", is_valid : false };
        _f += 1;
    }
    var _row_words = ceil(_first.width / 16) + 1;
    var _plane_bytes = _row_words * 2 * _first.height;
    var _frame_bytes = _plane_bytes * 6;
    var _frame_count = _end - _start + 1;
    var _total_bytes = _frame_bytes * _frame_count;
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _u = string(floor(_node.uid));
    var _state = "__bob_state_" + _id;
    var _anim = "__anim_bob_" + _id;
    var _data = "__anim_bob_data_" + _u;
    var _ready = "__anim_bob_ready_" + _u;
    var _frame_ok = "__anim_bob_frame_ok_" + _u;
    var _done = "__anim_bob_done_" + _u;
    var _after = "__anim_bob_after_" + _u;
    var _fail = "__anim_bob_fail_" + _u;
    var _rate = clamp(floor(_node.macro_anim_rate), 1, 50);
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += "\tTST.L " + _anim + "_bank\n\tBNE.W " + _ready + "\n\tMOVEA.L 4.W,A6\n\tMOVE.L #" + string(_total_bytes) + ",D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVE.L A3," + _anim + "_bank\n\tMOVE.L A3," + _state + "_data\n\tMOVEA.L A3,A1\n\tLEA " + _data + "(PC),A0\n\tMOVE.W #" + string((_total_bytes div 4) - 1) + ",D0\n__anim_bob_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__anim_bob_copy_" + _u + "\n\tCLR.W " + _anim + "_frame\n\tCLR.W " + _anim + "_acc\n";
    _s += _ready + ":\n\tADDI.W #" + string(_rate) + "," + _anim + "_acc\n\tCMPI.W #50," + _anim + "_acc\n\tBLT.W " + _done + "\n\tSUBI.W #50," + _anim + "_acc\n\tADDQ.W #1," + _anim + "_frame\n\tCMPI.W #" + string(_frame_count) + "," + _anim + "_frame\n\tBLT.S " + _frame_ok + "\n";
    if (_node.macro_anim_loop) _s += "\tCLR.W " + _anim + "_frame\n";
    else _s += "\tMOVE.W #" + string(_frame_count - 1) + "," + _anim + "_frame\n";
    _s += _frame_ok + ":\n\tMOVE.W " + _anim + "_frame,D0\n\tMULU.W #" + string(_frame_bytes) + ",D0\n\tMOVEA.L " + _anim + "_bank,A3\n\tADDA.L D0,A3\n\tMOVE.L A3," + _state + "_data\n" + _done + ":\n\tJMP " + _after + "\n" + _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _data + ":\n";
    _f = _start;
    while (_f <= _end) {
        var _bob = _frames[_f];
        for (var _plane = -1; _plane < 5; _plane += 1) {
            for (var _y = 0; _y < _bob.height; _y += 1) {
                _s += "\tDC.W ";
                for (var _wc = 0; _wc < _row_words; _wc += 1) {
                    var _word = 0;
                    if ((_wc * 16) < _bob.width) for (var _bit = 0; _bit < 16; _bit += 1) {
                        var _px = _wc * 16 + _bit;
                        var _pix = _px < _bob.width ? _bob.pixels[_y * _bob.width + _px] : 0;
                        var _set = _plane < 0 ? (_pix != 0) : ((_pix & (1 << _plane)) != 0);
                        if (_set) _word |= 1 << (15 - _bit);
                    }
                    if (_wc > 0) _s += ",";
                    _s += string(_word);
                }
                _s += "\n";
            }
        }
        _f += 1;
    }
    _s += "\tEVEN\n" + _anim + "_bank:\tDC.L 0\n" + _anim + "_frame:\tDC.W 0\n" + _anim + "_acc:\tDC.W 0\n" + _after + ":";
    return { text : _s, is_valid : true };
}

/// ANIM_SPR: the hardware-sprite equivalent of ANIM_BOB. Every selected
/// frame must have the same height so MOVE_SPR can share one control layout.
function scr_emit_macro_anim_spr(_node) {
    var _frames = [];
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == "SPRITE") array_push(_frames, global.asset_list[_i]);
        _i += 1;
    }
    if (array_length(_frames) == 0) return { text : "; ERROR: ANIM_SPR has no sprite frames", is_valid : false };
    var _start = clamp(floor(_node.macro_anim_start), 0, array_length(_frames) - 1);
    var _end = clamp(floor(_node.macro_anim_end), _start, array_length(_frames) - 1);
    var _height = clamp(_frames[_start].height, 1, 64);
    var _f = _start;
    while (_f <= _end) {
        if (_frames[_f].height != _height) return { text : "; ERROR: ANIM_SPR frames must share height", is_valid : false };
        _f += 1;
    }
    var _frame_bytes = 4 + _height * 4 + 4;
    var _frame_count = _end - _start + 1;
    var _total_bytes = _frame_bytes * _frame_count;
    var _id = string(clamp(floor(_node.macro_object_id), 0, 63));
    var _u = string(floor(_node.uid));
    var _state = "__spr_state_" + _id;
    var _anim = "__anim_spr_" + _id;
    var _data = "__anim_spr_data_" + _u;
    var _ready = "__anim_spr_ready_" + _u;
    var _frame_ok = "__anim_spr_frame_ok_" + _u;
    var _done = "__anim_spr_done_" + _u;
    var _after = "__anim_spr_after_" + _u;
    var _fail = "__anim_spr_fail_" + _u;
    var _rate = clamp(floor(_node.macro_anim_rate), 1, 50);
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += "\tTST.L " + _anim + "_bank\n\tBNE.W " + _ready + "\n\tMOVEA.L 4.W,A6\n\tMOVE.L #" + string(_total_bytes) + ",D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVE.L A3," + _anim + "_bank\n\tMOVE.L A3," + _state + "_ptr\n\tMOVEA.L A3,A1\n\tLEA " + _data + "(PC),A0\n\tMOVE.W #" + string((_total_bytes div 4) - 1) + ",D0\n__anim_spr_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__anim_spr_copy_" + _u + "\n\tCLR.W " + _anim + "_frame\n\tCLR.W " + _anim + "_acc\n";
    _s += _ready + ":\n\tADDI.W #" + string(_rate) + "," + _anim + "_acc\n\tCMPI.W #50," + _anim + "_acc\n\tBLT.W " + _done + "\n\tSUBI.W #50," + _anim + "_acc\n\tADDQ.W #1," + _anim + "_frame\n\tCMPI.W #" + string(_frame_count) + "," + _anim + "_frame\n\tBLT.S " + _frame_ok + "\n";
    if (_node.macro_anim_loop) _s += "\tCLR.W " + _anim + "_frame\n";
    else _s += "\tMOVE.W #" + string(_frame_count - 1) + "," + _anim + "_frame\n";
    _s += _frame_ok + ":\n\tMOVE.W " + _anim + "_frame,D0\n\tMULU.W #" + string(_frame_bytes) + ",D0\n\tMOVEA.L " + _anim + "_bank,A3\n\tADDA.L D0,A3\n\tMOVE.L A3," + _state + "_ptr\n" + _done + ":\n\tJMP " + _after + "\n" + _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _data + ":\n";
    _f = _start;
    while (_f <= _end) {
        var _sprite = _frames[_f];
        _s += "\tDC.W 32768,0\n";
        for (var _y = 0; _y < _height; _y += 1) {
            var _a = 0, _b = 0;
            for (var _x = 0; _x < 16; _x += 1) {
                var _pix = _sprite.pixels[_y * 16 + _x];
                if ((_pix & 1) != 0) _a |= 1 << (15 - _x);
                if ((_pix & 2) != 0) _b |= 1 << (15 - _x);
            }
            _s += "\tDC.W " + string(_a) + "," + string(_b) + "\n";
        }
        _s += "\tDC.W 0,0\n";
        _f += 1;
    }
    _s += "\tEVEN\n" + _anim + "_bank:\tDC.L 0\n" + _anim + "_frame:\tDC.W 0\n" + _anim + "_acc:\tDC.W 0\n" + _after + ":";
    return { text : _s, is_valid : true };
}
