/// @desc 68000 simulator for the 68K course: runs real machine code (vasm -Fbin
/// output) so a lesson can check registers, flags, memory and custom-chip writes.
///
///   var _cpu = scr_m68k_new();                // 512 KB chip RAM, 68000
///   scr_m68k_load_hex(_cpu, $1000, "7001...");  // or scr_m68k_load_file
///   scr_m68k_start(_cpu, $1000);               // supervisor, returns at RTS
///   scr_m68k_run(_cpu, 100000);                // "done" / "exception" / "timeout" ...
///   _cpu.d[0], _cpu.sr, scr_m68k_peek(_cpu, $2000, 4), scr_m68k_hw_value(_cpu, $180)
///   scr_m68k_free(_cpu);                       // the memory is a buffer
///
/// Values are kept unsigned (0..$FFFFFFFF). Memory map: chip RAM from 0, the
/// custom chips at $DFF000 and the CIAs at $BFxxxx (scr_m68k_hw); anything
/// else is a bus error. Word and long accesses to odd addresses are address
/// errors (68000). An exception whose vector is still 0 stops the run with a
/// plain-English message instead of jumping to 0. Cycle counts follow the
/// 68000 timing tables (no wait states) and drive the beam position, so VBL
/// waits and the VERTB interrupt work. Status: "ready", "running", "done"
/// (reached stop_pc), "stopped" (STOP with nothing to wake it), "exception",
/// "timeout" (instruction limit), "error" (simulator bug, message says).

#macro M68K_C 1
#macro M68K_V 2
#macro M68K_Z 4
#macro M68K_N 8
#macro M68K_X 16
/// Return address pushed by scr_m68k_start: an RTS to it ends the run.
#macro M68K_RETURN_PC $00F00000

function scr_m68k_tables() {
    if (variable_global_exists("m68k_ea_time_bw")) return;
    // Effective address time by scr_m68k_ea_calc index: Dn, An, (An), (An)+,
    // -(An), d16(An), d8(An,Xn), abs.W, abs.L, d16(PC), d8(PC,Xn), #imm.
    global.m68k_ea_time_bw = [0, 0, 4, 4, 6, 8, 10, 8, 12, 8, 10, 4];
    global.m68k_ea_time_l = [0, 0, 8, 8, 10, 12, 14, 12, 16, 12, 14, 8];
    // LEA time by the same index (control modes only); JMP / PEA / JSR add to it.
    global.m68k_lea_time = [0, 0, 4, 0, 0, 8, 12, 8, 12, 8, 12, 0];
}

/// A new CPU with _mem_size bytes of chip RAM. _model: 0 = 68000 (2 = 68020, later).
function scr_m68k_new(_mem_size = $80000, _model = 0) {
    scr_m68k_tables();
    var _c = {
        model : _model,
        mem_size : _mem_size,
        mem : buffer_create(_mem_size, buffer_fixed, 1),
        addr_mask : _model >= 2 ? $FFFFFFFF : $FFFFFF,
        d : array_create(8, 0),
        a : array_create(8, 0),
        usp : 0,
        ssp : 0,
        pc : 0,
        sr : $2700,
        vbr : 0,
        op_pc : 0,          // address of the instruction being run
        ir : 0,             // its first word
        cycles : 0,
        instructions : 0,
        status : "ready",
        message : "",
        fault : undefined,  // { vector, pc, address } of the exception that stopped a run
        stopped : false,    // inside STOP, waiting for an interrupt
        stop_pc : -1,       // the run is "done" when the PC gets here
        ea_kind : 0,        // last effective address: 0 Dn, 1 An, 2 memory, 3 immediate
        ea_reg : 0,
        ea_addr : 0,
        ea_val : 0,
        ea_index : 0,       // timing table index (see scr_m68k_tables)
    };
    scr_m68k_reset(_c);
    return _c;
}

function scr_m68k_free(_c) {
    if (buffer_exists(_c.mem)) buffer_delete(_c.mem);
}

/// Clears memory, registers, counters and the hardware state.
function scr_m68k_reset(_c) {
    buffer_fill(_c.mem, 0, buffer_u8, 0, _c.mem_size);
    for (var _i = 0; _i < 8; _i += 1) {
        _c.d[_i] = 0;
        _c.a[_i] = 0;
    }
    _c.usp = 0;
    _c.ssp = 0;
    _c.pc = 0;
    _c.sr = $2700;
    _c.vbr = 0;
    _c.cycles = 0;
    _c.instructions = 0;
    _c.status = "ready";
    _c.message = "";
    _c.fault = undefined;
    _c.stopped = false;
    _c.stop_pc = -1;
    scr_m68k_hw_reset(_c);
}

/// Copies a hex string ("70FF 4E75", spaces ignored) into memory at _addr; returns its length.
function scr_m68k_load_hex(_c, _addr, _hex) {
    _hex = string_replace_all(string_replace_all(_hex, " ", ""), "\n", "");
    var _len = string_length(_hex) div 2;
    for (var _i = 0; _i < _len; _i += 1) {
        buffer_poke(_c.mem, _addr + _i, buffer_u8, scr_m68k_parse_hex(string_copy(_hex, _i * 2 + 1, 2)));
    }
    return _len;
}

/// Copies a file (raw vasm -Fbin output) into memory at _addr; returns its length, -1 on failure.
function scr_m68k_load_file(_c, _addr, _path) {
    if (!file_exists(_path)) return -1;
    var _buf = buffer_load(_path);
    if (_buf < 0) return -1;
    var _len = buffer_get_size(_buf);
    if (_addr + _len > _c.mem_size) {
        buffer_delete(_buf);
        return -1;
    }
    buffer_copy(_buf, 0, _len, _c.mem, _addr);
    buffer_delete(_buf);
    return _len;
}

/// Gets ready to run from _pc. The stacks start at the top of chip RAM
/// (supervisor) and 4 KB below it (user) unless given. With _return_stop an
/// RTS from the first level ends the run ("done").
function scr_m68k_start(_c, _pc, _sr = $2700, _usp = -1, _ssp = -1, _return_stop = true) {
    _c.ssp = _ssp >= 0 ? _ssp : _c.mem_size;
    _c.usp = _usp >= 0 ? _usp : _c.mem_size - $1000;
    _c.sr = _sr & $A71F;
    _c.a[7] = (_c.sr & $2000) != 0 ? _c.ssp : _c.usp;
    _c.pc = _pc & $FFFFFFFF;
    _c.op_pc = _c.pc;
    _c.status = "running";
    _c.message = "";
    _c.fault = undefined;
    _c.stopped = false;
    if (_return_stop) {
        _c.a[7] = (_c.a[7] - 4) & $FFFFFFFF;
        scr_m68k_poke(_c, _c.a[7], 4, M68K_RETURN_PC);
        _c.stop_pc = M68K_RETURN_PC;
    }
}

/// Runs up to _max instructions; returns the status. Hitting the limit gives "timeout".
function scr_m68k_run(_c, _max) {
    var _n = 0;
    while (_c.status == "running" && _n < _max) {
        scr_m68k_step(_c);
        _n += 1;
    }
    if (_c.status == "running") {
        _c.status = "timeout";
        _c.message = "Still running after " + string(_max) + " instructions - is there an endless loop?";
    }
    return _c.status;
}

// ---------------------------------------------------------------- helpers

function scr_m68k_parse_hex(_s) {
    var _v = 0;
    _s = string_upper(_s);
    for (var _i = 1; _i <= string_length(_s); _i += 1) {
        var _ch = string_char_at(_s, _i);
        var _d = string_pos(_ch, "0123456789ABCDEF");
        if (_d == 0) continue;
        _v = _v * 16 + (_d - 1);
    }
    return _v;
}

function scr_m68k_hex(_v, _digits) {
    var _s = "";
    _v = _v & $FFFFFFFF;
    repeat (_digits) {
        _s = string_char_at("0123456789ABCDEF", (_v & 15) + 1) + _s;
        _v = _v >> 4;
    }
    return _s;
}

function scr_m68k_sx8(_v) {
    _v = _v & $FF;
    return _v >= $80 ? _v - $100 : _v;
}

function scr_m68k_sx16(_v) {
    _v = _v & $FFFF;
    return _v >= $8000 ? _v - $10000 : _v;
}

function scr_m68k_sx32(_v) {
    _v = _v & $FFFFFFFF;
    return _v >= $80000000 ? _v - $100000000 : _v;
}

function scr_m68k_mask(_size) {
    return _size == 1 ? $FF : (_size == 2 ? $FFFF : $FFFFFFFF);
}

function scr_m68k_msb(_size) {
    return _size == 1 ? $80 : (_size == 2 ? $8000 : $80000000);
}

function scr_m68k_size_name(_size) {
    return _size == 1 ? "byte" : (_size == 2 ? "word" : "long");
}

/// Raises exception _vec from inside an instruction (scr_m68k_step catches it).
function scr_m68k_throw(_vec) {
    throw { m68k_vector : _vec, address : 0, write : false, fetch : false };
}

function scr_m68k_illegal(_c) {
    throw { m68k_vector : 4, address : _c.op_pc, write : false, fetch : true };
}

function scr_m68k_need_super(_c) {
    if ((_c.sr & $2000) == 0) throw { m68k_vector : 8, address : _c.op_pc, write : false, fetch : true };
}

// ---------------------------------------------------------------- memory

function scr_m68k_rb(_c, _a) {
    _a = _a & _c.addr_mask;
    if (_a < _c.mem_size) return buffer_peek(_c.mem, _a, buffer_u8);
    return scr_m68k_io_read(_c, _a, 1);
}

function scr_m68k_rw(_c, _a, _fetch = false) {
    _a = _a & _c.addr_mask;
    // The 68020 allows odd data addresses, but never an odd PC.
    if ((_a & 1) != 0 && (_c.model < 2 || _fetch)) throw { m68k_vector : 3, address : _a, write : false, fetch : _fetch };
    if (_a + 1 < _c.mem_size) {
        var _v = buffer_peek(_c.mem, _a, buffer_u16);
        return ((_v & $FF) << 8) | (_v >> 8);
    }
    if (_fetch && _a >= _c.mem_size) throw { m68k_vector : 2, address : _a, write : false, fetch : true };
    return scr_m68k_io_read(_c, _a, 2);
}

function scr_m68k_rl(_c, _a) {
    var _hi = scr_m68k_rw(_c, _a);
    return (_hi << 16) | scr_m68k_rw(_c, _a + 2);
}

function scr_m68k_wb(_c, _a, _v) {
    _a = _a & _c.addr_mask;
    if (_a < _c.mem_size) {
        buffer_poke(_c.mem, _a, buffer_u8, _v & $FF);
        return;
    }
    scr_m68k_io_write(_c, _a, 1, _v & $FF);
}

function scr_m68k_ww(_c, _a, _v) {
    _a = _a & _c.addr_mask;
    if ((_a & 1) != 0 && _c.model < 2) throw { m68k_vector : 3, address : _a, write : true, fetch : false };
    _v = _v & $FFFF;
    if (_a + 1 < _c.mem_size) {
        buffer_poke(_c.mem, _a, buffer_u16, ((_v & $FF) << 8) | (_v >> 8));
        return;
    }
    scr_m68k_io_write(_c, _a, 2, _v);
}

function scr_m68k_wl(_c, _a, _v) {
    scr_m68k_ww(_c, _a, (_v >> 16) & $FFFF);
    scr_m68k_ww(_c, _a + 2, _v & $FFFF);
}

function scr_m68k_read(_c, _a, _size) {
    return _size == 1 ? scr_m68k_rb(_c, _a) : (_size == 2 ? scr_m68k_rw(_c, _a) : scr_m68k_rl(_c, _a));
}

function scr_m68k_write(_c, _a, _size, _v) {
    if (_size == 1) scr_m68k_wb(_c, _a, _v);
    else if (_size == 2) scr_m68k_ww(_c, _a, _v);
    else scr_m68k_wl(_c, _a, _v);
}

/// Reads chip RAM for a lesson check or the debugger: no exceptions, no hardware side effects (0 outside RAM).
function scr_m68k_peek(_c, _a, _size) {
    var _v = 0;
    for (var _i = 0; _i < _size; _i += 1) {
        var _b = (_a + _i) & _c.addr_mask;
        _v = (_v << 8) | (_b < _c.mem_size ? buffer_peek(_c.mem, _b, buffer_u8) : 0);
    }
    return _v;
}

/// Writes chip RAM directly (lesson setup); addresses outside RAM are ignored.
function scr_m68k_poke(_c, _a, _size, _v) {
    for (var _i = _size - 1; _i >= 0; _i -= 1) {
        var _b = (_a + _i) & _c.addr_mask;
        if (_b < _c.mem_size) buffer_poke(_c.mem, _b, buffer_u8, _v & $FF);
        _v = _v >> 8;
    }
}

function scr_m68k_fetch16(_c) {
    var _v = scr_m68k_rw(_c, _c.pc, true);
    _c.pc = (_c.pc + 2) & $FFFFFFFF;
    return _v;
}

function scr_m68k_fetch32(_c) {
    var _hi = scr_m68k_fetch16(_c);
    return (_hi << 16) | scr_m68k_fetch16(_c);
}

function scr_m68k_push16(_c, _v) {
    _c.a[7] = (_c.a[7] - 2) & $FFFFFFFF;
    scr_m68k_ww(_c, _c.a[7], _v);
}

function scr_m68k_push32(_c, _v) {
    _c.a[7] = (_c.a[7] - 4) & $FFFFFFFF;
    scr_m68k_wl(_c, _c.a[7], _v);
}

function scr_m68k_pop16(_c) {
    var _v = scr_m68k_rw(_c, _c.a[7]);
    _c.a[7] = (_c.a[7] + 2) & $FFFFFFFF;
    return _v;
}

function scr_m68k_pop32(_c) {
    var _v = scr_m68k_rl(_c, _c.a[7]);
    _c.a[7] = (_c.a[7] + 4) & $FFFFFFFF;
    return _v;
}

// ---------------------------------------------------------------- effective addresses

/// Decodes mode / register into _c.ea_* (fetching extension words, applying
/// (An)+ / -(An)) without adding cycles.
function scr_m68k_ea_calc(_c, _mode, _reg, _size) {
    switch (_mode) {
        case 0:
            _c.ea_kind = 0;
            _c.ea_reg = _reg;
            _c.ea_index = 0;
            return;
        case 1:
            _c.ea_kind = 1;
            _c.ea_reg = _reg;
            _c.ea_index = 1;
            return;
        case 2:
            _c.ea_kind = 2;
            _c.ea_addr = _c.a[_reg];
            _c.ea_index = 2;
            return;
        case 3:
            _c.ea_kind = 2;
            _c.ea_addr = _c.a[_reg];
            _c.a[_reg] = (_c.a[_reg] + ((_reg == 7 && _size == 1) ? 2 : _size)) & $FFFFFFFF;
            _c.ea_index = 3;
            return;
        case 4:
            _c.a[_reg] = (_c.a[_reg] - ((_reg == 7 && _size == 1) ? 2 : _size)) & $FFFFFFFF;
            _c.ea_kind = 2;
            _c.ea_addr = _c.a[_reg];
            _c.ea_index = 4;
            return;
        case 5:
            var _d16 = scr_m68k_sx16(scr_m68k_fetch16(_c));
            _c.ea_kind = 2;
            _c.ea_addr = (_c.a[_reg] + _d16) & $FFFFFFFF;
            _c.ea_index = 5;
            return;
        case 6:
            _c.ea_kind = 2;
            _c.ea_addr = scr_m68k_ea_indexed(_c, _c.a[_reg]);
            _c.ea_index = 6;
            return;
        case 7:
            switch (_reg) {
                case 0:
                    _c.ea_kind = 2;
                    _c.ea_addr = scr_m68k_sx16(scr_m68k_fetch16(_c)) & $FFFFFFFF;
                    _c.ea_index = 7;
                    return;
                case 1:
                    _c.ea_kind = 2;
                    _c.ea_addr = scr_m68k_fetch32(_c);
                    _c.ea_index = 8;
                    return;
                case 2:
                    var _base = _c.pc;
                    _c.ea_kind = 2;
                    _c.ea_addr = (_base + scr_m68k_sx16(scr_m68k_fetch16(_c))) & $FFFFFFFF;
                    _c.ea_index = 9;
                    return;
                case 3:
                    _c.ea_kind = 2;
                    _c.ea_addr = scr_m68k_ea_indexed(_c, _c.pc);
                    _c.ea_index = 10;
                    return;
                case 4:
                    _c.ea_kind = 3;
                    if (_size == 4) _c.ea_val = scr_m68k_fetch32(_c);
                    else _c.ea_val = scr_m68k_fetch16(_c) & scr_m68k_mask(_size);
                    _c.ea_index = 11;
                    return;
            }
            break;
    }
    scr_m68k_illegal(_c);
}

/// Brief extension word: base + d8 + Xn.W / Xn.L.
function scr_m68k_ea_indexed(_c, _base) {
    var _ext = scr_m68k_fetch16(_c);
    var _xr = (_ext >> 12) & 7;
    var _x = (_ext & $8000) != 0 ? _c.a[_xr] : _c.d[_xr];
    _x = (_ext & $0800) != 0 ? scr_m68k_sx32(_x) : scr_m68k_sx16(_x);
    if (_c.model >= 2) {
        if ((_ext & $0100) != 0) scr_m68k_illegal(_c);   // 68020 full extension format: not yet
        _x = _x * (1 << ((_ext >> 9) & 3));
    }
    return (_base + _x + scr_m68k_sx8(_ext)) & $FFFFFFFF;
}

/// An operand that is read (source or read-modify-write): decode and add its time.
function scr_m68k_ea(_c, _mode, _reg, _size) {
    scr_m68k_ea_calc(_c, _mode, _reg, _size);
    _c.cycles += _size == 4 ? global.m68k_ea_time_l[_c.ea_index] : global.m68k_ea_time_bw[_c.ea_index];
}

/// A MOVE destination: no PC-relative or immediate, -(An) costs the same as (An).
function scr_m68k_ea_dst(_c, _mode, _reg, _size) {
    if (_mode == 7 && _reg >= 2) scr_m68k_illegal(_c);
    scr_m68k_ea_calc(_c, _mode, _reg, _size);
    var _i = _c.ea_index == 4 ? 2 : _c.ea_index;
    _c.cycles += _size == 4 ? global.m68k_ea_time_l[_i] : global.m68k_ea_time_bw[_i];
}

/// A control address (LEA, PEA, JMP, JSR, MOVEM): returns it; time is up to the caller.
function scr_m68k_ea_control(_c, _mode, _reg) {
    if (_mode < 2 || _mode == 3 || _mode == 4 || (_mode == 7 && _reg >= 4)) scr_m68k_illegal(_c);
    scr_m68k_ea_calc(_c, _mode, _reg, 4);
    return _c.ea_addr;
}

function scr_m68k_ea_read(_c, _size) {
    switch (_c.ea_kind) {
        case 0: return _c.d[_c.ea_reg] & scr_m68k_mask(_size);
        case 1: return _c.a[_c.ea_reg] & scr_m68k_mask(_size);
        case 2: return scr_m68k_read(_c, _c.ea_addr, _size);
    }
    return _c.ea_val;
}

function scr_m68k_ea_write(_c, _size, _v) {
    switch (_c.ea_kind) {
        case 0: scr_m68k_set_d(_c, _c.ea_reg, _v, _size); return;
        case 1: _c.a[_c.ea_reg] = _v & $FFFFFFFF; return;
        case 2: scr_m68k_write(_c, _c.ea_addr, _size, _v); return;
    }
    scr_m68k_illegal(_c);
}

/// Writes the low _size bytes of Dn, keeping the rest.
function scr_m68k_set_d(_c, _r, _v, _size) {
    var _m = scr_m68k_mask(_size);
    _c.d[_r] = ((_c.d[_r] & ~_m) | (_v & _m)) & $FFFFFFFF;
}

// ---------------------------------------------------------------- flags

/// N and Z from the result, V and C cleared, X kept (MOVE, AND, OR, EOR, NOT, TST ...).
function scr_m68k_logic_flags(_c, _r, _size) {
    var _sr = _c.sr & ~$0F;
    if ((_r & scr_m68k_msb(_size)) != 0) _sr |= M68K_N;
    if ((_r & scr_m68k_mask(_size)) == 0) _sr |= M68K_Z;
    _c.sr = _sr & $FFFF;
}

/// _d + _s (+ _x). _kind 0 = ADD (all flags), 1 = ADDX (Z only cleared).
function scr_m68k_add(_c, _s, _d, _size, _x, _kind) {
    var _m = scr_m68k_mask(_size);
    var _msb = scr_m68k_msb(_size);
    _s = _s & _m;
    _d = _d & _m;
    var _full = _s + _d + _x;
    var _r = _full & _m;
    var _sr = _c.sr & ~$1F;
    if (_full > _m) _sr |= M68K_C | M68K_X;
    if (((_s ^ _r) & (_d ^ _r) & _msb) != 0) _sr |= M68K_V;
    if ((_r & _msb) != 0) _sr |= M68K_N;
    if (_r == 0 && (_kind == 0 || (_c.sr & M68K_Z) != 0)) _sr |= M68K_Z;
    _c.sr = _sr & $FFFF;
    return _r;
}

/// _d - _s (- _x). _kind 0 = SUB, 1 = SUBX (Z only cleared), 2 = CMP (X kept).
function scr_m68k_sub(_c, _s, _d, _size, _x, _kind) {
    var _m = scr_m68k_mask(_size);
    var _msb = scr_m68k_msb(_size);
    _s = _s & _m;
    _d = _d & _m;
    var _full = _d - _s - _x;
    var _r = _full & _m;
    var _sr = _kind == 2 ? (_c.sr & ~$0F) : (_c.sr & ~$1F);
    if (_full < 0) _sr |= _kind == 2 ? M68K_C : (M68K_C | M68K_X);
    if (((_s ^ _d) & (_r ^ _d) & _msb) != 0) _sr |= M68K_V;
    if ((_r & _msb) != 0) _sr |= M68K_N;
    if (_r == 0 && (_kind != 1 || (_c.sr & M68K_Z) != 0)) _sr |= M68K_Z;
    _c.sr = _sr & $FFFF;
    return _r;
}

/// Condition code test (T F HI LS CC CS NE EQ VC VS PL MI GE LT GT LE).
function scr_m68k_cond(_c, _cc) {
    var _sr = _c.sr;
    var _cf = (_sr & M68K_C) != 0;
    var _vf = (_sr & M68K_V) != 0;
    var _zf = (_sr & M68K_Z) != 0;
    var _nf = (_sr & M68K_N) != 0;
    switch (_cc) {
        case 0: return true;
        case 1: return false;
        case 2: return !_cf && !_zf;
        case 3: return _cf || _zf;
        case 4: return !_cf;
        case 5: return _cf;
        case 6: return !_zf;
        case 7: return _zf;
        case 8: return !_vf;
        case 9: return _vf;
        case 10: return !_nf;
        case 11: return _nf;
        case 12: return _nf == _vf;
        case 13: return _nf != _vf;
        case 14: return !_zf && _nf == _vf;
        case 15: return _zf || _nf != _vf;
    }
    return false;
}

/// Sets SR, swapping A7 between the user and supervisor stacks when S changes.
function scr_m68k_set_sr(_c, _v) {
    _v = _v & (_c.model >= 2 ? $F71F : $A71F);
    var _was = (_c.sr & $2000) != 0;
    var _now = (_v & $2000) != 0;
    if (_was != _now) {
        if (_was) {
            _c.ssp = _c.a[7];
            _c.a[7] = _c.usp;
        } else {
            _c.usp = _c.a[7];
            _c.a[7] = _c.ssp;
        }
    }
    _c.sr = _v;
}

// ---------------------------------------------------------------- exceptions

function scr_m68k_vector_name(_vec) {
    switch (_vec) {
        case 2: return "Bus error";
        case 3: return "Address error";
        case 4: return "Illegal instruction";
        case 5: return "Divide by zero";
        case 6: return "CHK out of bounds";
        case 7: return "TRAPV with overflow set";
        case 8: return "Privilege violation";
        case 9: return "Trace";
        case 10: return "Line A instruction";
        case 11: return "Line F instruction";
        case 24: return "Spurious interrupt";
    }
    if (_vec >= 25 && _vec <= 31) return "Level " + string(_vec - 24) + " interrupt";
    if (_vec >= 32 && _vec <= 47) return "TRAP #" + string(_vec - 32);
    return "Exception " + string(_vec);
}

/// Takes exception _vec: pushes the frame and jumps to the vector. _info is
/// the bus / address error struct (or undefined), _level an interrupt level.
/// A vector that is still 0 (or odd) stops the run with a message.
function scr_m68k_exception(_c, _vec, _info = undefined, _level = -1) {
    var _vaddr = (_c.vbr + _vec * 4) & $FFFFFFFF;
    var _handler = scr_m68k_peek(_c, _vaddr, 4);
    if (_handler == 0 || (_handler & 1) != 0) {
        var _what = scr_m68k_vector_name(_vec);
        if (_vec == 2 || _vec == 3) {
            if (is_struct(_info) && _info.fetch && _vec == 3) _what += ": the PC is odd ($" + scr_m68k_hex(_info.address, 6) + ")";
            else if (is_struct(_info) && _vec == 3) _what += ": " + (_info.write ? "write to" : "read from") + " odd address $" + scr_m68k_hex(_info.address, 6);
            else if (is_struct(_info)) _what += ": nothing at $" + scr_m68k_hex(_info.address, 6);
        }
        _c.status = "exception";
        _c.fault = { vector : _vec, pc : _c.op_pc, address : is_struct(_info) ? _info.address : 0 };
        _c.message = _what + " at $" + scr_m68k_hex(_c.op_pc, 6) + " (no handler in vector " + string(_vec) + " at $" + scr_m68k_hex(_vaddr, 3) + ")";
        _c.pc = _c.op_pc;
        return;
    }
    var _old_sr = _c.sr;
    try {
        scr_m68k_set_sr(_c, (_c.sr | $2000) & ~$C000);
        if (_level >= 0) _c.sr = (_c.sr & ~$0700) | (_level << 8);
        if (_c.model >= 1) scr_m68k_push16(_c, _vec * 4);
        scr_m68k_push32(_c, _c.pc);
        scr_m68k_push16(_c, _old_sr);
        if (_c.model == 0 && (_vec == 2 || _vec == 3) && is_struct(_info)) {
            // 68000 group 0 frame: access address, instruction, R/W + I/N + function code
            scr_m68k_push16(_c, _c.ir);
            scr_m68k_push32(_c, _info.address);
            var _fc = ((_old_sr & $2000) != 0 ? 4 : 0) | (_info.fetch ? 2 : 1);
            scr_m68k_push16(_c, (_info.write ? 0 : $10) | (_info.fetch ? 0 : 8) | _fc);
        }
    } catch (_e) {
        if (!is_struct(_e) || !variable_struct_exists(_e, "m68k_vector")) throw _e;
        _c.status = "exception";
        _c.fault = { vector : _vec, pc : _c.op_pc, address : _e.address };
        _c.message = "Double fault: " + scr_m68k_vector_name(_e.m68k_vector) + " while stacking a " + scr_m68k_vector_name(_vec) + " (A7 = $" + scr_m68k_hex(_c.a[7], 8) + ")";
        return;
    }
    _c.pc = _handler;
    _c.stopped = false;
    switch (_vec) {
        case 2: case 3: _c.cycles += 50; break;
        case 5: _c.cycles += 38; break;
        case 6: _c.cycles += 40; break;
        default: _c.cycles += _level >= 0 ? 44 : 34; break;
    }
}

// ---------------------------------------------------------------- one instruction

/// Runs one instruction (or takes a pending interrupt); returns the status.
function scr_m68k_step(_c) {
    if (_c.status != "running") return _c.status;
    if (_c.pc == _c.stop_pc && !_c.stopped) {
        _c.status = "done";
        return _c.status;
    }
    var _level = scr_m68k_hw_irq_level(_c);
    if (_level > 0 && (_level == 7 || _level > ((_c.sr >> 8) & 7))) {
        _c.op_pc = _c.pc;
        scr_m68k_exception(_c, 24 + _level, undefined, _level);
        scr_m68k_hw_tick(_c);
        return _c.status;
    }
    if (_c.stopped) {
        if (scr_m68k_hw_can_wake(_c)) {
            _c.cycles = (_c.frame + 1) * M68K_FRAME_CYCLES;
            scr_m68k_hw_tick(_c);
        } else {
            _c.status = "stopped";
            _c.message = "STOP with no interrupt enabled to wake the CPU";
        }
        return _c.status;
    }
    _c.op_pc = _c.pc;
    var _trace = (_c.sr & $8000) != 0;
    try {
        var _op = scr_m68k_fetch16(_c);
        _c.ir = _op;
        switch (_op >> 12) {
            case 0: scr_m68k_op_0(_c, _op); break;
            case 1: case 2: case 3: scr_m68k_op_move(_c, _op); break;
            case 4: scr_m68k_op_4(_c, _op); break;
            case 5: scr_m68k_op_5(_c, _op); break;
            case 6: scr_m68k_op_6(_c, _op); break;
            case 7:
                if ((_op & $0100) != 0) scr_m68k_illegal(_c);
                var _q = scr_m68k_sx8(_op) & $FFFFFFFF;
                _c.d[(_op >> 9) & 7] = _q;
                scr_m68k_logic_flags(_c, _q, 4);
                _c.cycles += 4;
                break;
            case 8: scr_m68k_op_8(_c, _op); break;
            case 9: scr_m68k_op_addsub(_c, _op, true); break;
            case 10: throw { m68k_vector : 10, address : _c.op_pc, write : false, fetch : true };
            case 11: scr_m68k_op_b(_c, _op); break;
            case 12: scr_m68k_op_c(_c, _op); break;
            case 13: scr_m68k_op_addsub(_c, _op, false); break;
            case 14: scr_m68k_op_e(_c, _op); break;
            case 15: throw { m68k_vector : 11, address : _c.op_pc, write : false, fetch : true };
        }
    } catch (_e) {
        if (!is_struct(_e) || !variable_struct_exists(_e, "m68k_vector")) {
            _c.status = "error";
            _c.message = "Simulator error at $" + scr_m68k_hex(_c.op_pc, 6) + " (opcode $" + scr_m68k_hex(_c.ir, 4) + "): " + (is_struct(_e) && variable_struct_exists(_e, "message") ? _e.message : string(_e));
            return _c.status;
        }
        var _v = _e.m68k_vector;
        // Faults point back at the instruction; traps return after it.
        if (_v == 4 || _v == 8 || _v == 10 || _v == 11) _c.pc = _c.op_pc;
        scr_m68k_exception(_c, _v, _e);
        _trace = false;
    }
    _c.instructions += 1;
    if (_trace && _c.status == "running") scr_m68k_exception(_c, 9);
    scr_m68k_hw_tick(_c);
    if (_c.status == "running" && _c.pc == _c.stop_pc && !_c.stopped) _c.status = "done";
    return _c.status;
}

// ---------------------------------------------------------------- line 0: immediates, bits, MOVEP

function scr_m68k_op_0(_c, _op) {
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    if ((_op & $0100) != 0) {
        if (_mode == 1) {
            scr_m68k_op_movep(_c, _op);
            return;
        }
        scr_m68k_op_bit(_c, _op, _c.d[(_op >> 9) & 7], false);
        return;
    }
    var _kind = (_op >> 9) & 7;
    if (_kind == 4) {
        scr_m68k_op_bit(_c, _op, scr_m68k_fetch16(_c) & $FF, true);
        return;
    }
    if (_kind == 7) scr_m68k_illegal(_c);
    var _sz = (_op >> 6) & 3;
    if ((_kind == 0 || _kind == 1 || _kind == 5) && (_op & $3F) == $3C) {
        // ORI / ANDI / EORI to CCR (byte) or SR (word, supervisor only)
        if (_sz == 0) {
            var _ib = scr_m68k_fetch16(_c) & $FF;
            var _ccr = _c.sr & $FF;
            _ccr = _kind == 0 ? (_ccr | _ib) : (_kind == 1 ? (_ccr & _ib) : (_ccr ^ _ib));
            _c.sr = (_c.sr & $FF00) | (_ccr & $1F);
            _c.cycles += 20;
            return;
        }
        if (_sz == 1) {
            scr_m68k_need_super(_c);
            var _iw = scr_m68k_fetch16(_c);
            scr_m68k_set_sr(_c, _kind == 0 ? (_c.sr | _iw) : (_kind == 1 ? (_c.sr & _iw) : (_c.sr ^ _iw)));
            _c.cycles += 20;
            return;
        }
    }
    if (_sz == 3) scr_m68k_illegal(_c);
    var _size = 1 << _sz;
    var _imm = _size == 4 ? scr_m68k_fetch32(_c) : (scr_m68k_fetch16(_c) & scr_m68k_mask(_size));
    scr_m68k_ea(_c, _mode, _reg, _size);
    var _dst = scr_m68k_ea_read(_c, _size);
    var _r = 0;
    switch (_kind) {
        case 0:
            _r = _dst | _imm;
            scr_m68k_logic_flags(_c, _r, _size);
            break;
        case 1:
            _r = _dst & _imm;
            scr_m68k_logic_flags(_c, _r, _size);
            break;
        case 2:
            _r = scr_m68k_sub(_c, _imm, _dst, _size, 0, 0);
            break;
        case 3:
            _r = scr_m68k_add(_c, _imm, _dst, _size, 0, 0);
            break;
        case 5:
            _r = _dst ^ _imm;
            scr_m68k_logic_flags(_c, _r, _size);
            break;
        case 6:
            scr_m68k_sub(_c, _imm, _dst, _size, 0, 2);
            _c.cycles += _mode == 0 ? (_size == 4 ? 14 : 8) : (_size == 4 ? 12 : 8);
            return;
    }
    scr_m68k_ea_write(_c, _size, _r);
    _c.cycles += _mode == 0 ? (_size == 4 ? 16 : 8) : (_size == 4 ? 20 : 12);
}

/// BTST / BCHG / BCLR / BSET: bit _bit of a data register (mod 32) or a memory byte (mod 8).
function scr_m68k_op_bit(_c, _op, _bit, _static) {
    var _type = (_op >> 6) & 3;
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    var _v, _m;
    if (_mode == 0) {
        _m = 1 << (_bit & 31);
        _v = _c.d[_reg];
        _c.sr = (_v & _m) == 0 ? (_c.sr | M68K_Z) : (_c.sr & ~M68K_Z);
        if (_type == 1) _c.d[_reg] = (_v ^ _m) & $FFFFFFFF;
        else if (_type == 2) _c.d[_reg] = (_v & ~_m) & $FFFFFFFF;
        else if (_type == 3) _c.d[_reg] = (_v | _m) & $FFFFFFFF;
        _c.cycles += (_type == 0 ? 6 : (_type == 2 ? 10 : 8)) + (_static ? 4 : 0);
        return;
    }
    _m = 1 << (_bit & 7);
    scr_m68k_ea(_c, _mode, _reg, 1);
    _v = scr_m68k_ea_read(_c, 1);
    _c.sr = (_v & _m) == 0 ? (_c.sr | M68K_Z) : (_c.sr & ~M68K_Z);
    if (_type == 1) scr_m68k_ea_write(_c, 1, _v ^ _m);
    else if (_type == 2) scr_m68k_ea_write(_c, 1, _v & ~_m);
    else if (_type == 3) scr_m68k_ea_write(_c, 1, _v | _m);
    _c.cycles += (_type == 0 ? 4 : 8) + (_static ? 4 : 0);
}

/// MOVEP: every other byte, for 8-bit peripherals (the CIAs).
function scr_m68k_op_movep(_c, _op) {
    var _dr = (_op >> 9) & 7;
    var _addr = (_c.a[_op & 7] + scr_m68k_sx16(scr_m68k_fetch16(_c))) & $FFFFFFFF;
    var _v;
    switch ((_op >> 6) & 7) {
        case 4:
            _v = (scr_m68k_rb(_c, _addr) << 8) | scr_m68k_rb(_c, _addr + 2);
            scr_m68k_set_d(_c, _dr, _v, 2);
            _c.cycles += 16;
            break;
        case 5:
            _v = (scr_m68k_rb(_c, _addr) << 24) | (scr_m68k_rb(_c, _addr + 2) << 16) | (scr_m68k_rb(_c, _addr + 4) << 8) | scr_m68k_rb(_c, _addr + 6);
            _c.d[_dr] = _v & $FFFFFFFF;
            _c.cycles += 24;
            break;
        case 6:
            _v = _c.d[_dr];
            scr_m68k_wb(_c, _addr, _v >> 8);
            scr_m68k_wb(_c, _addr + 2, _v);
            _c.cycles += 16;
            break;
        case 7:
            _v = _c.d[_dr];
            scr_m68k_wb(_c, _addr, _v >> 24);
            scr_m68k_wb(_c, _addr + 2, _v >> 16);
            scr_m68k_wb(_c, _addr + 4, _v >> 8);
            scr_m68k_wb(_c, _addr + 6, _v);
            _c.cycles += 24;
            break;
    }
}

// ---------------------------------------------------------------- lines 1-3: MOVE / MOVEA

function scr_m68k_op_move(_c, _op) {
    var _line = _op >> 12;
    var _size = _line == 1 ? 1 : (_line == 3 ? 2 : 4);
    var _dmode = (_op >> 6) & 7;
    var _dreg = (_op >> 9) & 7;
    scr_m68k_ea(_c, (_op >> 3) & 7, _op & 7, _size);
    var _v = scr_m68k_ea_read(_c, _size);
    _c.cycles += 4;
    if (_dmode == 1) {
        if (_size == 1) scr_m68k_illegal(_c);
        _c.a[_dreg] = _size == 2 ? (scr_m68k_sx16(_v) & $FFFFFFFF) : _v;
        return;
    }
    scr_m68k_ea_dst(_c, _dmode, _dreg, _size);
    scr_m68k_ea_write(_c, _size, _v);
    scr_m68k_logic_flags(_c, _v, _size);
}

// ---------------------------------------------------------------- line 4: miscellaneous

function scr_m68k_op_4(_c, _op) {
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    var _v, _addr, _size;
    switch (_op) {
        case $4AFC:
            scr_m68k_illegal(_c);
            return;
        case $4E70:     // RESET: resets the external hardware
            scr_m68k_need_super(_c);
            _c.cycles += 132;
            return;
        case $4E71:     // NOP
            _c.cycles += 4;
            return;
        case $4E72:     // STOP #sr
            scr_m68k_need_super(_c);
            _v = scr_m68k_fetch16(_c);
            scr_m68k_set_sr(_c, _v);
            _c.stopped = true;
            _c.cycles += 4;
            return;
        case $4E73:     // RTE
            scr_m68k_need_super(_c);
            _v = scr_m68k_pop16(_c);
            _addr = scr_m68k_pop32(_c);
            if (_c.model >= 1) scr_m68k_pop16(_c);
            scr_m68k_set_sr(_c, _v);
            _c.pc = _addr;
            _c.cycles += 20;
            return;
        case $4E74:     // RTD (68010+)
            if (_c.model < 1) scr_m68k_illegal(_c);
            _v = scr_m68k_sx16(scr_m68k_fetch16(_c));
            _c.pc = scr_m68k_pop32(_c);
            _c.a[7] = (_c.a[7] + _v) & $FFFFFFFF;
            _c.cycles += 16;
            return;
        case $4E75:     // RTS
            _c.pc = scr_m68k_pop32(_c);
            _c.cycles += 16;
            return;
        case $4E76:     // TRAPV
            _c.cycles += 4;
            if ((_c.sr & M68K_V) != 0) scr_m68k_throw(7);
            return;
        case $4E77:     // RTR
            _v = scr_m68k_pop16(_c);
            _c.pc = scr_m68k_pop32(_c);
            _c.sr = (_c.sr & $FF00) | (_v & $1F);
            _c.cycles += 20;
            return;
    }
    if ((_op & $FFF0) == $4E40) {       // TRAP #n
        scr_m68k_throw(32 + (_op & 15));
        return;
    }
    if ((_op & $FFF8) == $4E50) {       // LINK An,#d16
        _v = scr_m68k_sx16(scr_m68k_fetch16(_c));
        scr_m68k_push32(_c, _c.a[_reg]);
        _c.a[_reg] = _c.a[7];
        _c.a[7] = (_c.a[7] + _v) & $FFFFFFFF;
        _c.cycles += 16;
        return;
    }
    if ((_op & $FFF8) == $4E58) {       // UNLK An
        _c.a[7] = _c.a[_reg];
        _c.a[_reg] = scr_m68k_pop32(_c);
        _c.cycles += 12;
        return;
    }
    if ((_op & $FFF8) == $4E60) {       // MOVE An,USP
        scr_m68k_need_super(_c);
        _c.usp = _c.a[_reg];
        _c.cycles += 4;
        return;
    }
    if ((_op & $FFF8) == $4E68) {       // MOVE USP,An
        scr_m68k_need_super(_c);
        _c.a[_reg] = _c.usp;
        _c.cycles += 4;
        return;
    }
    if ((_op & $FFC0) == $4E80) {       // JSR
        _addr = scr_m68k_ea_control(_c, _mode, _reg);
        scr_m68k_push32(_c, _c.pc);
        _c.pc = _addr;
        _c.cycles += global.m68k_lea_time[_c.ea_index] + 12;
        return;
    }
    if ((_op & $FFC0) == $4EC0) {       // JMP
        _addr = scr_m68k_ea_control(_c, _mode, _reg);
        _c.pc = _addr;
        _c.cycles += global.m68k_lea_time[_c.ea_index] + 4;
        return;
    }
    if ((_op & $FFF8) == $4840) {       // SWAP
        _v = _c.d[_reg];
        _v = ((_v << 16) | (_v >> 16)) & $FFFFFFFF;
        _c.d[_reg] = _v;
        scr_m68k_logic_flags(_c, _v, 4);
        _c.cycles += 4;
        return;
    }
    if ((_op & $FFC0) == $4840) {       // PEA
        if (_mode < 2) scr_m68k_illegal(_c);
        _addr = scr_m68k_ea_control(_c, _mode, _reg);
        scr_m68k_push32(_c, _addr);
        _c.cycles += global.m68k_lea_time[_c.ea_index] + 8;
        return;
    }
    if ((_op & $FFF8) == $4880) {       // EXT.W
        _v = scr_m68k_sx8(_c.d[_reg]) & $FFFF;
        scr_m68k_set_d(_c, _reg, _v, 2);
        scr_m68k_logic_flags(_c, _v, 2);
        _c.cycles += 4;
        return;
    }
    if ((_op & $FFF8) == $48C0) {       // EXT.L
        _v = scr_m68k_sx16(_c.d[_reg]) & $FFFFFFFF;
        _c.d[_reg] = _v;
        scr_m68k_logic_flags(_c, _v, 4);
        _c.cycles += 4;
        return;
    }
    if ((_op & $FFF8) == $49C0 && _c.model >= 2) {  // EXTB.L
        _v = scr_m68k_sx8(_c.d[_reg]) & $FFFFFFFF;
        _c.d[_reg] = _v;
        scr_m68k_logic_flags(_c, _v, 4);
        _c.cycles += 4;
        return;
    }
    if ((_op & $FFC0) == $4C00 && _c.model >= 2) {  // MULU.L / MULS.L
        scr_m68k_op_mull(_c, _op);
        return;
    }
    if ((_op & $FFC0) == $4C40 && _c.model >= 2) {  // DIVU.L / DIVS.L
        scr_m68k_op_divl(_c, _op);
        return;
    }
    if ((_op & $FB80) == $4880 && _mode >= 2) {
        scr_m68k_op_movem(_c, _op);
        return;
    }
    if ((_op & $F1C0) == $41C0) {       // LEA
        _addr = scr_m68k_ea_control(_c, _mode, _reg);
        _c.a[(_op >> 9) & 7] = _addr;
        _c.cycles += global.m68k_lea_time[_c.ea_index];
        return;
    }
    if ((_op & $F1C0) == $4180) {       // CHK.W <ea>,Dn
        scr_m68k_ea(_c, _mode, _reg, 2);
        var _bound = scr_m68k_sx16(scr_m68k_ea_read(_c, 2));
        _v = scr_m68k_sx16(_c.d[(_op >> 9) & 7]);
        _c.cycles += 10;
        if (_v < 0) {
            _c.sr |= M68K_N;
            scr_m68k_throw(6);
        }
        if (_v > _bound) {
            _c.sr &= ~M68K_N;
            scr_m68k_throw(6);
        }
        return;
    }
    switch (_op & $FFC0) {
        case $40C0:     // MOVE SR,<ea> (privileged from the 68010 on)
            if (_c.model >= 1) scr_m68k_need_super(_c);
            scr_m68k_ea(_c, _mode, _reg, 2);
            scr_m68k_ea_write(_c, 2, _c.sr);
            _c.cycles += _mode == 0 ? 6 : 8;
            return;
        case $42C0:     // MOVE CCR,<ea> (68010+)
            if (_c.model < 1) scr_m68k_illegal(_c);
            scr_m68k_ea(_c, _mode, _reg, 2);
            scr_m68k_ea_write(_c, 2, _c.sr & $1F);
            _c.cycles += _mode == 0 ? 6 : 8;
            return;
        case $44C0:     // MOVE <ea>,CCR
            scr_m68k_ea(_c, _mode, _reg, 2);
            _v = scr_m68k_ea_read(_c, 2);
            _c.sr = (_c.sr & $FF00) | (_v & $1F);
            _c.cycles += 12;
            return;
        case $46C0:     // MOVE <ea>,SR
            scr_m68k_need_super(_c);
            scr_m68k_ea(_c, _mode, _reg, 2);
            scr_m68k_set_sr(_c, scr_m68k_ea_read(_c, 2));
            _c.cycles += 12;
            return;
        case $4AC0:     // TAS
            scr_m68k_ea(_c, _mode, _reg, 1);
            _v = scr_m68k_ea_read(_c, 1);
            scr_m68k_logic_flags(_c, _v, 1);
            scr_m68k_ea_write(_c, 1, _v | $80);
            _c.cycles += _mode == 0 ? 4 : 14;
            return;
        case $4800:     // NBCD
            if (_mode == 1) scr_m68k_illegal(_c);
            scr_m68k_ea(_c, _mode, _reg, 1);
            _v = scr_m68k_bcd_neg(_c, scr_m68k_ea_read(_c, 1));
            if (_v >= 0) scr_m68k_ea_write(_c, 1, _v);
            _c.cycles += _mode == 0 ? 6 : 8;
            return;
    }
    var _sz = (_op >> 6) & 3;
    if (_sz == 3) scr_m68k_illegal(_c);
    _size = 1 << _sz;
    var _long = _size == 4;
    switch (_op & $FF00) {
        case $4000:     // NEGX
            scr_m68k_ea(_c, _mode, _reg, _size);
            _v = scr_m68k_sub(_c, scr_m68k_ea_read(_c, _size), 0, _size, (_c.sr & M68K_X) != 0 ? 1 : 0, 1);
            scr_m68k_ea_write(_c, _size, _v);
            _c.cycles += _mode == 0 ? (_long ? 6 : 4) : (_long ? 12 : 8);
            return;
        case $4200:     // CLR
            scr_m68k_ea(_c, _mode, _reg, _size);
            scr_m68k_ea_write(_c, _size, 0);
            _c.sr = (_c.sr & ~$0F) | M68K_Z;
            _c.cycles += _mode == 0 ? (_long ? 6 : 4) : (_long ? 12 : 8);
            return;
        case $4400:     // NEG
            scr_m68k_ea(_c, _mode, _reg, _size);
            _v = scr_m68k_sub(_c, scr_m68k_ea_read(_c, _size), 0, _size, 0, 0);
            scr_m68k_ea_write(_c, _size, _v);
            _c.cycles += _mode == 0 ? (_long ? 6 : 4) : (_long ? 12 : 8);
            return;
        case $4600:     // NOT
            scr_m68k_ea(_c, _mode, _reg, _size);
            _v = ~scr_m68k_ea_read(_c, _size) & scr_m68k_mask(_size);
            scr_m68k_ea_write(_c, _size, _v);
            scr_m68k_logic_flags(_c, _v, _size);
            _c.cycles += _mode == 0 ? (_long ? 6 : 4) : (_long ? 12 : 8);
            return;
        case $4A00:     // TST
            if (_mode == 1 && _c.model < 2) scr_m68k_illegal(_c);
            scr_m68k_ea(_c, _mode, _reg, _size);
            scr_m68k_logic_flags(_c, scr_m68k_ea_read(_c, _size), _size);
            _c.cycles += 4;
            return;
    }
    scr_m68k_illegal(_c);
}

/// MOVEM: register mask word first, then the effective address.
function scr_m68k_op_movem(_c, _op) {
    var _size = (_op & $40) != 0 ? 4 : 2;
    var _to_regs = (_op & $0400) != 0;
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    var _list = scr_m68k_fetch16(_c);
    var _n = 0;
    var _addr, _i, _v;
    if (!_to_regs && _mode == 4) {
        // -(An): the mask is reversed (bit 0 = A7 ... bit 15 = D0)
        _addr = _c.a[_reg];
        for (_i = 0; _i < 16; _i += 1) {
            if ((_list & (1 << _i)) == 0) continue;
            var _r = 15 - _i;
            _addr = (_addr - _size) & $FFFFFFFF;
            scr_m68k_write(_c, _addr, _size, _r < 8 ? _c.d[_r] : _c.a[_r - 8]);
            _n += 1;
        }
        _c.a[_reg] = _addr;
        _c.cycles += 8 + _n * (_size == 4 ? 8 : 4);
        return;
    }
    if (_to_regs && _mode == 3) {
        _addr = _c.a[_reg];
    } else {
        if (_mode == 3 || _mode == 4) scr_m68k_illegal(_c);
        if (!_to_regs && _mode == 7 && _reg >= 2) scr_m68k_illegal(_c);
        _addr = scr_m68k_ea_control(_c, _mode, _reg);
        _c.cycles += global.m68k_lea_time[_c.ea_index];
    }
    for (_i = 0; _i < 16; _i += 1) {
        if ((_list & (1 << _i)) == 0) continue;
        if (_to_regs) {
            _v = _size == 2 ? (scr_m68k_sx16(scr_m68k_rw(_c, _addr)) & $FFFFFFFF) : scr_m68k_rl(_c, _addr);
            if (_i < 8) _c.d[_i] = _v;
            else _c.a[_i - 8] = _v;
        } else {
            scr_m68k_write(_c, _addr, _size, _i < 8 ? _c.d[_i] : _c.a[_i - 8]);
        }
        _addr = (_addr + _size) & $FFFFFFFF;
        _n += 1;
    }
    if (_to_regs && _mode == 3) _c.a[_reg] = _addr;
    _c.cycles += (_to_regs ? 12 : 8) + _n * (_size == 4 ? 8 : 4);
}

// ---------------------------------------------------------------- line 5: ADDQ / SUBQ / Scc / DBcc

function scr_m68k_op_5(_c, _op) {
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    if (((_op >> 6) & 3) == 3) {
        var _cc = (_op >> 8) & 15;
        if (_mode == 1) {               // DBcc Dn,label
            var _base = _c.pc;
            var _disp = scr_m68k_sx16(scr_m68k_fetch16(_c));
            if (scr_m68k_cond(_c, _cc)) {
                _c.cycles += 12;
                return;
            }
            var _w = (_c.d[_reg] - 1) & $FFFF;
            scr_m68k_set_d(_c, _reg, _w, 2);
            if (_w != $FFFF) {
                _c.pc = (_base + _disp) & $FFFFFFFF;
                _c.cycles += 10;
            } else {
                _c.cycles += 14;
            }
            return;
        }
        if (_mode == 7 && _reg >= 2) scr_m68k_illegal(_c);   // TRAPcc is 68020
        scr_m68k_ea(_c, _mode, _reg, 1);    // Scc
        var _t = scr_m68k_cond(_c, _cc);
        scr_m68k_ea_write(_c, 1, _t ? $FF : 0);
        _c.cycles += _mode == 0 ? (_t ? 6 : 4) : 8;
        return;
    }
    var _size = 1 << ((_op >> 6) & 3);
    var _q = (_op >> 9) & 7;
    if (_q == 0) _q = 8;
    var _sub = (_op & $0100) != 0;
    if (_mode == 1) {
        // An: the whole register, flags untouched
        if (_size == 1) scr_m68k_illegal(_c);
        _c.a[_reg] = (_c.a[_reg] + (_sub ? -_q : _q)) & $FFFFFFFF;
        _c.cycles += 8;
        return;
    }
    scr_m68k_ea(_c, _mode, _reg, _size);
    var _d = scr_m68k_ea_read(_c, _size);
    var _r = _sub ? scr_m68k_sub(_c, _q, _d, _size, 0, 0) : scr_m68k_add(_c, _q, _d, _size, 0, 0);
    scr_m68k_ea_write(_c, _size, _r);
    _c.cycles += _mode == 0 ? (_size == 4 ? 8 : 4) : (_size == 4 ? 12 : 8);
}

// ---------------------------------------------------------------- line 6: BRA / BSR / Bcc

function scr_m68k_op_6(_c, _op) {
    var _cc = (_op >> 8) & 15;
    var _base = _c.pc;
    var _disp = _op & $FF;
    var _short = true;
    if (_disp == 0) {
        _disp = scr_m68k_sx16(scr_m68k_fetch16(_c));
        _short = false;
    } else if (_disp == $FF && _c.model >= 2) {
        _disp = scr_m68k_sx32(scr_m68k_fetch32(_c));
        _short = false;
    } else {
        _disp = scr_m68k_sx8(_disp);
    }
    if (_cc == 1) {
        scr_m68k_push32(_c, _c.pc);
        _c.pc = (_base + _disp) & $FFFFFFFF;
        _c.cycles += 18;
        return;
    }
    if (_cc == 0 || scr_m68k_cond(_c, _cc)) {
        _c.pc = (_base + _disp) & $FFFFFFFF;
        _c.cycles += 10;
    } else {
        _c.cycles += _short ? 8 : 12;
    }
}

// ---------------------------------------------------------------- shared ALU (OR AND ADD SUB CMP EOR)

/// _fn: 0 OR, 1 AND, 2 ADD, 3 SUB, 4 CMP, 5 EOR. Bit 8 of the opcode: Dn,<ea> instead of <ea>,Dn.
function scr_m68k_alu(_c, _op, _fn) {
    var _dr = (_op >> 9) & 7;
    var _size = 1 << ((_op >> 6) & 3);
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    var _to_ea = (_op & $0100) != 0 && _fn != 4;
    scr_m68k_ea(_c, _mode, _reg, _size);
    var _e = scr_m68k_ea_read(_c, _size);
    var _dn = _c.d[_dr] & scr_m68k_mask(_size);
    var _src = _to_ea ? _dn : _e;
    var _dst = _to_ea ? _e : _dn;
    var _r = 0;
    switch (_fn) {
        case 0:
            _r = _src | _dst;
            scr_m68k_logic_flags(_c, _r, _size);
            break;
        case 1:
            _r = _src & _dst;
            scr_m68k_logic_flags(_c, _r, _size);
            break;
        case 5:
            _r = _src ^ _dst;
            scr_m68k_logic_flags(_c, _r, _size);
            break;
        case 2:
            _r = scr_m68k_add(_c, _src, _dst, _size, 0, 0);
            break;
        case 3:
            _r = scr_m68k_sub(_c, _src, _dst, _size, 0, 0);
            break;
        case 4:
            scr_m68k_sub(_c, _src, _dst, _size, 0, 2);
            _c.cycles += _size == 4 ? 6 : 4;
            return;
    }
    if (_to_ea) {
        scr_m68k_ea_write(_c, _size, _r);
        _c.cycles += _mode == 0 ? (_size == 4 ? 8 : 4) : (_size == 4 ? 12 : 8);
    } else {
        scr_m68k_set_d(_c, _dr, _r, _size);
        _c.cycles += _size == 4 ? ((_mode <= 1 || (_mode == 7 && _reg == 4)) ? 8 : 6) : 4;
    }
}

// ---------------------------------------------------------------- line 8: OR / DIVU / DIVS / SBCD

function scr_m68k_op_8(_c, _op) {
    var _opm = (_op >> 6) & 7;
    var _mode = (_op >> 3) & 7;
    if (_opm == 3 || _opm == 7) {
        scr_m68k_op_div(_c, _op, _opm == 7);
        return;
    }
    if (_opm == 4 && _mode <= 1) {
        scr_m68k_op_bcd(_c, _op, false);
        return;
    }
    if (_opm >= 5 && _mode <= 1) scr_m68k_illegal(_c);   // PACK / UNPK are 68020
    scr_m68k_alu(_c, _op, 0);
}

/// DIVU.W / DIVS.W <ea>,Dn: 32 / 16 -> remainder : quotient.
function scr_m68k_op_div(_c, _op, _signed) {
    var _dr = (_op >> 9) & 7;
    scr_m68k_ea(_c, (_op >> 3) & 7, _op & 7, 2);
    var _s = scr_m68k_ea_read(_c, 2);
    if (_s == 0) {
        _c.sr &= ~M68K_C;
        scr_m68k_throw(5);
    }
    var _d = _c.d[_dr];
    var _q, _r;
    if (_signed) {
        _s = scr_m68k_sx16(_s);
        _d = scr_m68k_sx32(_d);
        _q = (abs(_d) div abs(_s)) * sign(_d) * sign(_s);
        _r = _d - _q * _s;
        _c.cycles += 158;
        if (_q < -32768 || _q > 32767) {
            _c.sr = (_c.sr & ~M68K_C) | M68K_V | M68K_N;
            return;
        }
    } else {
        _q = _d div _s;
        _r = _d - _q * _s;
        _c.cycles += 140;
        if (_q > $FFFF) {
            _c.sr = (_c.sr & ~M68K_C) | M68K_V | M68K_N;
            return;
        }
    }
    _c.d[_dr] = (((_r & $FFFF) << 16) | (_q & $FFFF)) & $FFFFFFFF;
    scr_m68k_logic_flags(_c, _q, 2);
}

// ---------------------------------------------------------------- BCD

/// ABCD / SBCD Dy,Dx or -(Ay),-(Ax).
function scr_m68k_op_bcd(_c, _op, _add) {
    var _rx = (_op >> 9) & 7;
    var _ry = _op & 7;
    var _mem = (_op & 8) != 0;
    var _s, _d, _addr = 0;
    if (_mem) {
        _c.a[_ry] = (_c.a[_ry] - (_ry == 7 ? 2 : 1)) & $FFFFFFFF;
        _s = scr_m68k_rb(_c, _c.a[_ry]);
        _c.a[_rx] = (_c.a[_rx] - (_rx == 7 ? 2 : 1)) & $FFFFFFFF;
        _addr = _c.a[_rx];
        _d = scr_m68k_rb(_c, _addr);
    } else {
        _s = _c.d[_ry] & $FF;
        _d = _c.d[_rx] & $FF;
    }
    var _x = (_c.sr & M68K_X) != 0 ? 1 : 0;
    var _res, _v, _carry;
    if (_add) {
        _res = (_s & $0F) + (_d & $0F) + _x;
        _v = ~_res;
        if (_res > 9) _res += 6;
        _res += (_s & $F0) + (_d & $F0);
        _carry = _res > $99;
        if (_carry) _res -= $A0;
    } else {
        _res = (_d & $0F) - (_s & $0F) - _x;
        _v = ~_res;
        if (_res > 9 || _res < 0) _res -= 6;
        _res += (_d & $F0) - (_s & $F0);
        _carry = _res > $99 || _res < 0;
        if (_carry) _res += $A0;
    }
    _res = _res & $FF;
    _v = _v & _res;
    var _sr = _c.sr & ~(M68K_X | M68K_N | M68K_V | M68K_C);
    if (_carry) _sr |= M68K_X | M68K_C;
    if ((_v & $80) != 0) _sr |= M68K_V;
    if ((_res & $80) != 0) _sr |= M68K_N;
    if (_res != 0) _sr &= ~M68K_Z;
    _c.sr = _sr;
    if (_mem) {
        scr_m68k_wb(_c, _addr, _res);
        _c.cycles += 18;
    } else {
        scr_m68k_set_d(_c, _rx, _res, 1);
        _c.cycles += 6;
    }
}

/// NBCD: 0 - _d - X in BCD; returns the byte to write, or -1 when it stays 0.
function scr_m68k_bcd_neg(_c, _d) {
    var _x = (_c.sr & M68K_X) != 0 ? 1 : 0;
    var _res = ($9A - _d - _x) & $FF;
    var _sr = _c.sr & ~(M68K_X | M68K_N | M68K_V | M68K_C);
    if (_res == $9A) {
        _c.sr = _sr;
        return -1;
    }
    var _v = ~_res;
    if ((_res & $0F) == $0A) _res = (_res & $F0) + $10;
    _res = _res & $FF;
    _v = _v & _res;
    _sr |= M68K_X | M68K_C;
    if ((_v & $80) != 0) _sr |= M68K_V;
    if ((_res & $80) != 0) _sr |= M68K_N;
    if (_res != 0) _sr &= ~M68K_Z;
    _c.sr = _sr;
    return _res;
}

// ---------------------------------------------------------------- lines 9 / D: SUB / ADD

function scr_m68k_op_addsub(_c, _op, _sub) {
    var _opm = (_op >> 6) & 7;
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    var _size, _v;
    if (_opm == 3 || _opm == 7) {       // ADDA / SUBA: whole register, no flags
        _size = _opm == 3 ? 2 : 4;
        scr_m68k_ea(_c, _mode, _reg, _size);
        _v = scr_m68k_ea_read(_c, _size);
        if (_size == 2) _v = scr_m68k_sx16(_v);
        var _ar = (_op >> 9) & 7;
        _c.a[_ar] = (_c.a[_ar] + (_sub ? -_v : _v)) & $FFFFFFFF;
        _c.cycles += _size == 2 ? 8 : ((_mode <= 1 || (_mode == 7 && _reg == 4)) ? 8 : 6);
        return;
    }
    if (_opm >= 4 && _mode <= 1) {      // ADDX / SUBX
        _size = 1 << (_opm & 3);
        var _rx = (_op >> 9) & 7;
        var _x = (_c.sr & M68K_X) != 0 ? 1 : 0;
        if (_mode == 0) {
            _v = _sub ? scr_m68k_sub(_c, _c.d[_reg], _c.d[_rx], _size, _x, 1) : scr_m68k_add(_c, _c.d[_reg], _c.d[_rx], _size, _x, 1);
            scr_m68k_set_d(_c, _rx, _v, _size);
            _c.cycles += _size == 4 ? 8 : 4;
        } else {
            _c.a[_reg] = (_c.a[_reg] - ((_reg == 7 && _size == 1) ? 2 : _size)) & $FFFFFFFF;
            var _s = scr_m68k_read(_c, _c.a[_reg], _size);
            _c.a[_rx] = (_c.a[_rx] - ((_rx == 7 && _size == 1) ? 2 : _size)) & $FFFFFFFF;
            var _d = scr_m68k_read(_c, _c.a[_rx], _size);
            _v = _sub ? scr_m68k_sub(_c, _s, _d, _size, _x, 1) : scr_m68k_add(_c, _s, _d, _size, _x, 1);
            scr_m68k_write(_c, _c.a[_rx], _size, _v);
            _c.cycles += _size == 4 ? 30 : 18;
        }
        return;
    }
    scr_m68k_alu(_c, _op, _sub ? 3 : 2);
}

// ---------------------------------------------------------------- line B: CMP / CMPA / CMPM / EOR

function scr_m68k_op_b(_c, _op) {
    var _opm = (_op >> 6) & 7;
    var _mode = (_op >> 3) & 7;
    var _reg = _op & 7;
    var _size;
    if (_opm == 3 || _opm == 7) {       // CMPA: word source sign-extended, compared as long
        _size = _opm == 3 ? 2 : 4;
        scr_m68k_ea(_c, _mode, _reg, _size);
        var _v = scr_m68k_ea_read(_c, _size);
        if (_size == 2) _v = scr_m68k_sx16(_v) & $FFFFFFFF;
        scr_m68k_sub(_c, _v, _c.a[(_op >> 9) & 7], 4, 0, 2);
        _c.cycles += 6;
        return;
    }
    if (_opm >= 4) {
        if (_mode == 1) {               // CMPM (Ay)+,(Ax)+
            _size = 1 << (_opm & 3);
            scr_m68k_ea_calc(_c, 3, _reg, _size);
            var _s = scr_m68k_read(_c, _c.ea_addr, _size);
            scr_m68k_ea_calc(_c, 3, (_op >> 9) & 7, _size);
            var _d = scr_m68k_read(_c, _c.ea_addr, _size);
            scr_m68k_sub(_c, _s, _d, _size, 0, 2);
            _c.cycles += _size == 4 ? 20 : 12;
            return;
        }
        scr_m68k_alu(_c, _op, 5);
        return;
    }
    scr_m68k_alu(_c, _op, 4);
}

// ---------------------------------------------------------------- line C: AND / MULU / MULS / ABCD / EXG

function scr_m68k_op_c(_c, _op) {
    var _opm = (_op >> 6) & 7;
    var _mode = (_op >> 3) & 7;
    var _rx = (_op >> 9) & 7;
    var _ry = _op & 7;
    var _v;
    if (_opm == 3 || _opm == 7) {       // MULU.W / MULS.W <ea>,Dn: 16 x 16 -> 32
        scr_m68k_ea(_c, _mode, _ry, 2);
        var _s = scr_m68k_ea_read(_c, 2);
        var _bits = 0;
        if (_opm == 3) {
            _v = (_c.d[_rx] & $FFFF) * _s;
            for (var _i = 0; _i < 16; _i += 1) if ((_s & (1 << _i)) != 0) _bits += 1;
        } else {
            _v = (scr_m68k_sx16(_c.d[_rx]) * scr_m68k_sx16(_s)) & $FFFFFFFF;
            var _pairs = (_s << 1) ^ _s;
            for (var _j = 0; _j < 17; _j += 1) if ((_pairs & (1 << _j)) != 0) _bits += 1;
        }
        _c.d[_rx] = _v & $FFFFFFFF;
        scr_m68k_logic_flags(_c, _v, 4);
        _c.cycles += 38 + 2 * _bits;
        return;
    }
    if (_opm == 4 && _mode <= 1) {
        scr_m68k_op_bcd(_c, _op, true);
        return;
    }
    if ((_op & $1F8) == $140) {         // EXG Dx,Dy
        _v = _c.d[_rx];
        _c.d[_rx] = _c.d[_ry];
        _c.d[_ry] = _v;
        _c.cycles += 6;
        return;
    }
    if ((_op & $1F8) == $148) {         // EXG Ax,Ay
        _v = _c.a[_rx];
        _c.a[_rx] = _c.a[_ry];
        _c.a[_ry] = _v;
        _c.cycles += 6;
        return;
    }
    if ((_op & $1F8) == $188) {         // EXG Dx,Ay
        _v = _c.d[_rx];
        _c.d[_rx] = _c.a[_ry];
        _c.a[_ry] = _v;
        _c.cycles += 6;
        return;
    }
    if (_opm >= 4 && _mode <= 1) scr_m68k_illegal(_c);
    scr_m68k_alu(_c, _op, 1);
}

// ---------------------------------------------------------------- line E: shifts and rotates

function scr_m68k_op_e(_c, _op) {
    var _szf = (_op >> 6) & 3;
    var _left = (_op & $0100) != 0;
    var _r;
    if (_szf == 3) {
        // memory: one word, by one bit (bit 11 set = 68020 bit fields)
        if ((_op & $0800) != 0) {
            if (_c.model < 2) scr_m68k_illegal(_c);
            scr_m68k_op_bitfield(_c, _op);
            return;
        }
        scr_m68k_ea(_c, (_op >> 3) & 7, _op & 7, 2);
        _r = scr_m68k_shift(_c, (_op >> 9) & 3, _left, scr_m68k_ea_read(_c, 2), 1, 2);
        scr_m68k_ea_write(_c, 2, _r);
        _c.cycles += 8;
        return;
    }
    var _size = 1 << _szf;
    var _reg = _op & 7;
    var _cnt = (_op >> 9) & 7;
    if ((_op & $20) != 0) _cnt = _c.d[_cnt] & 63;
    else if (_cnt == 0) _cnt = 8;
    _r = scr_m68k_shift(_c, (_op >> 3) & 3, _left, _c.d[_reg], _cnt, _size);
    scr_m68k_set_d(_c, _reg, _r, _size);
    _c.cycles += (_size == 4 ? 8 : 6) + 2 * _cnt;
}

/// _type: 0 AS, 1 LS, 2 ROX, 3 RO. Shifts _v by _n bits one at a time and sets the flags.
function scr_m68k_shift(_c, _type, _left, _v, _n, _size) {
    var _m = scr_m68k_mask(_size);
    var _msb = scr_m68k_msb(_size);
    _v = _v & _m;
    var _x = (_c.sr & M68K_X) != 0 ? 1 : 0;
    var _carry = 0;
    var _over = false;
    for (var _i = 0; _i < _n; _i += 1) {
        if (_left) {
            _carry = (_v & _msb) != 0 ? 1 : 0;
            var _nv;
            if (_type == 2) _nv = ((_v << 1) | _x) & _m;
            else if (_type == 3) _nv = ((_v << 1) | _carry) & _m;
            else _nv = (_v << 1) & _m;
            if (((_nv ^ _v) & _msb) != 0) _over = true;
            _v = _nv;
        } else {
            _carry = _v & 1;
            if (_type == 0) _v = (_v >> 1) | (_v & _msb);
            else if (_type == 1) _v = _v >> 1;
            else if (_type == 2) _v = (_v >> 1) | (_x != 0 ? _msb : 0);
            else _v = (_v >> 1) | (_carry != 0 ? _msb : 0);
        }
        if (_type == 2) _x = _carry;
    }
    var _sr = _c.sr & ~$0F;
    if (_type == 2) {
        // ROX: C is the final X (X itself when the count is 0)
        _sr = (_sr & ~M68K_X) | (_x != 0 ? (M68K_X | M68K_C) : 0);
    } else if (_n > 0) {
        if (_carry != 0) _sr |= M68K_C;
        if (_type < 2) _sr = (_sr & ~M68K_X) | (_carry != 0 ? M68K_X : 0);
        if (_type == 0 && _left && _over) _sr |= M68K_V;
    }
    if ((_v & _msb) != 0) _sr |= M68K_N;
    if (_v == 0) _sr |= M68K_Z;
    _c.sr = _sr & $FFFF;
    return _v;
}

// ---------------------------------------------------------------- 68020: long multiply, divide, bit fields

/// Unsigned 32 x 32 -> 64: returns [high long, low long] (exact, in 16-bit pieces).
function scr_m68k_mul64(_a, _b) {
    var _a0 = _a & $FFFF, _a1 = (_a >> 16) & $FFFF;
    var _b0 = _b & $FFFF, _b1 = (_b >> 16) & $FFFF;
    var _mid = _a1 * _b0 + _a0 * _b1;
    var _lo = _a0 * _b0 + ((_mid & $FFFF) << 16);
    var _hi = _a1 * _b1 + (_mid >> 16) + (_lo >> 32);
    return [_hi & $FFFFFFFF, _lo & $FFFFFFFF];
}

/// Two's complement of a 64-bit [high, low].
function scr_m68k_neg64(_v) {
    var _lo = (~_v[1] + 1) & $FFFFFFFF;
    var _hi = (~_v[0] + (_lo == 0 ? 1 : 0)) & $FFFFFFFF;
    return [_hi, _lo];
}

/// MULU.L / MULS.L <ea>,Dl or <ea>,Dh:Dl.
function scr_m68k_op_mull(_c, _op) {
    var _ext = scr_m68k_fetch16(_c);
    var _signed = (_ext & $0800) != 0;
    var _wide = (_ext & $0400) != 0;
    var _dl = (_ext >> 12) & 7;
    var _dh = _ext & 7;
    scr_m68k_ea(_c, (_op >> 3) & 7, _op & 7, 4);
    var _s = scr_m68k_ea_read(_c, 4);
    var _d = _c.d[_dl];
    var _neg = _signed && (((_s ^ _d) & $80000000) != 0) && _s != 0 && _d != 0;
    if (_signed) {
        _s = abs(scr_m68k_sx32(_s));
        _d = abs(scr_m68k_sx32(_d));
    }
    var _p = scr_m68k_mul64(_s, _d);
    if (_neg) _p = scr_m68k_neg64(_p);
    var _sr = _c.sr & ~$0F;
    if (_wide) {
        _c.d[_dh] = _p[0];
        _c.d[_dl] = _p[1];
        if ((_p[0] & $80000000) != 0) _sr |= M68K_N;
        if (_p[0] == 0 && _p[1] == 0) _sr |= M68K_Z;
    } else {
        _c.d[_dl] = _p[1];
        if ((_p[1] & $80000000) != 0) _sr |= M68K_N;
        if (_p[1] == 0) _sr |= M68K_Z;
        var _fits = _signed ? (_p[0] == (((_p[1] & $80000000) != 0) ? $FFFFFFFF : 0)) : (_p[0] == 0);
        if (!_fits) _sr |= M68K_V;
    }
    _c.sr = _sr;
    _c.cycles += 44;
}

/// DIVU.L / DIVS.L <ea>,Dq (32-bit), <ea>,Dr:Dq (DIVxL: remainder in Dr) or
/// the 64-bit dividend Dr:Dq.
function scr_m68k_op_divl(_c, _op) {
    var _ext = scr_m68k_fetch16(_c);
    var _signed = (_ext & $0800) != 0;
    var _wide = (_ext & $0400) != 0;
    var _dq = (_ext >> 12) & 7;
    var _dr = _ext & 7;
    scr_m68k_ea(_c, (_op >> 3) & 7, _op & 7, 4);
    var _s = scr_m68k_ea_read(_c, 4);
    if (_s == 0) {
        _c.sr &= ~M68K_C;
        scr_m68k_throw(5);
    }
    var _hi = _wide ? _c.d[_dr] : 0;
    var _lo = _c.d[_dq];
    var _neg_dividend = false;
    var _neg_divisor = false;
    if (_signed) {
        if (_wide) {
            _neg_dividend = (_hi & $80000000) != 0;
        } else {
            _neg_dividend = (_lo & $80000000) != 0;
            if (_neg_dividend) _hi = $FFFFFFFF;
        }
        if (_neg_dividend) {
            var _n = scr_m68k_neg64([_hi, _lo]);
            _hi = _n[0];
            _lo = _n[1];
        }
        _neg_divisor = (_s & $80000000) != 0;
        if (_neg_divisor) _s = (-scr_m68k_sx32(_s)) & $FFFFFFFF;
    }
    // shift-and-subtract over the 64-bit dividend
    var _rem = 0;
    var _qhi = 0;
    var _qlo = 0;
    for (var _i = 63; _i >= 0; _i -= 1) {
        var _bit = _i >= 32 ? (_hi >> (_i - 32)) & 1 : (_lo >> _i) & 1;
        _rem = (_rem << 1) | _bit;
        if (_rem >= _s) {
            _rem -= _s;
            if (_i >= 32) _qhi |= 1 << (_i - 32);
            else _qlo |= 1 << _i;
        }
    }
    _qlo = _qlo & $FFFFFFFF;
    var _overflow = _qhi != 0;
    var _q = _qlo;
    if (_signed && !_overflow) {
        var _qneg = _neg_dividend != _neg_divisor;
        if (_qneg) _overflow = _qlo > $80000000;
        else _overflow = _qlo > $7FFFFFFF;
        if (_qneg) _q = (-_qlo) & $FFFFFFFF;
        if (_neg_dividend) _rem = (-_rem) & $FFFFFFFF;
    }
    _c.cycles += 90;
    if (_overflow) {
        _c.sr = (_c.sr & ~M68K_C) | M68K_V;
        return;
    }
    if (_dr != _dq) _c.d[_dr] = _rem & $FFFFFFFF;
    _c.d[_dq] = _q;
    scr_m68k_logic_flags(_c, _q, 4);
}

function scr_m68k_rol32(_v, _n) {
    _n = _n & 31;
    _v = _v & $FFFFFFFF;
    if (_n == 0) return _v;
    return ((_v << _n) | (_v >> (32 - _n))) & $FFFFFFFF;
}

/// BFTST BFEXTU BFCHG BFEXTS BFCLR BFFFO BFSET BFINS <ea>{offset:width}.
function scr_m68k_op_bitfield(_c, _op) {
    var _kind = (_op >> 8) & 7;     // 0 TST, 1 EXTU, 2 CHG, 3 EXTS, 4 CLR, 5 FFO, 6 SET, 7 INS
    var _ext = scr_m68k_fetch16(_c);
    var _reg = (_ext >> 12) & 7;
    var _off = (_ext & $0800) != 0 ? scr_m68k_sx32(_c.d[(_ext >> 6) & 7]) : (_ext >> 6) & 31;
    var _w = (_ext & $0020) != 0 ? _c.d[_ext & 7] & 31 : _ext & 31;
    if (_w == 0) _w = 32;
    var _mode = (_op >> 3) & 7;
    var _wmask = _w == 32 ? $FFFFFFFF : (1 << _w) - 1;
    var _field, _addr = 0, _span = 0, _bitoff = 0, _raw = 0;
    if (_mode == 0) {
        _field = (scr_m68k_rol32(_c.d[_op & 7], _off) >> (32 - _w)) & _wmask;
    } else {
        _addr = scr_m68k_ea_control(_c, _mode, _op & 7);
        _addr = (_addr + floor(_off / 8)) & $FFFFFFFF;
        _bitoff = _off - floor(_off / 8) * 8;
        _span = ceil((_bitoff + _w) / 8);
        for (var _b = 0; _b < 5; _b += 1) _raw = (_raw << 8) | (_b < _span ? scr_m68k_rb(_c, _addr + _b) : 0);
        _field = (_raw >> (40 - _bitoff - _w)) & _wmask;
    }
    var _flag_v = _kind == 7 ? (_c.d[_reg] & _wmask) : _field;
    var _sr = _c.sr & ~$0F;
    if (((_flag_v >> (_w - 1)) & 1) != 0) _sr |= M68K_N;
    if (_flag_v == 0) _sr |= M68K_Z;
    _c.sr = _sr;
    _c.cycles += 12;
    var _new = -1;
    switch (_kind) {
        case 0: return;
        case 1: _c.d[_reg] = _field; return;
        case 3:
            _c.d[_reg] = (((_field >> (_w - 1)) & 1) != 0 ? (_field | ~_wmask) : _field) & $FFFFFFFF;
            return;
        case 5:
            var _pos = 0;
            while (_pos < _w && ((_field >> (_w - 1 - _pos)) & 1) == 0) _pos += 1;
            _c.d[_reg] = (_off + _pos) & $FFFFFFFF;
            return;
        case 2: _new = (~_field) & _wmask; break;
        case 4: _new = 0; break;
        case 6: _new = _wmask; break;
        case 7: _new = _c.d[_reg] & _wmask; break;
    }
    if (_mode == 0) {
        var _r = _op & 7;
        var _top = (_new << (32 - _w)) & $FFFFFFFF;
        var _mtop = (_wmask << (32 - _w)) & $FFFFFFFF;
        var _rot = (32 - (_off & 31)) & 31;
        _c.d[_r] = ((_c.d[_r] & ~scr_m68k_rol32(_mtop, _rot)) | scr_m68k_rol32(_top, _rot)) & $FFFFFFFF;
    } else {
        var _shift = 40 - _bitoff - _w;
        _raw = (_raw & ~(_wmask << _shift)) | (_new << _shift);
        for (var _k = _span - 1; _k >= 0; _k -= 1) scr_m68k_wb(_c, _addr + _k, (_raw >> (8 * (4 - _k))) & $FF);
    }
}

// ---------------------------------------------------------------- debugging

/// One line of registers for messages and the self test.
function scr_m68k_state_text(_c) {
    var _s = "PC=" + scr_m68k_hex(_c.pc, 6) + " SR=" + scr_m68k_hex(_c.sr, 4);
    for (var _i = 0; _i < 8; _i += 1) _s += " D" + string(_i) + "=" + scr_m68k_hex(_c.d[_i], 8);
    for (var _j = 0; _j < 8; _j += 1) _s += " A" + string(_j) + "=" + scr_m68k_hex(_c.a[_j], 8);
    return _s;
}
