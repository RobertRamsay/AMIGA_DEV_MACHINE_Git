/// @desc scr_is_dbcc_opcode(_mnemonic)
function scr_is_dbcc_opcode(_mnemonic) {
    var _starts_with_db = (string_copy(_mnemonic, 1, 2) == "DB");
    return _starts_with_db;
}
