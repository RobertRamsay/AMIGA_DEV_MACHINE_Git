/// @desc Test specs for the 68000 simulator, shared by the simulator self test
/// (scr_m68k_selftest) and the 68K course lessons (scr_course).
///
/// Setup: "d0=7FFF a0=2000 sr=2000 ccr=X-Z-C ssp=4000 usp=3000 m2000.w=1234
///   str2100=HELLO_WORLD joy=left+fire max=1000"
///   (hex; a7 = the active stack; _ in a string is a space)
/// Expected: "d0=8000 ccr=-N-V- m2000.l=1 a7=3000 sr=2700 pc=1000
///   status=exception vector=3 hw180=0F00 hwlong080=20000 hwcount180=2
///   ciaa2=3 vpos=12C cyc=22 maxcyc=40 maxsize=12 str2100=HI uses=dbra
///   avoid=mulu+muls keep=d2+d3+a6"
///   (hex except vector, cyc, maxcyc, maxsize, hwcount; ccr letters XNZVC,
///   - = clear, ? = don't care; uses / avoid look at the source text, keep
///   compares with the registers at the start)

/// Applies _setup and starts the CPU at _pc. _stop_pc < 0: the run ends at an
/// RTS from the first level (a return address is pushed). Returns the
/// instruction limit (max=, else _max).
function scr_m68k_spec_setup(_cpu, _setup, _pc, _stop_pc = -1, _max = 300000) {
    var _sr = $2700;
    var _ccr = -1;
    var _usp = -1;
    var _ssp = -1;
    var _later = [];
    var _a7 = -1;
    var _tokens = string_split(_setup, " ", true);
    for (var _i = 0; _i < array_length(_tokens); _i += 1) {
        var _kv = string_split(_tokens[_i], "=");
        var _key = string_lower(_kv[0]);
        var _val = array_length(_kv) > 1 ? _kv[1] : "";
        switch (_key) {
            case "sr": _sr = scr_m68k_parse_hex(_val); break;
            case "ccr": _ccr = scr_m68k_spec_ccr_bits(_val); break;
            case "usp": _usp = scr_m68k_parse_hex(_val); break;
            case "ssp": _ssp = scr_m68k_parse_hex(_val); break;
            case "a7": _a7 = scr_m68k_parse_hex(_val); break;
            case "max": _max = real(_val); break;
            case "joy":
                scr_m68k_set_joystick(_cpu, string_pos("up", _val) > 0, string_pos("down", _val) > 0,
                    string_pos("left", _val) > 0, string_pos("right", _val) > 0, string_pos("fire", _val) > 0);
                break;
            default: array_push(_later, _kv); break;
        }
    }
    if (_ccr >= 0) _sr = (_sr & $FF00) | _ccr;
    // a7 is the stack of the starting mode, so the pushed return address lands there.
    if (_a7 >= 0) {
        if ((_sr & $2000) != 0) _ssp = _a7;
        else _usp = _a7;
    }
    scr_m68k_start(_cpu, _pc, _sr, _usp, _ssp, _stop_pc < 0);
    if (_stop_pc >= 0) _cpu.stop_pc = _stop_pc;
    for (var _j = 0; _j < array_length(_later); _j += 1) {
        var _k = string_lower(_later[_j][0]);
        var _raw = array_length(_later[_j]) > 1 ? _later[_j][1] : "";
        var _c0 = string_char_at(_k, 1);
        if (string_copy(_k, 1, 3) == "str") {
            var _addr = scr_m68k_parse_hex(string_delete(_k, 1, 3));
            var _s = string_replace_all(_raw, "_", " ");
            for (var _b = 1; _b <= string_length(_s); _b += 1) scr_m68k_poke(_cpu, _addr + _b - 1, 1, ord(string_char_at(_s, _b)));
            scr_m68k_poke(_cpu, _addr + string_length(_s), 1, 0);
            continue;
        }
        var _v = scr_m68k_parse_hex(_raw);
        if (_c0 == "d") _cpu.d[real(string_char_at(_k, 2))] = _v;
        else if (_c0 == "a") _cpu.a[real(string_char_at(_k, 2))] = _v;
        else if (_c0 == "m") {
            var _parts = string_split(string_delete(_k, 1, 1), ".");
            var _size = array_length(_parts) < 2 ? 1 : (_parts[1] == "b" ? 1 : (_parts[1] == "w" ? 2 : 4));
            scr_m68k_poke(_cpu, scr_m68k_parse_hex(_parts[0]), _size, _v);
        }
    }
    _cpu.start_d = array_create(8, 0);
    _cpu.start_a = array_create(8, 0);
    array_copy(_cpu.start_d, 0, _cpu.d, 0, 8);
    array_copy(_cpu.start_a, 0, _cpu.a, 0, 8);
    return _max;
}

/// "X-Z-C" -> the CCR bits (letters set, anything else clear).
function scr_m68k_spec_ccr_bits(_pattern) {
    var _bits = 0;
    for (var _i = 0; _i < 5; _i += 1) {
        var _ch = string_char_at(_pattern, _i + 1);
        if (_ch != "-" && _ch != "?" && _ch != "") _bits |= 1 << (4 - _i);
    }
    return _bits;
}

/// True when the mnemonic _word (any size suffix) appears in _source outside comments.
function scr_m68k_spec_source_uses(_source, _word) {
    var _lines = string_split(string_lower(_source), "\n");
    _word = string_lower(_word);
    for (var _i = 0; _i < array_length(_lines); _i += 1) {
        var _l = _lines[_i];
        var _semi = string_pos(";", _l);
        if (_semi > 0) _l = string_copy(_l, 1, _semi - 1);
        if (string_char_at(string_trim(_l), 1) == "*") continue;
        _l = string_replace_all(_l, "\t", " ");
        var _toks = string_split(_l, " ", true);
        for (var _t = 0; _t < array_length(_toks); _t += 1) {
            var _tok = _toks[_t];
            var _dot = string_pos(".", _tok);
            if (_dot > 1) _tok = string_copy(_tok, 1, _dot - 1);
            if (_tok == _word) return true;
        }
    }
    return false;
}

/// Compares the CPU with _expect; returns an array of readable problems
/// (empty = pass). _ctx: { source, code_size } (either may be missing).
function scr_m68k_spec_check(_cpu, _expect, _ctx = undefined) {
    var _out = [];
    var _tokens = string_split(_expect, " ", true);
    for (var _i = 0; _i < array_length(_tokens); _i += 1) {
        var _kv = string_split(_tokens[_i], "=");
        var _key = string_lower(_kv[0]);
        var _want = array_length(_kv) > 1 ? _kv[1] : "";
        var _c0 = string_char_at(_key, 1);
        var _name = string_upper(_key);
        switch (_key) {
            case "status":
                if (_cpu.status != _want) array_push(_out, "The program should end with status " + _want + ", not " + _cpu.status);
                continue;
            case "vector":
                var _vec = is_struct(_cpu.fault) ? string(_cpu.fault.vector) : "none";
                if (_vec != _want) array_push(_out, "Expected exception vector " + _want + ", got " + _vec);
                continue;
            case "cyc":
                if (string(_cpu.cycles) != _want) array_push(_out, "Took " + string(_cpu.cycles) + " cycles, expected " + _want);
                continue;
            case "maxcyc":
                if (_cpu.cycles > real(_want)) array_push(_out, "Too slow: " + string(_cpu.cycles) + " cycles, the limit is " + _want);
                continue;
            case "maxsize":
                if (is_struct(_ctx) && variable_struct_exists(_ctx, "code_size") && _ctx.code_size > real(_want)) {
                    array_push(_out, "Too big: " + string(_ctx.code_size) + " bytes of code, the limit is " + _want);
                }
                continue;
            case "uses":
            case "avoid":
                if (!is_struct(_ctx) || !variable_struct_exists(_ctx, "source")) continue;
                var _words = string_split(_want, "+", true);
                for (var _w = 0; _w < array_length(_words); _w += 1) {
                    var _has = scr_m68k_spec_source_uses(_ctx.source, _words[_w]);
                    if (_key == "uses" && !_has) array_push(_out, "Use " + string_upper(_words[_w]) + " for this one");
                    if (_key == "avoid" && _has) array_push(_out, "Do it without " + string_upper(_words[_w]));
                }
                continue;
            case "keep":
                var _regs = string_split(string_lower(_want), "+", true);
                for (var _r = 0; _r < array_length(_regs); _r += 1) {
                    var _rn = real(string_char_at(_regs[_r], 2));
                    var _is_a = string_char_at(_regs[_r], 1) == "a";
                    var _now = _is_a ? _cpu.a[_rn] : _cpu.d[_rn];
                    var _was = _is_a ? _cpu.start_a[_rn] : _cpu.start_d[_rn];
                    if (_now != _was) array_push(_out, string_upper(_regs[_r]) + " changed from $" + scr_m68k_hex(_was, 8) + " to $" + scr_m68k_hex(_now, 8) + " - it should be left alone");
                }
                continue;
            case "ccr":
                var _ccr = _cpu.sr & $1F;
                var _got = "";
                var _ok = true;
                for (var _b = 0; _b < 5; _b += 1) {
                    var _set = (_ccr & (1 << (4 - _b))) != 0;
                    _got += _set ? string_char_at("XNZVC", _b + 1) : "-";
                    var _wc = string_char_at(_want, _b + 1);
                    if (_wc != "?" && _set != (_wc != "-")) _ok = false;
                }
                if (!_ok) array_push(_out, "Flags XNZVC are " + _got + ", expected " + _want);
                continue;
        }
        if (string_copy(_key, 1, 7) == "hwcount") {
            var _n = scr_m68k_hw_count(_cpu, scr_m68k_parse_hex(string_delete(_key, 1, 7)));
            if (_n != real(_want)) array_push(_out, "Register $DFF" + string_upper(string_delete(_key, 1, 7)) + " written " + string(_n) + " times, expected " + _want);
            continue;
        }
        if (string_copy(_key, 1, 3) == "str") {
            var _addr = scr_m68k_parse_hex(string_delete(_key, 1, 3));
            var _s = string_replace_all(_want, "_", " ");
            var _got_s = "";
            for (var _k = 0; _k < string_length(_s) + 1; _k += 1) {
                var _ch = scr_m68k_peek(_cpu, _addr + _k, 1);
                if (_ch == 0) break;
                _got_s += (_ch >= 32 && _ch < 127) ? chr(_ch) : "?";
            }
            if (_got_s != _s) array_push(_out, "The text at $" + string_upper(string_delete(_key, 1, 3)) + " is \"" + _got_s + "\", expected \"" + _s + "\"");
            continue;
        }
        var _v = 0;
        if (_key == "sr") _v = _cpu.sr;
        else if (_key == "pc") _v = _cpu.pc;
        else if (_key == "ssp") _v = (_cpu.sr & $2000) != 0 ? _cpu.a[7] : _cpu.ssp;
        else if (_key == "usp") _v = (_cpu.sr & $2000) != 0 ? _cpu.usp : _cpu.a[7];
        else if (_key == "vpos") _v = scr_m68k_hw_vpos(_cpu);
        else if (string_copy(_key, 1, 6) == "hwlong") {
            _v = scr_m68k_hw_long(_cpu, scr_m68k_parse_hex(string_delete(_key, 1, 6)));
            _name = "$DFF" + string_upper(string_delete(_key, 1, 6)) + " (long)";
        } else if (string_copy(_key, 1, 2) == "hw") {
            _v = scr_m68k_hw_value(_cpu, scr_m68k_parse_hex(string_delete(_key, 1, 2)));
            _name = "$DFF" + string_upper(string_delete(_key, 1, 2));
        } else if (string_copy(_key, 1, 4) == "ciaa") _v = _cpu.ciaa[real(string_delete(_key, 1, 4))];
        else if (string_copy(_key, 1, 4) == "ciab") _v = _cpu.ciab[real(string_delete(_key, 1, 4))];
        else if (_c0 == "d") _v = _cpu.d[real(string_char_at(_key, 2))];
        else if (_c0 == "a") _v = _cpu.a[real(string_char_at(_key, 2))];
        else if (_c0 == "m") {
            var _parts = string_split(string_delete(_key, 1, 1), ".");
            var _size = array_length(_parts) < 2 ? 1 : (_parts[1] == "b" ? 1 : (_parts[1] == "w" ? 2 : 4));
            _v = scr_m68k_peek(_cpu, scr_m68k_parse_hex(_parts[0]), _size);
            _name = "Memory at $" + string_upper(_parts[0]) + (_size == 1 ? " (byte)" : (_size == 2 ? " (word)" : " (long)"));
        }
        var _wv = scr_m68k_parse_hex(_want);
        if ((_v & $FFFFFFFF) != _wv) {
            var _digits = 8;
            if (string_copy(_key, 1, 2) == "hw" && string_copy(_key, 1, 6) != "hwlong") _digits = 4;
            if (_key == "sr") _digits = 4;
            if (_c0 == "m") _digits = string_pos(".b", _key) > 0 ? 2 : (string_pos(".w", _key) > 0 ? 4 : 8);
            array_push(_out, _name + " is $" + scr_m68k_hex(_v, _digits) + ", expected $" + scr_m68k_hex(_wv, _digits));
        }
    }
    return _out;
}
