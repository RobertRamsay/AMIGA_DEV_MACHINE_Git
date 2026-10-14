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
    global.selftest_expect_error = false;
    // -admtutorials builds all ten tutorials (no emulator); -admtutorial N builds
    // tutorial N and boots it in FS-UAE.
    global.selftest_tutorial_first = -1;
    global.selftest_tutorial_last = -1;
    global.selftest_tutorial_index = -1;
    global.selftest_tutorial_ok = true;
    global.build_skip_launch = false;
    // -admtour runs the whole editor tour, saving a screenshot of every step.
    global.selftest_tour = false;
    // -admshowcase: clean screenshots of every screen into <data>/showcase/.
    global.selftest_showcase = false;
    global.selftest_showcase_index = 0;

    var _p = 0;
    while (_p < parameter_count()) {
        if (parameter_string(_p) == "-admselftesterr") global.selftest_expect_error = true;
        if (parameter_string(_p) == "-admselftest" || parameter_string(_p) == "-admselftesterr") {
            global.selftest_active = true;
            if (_p + 1 < parameter_count()) global.selftest_mod_path = parameter_string(_p + 1);
        }
        if (parameter_string(_p) == "-admshowcase") {
            global.selftest_active = true;
            global.selftest_showcase = true;
        }
        if (parameter_string(_p) == "-admtour") {
            global.selftest_active = true;
            global.selftest_tour = true;
        }
        if (parameter_string(_p) == "-admtutorials") {
            global.selftest_active = true;
            global.selftest_tutorial_first = 1;
            global.selftest_tutorial_last = 10;
            global.build_skip_launch = true;
        }
        if (parameter_string(_p) == "-admtutorial" && _p + 1 < parameter_count()) {
            global.selftest_active = true;
            global.selftest_tutorial_first = clamp(real(parameter_string(_p + 1)), 1, 10);
            global.selftest_tutorial_last = global.selftest_tutorial_first;
        }
        _p += 1;
    }

    if (global.selftest_active) {
        // A recovered autosave would replace the test graph mid-run, and the
        // test must never overwrite the user's own recovery file.
        global.tutorial_home_startup_pending = false;
        global.autosave_recovery_pending = false;
        global.autosave_workspace_path = global.current_project_path + "/selftest_autosave_workspace.json";
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
    if (global.selftest_tutorial_first > 0) {
        scr_amiga_selftest_tutorial_step();
        return;
    }
    if (global.selftest_tour) {
        scr_amiga_selftest_tour_step();
        return;
    }
    if (global.selftest_showcase) {
        scr_amiga_selftest_showcase_step();
        return;
    }

    switch (global.selftest_stage) {
        case 0:
            if (global.selftest_timer < 30) break;
            scr_amiga_selftest_note("machine " + global.amiga_machine + ", boot " + global.build_boot_mode);

            // Unit self tests of the language module and the audio code.
            var _asm_failures = scr_asm_lang_selftest();
            scr_amiga_selftest_note("scr_asm_lang_selftest failures: " + string(array_length(_asm_failures)) + (array_length(_asm_failures) > 0 ? " " + json_stringify(_asm_failures) : ""));
            var _audio_failures = scr_audio_selftest();
            scr_amiga_selftest_note("scr_audio_selftest failures: " + string(array_length(_audio_failures)) + (array_length(_audio_failures) > 0 ? " " + json_stringify(_audio_failures) : ""));
            var _tile_failures = scr_tile_editor_selftest();
            scr_amiga_selftest_note("scr_tile_editor_selftest failures: " + string(array_length(_tile_failures)) + (array_length(_tile_failures) > 0 ? " " + json_stringify(_tile_failures) : ""));
            var _ced_failures = scr_code_editor_selftest();
            var _op_failures = scr_opcode_rules_selftest();
            scr_amiga_selftest_note("scr_opcode_rules_selftest failures: " + string(array_length(_op_failures)) + (array_length(_op_failures) > 0 ? " " + json_stringify(_op_failures) : ""));
            _ced_failures = array_concat(_ced_failures, _op_failures);
            scr_amiga_selftest_note("scr_code_editor_selftest failures: " + string(array_length(_ced_failures)) + (array_length(_ced_failures) > 0 ? " " + json_stringify(_ced_failures) : ""));
            if (array_length(_asm_failures) + array_length(_audio_failures) + array_length(_tile_failures) + array_length(_ced_failures) > 0) {
                scr_amiga_selftest_finish(false);
                exit;
            }

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
            if (global.selftest_expect_error) {
                // Line 3 (index 2) uses a data register that does not exist.
                _setup.macro_code_text = "; deliberate error on line 3\n\tlea\tCUSTOM,a6\n\tmove.w\t#1,d9\n";
                // A name and a label add two lines before the code in main.s:
                // the error must still map back to line 3 of the block.
                _setup.macro_code_name = "Broken setup";
                _setup.node_label = "setup_block";
            }
            _y += _setup.node_height;

            var _music = scr_amiga_selftest_add_node(_init, _y, "PLAY_MOD");
            _music.macro_asset_name = _mod_name;
            _y += _music.node_height;

            var _sfx = scr_amiga_selftest_add_node(_init, _y, "PLAY_SFX");
            _sfx.macro_asset_name = "Blip";
            _y += _sfx.node_height;

            var _loop = scr_amiga_selftest_add_node(_init, _y, "CODE");
            _loop.macro_code_name = "Main loop";
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
            if (global.selftest_expect_error) {
                var _errors = global.code_editor_build_errors;
                scr_amiga_selftest_note("mapped CODE errors: " + json_stringify(_errors));
                _ok = !file_exists(_adf) && array_length(_errors) > 0 && _errors[0].line == 2;
            }
            scr_amiga_selftest_finish(_ok);
            break;
    }
}

/// -admtutorials / -admtutorial N: loads each tutorial, builds it with F5's
/// pipeline and checks that vasm and the disk writer succeeded.
function scr_amiga_selftest_tutorial_step() {
    switch (global.selftest_stage) {
        case 0:
            if (global.selftest_timer < 30) break;
            scr_amiga_selftest_note("machine " + global.amiga_machine + ", boot " + global.build_boot_mode);
            var _te_failures = scr_tile_editor_selftest();
            scr_amiga_selftest_note("scr_tile_editor_selftest failures: " + string(array_length(_te_failures)) + (array_length(_te_failures) > 0 ? " " + json_stringify(_te_failures) : ""));
            if (array_length(_te_failures) > 0) global.selftest_tutorial_ok = false;
            global.selftest_tutorial_index = global.selftest_tutorial_first;
            global.selftest_stage = 10;
            break;

        case 10:
            var _n = global.selftest_tutorial_index;
            global.status_message_log = [];
            global.workspace_dirty = false;
            if (!scr_tutorial_load(_n - 1)) {
                scr_amiga_selftest_note("tutorial " + string(_n) + ": load failed");
                global.selftest_tutorial_ok = false;
                global.selftest_stage = 12;
                break;
            }
            var _assets = "";
            var _a = 0;
            while (_a < array_length(global.asset_list)) {
                _assets += global.asset_list[_a].type + ":" + global.asset_list[_a].name + " ";
                _a += 1;
            }
            scr_amiga_selftest_note("tutorial " + string(_n) + ": " + string(array_length(scr_amiga_collect_program_nodes())) + " program nodes; assets " + _assets);
            var _old_adf = global.current_project_path + "/build/disk.adf";
            if (file_exists(_old_adf)) file_delete(_old_adf);
            scr_amiga_trigger_build();
            if (obj_amiga_manager.build_state == "idle") {
                scr_amiga_selftest_note("tutorial " + string(_n) + ": build did not start");
                global.selftest_tutorial_ok = false;
                global.selftest_stage = 12;
                break;
            }
            global.selftest_stage = 11;
            global.selftest_timer = 0;
            break;

        case 11:
            if (obj_amiga_manager.build_state != "idle") {
                if (global.selftest_timer > 3000) {
                    scr_amiga_selftest_note("build stuck in " + obj_amiga_manager.build_state);
                    global.selftest_tutorial_ok = false;
                    global.selftest_stage = 12;
                }
                break;
            }
            var _ok = file_exists(global.current_project_path + "/build/disk.adf");
            var _i = 0;
            while (_i < array_length(global.status_message_log)) {
                var _text = global.status_message_log[_i].text;
                if (string_pos("FAILED", _text) > 0 || string_pos("TIMED OUT", _text) > 0 || string_pos("ERROR", _text) > 0 || string_pos("NOT WRITTEN", _text) > 0 || string_pos("Assembled", _text) > 0) {
                    scr_amiga_selftest_note("  status: " + _text);
                }
                if (string_pos("FAILED", _text) > 0 || string_pos("TIMED OUT", _text) > 0 || string_pos("ERROR", _text) > 0 || string_pos("NOT WRITTEN", _text) > 0) _ok = false;
                _i += 1;
            }
            scr_amiga_selftest_note("tutorial " + string(global.selftest_tutorial_index) + (_ok ? ": OK" : ": FAILED"));
            if (!_ok) {
                global.selftest_tutorial_ok = false;
                // Keep the failing program for inspection.
                var _src = global.current_project_path + "/build/main.s";
                if (file_exists(_src)) file_copy(_src, global.amiga_dev_data_path + "/selftest_tutorial_" + string(global.selftest_tutorial_index) + ".s");
            }
            global.selftest_stage = 12;
            break;

        case 12:
            global.selftest_tutorial_index += 1;
            if (global.selftest_tutorial_index > global.selftest_tutorial_last) {
                scr_amiga_selftest_finish(global.selftest_tutorial_ok);
            } else {
                global.selftest_stage = 10;
                global.selftest_timer = 0;
            }
            break;
    }
}

/// -admtour: loads tutorial 2 as the "user's" workspace, runs every tour step
/// (screenshot of each in <data>/tour_shots/), ends the tour and checks the
/// user's workspace came back unchanged.
function scr_amiga_selftest_tour_step() {
    switch (global.selftest_stage) {
        case 0:
            if (global.selftest_timer < 30) break;
            global.workspace_dirty = false;
            scr_tutorial_load(1);
            global.workspace_dirty = true;          // pretend there is unsaved work
            global.selftest_tour_before = scr_amiga_selftest_tour_signature();
            scr_amiga_selftest_note("user workspace: " + global.selftest_tour_before);
            global.selftest_tour_dir = global.amiga_dev_data_path + "/tour_shots";
            scr_tour_open();
            global.selftest_tour_missing = 0;
            global.selftest_stage = 4;
            global.selftest_timer = 0;
            break;

        case 5:
            if (current_time - global.selftest_tour_auto_from < 2500) break;
            var _auto_tour = instance_find(obj_editor_tour, 0);
            scr_amiga_selftest_note("auto-play after 2.5 s at 1 s per step: step " + string(_auto_tour.tour_index + 1));
            if (_auto_tour.tour_index != 2) global.selftest_tour_missing += 100;
            _auto_tour.tour_auto = false;
            global.tour_delay_seconds = global.selftest_tour_delay;
            _auto_tour.tour_index = 0;
            _auto_tour.tour_enter();
            global.selftest_stage = 1;
            global.selftest_timer = 0;
            break;

        case 4:
            // The category picker, then start with every category ticked.
            if (global.selftest_timer == 10) screen_save(global.selftest_tour_dir + "/000_menu.png");
            if (global.selftest_timer < 12) break;
            var _tour = instance_find(obj_editor_tour, 0);
            _tour.tour_begin();
            scr_amiga_selftest_note("tour steps: " + string(array_length(_tour.tour_queue)));
            // Auto-play at 1 s per step (not saved to settings.ini).
            global.selftest_tour_delay = global.tour_delay_seconds;
            global.tour_delay_seconds = 1;
            _tour.tour_auto = true;
            _tour.tour_step_started = current_time;
            global.selftest_tour_auto_from = current_time;
            global.selftest_stage = 5;
            global.selftest_timer = 0;
            break;

        case 1:
            var _t = instance_find(obj_editor_tour, 0);
            if (_t == noone) {
                scr_amiga_selftest_note("tour vanished");
                scr_amiga_selftest_finish(false);
                break;
            }
            // Let the editor settle and draw, then capture.
            if (global.selftest_timer == 12) {
                var _entry = _t.tour_queue[_t.tour_index];
                var _name = string_replace_all(string_format(_t.tour_index + 1, 3, 0), " ", "0") + "_" + _t.tour_categories[_entry.category_index].id;
                screen_save(global.selftest_tour_dir + "/" + _name + ".png");
                var _has_rect = _t.tour_rect != undefined;
                if (!_has_rect && is_callable(_entry.step.rect)) {
                    global.selftest_tour_missing += 1;
                    scr_amiga_selftest_note("NO RECT: " + _name + " '" + _entry.step.title + "'");
                }
            }
            if (global.selftest_timer >= 14) {
                if (_t.tour_index >= array_length(_t.tour_queue) - 1) {
                    _t.tour_next();               // to the "done" page
                    global.selftest_stage = 2;
                } else {
                    _t.tour_next();
                }
                global.selftest_timer = 0;
            }
            break;

        case 2:
            if (global.selftest_timer == 10) screen_save(global.selftest_tour_dir + "/999_done.png");
            if (global.selftest_timer < 12) break;
            with (obj_editor_tour) tour_finish();
            global.selftest_stage = 3;
            global.selftest_timer = 0;
            break;

        case 3:
            if (global.selftest_timer < 10) break;
            var _after = scr_amiga_selftest_tour_signature();
            scr_amiga_selftest_note("after tour: " + _after);
            scr_amiga_selftest_note("dirty kept: " + string(global.workspace_dirty) + ", tutorial " + string(global.tutorial_current));
            scr_amiga_selftest_note("steps without highlight: " + string(global.selftest_tour_missing));
            var _ok = global.selftest_tour_missing == 0 && _after == global.selftest_tour_before && global.workspace_dirty && global.tutorial_current == 1
                && !instance_exists(obj_editor_tour) && !instance_exists(obj_code_editor) && !instance_exists(obj_tile_editor)
                && !file_exists(global.amiga_dev_data_path + "/tour_stash_workspace.json");
            screen_save(global.selftest_tour_dir + "/999_restored.png");
            global.workspace_dirty = false;
            scr_amiga_selftest_finish(_ok);
            break;
    }
}

/// Node / root / asset summary used to compare workspaces.
function scr_amiga_selftest_tour_signature() {
    var _parts = [];
    with (obj_amiga_root_node) array_push(_parts, root_type + "@" + string(node_x) + "," + string(node_y));
    with (obj_opcode_node) array_push(_parts, (is_macro ? macro_type : opcode_mnemonic) + "@" + string(node_x) + "," + string(node_y) + "/" + node_label);
    array_sort(_parts, true);
    var _assets = [];
    var _a = 0;
    while (_a < array_length(global.asset_list)) {
        array_push(_assets, global.asset_list[_a].type + ":" + global.asset_list[_a].name);
        _a += 1;
    }
    return string(array_length(_parts)) + " items [" + string_join_ext(" ", _parts) + "] assets [" + string_join_ext(" ", _assets) + "]";
}
