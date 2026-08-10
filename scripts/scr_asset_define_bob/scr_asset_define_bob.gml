/// @desc scr_asset_define_bob(_name, _width, _height, _pixels)
/// Stores a masked blitter object. Pixel index 0 is transparent; indices
/// 1-31 are interpreted through the current TestBitmap palette.
function scr_asset_define_bob(_name, _width, _height, _pixels) {
    var _pixel_count = _width * _height;
    var _pixels_copy = array_create(_pixel_count, 0);
    array_copy(_pixels_copy, 0, _pixels, 0, _pixel_count);

    var _asset_data = {
        name : _name,
        type : "BOB",
        width : _width,
        height : _height,
        depth : 5,
        transparent_index : 0,
        pixels : _pixels_copy
    };

    var _existing_index = -1;
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].name == _name) _existing_index = _i;
        _i += 1;
    }

    if (_existing_index == -1) array_push(global.asset_list, _asset_data);
    else global.asset_list[_existing_index] = _asset_data;
}
