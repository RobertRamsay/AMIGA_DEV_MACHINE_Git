/// @desc scr_addressing_mode_flag(_mode_label)
function scr_addressing_mode_flag(_mode_label) {
    var _flag = 0;

    switch (_mode_label) {
        case "Dn":         _flag = global.AM_DN;         break;
        case "An":         _flag = global.AM_AN;         break;
        case "(An)":       _flag = global.AM_AN_IND;     break;
        case "(An)+":      _flag = global.AM_AN_POSTINC; break;
        case "-(An)":      _flag = global.AM_AN_PREDEC;  break;
        case "d16(An)":    _flag = global.AM_AN_DISP;    break;
        case "d8(An,Xn)":  _flag = global.AM_AN_INDEX;   break;
        case "abs.W":      _flag = global.AM_ABS_W;      break;
        case "abs.L":      _flag = global.AM_ABS_L;      break;
        case "d16(PC)":    _flag = global.AM_PC_DISP;    break;
        case "d8(PC,Xn)":  _flag = global.AM_PC_INDEX;   break;
        case "#imm":       _flag = global.AM_IMM;        break;
        default:           _flag = 0;                    break;
    }

    return _flag;
}