/// @desc scr_amiga_ensure_kickstart_path()
/// Prompts for a Kickstart ROM the first time one is needed and saves the
/// choice to settings.ini so it persists across runs. Never blocks the
/// build — FS-UAE will fall back to its AROS replacement ROM if none is
/// set, which still boots, just without auto-running Startup-Sequence.
function scr_amiga_ensure_kickstart_path() {
    if (global.kickstart_path != "") {
        return true;
    }

    var _chosen_path = get_open_filename("Kickstart ROM|*.rom|All Files|*.*", "");

    if (_chosen_path == "") {
        scr_set_status_message("No Kickstart ROM set — FS-UAE will boot to a CLI. Type DF0:main at the 1> prompt to run the build.");
        return false;
    }

    global.kickstart_path = _chosen_path;

    ini_open("settings.ini");
    ini_write_string("paths", "kickstart", global.kickstart_path);
    ini_close();

    scr_set_status_message("Kickstart ROM set: " + global.kickstart_path);
    return true;
}