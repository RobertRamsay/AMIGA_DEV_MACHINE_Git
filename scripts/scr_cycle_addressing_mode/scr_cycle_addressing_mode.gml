/// @desc scr_cycle_addressing_mode(_current_label, _legal_flags)
function scr_cycle_addressing_mode(_current_label, _legal_flags) {
    var _legal_list = scr_addressing_mode_list_from_flags(_legal_flags);
    var _legal_count = array_length(_legal_list);

    if (_legal_count == 0) {
        return _current_label;
    }

    var _current_index = -1;
    var _i = 0;

    while (_i < _legal_count) {
        if (_legal_list[_i] == _current_label) {
            _current_index = _i;
        }
        _i += 1;
    }

    var _next_index = 0;

    if (_current_index == -1) {
        _next_index = 0;
    } else {
        if (_current_index + 1 >= _legal_count) {
            _next_index = 0;
        } else {
            _next_index = _current_index + 1;
        }
    }

    return _legal_list[_next_index];
}