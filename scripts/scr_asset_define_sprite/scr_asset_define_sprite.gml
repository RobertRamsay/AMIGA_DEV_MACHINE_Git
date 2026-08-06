/// @desc scr_asset_define_sprite(_name, _channel, _height, _address, _pixels, _colour_r, _colour_g, _colour_b)
/// Stores a hardware sprite asset under _name in global.asset_list — the
/// data a SPRITE_DISPLAY macro node looks up by name at build time.
/// _pixels is a flat array of 16*height entries, each 0-3 (0=transparent).
/// _colour_r/g/b are 3-entry arrays (0-15 per channel) for colour indices
/// 1/2/3. The pixel array is copied explicitly, not referenced — otherwise
/// this asset would keep changing every time the editor is touched again.
function scr_asset_define_sprite(_name, _channel, _height, _address, _pixels, _colour_r, _colour_g, _colour_b) {
    var _pixel_count = 16 * _height;
    var _pixels_copy = array_create(_pixel_count, 0);
    array_copy(_pixels_copy, 0, _pixels, 0, _pixel_count);

    var _colour_r_copy = [_colour_r[0], _colour_r[1], _colour_r[2]];
    var _colour_g_copy = [_colour_g[0], _colour_g[1], _colour_g[2]];
    var _colour_b_copy = [_colour_b[0], _colour_b[1], _colour_b[2]];

    var _asset_data = {
        name : _name,
        type : "SPRITE",
        channel : _channel,
        height : _height,
        address : _address,
        pixels : _pixels_copy,
        colour_r : _colour_r_copy,
        colour_g : _colour_g_copy,
        colour_b : _colour_b_copy
    };

    var _existing_index = -1;
    var _count = array_length(global.asset_list);
    var _idx = 0;

    while (_idx < _count) {
        if (global.asset_list[_idx].name == _name) {
            _existing_index = _idx;
        }

        _idx += 1;
    }

    if (_existing_index != -1) {
        global.asset_list[_existing_index] = _asset_data;
    } else {
        array_push(global.asset_list, _asset_data);
    }
}
