/// @desc scr_asset_define_bitmap(_name, _pixels, _colour_r, _colour_g, _colour_b)
/// Stores a native 320x256, 32-colour bitmap asset. Pixel values are chunky
/// editor indices 0-31; the future payload writer converts them to 5 planes.
function scr_asset_define_bitmap(_name, _pixels, _colour_r, _colour_g, _colour_b) {
    var _pixels_copy = array_create(320 * 256, 0);
    array_copy(_pixels_copy, 0, _pixels, 0, 320 * 256);

    var _r_copy = array_create(32, 0);
    var _g_copy = array_create(32, 0);
    var _b_copy = array_create(32, 0);
    array_copy(_r_copy, 0, _colour_r, 0, 32);
    array_copy(_g_copy, 0, _colour_g, 0, 32);
    array_copy(_b_copy, 0, _colour_b, 0, 32);

    var _asset_data = {
        name : _name,
        type : "BITMAP",
        width : 320,
        height : 256,
        depth : 5,
        pixels : _pixels_copy,
        colour_r : _r_copy,
        colour_g : _g_copy,
        colour_b : _b_copy
    };

    var _existing_index = -1;
    var _asset_index = 0;

    while (_asset_index < array_length(global.asset_list)) {
        if (global.asset_list[_asset_index].name == _name) _existing_index = _asset_index;
        _asset_index += 1;
    }

    if (_existing_index == -1) {
        array_push(global.asset_list, _asset_data);
    } else {
        global.asset_list[_existing_index] = _asset_data;
    }
}
