/// @desc scr_amiga_trigger_build()
/// The full F5 build sequence, extracted so both the F5 keypress and
/// clicking the INIT node can trigger it identically. Wrapped in
/// with(obj_amiga_manager) so build_state and friends resolve correctly
/// no matter which instance actually calls this.
function scr_amiga_trigger_build() {
    with (obj_amiga_manager) {
        if (build_state != "idle") {
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
            // Only the DOS-loader path (a BITMAP_DISPLAY macro anywhere in
            // the program) needs a real Kickstart to auto-run
            // Startup-Sequence. Plain direct-bootblock tests boot fine on
            // FS-UAE's built-in AROS replacement, so there's no reason to
            // interrupt those with a prompt.
            var _requires_kickstart = false;
            var _node_scan_index = 0;
            var _node_count = array_length(_node_array);

            while (_node_scan_index < _node_count) {
                if (_node_array[_node_scan_index].is_macro && _node_array[_node_scan_index].macro_type == "BITMAP_DISPLAY") {
                    _requires_kickstart = true;
                }
                _node_scan_index += 1;
            }

            // Kickstart ROM picker disabled for now — internal testing
            // only, boots straight to FS-UAE's bundled AROS fallback as
            // before. Revisit once a licensed ROM workflow is needed.
            // if (_requires_kickstart) {
            //     scr_amiga_ensure_kickstart_path();
            // }

            if (_requires_kickstart) {
                scr_set_status_message("Booting with unknown Kickstart — at CLI 1> please enter " + chr(34) + "DF0:main" + chr(34));
            }

            var _start_result = scr_amiga_start_build(_node_array, global.current_project_path, global.current_chipset_mode);

            if (_start_result.success) {
                build_project_path = global.current_project_path;
                build_volume_name = global.current_volume_name;
                build_exe_path = _start_result.exe_path;
                build_uses_dos_loader = _start_result.uses_dos_loader;
                build_state = "waiting_for_asm";
                build_wait_timer = 0;
                build_exe_last_size = -1;
                build_exe_stable_timer = 0;
            } else {
                show_debug_message("Build blocked by opcode errors — see previous debug lines.");
                scr_set_status_message("WONT BUILD (ERRORS IN CODE)", c_red);
            }
        }
    }
}
