/// @desc scr_pick_default_size(_sizes_array)
/// Prefers "W" if the opcode supports it, otherwise falls back to the first supported size.
function scr_pick_default_size(_sizes_array) {
    var _picked_size = "";
    var _size_count = array_length(_sizes_array);

    if (_size_count > 0) {
        _picked_size = _sizes_array[0];

        var _s = 0;

        while (_s < _size_count) {
            if (_sizes_array[_s] == "W") {
                _picked_size = "W";
            }

            _s += 1;
        }
    }

    return _picked_size;
}