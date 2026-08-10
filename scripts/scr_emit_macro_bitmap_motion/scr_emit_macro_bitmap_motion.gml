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

/// GetBitmap (BOB): establish the five-plane display and make two genuinely
/// independent Chip-RAM buffers: A2 is displayed, A4 is never displayed and
/// remains the pristine restore source. A3 holds the mask + five BOB planes.
function scr_emit_macro_get_bitmap_bob(_node) {
    var _bob = scr_asset_find_by_name(_node.macro_asset_name);
    var _bitmap = scr_asset_find_by_name("TestBitmap");
    if (_bob == undefined || _bob.type != "BOB" || _bob.width != 32 || _bob.height != 32) return { text : "; ERROR: BOB asset must be 32x32", is_valid : false };
    if (_bitmap == undefined || _bitmap.type != "BITMAP") return { text : "; ERROR: TestBitmap not found", is_valid : false };
    var _saved = _node.macro_asset_name; _node.macro_asset_name = "TestBitmap";
    var _base = scr_emit_macro_bitmap_display(_node); _node.macro_asset_name = _saved;
    if (!_base.is_valid) return _base;
    var _u = string(floor(_node.uid));
    var _data = "__getbob_data_" + _u;
    var _after = "__getbob_after_data_" + _u;
    var _fail = "__getbob_fail_" + _u;
    var _s = _base.text + "\n";
    _s += "\tMOVEA.L 4.W,A6\n\tMOVE.L #51200,D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A4\n";
    // Copy the editor bitmap into the pristine buffer directly from embedded
    // program data, not from the live display buffer.
    _s += "\tMOVEA.L A4,A1\n\tLEA __bitmap_data_" + _u + ",A0\n\tMOVE.W #12799,D0\n__getbob_bgcopy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__getbob_bgcopy_" + _u + "\n";
    _s += "\tMOVE.L #1152,D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVEA.L A3,A1\n\tLEA " + _data + "(PC),A0\n\tMOVE.W #287,D0\n__getbob_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__getbob_copy_" + _u + "\n";
    _s += "\tMOVEA.L #14675968,A5\n\tMOVE.W #33728,150(A5)\n\tMOVEQ #0,D7\n\tBRA.W " + _after + "\n" + _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _data + ":\n";
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
    _s += _after + ":";
    return { text : _s, is_valid : true };
}

/// ReplaceBitmap (BOB): wait for the next frame, then restore the full clean
/// image from A4 into displayed A2 before DrawBOB touches it.
function scr_emit_macro_replace_bitmap_bob(_node) {
    var _u = string(floor(_node.uid));
    var _vb1 = "__replace_vb1_" + _u;
    var _vb2 = "__replace_vb2_" + _u;
    var _wait = "__replace_wait_" + _u;
    var _done = "__replace_done_" + _u;
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += _vb1 + ":\n\tCMPI.B #255,6(A5)\n\tBNE.S " + _vb1 + "\n" + _vb2 + ":\n\tCMPI.B #255,6(A5)\n\tBEQ.S " + _vb2 + "\n";
    _s += _wait + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _wait + "\n\tMOVE.W #2544,64(A5)\n\tCLR.W 66(A5)\n\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n\tMOVE.L A4,80(A5)\n\tMOVE.L A2,84(A5)\n\tCLR.W 100(A5)\n\tCLR.W 102(A5)\n\tMOVE.W #16404,88(A5)\n";
    _s += _done + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _done;
    return { text : _s, is_valid : true };
}

/// DrawBOB (X,Y): D7 is X in the moving test; Y is 112. The BOB uses the
/// canonical $0FCA cookie-cut: D = (mask AND image) OR (!mask AND background).
function scr_emit_macro_draw_bob(_node) {
    var _u = string(floor(_node.uid));
    var _wait = "__drawbob_wait_" + _u;
    var _s = _node.node_label != "" ? _node.node_label + ":\n" : "";
    _s += _wait + ":\n\tBTST #6,2(A5)\n\tBNE.S " + _wait + "\n\tMOVE.W D7,D6\n\tANDI.W #15,D6\n\tLSL.W #8,D6\n\tLSL.W #4,D6\n\tMOVE.W D6,D5\n\tORI.W #4042,D5\n\tMOVE.W D5,64(A5)\n\tMOVE.W D6,66(A5)\n\tMOVE.W #65535,68(A5)\n\tMOVE.W #65535,70(A5)\n\tCLR.W 100(A5)\n\tCLR.W 98(A5)\n\tMOVE.W #34,96(A5)\n\tMOVE.W #34,102(A5)\n\tMOVE.L A3,80(A5)\n\tMOVE.W D7,D4\n\tLSR.W #4,D4\n\tADD.W D4,D4\n\tMOVEA.L A2,A0\n\tADDA.L #4480,A0\n\tADDA.W D4,A0\n";
    for (var _p = 0; _p < 5; _p += 1) {
        _s += "\tMOVE.L A3,D0\n\tADD.L #" + string(192 + _p * 192) + ",D0\n\tMOVE.L D0,76(A5)\n\tMOVE.L A0,72(A5)\n\tMOVE.L A0,84(A5)\n\tMOVE.W #2051,88(A5)\n";
        _s += "__drawbob_plane_wait_" + _u + "_" + string(_p) + ":\n\tBTST #6,2(A5)\n\tBNE.S __drawbob_plane_wait_" + _u + "_" + string(_p) + "\n";
        if (_p < 4) _s += "\tADDA.L #10240,A0\n";
    }
    _s += "\tADDQ.W #1,D7\n\tCMPI.W #288,D7\n\tBLE.S __drawbob_x_ok_" + _u + "\n\tMOVEQ #0,D7\n__drawbob_x_ok_" + _u + ":";
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
    var _data = "__sprbmp_data_" + _u;
    var _loop = "__sprbmp_frame_" + _u;
    var _fail = "__sprbmp_fail_" + _u;
    var _height = clamp(_sprite.height, 1, 64);
    var _bytes = 4 + _height * 4 + 4;
    var _s = _base.text + "\n\tMOVEA.L 4.W,A6\n\tMOVE.L #" + string(_bytes) + ",D0\n\tMOVE.L #65538,D1\n\tJSR -198(A6)\n\tTST.L D0\n\tBEQ.W " + _fail + "\n\tMOVEA.L D0,A3\n\tMOVEA.L D0,A1\n\tLEA " + _data + "(PC),A0\n";
    _s += "\tMOVE.W #" + string((_bytes div 4) - 1) + ",D0\n__sprbmp_copy_" + _u + ":\n\tMOVE.L (A0)+,(A1)+\n\tDBRA D0,__sprbmp_copy_" + _u + "\n";
    var _sprptr = 14675968 + 288 + clamp(_sprite.channel, 0, 7) * 4;
    _s += "\tMOVE.L A3," + string(_sprptr) + ".L\n\tMOVE.W #33760,14676118.L\n\tMOVEQ #0,D7\n\tMOVEA.L #14675968,A5\n" + _loop + ":\n";
    _s += "__sprbmp_vb1_" + _u + ":\n\tCMPI.B #255,6(A5)\n\tBNE.S __sprbmp_vb1_" + _u + "\n__sprbmp_vb2_" + _u + ":\n\tCMPI.B #255,6(A5)\n\tBEQ.S __sprbmp_vb2_" + _u + "\n";
    // PAL display origin is hardware x=128. POS stores x/2 and CTL bit0 x LSB.
    _s += "\tMOVE.L A3," + string(_sprptr) + ".L\n\tMOVE.W D7,D0\n\tADDI.W #128,D0\n\tMOVE.W D0,D1\n\tLSR.W #1,D1\n\tANDI.W #255,D1\n\tORI.W #32768,D1\n\tMOVE.W D1,(A3)\n\tANDI.W #1,D0\n\tORI.W #" + string((128 + _height) * 256) + ",D0\n\tMOVE.W D0,2(A3)\n\tADDQ.W #1,D7\n\tCMPI.W #304,D7\n\tBLE.W " + _loop + "\n\tMOVEQ #0,D7\n\tBRA.W " + _loop + "\n" + _fail + ":\n\tBRA.W " + _fail + "\n\tEVEN\n" + _data + ":\n";
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
    return { text : _s, is_valid : true };
}
