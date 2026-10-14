/// @desc scr_amiga_trigger_build()
/// The full F5 build sequence, extracted so the F5 key, the RUN button,
/// clicking the INIT node and F5 inside the code editor all trigger it
/// identically. Wrapped in with(obj_amiga_manager) so build_state and
/// friends resolve correctly no matter which instance calls this.
function scr_amiga_trigger_build() {
    with (obj_amiga_manager) {
        if (build_state != "idle") {
            scr_set_status_message("A build is already running.");
            exit;
        }

        var _node_array = scr_amiga_collect_program_nodes();

        if (array_length(_node_array) == 0) {
            scr_set_status_message("Nothing to build — add at least one node first.");
        } else if (!scr_amiga_has_core_loop(_node_array)) {
            // Amiga has nowhere to fall back to the way C64 returns to BASIC
            // on RTS — a program with no branch back to an earlier label
            // just runs off the end into unowned memory and traps. Catch
            // that here rather than let it build clean and crash in FS-UAE.
            scr_set_status_message("F5 - BAD BUILD (NO CORE LOOP)", c_red);
        } else {
            with (obj_opcode_node) build_error_text = "";
            var _start_result = scr_amiga_start_build(_node_array, global.current_project_path, global.current_chipset_mode);

            if (_start_result.success) {
                build_project_path = global.current_project_path;
                build_volume_name = global.current_volume_name;
                build_exe_path = _start_result.exe_path;
                build_done_path = _start_result.done_path;
                build_log_path = _start_result.log_path;
                build_line_map = _start_result.line_map;
                build_uses_dos_loader = _start_result.uses_dos_loader;
                build_state = "waiting_for_asm";
                build_wait_timer = 0;
                build_exe_last_size = -1;
                build_exe_stable_timer = 0;
                global.code_editor_build_errors = [];
                scr_set_status_message("Assembling (" + scr_amiga_machine_profile().name + ")...");
            } else {
                var _e = 0;
                while (_e < array_length(_start_result.error_list) && _e < 5) {
                    scr_set_status_message(string_replace(_start_result.error_list[_e], "; ERROR: ", "ERROR: "), c_red);
                    _e += 1;
                }
                scr_set_status_message("WONT BUILD (ERRORS IN CODE)", c_red);
            }
        }
    }
}
