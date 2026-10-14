/// @desc Reads vasm.log after a build and maps every message back to the
/// node that produced it. vasm writes, for example:
///     error 2 in line 5 of "main.s": unknown mnemonic <foo>
///     >	foo d0
/// Messages from an INCLUDEd file (ptplayer) end with an "included from line
/// N of "main.s"" line, which is used for the mapping instead.
/// Fills global.code_editor_build_errors ({ node_uid, line, message } with a
/// 0-based CODE-block line) for the code editor, sets each node's
/// build_error_text for the red outline, and returns
/// { error_count, warning_count, messages[] } (messages are display strings).

function scr_amiga_vasm_line_owner(_line_map, _main_line) {
    var _i = 0;
    while (_i < array_length(_line_map)) {
        var _entry = _line_map[_i];
        if (_main_line >= _entry.first_line && _main_line <= _entry.last_line) return _entry;
        _i += 1;
    }
    return undefined;
}

/// Number after "line " in _text, or -1.
function scr_amiga_vasm_line_number(_text) {
    var _pos = string_pos("line ", _text);
    if (_pos <= 0) return -1;
    var _digits = "";
    var _i = _pos + 5;
    while (_i <= string_length(_text)) {
        var _c = string_char_at(_text, _i);
        if (_c < "0" || _c > "9") break;
        _digits += _c;
        _i += 1;
    }
    if (_digits == "") return -1;
    return real(_digits);
}

function scr_amiga_vasm_report(_log_path, _line_map) {
    var _report = { error_count : 0, warning_count : 0, messages : [] };
    global.code_editor_build_errors = [];

    if (!file_exists(_log_path)) return _report;

    var _lines = [];
    var _file = file_text_open_read(_log_path);
    while (!file_text_eof(_file)) {
        array_push(_lines, file_text_read_string(_file));
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _i = 0;
    var _count = array_length(_lines);
    while (_i < _count) {
        var _line = string_trim(_lines[_i]);
        var _is_error = string_pos("error ", _line) == 1 || string_pos("fatal error", _line) == 1;
        var _is_warning = string_pos("warning ", _line) == 1;

        if (_is_error || _is_warning) {
            // The message text follows the first ": " after the location.
            var _colon = string_pos("\": ", _line);
            var _message = _colon > 0 ? string_copy(_line, _colon + 3, string_length(_line) - _colon - 2) : _line;
            var _main_line = -1;
            var _in_main = string_pos("of \"main.s\"", _line) > 0;
            if (_in_main) _main_line = scr_amiga_vasm_line_number(_line);

            // Look ahead for the source echo and "included from" / "called from".
            var _source_echo = "";
            var _j = _i + 1;
            while (_j < _count) {
                var _next = string_trim(_lines[_j]);
                if (string_pos("error ", _next) == 1 || string_pos("warning ", _next) == 1 || string_pos("fatal error", _next) == 1) break;
                if (string_char_at(_next, 1) == ">" && _source_echo == "") _source_echo = string_trim(string_delete(_next, 1, 1));
                if (_main_line < 0 && (string_pos("included from", _next) > 0 || string_pos("called from", _next) > 0) && string_pos("\"main.s\"", _next) > 0) {
                    _main_line = scr_amiga_vasm_line_number(_next);
                }
                _j += 1;
            }

            var _owner = _main_line > 0 ? scr_amiga_vasm_line_owner(_line_map, _main_line) : undefined;
            var _where = "program";
            if (_owner != undefined) {
                _where = scr_amiga_describe_node(_owner.node);
                if (_owner.node.node_label != "") _where += " (" + _owner.node.node_label + ")";

                if (_is_error) {
                    if (_owner.node.build_error_text == "") _owner.node.build_error_text = _message;
                    if (_owner.code_first_line > 0 && _main_line >= _owner.code_first_line) {
                        var _code_line = _main_line - _owner.code_first_line;
                        array_push(global.code_editor_build_errors, { node_uid : _owner.node.uid, line : _code_line, message : _message });
                        _where += " line " + string(_code_line + 1);
                    }
                }
            } else if (_main_line > 0) {
                _where = "main.s line " + string(_main_line);
            }

            var _display = (_is_error ? "ASM ERROR " : "asm warning ") + _where + ": " + _message;
            if (_source_echo != "") _display += "   >  " + _source_echo;
            array_push(_report.messages, { text : _display, is_error : _is_error });

            if (_is_error) _report.error_count += 1;
            else _report.warning_count += 1;
        }
        _i += 1;
    }

    return _report;
}
