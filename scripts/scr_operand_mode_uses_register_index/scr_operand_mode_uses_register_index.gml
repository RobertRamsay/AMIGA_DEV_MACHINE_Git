/// @desc scr_operand_mode_uses_register_index(_mode_label)
/// True if the number attached to this mode is a register index (0-7),
/// false if it's a free-form value (immediate or absolute address).
function scr_operand_mode_uses_register_index(_mode_label) {
    var _uses_register = false;

    switch (_mode_label) {
        case "Dn":
        case "An":
        case "(An)":
        case "(An)+":
        case "-(An)":
        case "d16(An)":
        case "d8(An,Xn)":
            _uses_register = true;
            break;
        default:
            _uses_register = false;
            break;
    }

    return _uses_register;
}