/// @desc End-to-end self test of the build pipeline, for development.
/// Run the app with:   AmigaDevMachine.exe -admselftest "C:\path\song.mod"
/// It imports the MOD, makes a short synthetic sample, builds a program of
/// PLAY MOD + PLAY SFX + CODE blocks on the INIT column, presses F5 for real
/// (vasm -> auto-boot ADF -> FS-UAE) and writes the outcome to
/// %LOCALAPPDATA%/AmigaDevMachine/selftest_result.txt, then quits. The CODE
/// main loop turns the screen green while Paula audio DMA is running and dark
/// blue when it is not, so one look at FS-UAE shows the music is playing.

function scr_amiga_selftest_init() {
    global.selftest_active = false;
    global.selftest_stage = 0;
    global.selftest_timer = 0;
    global.selftest_mod_path = "";
    global.selftest_log = "";

    var _p = 0;
    while (_p < parameter_count()) {
        if (parameter_string(_p) == "-admselftest") {
            global.selftest_active = true;
            if (_p + 1 < parameter_count()) global.selftest_mod_path = parameter_string(_p + 1);
        }
        _p += 1;
    }

    if (global.selftest_active) {
        // A recovered autosave would replace the test graph mid-run.
        global.autosave_recovery_pending = false;
    }
}

function scr_amiga_selftest_note(_text) {
    global.selftest_log += _text + "\n";
    show_debug_message("[selftest] " + _text);
}

function scr_amiga_selftest_finish(_ok) {
    scr_amiga_selftest_note(_ok ? "RESULT: PASS" : "RESULT: FAIL");
    var _file = file_text_open_write(global.amiga_dev_data_path + "/selftest_result.txt");
    file_text_write_string(_file, global.selftest_log);
    file_text_close(_file);
    global.selftest_active = false;
    global.workspace_dirty = false;
    game_end();
}

/// Adds a connected macro node under _root at _y; returns it.
function scr_amiga_selftest_add_node(_root, _y, _macro_type) {
    var _node = instance_create_layer(_root.node_x, _y, "Instances", obj_opcode_node);
    scr_macro_node_init(_node, _macro_type);
    _node.node_x = _root.node_x;
    _node.node_y = _y;
    _node.is_connected = true;
    _node.root_uid = _root.uid;
    return _node;
}

function scr_amiga_selftest_step() {
    if (!global.selftest_active) return;
    global.selftest_timer += 1;

    switch (global.selftest_stage) {
        case 0:
            if (global.selftest_timer < 30) break;
            scr_amiga_selftest_note("machine " + global.amiga_machine + ", boot " + global.build_boot_mode);

            // Music.
            var _mod_name = "";
            if (global.selftest_mod_path != "" && file_exists(global.selftest_mod_path)) {
                _mod_name = scr_audio_import_mod(global.selftest_mod_path);
            }
            if (_mod_name == "") {
                scr_amiga_selftest_note("MOD import failed: " + global.selftest_mod_path);
                scr_amiga_selftest_finish(false);
                exit;
            }
            scr_amiga_selftest_note("imported MOD " + _mod_name);

            // A 0.2 s square-wave blip as the sound effect.
            var _len = 2200;
            var _buffer = buffer_create(_len, buffer_fixed, 1);
            var _b = 0;
            while (_b < _len) {
                buffer_write(_buffer, buffer_s8, ((_b div 16) mod 2) == 0 ? 90 : -90);
                _b += 1;
            }
            var _b64 = buffer_base64_encode(_buffer, 0, _len);
            buffer_delete(_buffer);
            scr_audio_define_sample("Blip", _b64, _len, 322, 64, false, 0, 0, "selftest");
            scr_amiga_selftest_note("defined sample Blip");

            // Program: CODE setup, PLAY MOD, PLAY SFX, CODE main loop.
            var _init = noone;
            with (obj_amiga_root_node) if (root_type == "INIT") _init = id;
            with (obj_opcode_node) instance_destroy();
            var _y = _init.node_y + _init.node_height;

            var _setup = scr_amiga_selftest_add_node(_init, _y, "CODE");
            _setup.macro_code_text = "; screen off, dark blue\n\tlea\tCUSTOM,a6\n\tmove.w\t#$7fff,INTENA(a6)\n\tmove.w\t#$7fff,DMACON(a6)\n\tmove.w\t#$0200,BPLCON0(a6)\n\tmove.w\t#$008,COLOR00(a6)\n";
            _y += _setup.node_height;

            var _music = scr_amiga_selftest_add_node(_init, _y, "PLAY_MOD");
            _music.macro_asset_name = _mod_name;
            _y += _music.node_height;

            var _sfx = scr_amiga_selftest_add_node(_init, _y, "PLAY_SFX");
            _sfx.macro_asset_name = "Blip";
            _y += _sfx.node_height;

            var _loop = scr_amiga_selftest_add_node(_init, _y, "CODE");
            _loop.macro_code_text = "; green while Paula audio DMA runs\n\tlea\tCUSTOM,a6\nmainloop:\n\tmove.w\tDMACONR(a6),d0\n\tand.w\t#15,d0\n\tbeq.s\t.quiet\n\tmove.w\t#$0f0,COLOR00(a6)\n\tbra.s\tmainloop\n.quiet\tmove.w\t#$008,COLOR00(a6)\n\tbra.s\tmainloop\n";

            var _old_adf = global.current_project_path + "/build/disk.adf";
            if (file_exists(_old_adf)) file_delete(_old_adf);
            scr_amiga_selftest_note("program nodes: " + string(array_length(scr_amiga_collect_program_nodes())));
            scr_amiga_trigger_build();
            if (obj_amiga_manager.build_state == "idle") {
                scr_amiga_selftest_note("build did not start");
                scr_amiga_selftest_finish(false);
                exit;
            }
            global.selftest_stage = 1;
            global.selftest_timer = 0;
            break;

        case 1:
            if (obj_amiga_manager.build_state != "idle") {
                if (global.selftest_timer > 3000) {
                    scr_amiga_selftest_note("build stuck in " + obj_amiga_manager.build_state);
                    scr_amiga_selftest_finish(false);
                }
                break;
            }
            var _adf = global.current_project_path + "/build/disk.adf";
            var _ok = file_exists(_adf);
            var _log_i = 0;
            while (_log_i < array_length(global.status_message_log)) {
                var _status_text = global.status_message_log[_log_i].text;
                scr_amiga_selftest_note("status: " + _status_text);
                if (string_pos("FAILED", _status_text) > 0 || string_pos("TIMED OUT", _status_text) > 0 || string_pos("ERROR", _status_text) > 0 || string_pos("NOT WRITTEN", _status_text) > 0) _ok = false;
                _log_i += 1;
            }
            scr_amiga_selftest_note(_ok ? "disk.adf written: " + _adf : "no disk.adf");
            scr_amiga_selftest_finish(_ok);
            break;
    }
}
