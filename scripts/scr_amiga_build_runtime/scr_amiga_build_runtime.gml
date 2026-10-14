/// @desc Program-wide build pieces that are not one node: the header (the
/// hardware equates CODE blocks use), the audio runtime (Frank Wille's
/// ptplayer, public domain, datafiles/audio) and the MOD / sample data the
/// PLAY_MOD and PLAY_SFX macros reference. The emitted program is laid out as
///
///     SECTION code,CODE        ; every node, in program order (entry point)
///     <hardware equates>       ; only when a CODE block exists
///     ...nodes...
///     SECTION adm_runtime,CODE ; __adm_audio_init + ptplayer (audio only)
///     SECTION adm_audio,DATA_C ; MODs, samples, per-node sfx structures
///
/// The auto-boot loader puts every hunk in chip RAM, so Paula can play the
/// data where it lands.

/// Turns an asset name into the label part of __mod_<name> / __smp_<name>.
function scr_amiga_label_safe(_name) {
    var _out = "";
    var _i = 1;
    var _len = string_length(_name);
    while (_i <= _len) {
        var _c = string_char_at(_name, _i);
        var _ok = (_c >= "a" && _c <= "z") || (_c >= "A" && _c <= "Z") || (_c >= "0" && _c <= "9") || _c == "_";
        _out += _ok ? _c : "_";
        _i += 1;
    }
    if (_out == "") _out = "unnamed";
    return _out;
}

/// What the program needs beyond its nodes.
/// Returns { uses_code, uses_audio, mods[], samples[], sfx_nodes[] } (asset names, unique).
function scr_amiga_program_scan(_node_array) {
    var _scan = { uses_code : false, uses_audio : false, mods : [], samples : [], sfx_nodes : [] };
    var _i = 0;
    while (_i < array_length(_node_array)) {
        var _node = _node_array[_i];
        if (_node.is_macro) {
            if (_node.macro_type == "CODE") _scan.uses_code = true;
            if (_node.macro_type == "PLAY_MOD" || _node.macro_type == "STOP_MOD" || _node.macro_type == "PLAY_SFX") _scan.uses_audio = true;
            if (_node.macro_type == "PLAY_MOD" && !array_contains(_scan.mods, _node.macro_asset_name)) array_push(_scan.mods, _node.macro_asset_name);
            if (_node.macro_type == "PLAY_SFX") {
                if (!array_contains(_scan.samples, _node.macro_asset_name)) array_push(_scan.samples, _node.macro_asset_name);
                array_push(_scan.sfx_nodes, _node);
            }
        }
        _i += 1;
    }
    scr_gk_scan(_node_array, _scan);
    return _scan;
}

/// Names ptplayer.asm defines itself with EQU (DMACON, INTENA, CIAB ...).
/// The hardware equates skip them when ptplayer is in the program, or vasm
/// would see them twice.
function scr_amiga_ptplayer_equ_names() {
    if (is_array(global.ptplayer_equ_names_cache)) return global.ptplayer_equ_names_cache;

    var _names = [];
    var _path = working_directory + "audio/ptplayer.asm";
    if (file_exists(_path)) {
        var _file = file_text_open_read(_path);
        while (!file_text_eof(_file)) {
            var _line = file_text_read_string(_file);
            file_text_readln(_file);
            var _first = string_char_at(_line, 1);
            var _starts_label = (_first >= "A" && _first <= "Z") || (_first >= "a" && _first <= "z") || _first == "_";
            if (!_starts_label) continue;
            var _parts = string_split_ext(string_replace_all(_line, "\t", " "), [" "], true);
            if (array_length(_parts) >= 2) {
                var _directive = string_upper(_parts[1]);
                if (_directive == "EQU" || _directive == "=") array_push(_names, _parts[0]);
            }
        }
        file_text_close(_file);
    }
    global.ptplayer_equ_names_cache = _names;
    return _names;
}

/// Lines emitted right after SECTION code,CODE.
function scr_amiga_build_header_text(_scan) {
    var _flags = "";
    if (_scan.uses_gamekit && _scan.uses_audio) _flags = "GK_AUDIO\tequ\t1\t\t\t; the Game Kit plays sound effects\n";
    if (!_scan.uses_code) return _flags;

    var _equates = scr_asm_hardware_equates_text();
    if (!_scan.uses_audio) return _flags + "; ---- hardware equates for CODE blocks (CUSTOM = $DFF000) ----\n" + _equates + "\n";

    var _skip = scr_amiga_ptplayer_equ_names();
    var _lines = string_split(string_replace_all(_equates, "\r", ""), "\n");
    var _out = _flags + "; ---- hardware equates for CODE blocks (CUSTOM = $DFF000; some come from ptplayer) ----\n";
    var _i = 0;
    while (_i < array_length(_lines)) {
        var _parts = string_split_ext(string_replace_all(_lines[_i], "\t", " "), [" "], true);
        var _keep = true;
        if (array_length(_parts) > 0 && array_contains(_skip, _parts[0])) _keep = false;
        if (_keep && _lines[_i] != "") _out += _lines[_i] + "\n";
        _i += 1;
    }
    return _out + "\n";
}

/// Writes the asset files the footer INCBINs. Returns "" or an error message.
function scr_amiga_write_audio_assets(_scan, _asset_dir) {
    if (!directory_exists(_asset_dir)) directory_create(_asset_dir);

    var _lists = [_scan.mods, _scan.samples];
    var _types = ["MOD", "SAMPLE"];
    var _exts = [".mod", ".raw"];
    var _l = 0;
    while (_l < 2) {
        var _names = _lists[_l];
        var _i = 0;
        while (_i < array_length(_names)) {
            var _asset = scr_asset_find_by_name(_names[_i]);
            if (_asset == undefined || _asset.type != _types[_l]) {
                return _types[_l] + " asset '" + _names[_i] + "' not found - import it in SND-EDIT.";
            }
            var _buffer = scr_audio_asset_bytes(_asset);
            if (_buffer < 0 || buffer_get_size(_buffer) < 2) {
                if (_buffer >= 0) buffer_delete(_buffer);
                return _types[_l] + " asset '" + _names[_i] + "' has no data.";
            }
            buffer_save(_buffer, _asset_dir + "/" + scr_amiga_label_safe(_names[_i]) + _exts[_l]);
            buffer_delete(_buffer);
            _i += 1;
        }
        _l += 1;
    }
    return "";
}

/// The runtime and data sections appended after the last node.
/// Returns { ok, text, error }.
function scr_amiga_build_footer_text(_scan, _build_dir) {
    var _result = { ok : true, text : "", error : "" };
    if (_scan.uses_audio) {
        _result = scr_amiga_build_audio_footer_text(_scan, _build_dir);
        if (!_result.ok) return _result;
    }
    var _gk = scr_gk_footer_text(_scan);
    if (!_gk.ok) return _gk;
    _result.text += _gk.text;
    return _result;
}

function scr_amiga_build_audio_footer_text(_scan, _build_dir) {
    var _result = { ok : true, text : "", error : "" };

    var _asset_dir = _build_dir + "/assets";
    var _write_error = scr_amiga_write_audio_assets(_scan, _asset_dir);
    if (_write_error != "") {
        _result.ok = false;
        _result.error = _write_error;
        return _result;
    }

    var _ptplayer = string_replace_all(working_directory + "audio/ptplayer.asm", "\\", "/");
    var _assets = string_replace_all(_asset_dir, "\\", "/");
    var _t = "";

    _t += "\n; ==== Amiga Dev Machine audio runtime ====\n";
    _t += "; ptplayer 6.4 by Frank Wille (public domain) plays ProTracker MODs and\n";
    _t += "; sound effects from CIA-B level 6 interrupts. __adm_audio_init installs it\n";
    _t += "; once (first PLAY node) and switches the interrupt master back on, so it\n";
    _t += "; still plays after a macro has written INTENA $7FFF.\n";
    _t += "\tSECTION adm_runtime,CODE\n";
    _t += "__adm_audio_init:\n";
    _t += "\tMOVEM.L D0-D7/A0-A6,-(SP)\n";
    _t += "\tLEA __adm_audio_ready(PC),A0\n";
    _t += "\tTST.B (A0)\n";
    _t += "\tBNE.S .done\n";
    _t += "\tST (A0)\n";
    _t += "\tMOVEA.L 4.W,A6\n";
    _t += "\tMOVEQ #0,D0\n";
    _t += "\tBTST #0,297(A6)\t\t; AttnFlags: 68010 or better has a VBR\n";
    _t += "\tBEQ.S .vbr\n";
    _t += "\tLEA __adm_get_vbr(PC),A5\n";
    _t += "\tJSR -30(A6)\t\t\t; Supervisor\n";
    _t += ".vbr:\tMOVEA.L D0,A0\n";
    _t += "\tMOVEQ #0,D0\n";
    _t += "\tCMP.B #50,530(A6)\t\t; VBlankFrequency: PAL timers?\n";
    _t += "\tBNE.S .ntsc\n";
    _t += "\tMOVEQ #1,D0\n";
    _t += ".ntsc:\tLEA $DFF000,A6\n";
    _t += "\tJSR _mt_install\n";
    _t += "\tMOVE.W #$C000,$9A(A6)\t\t; INTENA master on (EXTER set by _mt_install)\n";
    _t += ".done:\tMOVEM.L (SP)+,D0-D7/A0-A6\n";
    _t += "\tRTS\n";
    _t += "__adm_get_vbr:\n";
    _t += "\tDC.L $4E7A0801\t\t\t; MOVEC VBR,D0\n";
    _t += "\tRTE\n";
    _t += "__adm_audio_ready:\n";
    _t += "\tDC.B 0\n";
    _t += "\tEVEN\n";
    _t += "\tINCLUDE \"" + _ptplayer + "\"\n";
    _t += "\n\tSECTION adm_audio,DATA_C\n";

    var _i = 0;
    while (_i < array_length(_scan.mods)) {
        var _safe = scr_amiga_label_safe(_scan.mods[_i]);
        _t += "__mod_" + _safe + ":\n";
        _t += "\tINCBIN \"" + _assets + "/" + _safe + ".mod\"\n";
        _t += "\tEVEN\n";
        _i += 1;
    }

    // Each sample starts with a zero word: ptplayer idles a channel on the
    // word in front of an effect (and _mt_loopfx needs it).
    _i = 0;
    while (_i < array_length(_scan.samples)) {
        var _sample = scr_asset_find_by_name(_scan.samples[_i]);
        var _sname = scr_amiga_label_safe(_scan.samples[_i]);
        _t += "\tCNOP 0,2\n";
        _t += "__smp_" + _sname + ":\n";
        _t += "\tDC.W 0\n";
        _t += "\tINCBIN \"" + _assets + "/" + _sname + ".raw\"\n";
        _t += "\tEVEN\n";
        if (_sample.loop && _sample.loop_length >= 4) {
            // The repeating part only: a looped effect plays this, from its own zero word.
            _t += "__smpl_" + _sname + ":\n";
            _t += "\tDC.W 0\n";
            _t += "\tINCBIN \"" + _assets + "/" + _sname + ".raw\"," + string(_sample.loop_start & ~1) + "," + string(_sample.loop_length & ~1) + "\n";
            _t += "\tEVEN\n";
        }
        _i += 1;
    }

    // One ptplayer SfxStructure per PLAY_SFX node: ptr.l, len.w (words),
    // period.w, volume.w, channel.b (-1 = best), priority.b
    _i = 0;
    while (_i < array_length(_scan.sfx_nodes)) {
        var _node = _scan.sfx_nodes[_i];
        var _asset = scr_asset_find_by_name(_node.macro_asset_name);
        var _safe_name = scr_amiga_label_safe(_node.macro_asset_name);
        var _looped = _asset.loop && _asset.loop_length >= 4;
        var _pointer = _looped ? "__smpl_" + _safe_name : "__smp_" + _safe_name;
        var _bytes = _looped ? (_asset.loop_length & ~1) : _asset.length;
        var _words = 1 + (_bytes div 2);
        var _volume = _node.macro_sfx_volume >= 0 ? _node.macro_sfx_volume : _asset.volume;
        var _channel = _node.macro_sfx_channel;
        if (_looped && _channel < 0) _channel = 3;
        _t += "\tCNOP 0,2\n";
        _t += "__sfxnode_" + string(floor(_node.uid)) + ":\n";
        _t += "\tDC.L " + _pointer + "\n";
        _t += "\tDC.W " + string(min(_words, 65535)) + "," + string(clamp(_asset.period, 124, 65535)) + "," + string(clamp(_volume, 0, 64)) + "\n";
        _t += "\tDC.B " + string(_channel) + ",64\n";
        _i += 1;
    }
    _t += scr_gk_sfx_structs_text(_scan);
    _t += "\tEVEN\n";

    _result.text = _t;
    return _result;
}

/// PLAY_MOD: starts a MOD asset from song position macro_music_pos.
function scr_emit_macro_play_mod(_node) {
    var _asset = scr_asset_find_by_name(_node.macro_asset_name);
    if (_asset == undefined || _asset.type != "MOD") {
        return { text : "; ERROR: MOD asset '" + _node.macro_asset_name + "' not found - import one in SND-EDIT", is_valid : false };
    }
    var _lines = "";
    if (_node.node_label != "") _lines += _node.node_label + ":\n";
    _lines += "\tMOVEM.L D0-D7/A0-A6,-(SP)\t; PLAY MOD " + _node.macro_asset_name + "\n";
    _lines += "\tJSR __adm_audio_init\n";
    _lines += "\tLEA $DFF000,A6\n";
    _lines += "\tLEA __mod_" + scr_amiga_label_safe(_node.macro_asset_name) + ",A0\n";
    _lines += "\tSUBA.L A1,A1\t\t\t; samples follow the patterns\n";
    _lines += "\tMOVEQ #" + string(clamp(_node.macro_music_pos, 0, 127)) + ",D0\t\t\t; song position\n";
    _lines += "\tJSR _mt_init\n";
    _lines += "\tST _mt_Enable\n";
    _lines += "\tMOVEM.L (SP)+,D0-D7/A0-A6";
    return { text : _lines, is_valid : true };
}

/// STOP_MOD: silences the music and every sound effect.
function scr_emit_macro_stop_mod(_node) {
    var _lines = "";
    if (_node.node_label != "") _lines += _node.node_label + ":\n";
    _lines += "\tMOVEM.L D0-D7/A0-A6,-(SP)\t; STOP MUSIC + SFX\n";
    _lines += "\tJSR __adm_audio_init\n";
    _lines += "\tLEA $DFF000,A6\n";
    _lines += "\tJSR _mt_end\n";
    _lines += "\tMOVEM.L (SP)+,D0-D7/A0-A6";
    return { text : _lines, is_valid : true };
}

/// PLAY_SFX: plays a SAMPLE asset through ptplayer, mixed with any music.
function scr_emit_macro_play_sfx(_node) {
    var _asset = scr_asset_find_by_name(_node.macro_asset_name);
    if (_asset == undefined || _asset.type != "SAMPLE") {
        return { text : "; ERROR: sample asset '" + _node.macro_asset_name + "' not found - import one in SND-EDIT", is_valid : false };
    }
    var _looped = _asset.loop && _asset.loop_length >= 4;
    var _lines = "";
    if (_node.node_label != "") _lines += _node.node_label + ":\n";
    _lines += "\tMOVEM.L D0-D7/A0-A6,-(SP)\t; PLAY SFX " + _node.macro_asset_name + "\n";
    _lines += "\tJSR __adm_audio_init\n";
    _lines += "\tLEA $DFF000,A6\n";
    _lines += "\tLEA __sfxnode_" + string(floor(_node.uid)) + ",A0\n";
    _lines += "\tJSR " + (_looped ? "_mt_loopfx\t\t\t; loops until STOP MUSIC" : "_mt_playfx") + "\n";
    _lines += "\tMOVEM.L (SP)+,D0-D7/A0-A6";
    return { text : _lines, is_valid : true };
}

/// CODE: the block's own source, label first, column-1 mnemonics indented.
/// The assembler is the final judge, so editor diagnostics never block a build.
function scr_emit_macro_code(_node) {
    var _lines = "";
    if (_node.node_label != "") _lines += _node.node_label + ":\n";
    var _source = scr_asm_normalise_for_emit(_node.macro_code_text);
    if (string_trim(_source) == "") _source = "\t; (empty CODE block)";
    _lines += _source;
    return { text : _lines, is_valid : true };
}
