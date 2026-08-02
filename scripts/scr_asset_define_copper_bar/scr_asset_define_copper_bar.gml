/// @desc scr_asset_define_copper_bar(_name, _sky_band_count, _sky_vp_start, _sky_vp_end, _sky_r_start, _sky_g_start, _sky_b_start, _sky_r_end, _sky_g_end, _sky_b_end, _water_band_count, _water_vp_start, _water_vp_end, _water_r_start, _water_g_start, _water_b_start, _water_r_end, _water_g_end, _water_b_end)
/// Computes a two-half (sky/water) colour gradient as a list of {vp, colour}
/// bands and stores it under _name in global.asset_list — the byte/word
/// data a COPPER_BAR macro node looks up by name at build time. Re-defining
/// an existing name replaces it in place.
function scr_asset_define_copper_bar(_name, _sky_band_count, _sky_vp_start, _sky_vp_end, _sky_r_start, _sky_g_start, _sky_b_start, _sky_r_end, _sky_g_end, _sky_b_end, _water_band_count, _water_vp_start, _water_vp_end, _water_r_start, _water_g_start, _water_b_start, _water_r_end, _water_g_end, _water_b_end) {
    var _bands = [];
    var _i = 0;

    while (_i < _sky_band_count) {
        var _t = _i / (_sky_band_count - 1);
        var _vp = floor(_sky_vp_start + (_sky_vp_end - _sky_vp_start) * _t);
        var _r = floor(_sky_r_start + (_sky_r_end - _sky_r_start) * _t);
        var _g = floor(_sky_g_start + (_sky_g_end - _sky_g_start) * _t);
        var _b = floor(_sky_b_start + (_sky_b_end - _sky_b_start) * _t);
        var _colour = (_r * 256) + (_g * 16) + _b;

        array_push(_bands, { vp : _vp, colour : _colour });
        _i += 1;
    }

    _i = 0;

    while (_i < _water_band_count) {
        var _t = _i / (_water_band_count - 1);
        var _vp = floor(_water_vp_start + (_water_vp_end - _water_vp_start) * _t);
        var _r = floor(_water_r_start + (_water_r_end - _water_r_start) * _t);
        var _g = floor(_water_g_start + (_water_g_end - _water_g_start) * _t);
        var _b = floor(_water_b_start + (_water_b_end - _water_b_start) * _t);
        var _colour = (_r * 256) + (_g * 16) + _b;

        array_push(_bands, { vp : _vp, colour : _colour });
        _i += 1;
    }

    var _asset_data = { name : _name, type : "COPPER_BAR", bands : _bands };

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
