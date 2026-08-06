/// @desc scr_opcode_condition_family_key(_lower_key)
/// If _lower_key is "b"/"db"/"s" followed by one of the 14 condition codes
/// (eq, ne, cc, cs, ge, gt, le, lt, hi, ls, mi, pl, vc, vs), returns which
/// generic tooltip key it belongs to ("bcc", "dbcc", or "scc"). Returns ""
/// if it doesn't match the pattern (e.g. DBRA, which is a real distinct
/// opcode with its own dedicated entry, not part of this family).
function scr_opcode_condition_family_key(_lower_key) {
    var _condition_codes = ["eq", "ne", "cc", "cs", "ge", "gt", "le", "lt", "hi", "ls", "mi", "pl", "vc", "vs"];
    var _condition_count = array_length(_condition_codes);
    var _c = 0;

    while (_c < _condition_count) {
        var _condition = _condition_codes[_c];

        if (_lower_key == ("b" + _condition)) {
            return "bcc";
        }

        if (_lower_key == ("db" + _condition)) {
            return "dbcc";
        }

        if (_lower_key == ("s" + _condition)) {
            return "scc";
        }

        _c += 1;
    }

    return "";
}
