/// @desc scr_format_operand(_mode_label, _value, _extra)
function scr_format_operand(_mode_label, _value, _extra) {
    var _text = "";
    var _index_letter = "";

    switch (_mode_label) {
        case "Dn":
            _text = "D" + string(_value);
            break;
        case "An":
            _text = "A" + string(_value);
            break;
        case "(An)":
            _text = "(A" + string(_value) + ")";
            break;
        case "(An)+":
            _text = "(A" + string(_value) + ")+";
            break;
        case "-(An)":
            _text = "-(A" + string(_value) + ")";
            break;
        case "d16(An)":
            _text = string(_extra.displacement) + "(A" + string(_value) + ")";
            break;
        case "d8(An,Xn)":
            if (_extra.index_register_is_address) {
                _index_letter = "A";
            } else {
                _index_letter = "D";
            }
            _text = string(_extra.displacement) + "(A" + string(_value) + "," + _index_letter + string(_extra.index_register) + ")";
            break;
        case "abs.W":
            _text = string(_value) + ".W";
            break;
        case "abs.L":
            _text = string(_value) + ".L";
            break;
        case "d16(PC)":
            _text = string(_extra.displacement) + "(PC)";
            break;
        case "d8(PC,Xn)":
            if (_extra.index_register_is_address) {
                _index_letter = "A";
            } else {
                _index_letter = "D";
            }
            _text = string(_extra.displacement) + "(PC," + _index_letter + string(_extra.index_register) + ")";
            break;
        case "#imm":
            _text = "#" + string(_value);
            break;
        default:
            _text = "?";
            break;
    }

    return _text;
}