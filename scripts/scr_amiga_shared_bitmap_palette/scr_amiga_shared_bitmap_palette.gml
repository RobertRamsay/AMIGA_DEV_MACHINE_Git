/// Returns copies of the current bitmap palette, creating a blank TestBitmap
/// with the standard 12-bit palette when no bitmap has been edited yet.
function scr_amiga_get_shared_bitmap_palette() {
    var _bitmap = scr_asset_find_by_name("TestBitmap");

    if (_bitmap == undefined || _bitmap.type != "BITMAP") {
        var _defaults = [
            $000, $FFF, $F00, $0F0, $00F, $FF0, $0FF, $F0F,
            $888, $444, $800, $080, $008, $880, $088, $808,
            $F88, $8F8, $88F, $FC8, $8FC, $C8F, $F80, $0F8,
            $08F, $80F, $F08, $8F0, $0CF, $C0F, $FC0, $CCC
        ];
        var _r = array_create(32, 0);
        var _g = array_create(32, 0);
        var _b = array_create(32, 0);
        var _i = 0;
        while (_i < 32) {
            _r[_i] = (_defaults[_i] >> 8) & 15;
            _g[_i] = (_defaults[_i] >> 4) & 15;
            _b[_i] = _defaults[_i] & 15;
            _i += 1;
        }
        scr_asset_define_bitmap("TestBitmap", array_create(320 * 256, 0), _r, _g, _b);
        _bitmap = scr_asset_find_by_name("TestBitmap");
    }

    var _out_r = array_create(32, 0);
    var _out_g = array_create(32, 0);
    var _out_b = array_create(32, 0);
    array_copy(_out_r, 0, _bitmap.colour_r, 0, 32);
    array_copy(_out_g, 0, _bitmap.colour_g, 0, 32);
    array_copy(_out_b, 0, _bitmap.colour_b, 0, 32);
    return { colour_r : _out_r, colour_g : _out_g, colour_b : _out_b };
}

/// Writes palette edits back into the bitmap asset. BOBs deliberately do not
/// own a separate palette, so reopening either editor sees the same registers.
function scr_amiga_commit_shared_bitmap_palette(_r, _g, _b) {
    var _bitmap = scr_asset_find_by_name("TestBitmap");
    if (_bitmap == undefined || _bitmap.type != "BITMAP") {
        scr_asset_define_bitmap("TestBitmap", array_create(320 * 256, 0), _r, _g, _b);
    } else {
        array_copy(_bitmap.colour_r, 0, _r, 0, 32);
        array_copy(_bitmap.colour_g, 0, _g, 0, 32);
        array_copy(_bitmap.colour_b, 0, _b, 0, 32);
    }
    global.workspace_dirty = true;
}
