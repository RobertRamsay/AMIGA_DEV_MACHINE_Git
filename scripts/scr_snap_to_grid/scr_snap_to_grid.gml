/// @desc scr_snap_to_grid(_value, _grid_size)
function scr_snap_to_grid(_value, _grid_size) {
    var _snapped = round(_value / _grid_size) * _grid_size;
    return _snapped;
}