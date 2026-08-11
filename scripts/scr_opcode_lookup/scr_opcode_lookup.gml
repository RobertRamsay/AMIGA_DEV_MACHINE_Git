/// @desc scr_opcode_lookup(_key)
/// Combined lookup across both tooltip banks. Falls back to the base mnemonic
/// (text before an underscore) for privileged variants like MOVE_SR, and to
/// the generic bcc/dbcc/scc entry for any of the 14 condition-code variants
/// (BEQ, DBNE, SGT, etc. — all 42 of them share the same underlying text).
/// Returns a struct or undefined.
function scr_opcode_lookup(_key) {
    var _lower_key = string_lower(_key);

    // Fixed top-strip controls are macros rather than 68000 opcodes, so they
    // do not exist in the instruction helper banks below. Give them the same
    // hover-help shape while clearly labelling their generated/runtime cost.
    if (_lower_key == "org") return {
        format : "ORG", mode : "Program root",
        use : "Starts an assembled program chain at the selected origin address.",
        cycles : "none", bytes : "none", generated_help : true
    };
    if (_lower_key == "cprbar") return {
        format : "CPRBAR", mode : "Copper macro",
        use : "Builds raster-timed 12-bit colour bands and repeats them every video frame.",
        cycles : "Copper-timed", bytes : "generated", generated_help : true
    };
    if (_lower_key == "setbkg") return {
        format : "SETBKG", mode : "Display macro",
        use : "Programs bitmap background register COLOR00 with a chosen Amiga 12-bit colour.",
        cycles : "setup", bytes : "generated", generated_help : true
    };
    if (_lower_key == "move_bob" || _lower_key == "move_spr") return {
        format : string_upper(_lower_key), mode : "Runtime movement macro",
        use : "Moves the selected runtime ID using editable signed X and Y speeds each update.",
        cycles : "per frame", bytes : "generated", generated_help : true
    };
    if (_lower_key == "anim_bob" || _lower_key == "anim_spr") return {
        format : string_upper(_lower_key), mode : "Runtime animation macro",
        use : "Animates an editable frame range at the selected rate, with optional looping.",
        cycles : "per frame", bytes : "frame-dependent", generated_help : true
    };

    var _result_first = scr_opcode_helper_68k(_lower_key);

    if (_result_first != undefined) {
        return _result_first;
    }

    var _result_second = scr_opcode_helper_68k_part2(_lower_key);

    if (_result_second != undefined) {
        return _result_second;
    }

    var _result_third = scr_opcode_helper_68k_part3(_lower_key);

    if (_result_third != undefined) {
        return _result_third;
    }

    var _underscore_pos = string_pos("_", _lower_key);

    if (_underscore_pos > 0) {
        var _base_key = string_copy(_lower_key, 1, _underscore_pos - 1);
        var _result_base_first = scr_opcode_helper_68k(_base_key);

        if (_result_base_first != undefined) {
            return _result_base_first;
        }

        var _result_base_second = scr_opcode_helper_68k_part2(_base_key);

        if (_result_base_second != undefined) {
            return _result_base_second;
        }
    }

    var _condition_family_key = scr_opcode_condition_family_key(_lower_key);

    if (_condition_family_key != "") {
        return scr_opcode_helper_68k_part2(_condition_family_key);
    }

    return undefined;
}
