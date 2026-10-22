/// @desc The Amiga hardware around the 68K course simulator (scr_m68k_sim):
/// custom chips at $DFF000, CIA-A (odd bytes, $BFE001) and CIA-B (even
/// bytes, $BFD000). Every write is logged in _c.hw_log { addr, reg, value,
/// size, pc, frame, line } so a lesson can check "COLOR00 was set to $0F00";
/// scr_m68k_hw_value(_c, $180) is the last value written to a register and
/// scr_m68k_hw_long(_c, $080) a pointer pair. Readable registers are modelled:
/// DMACONR, VPOSR / VHPOSR (a PAL beam driven by the cycle count), JOY0DAT /
/// JOY1DAT and the CIA-A fire buttons (_c.joy), ADKCONR, INTENAR, INTREQR,
/// POTGOR, DENISEID. VERTB is raised at the start of every frame and the CPU
/// takes the level 3 interrupt when INTENA allows it. The blitter runs at once
/// when BLTSIZE is written (copy and fill modes; DMACONR BBUSY always reads
/// 0, BZERO is set). The copper and the display are not run: a lesson reads
/// the copper list from memory.

/// PAL: 313 lines of 227 colour clocks, two CPU cycles each.
#macro M68K_LINE_CYCLES 454
#macro M68K_FRAME_CYCLES 142102
#macro M68K_HW_LOG_MAX 20000

function scr_m68k_hw_reset(_c) {
    _c.hw_regs = array_create(256, 0);
    _c.hw_log = [];
    _c.hw_log_full = false;
    _c.dmacon = 0;
    _c.intena = 0;
    _c.intreq = 0;
    _c.adkcon = 0;
    _c.blit_zero = true;
    _c.blits = 0;
    _c.frame = 0;
    _c.agnus_id = $20;      // ECS PAL (A600); AGA would be $22
    _c.joy = { up : false, down : false, left : false, right : false, fire : false };
    _c.mouse_fire = false;
    _c.ciaa = array_create(16, 0);
    _c.ciab = array_create(16, 0);
}

/// Joystick in port 2 (JOY1DAT, fire = CIA-A PRA bit 7).
function scr_m68k_set_joystick(_c, _up, _down, _left, _right, _fire) {
    _c.joy.up = _up;
    _c.joy.down = _down;
    _c.joy.left = _left;
    _c.joy.right = _right;
    _c.joy.fire = _fire;
}

function scr_m68k_hw_value(_c, _reg) {
    return _c.hw_regs[(_reg >> 1) & $FF];
}

function scr_m68k_hw_long(_c, _reg) {
    return (_c.hw_regs[(_reg >> 1) & $FF] << 16) | _c.hw_regs[((_reg >> 1) + 1) & $FF];
}

/// How many times register _reg was written.
function scr_m68k_hw_count(_c, _reg) {
    var _n = 0;
    for (var _i = 0; _i < array_length(_c.hw_log); _i += 1) {
        var _e = _c.hw_log[_i];
        if (_e.addr >= $DFF000 && _e.reg == _reg) _n += 1;
    }
    return _n;
}

function scr_m68k_hw_vpos(_c) {
    return (_c.cycles mod M68K_FRAME_CYCLES) div M68K_LINE_CYCLES;
}

function scr_m68k_hw_hpos(_c) {
    return ((_c.cycles mod M68K_FRAME_CYCLES) mod M68K_LINE_CYCLES) div 2;
}

/// After every instruction: a new frame raises VERTB.
function scr_m68k_hw_tick(_c) {
    var _f = _c.cycles div M68K_FRAME_CYCLES;
    if (_f != _c.frame) {
        _c.frame = _f;
        _c.intreq |= $0020;
    }
}

/// The interrupt level Paula is asking for (0 = none).
function scr_m68k_hw_irq_level(_c) {
    if ((_c.intena & $4000) == 0) return 0;
    var _p = _c.intena & _c.intreq & $3FFF;
    if (_p == 0) return 0;
    if ((_p & $2000) != 0) return 6;
    if ((_p & $1800) != 0) return 5;
    if ((_p & $0780) != 0) return 4;
    if ((_p & $0070) != 0) return 3;
    if ((_p & $0008) != 0) return 2;
    return 1;
}

/// True when the next VERTB would interrupt the CPU (so STOP can wait for it).
function scr_m68k_hw_can_wake(_c) {
    return (_c.intena & $4020) == $4020 && ((_c.sr >> 8) & 7) < 3;
}

function scr_m68k_io_read(_c, _a, _size) {
    if (_a >= $DFF000 && _a <= $DFFFFF) {
        var _w = scr_m68k_hw_read(_c, _a & $1FE);
        if (_size == 2) return _w;
        return (_a & 1) != 0 ? (_w & $FF) : (_w >> 8);
    }
    if (_a >= $BF0000 && _a <= $BFFFFF) {
        if (_size == 1) return scr_m68k_cia_read(_c, _a);
        return (scr_m68k_cia_read(_c, _a) << 8) | scr_m68k_cia_read(_c, _a + 1);
    }
    throw { m68k_vector : 2, address : _a, write : false, fetch : false };
}

function scr_m68k_io_write(_c, _a, _size, _v) {
    if (_a >= $DFF000 && _a <= $DFFFFF) {
        // A byte write puts the byte on both halves of the data bus.
        if (_size == 1) _v = (_v << 8) | _v;
        scr_m68k_hw_write(_c, _a & $1FE, _v & $FFFF, _size);
        return;
    }
    if (_a >= $BF0000 && _a <= $BFFFFF) {
        if (_size == 1) {
            scr_m68k_cia_write(_c, _a, _v);
        } else {
            scr_m68k_cia_write(_c, _a, _v >> 8);
            scr_m68k_cia_write(_c, _a + 1, _v & $FF);
        }
        return;
    }
    throw { m68k_vector : 2, address : _a, write : true, fetch : false };
}

function scr_m68k_hw_log_add(_c, _addr, _reg, _v, _size) {
    if (array_length(_c.hw_log) >= M68K_HW_LOG_MAX) {
        _c.hw_log_full = true;
        return;
    }
    array_push(_c.hw_log, { addr : _addr, reg : _reg, value : _v, size : _size, pc : _c.op_pc, frame : _c.frame, line : scr_m68k_hw_vpos(_c) });
}

function scr_m68k_hw_read(_c, _reg) {
    switch (_reg) {
        case $002: return (_c.dmacon & $07FF) | (_c.blit_zero ? $2000 : 0);   // DMACONR
        case $004:                                                            // VPOSR
            return $8000 | (_c.agnus_id << 8) | ((scr_m68k_hw_vpos(_c) >> 8) & 1);
        case $006:                                                            // VHPOSR
            return ((scr_m68k_hw_vpos(_c) & $FF) << 8) | (scr_m68k_hw_hpos(_c) & $FF);
        case $00A: return 0;                                                  // JOY0DAT (mouse counters)
        case $00C:                                                            // JOY1DAT
            var _x1 = _c.joy.right ? 1 : 0;
            var _y1 = _c.joy.left ? 1 : 0;
            var _x0 = _x1 ^ (_c.joy.down ? 1 : 0);
            var _y0 = _y1 ^ (_c.joy.up ? 1 : 0);
            return (_y1 << 9) | (_y0 << 8) | (_x1 << 1) | _x0;
        case $010: return _c.adkcon;                                          // ADKCONR
        case $016: return $FF00;                                              // POTGOR: no second buttons
        case $018: return $3000;                                              // SERDATR: empty
        case $01C: return _c.intena;                                          // INTENAR
        case $01E: return _c.intreq;                                          // INTREQR
        case $07C: return $FC;                                                // DENISEID (ECS)
    }
    return 0;   // write-only register
}

function scr_m68k_hw_write(_c, _reg, _v, _size) {
    _c.hw_regs[_reg >> 1] = _v;
    scr_m68k_hw_log_add(_c, $DFF000 + _reg, _reg, _v, _size);
    switch (_reg) {
        case $096:      // DMACON
            if ((_v & $8000) != 0) _c.dmacon |= _v & $07FF;
            else _c.dmacon &= ~(_v & $07FF);
            break;
        case $09A:      // INTENA
            if ((_v & $8000) != 0) _c.intena |= _v & $7FFF;
            else _c.intena &= ~(_v & $7FFF);
            break;
        case $09C:      // INTREQ
            if ((_v & $8000) != 0) _c.intreq |= _v & $7FFF;
            else _c.intreq &= ~(_v & $7FFF);
            break;
        case $09E:      // ADKCON
            if ((_v & $8000) != 0) _c.adkcon |= _v & $7FFF;
            else _c.adkcon &= ~(_v & $7FFF);
            break;
        case $058:      // BLTSIZE: height << 6 | width in words
            var _h = (_v >> 6) & $3FF;
            var _w = _v & $3F;
            scr_m68k_blit(_c, _w == 0 ? 64 : _w, _h == 0 ? 1024 : _h);
            break;
        case $05E:      // BLTSIZH (ECS): starts the blit with BLTSIZV
            scr_m68k_blit(_c, _v & $7FF, scr_m68k_hw_value(_c, $05C) & $7FFF);
            break;
    }
}

// ---------------------------------------------------------------- CIAs

function scr_m68k_cia_read(_c, _a) {
    var _reg = (_a >> 8) & 15;
    if ((_a & 1) != 0 && (_a & $1000) == 0) {          // CIA-A
        if (_reg == 0) return $3F | (_c.joy.fire ? 0 : $80) | (_c.mouse_fire ? 0 : $40);
        return _c.ciaa[_reg];
    }
    if ((_a & 1) == 0 && (_a & $2000) == 0) return _c.ciab[_reg];   // CIA-B
    return $FF;
}

function scr_m68k_cia_write(_c, _a, _v) {
    var _reg = (_a >> 8) & 15;
    _v = _v & $FF;
    if ((_a & 1) != 0 && (_a & $1000) == 0) {
        _c.ciaa[_reg] = _v;
        scr_m68k_hw_log_add(_c, _a, _reg, _v, 1);
    } else if ((_a & 1) == 0 && (_a & $2000) == 0) {
        _c.ciab[_reg] = _v;
        scr_m68k_hw_log_add(_c, _a, _reg, _v, 1);
    }
}

// ---------------------------------------------------------------- blitter

/// Runs a whole blit of _w words x _h rows from the blitter registers (copy
/// and area-fill modes; line mode is not simulated and only logged).
function scr_m68k_blit(_c, _w, _h) {
    _c.blits += 1;
    var _con0 = scr_m68k_hw_value(_c, $040);
    var _con1 = scr_m68k_hw_value(_c, $042);
    if ((_con1 & 1) != 0) return;
    var _ash = _con0 >> 12;
    var _bsh = _con1 >> 12;
    var _use_a = (_con0 & $0800) != 0;
    var _use_b = (_con0 & $0400) != 0;
    var _use_c = (_con0 & $0200) != 0;
    var _use_d = (_con0 & $0100) != 0;
    var _lf = _con0 & $FF;
    var _desc = (_con1 & 2) != 0;
    var _fill = (_con1 & $18) != 0;
    var _ife = (_con1 & 8) != 0;
    var _fci = (_con1 & 4) != 0 ? 1 : 0;
    var _fwm = scr_m68k_hw_value(_c, $044);
    var _lwm = scr_m68k_hw_value(_c, $046);
    var _cpt = scr_m68k_hw_long(_c, $048) & $1FFFFE;
    var _bpt = scr_m68k_hw_long(_c, $04C) & $1FFFFE;
    var _apt = scr_m68k_hw_long(_c, $050) & $1FFFFE;
    var _dpt = scr_m68k_hw_long(_c, $054) & $1FFFFE;
    var _cmod = scr_m68k_sx16(scr_m68k_hw_value(_c, $060) & $FFFE);
    var _bmod = scr_m68k_sx16(scr_m68k_hw_value(_c, $062) & $FFFE);
    var _amod = scr_m68k_sx16(scr_m68k_hw_value(_c, $064) & $FFFE);
    var _dmod = scr_m68k_sx16(scr_m68k_hw_value(_c, $066) & $FFFE);
    var _cdat = scr_m68k_hw_value(_c, $070);
    var _bdat = scr_m68k_hw_value(_c, $072);
    var _adat = scr_m68k_hw_value(_c, $074);
    var _step = _desc ? -2 : 2;
    var _dir = _desc ? -1 : 1;
    var _prev_a = 0;
    var _prev_b = 0;
    var _zero = true;
    for (var _y = 0; _y < _h; _y += 1) {
        var _carry = _fci;
        for (var _x = 0; _x < _w; _x += 1) {
            var _a = _adat;
            if (_use_a) {
                _a = scr_m68k_peek(_c, _apt, 2);
                _apt += _step;
            }
            if (_x == 0) _a &= _fwm;
            if (_x == _w - 1) _a &= _lwm;
            var _b = _bdat;
            if (_use_b) {
                _b = scr_m68k_peek(_c, _bpt, 2);
                _bpt += _step;
            }
            var _cc = _cdat;
            if (_use_c) {
                _cc = scr_m68k_peek(_c, _cpt, 2);
                _cpt += _step;
            }
            var _as, _bs;
            if (_desc) {
                _as = ((_a << _ash) | (_prev_a >> (16 - _ash))) & $FFFF;
                _bs = ((_b << _bsh) | (_prev_b >> (16 - _bsh))) & $FFFF;
            } else {
                _as = (((_prev_a << 16) | _a) >> _ash) & $FFFF;
                _bs = (((_prev_b << 16) | _b) >> _bsh) & $FFFF;
            }
            _prev_a = _a;
            _prev_b = _b;
            var _d = 0;
            if ((_lf & $01) != 0) _d |= ~_as & ~_bs & ~_cc;
            if ((_lf & $02) != 0) _d |= ~_as & ~_bs & _cc;
            if ((_lf & $04) != 0) _d |= ~_as & _bs & ~_cc;
            if ((_lf & $08) != 0) _d |= ~_as & _bs & _cc;
            if ((_lf & $10) != 0) _d |= _as & ~_bs & ~_cc;
            if ((_lf & $20) != 0) _d |= _as & ~_bs & _cc;
            if ((_lf & $40) != 0) _d |= _as & _bs & ~_cc;
            if ((_lf & $80) != 0) _d |= _as & _bs & _cc;
            _d = _d & $FFFF;
            if (_fill) {
                // right to left: each set bit toggles the fill
                var _out = 0;
                for (var _bit = 0; _bit < 16; _bit += 1) {
                    var _in = (_d >> _bit) & 1;
                    if (_ife) {
                        // inclusive: both edge bits stay set
                        _out |= (_carry | _in) << _bit;
                        if (_in != 0) _carry ^= 1;
                    } else {
                        // exclusive: the left edge bit is dropped
                        if (_in != 0) _carry ^= 1;
                        _out |= _carry << _bit;
                    }
                }
                _d = _out;
            }
            if (_d != 0) _zero = false;
            if (_use_d) {
                scr_m68k_poke(_c, _dpt, 2, _d);
                _dpt += _step;
            }
        }
        _apt += _dir * _amod;
        _bpt += _dir * _bmod;
        _cpt += _dir * _cmod;
        _dpt += _dir * _dmod;
    }
    _c.blit_zero = _zero;
}
