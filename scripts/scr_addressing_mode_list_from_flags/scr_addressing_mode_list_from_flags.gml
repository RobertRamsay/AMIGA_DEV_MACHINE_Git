/// @desc scr_addressing_mode_list_from_flags(_flags)
/// Returns an array of mode label strings present in the given bitflag.
function scr_addressing_mode_list_from_flags(_flags) {
    var _ordered_modes = [
        ["Dn", global.AM_DN],
        ["An", global.AM_AN],
        ["(An)", global.AM_AN_IND],
        ["(An)+", global.AM_AN_POSTINC],
        ["-(An)", global.AM_AN_PREDEC],
        ["d16(An)", global.AM_AN_DISP],
        ["d8(An,Xn)", global.AM_AN_INDEX],
        ["abs.W", global.AM_ABS_W],
        ["abs.L", global.AM_ABS_L],
        ["d16(PC)", global.AM_PC_DISP],
        ["d8(PC,Xn)", global.AM_PC_INDEX],
        ["#imm", global.AM_IMM]
    ];

    var _result = [];
    var _i = 0;
    var _count = array_length(_ordered_modes);

    while (_i < _count) {
        var _label = _ordered_modes[_i][0];
        var _flag = _ordered_modes[_i][1];
        var _is_present = (_flag & _flags) != 0;

        if (_is_present) {
            array_push(_result, _label);
        }

        _i += 1;
    }

    return _result;
}