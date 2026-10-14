/// @desc FS-UAE machine settings and launch, modelled on ADAM's launch_fsuae_now.
/// Two machines, picked with the MACHINE button (and following the chipset):
///   A600  - OCS/ECS, 1 MB chip RAM (FS-UAE model A600)
///   A1200 - AGA, 2 MB chip RAM (FS-UAE model A1200)
/// The Kickstart ROM is optional and per machine: with none FS-UAE uses its
/// free AROS replacement ROM, which boots the auto-boot disks fine.

/// Loads machine/ROM/launch preferences from settings.ini. Call once at start.
function scr_amiga_machine_settings_load() {
    ini_open("settings.ini");
    global.amiga_machine = ini_read_string("machine", "model", "A1200");
    global.kickstart_path_a600 = ini_read_string("paths", "kickstart_a600", "");
    global.kickstart_path_a1200 = ini_read_string("paths", "kickstart_a1200", "");
    global.fsuae_light_mode = ini_read_real("machine", "light_mode", 0) == 1;
    global.fsuae_joystick_pad = ini_read_real("machine", "gamepad", 0) == 1;
    global.build_boot_mode = ini_read_string("machine", "boot_mode", "AUTO");
    ini_close();

    if (global.amiga_machine != "A600" && global.amiga_machine != "A1200") global.amiga_machine = "A1200";
    if (global.build_boot_mode != "AUTO" && global.build_boot_mode != "DOS") global.build_boot_mode = "AUTO";
    if (global.kickstart_path_a600 != "" && !file_exists(global.kickstart_path_a600)) global.kickstart_path_a600 = "";
    if (global.kickstart_path_a1200 != "" && !file_exists(global.kickstart_path_a1200)) global.kickstart_path_a1200 = "";

    // The chipset follows the machine: AGA only exists on the A1200.
    global.current_chipset_mode = global.amiga_machine == "A1200" ? "AGA" : "OCS";
}

function scr_amiga_machine_settings_save() {
    ini_open("settings.ini");
    ini_write_string("machine", "model", global.amiga_machine);
    ini_write_string("paths", "kickstart_a600", global.kickstart_path_a600);
    ini_write_string("paths", "kickstart_a1200", global.kickstart_path_a1200);
    ini_write_real("machine", "light_mode", global.fsuae_light_mode ? 1 : 0);
    ini_write_real("machine", "gamepad", global.fsuae_joystick_pad ? 1 : 0);
    ini_write_string("machine", "boot_mode", global.build_boot_mode);
    ini_close();
}

/// { name, fsuae_model, chip_kb, chipset } for the selected machine.
function scr_amiga_machine_profile() {
    if (global.amiga_machine == "A600") {
        return { name : "A600", fsuae_model : "A600", chip_kb : 1024, chipset : "OCS" };
    }
    return { name : "A1200", fsuae_model : "A1200", chip_kb : 2048, chipset : "AGA" };
}

function scr_amiga_machine_toggle() {
    global.amiga_machine = global.amiga_machine == "A600" ? "A1200" : "A600";
    global.current_chipset_mode = global.amiga_machine == "A1200" ? "AGA" : "OCS";
    scr_amiga_machine_settings_save();
    var _profile = scr_amiga_machine_profile();
    scr_set_status_message("Machine: " + _profile.name + " (" + _profile.chipset + ", " + string(_profile.chip_kb div 1024) + " MB chip RAM). Kickstart: " + scr_amiga_kickstart_label(), make_colour_rgb(0, 255, 255));
}

/// Kickstart ROM of the selected machine, or "" for FS-UAE's AROS ROM.
function scr_amiga_kickstart_current() {
    var _path = global.amiga_machine == "A600" ? global.kickstart_path_a600 : global.kickstart_path_a1200;
    if (_path != "" && !file_exists(_path)) return "";
    return _path;
}

function scr_amiga_kickstart_label() {
    var _path = scr_amiga_kickstart_current();
    if (_path == "") return "AROS (built in)";
    return filename_name(_path);
}

/// Lets the user pick a Kickstart ROM for the selected machine.
function scr_amiga_kickstart_choose() {
    var _chosen = get_open_filename("Kickstart ROM|*.rom;*.bin|All Files|*.*", "");
    if (_chosen == "") return false;

    if (global.amiga_machine == "A600") global.kickstart_path_a600 = _chosen;
    else global.kickstart_path_a1200 = _chosen;

    // Keep the legacy single key in step for older builds reading settings.ini.
    global.kickstart_path = _chosen;
    scr_amiga_machine_settings_save();
    scr_set_status_message(global.amiga_machine + " Kickstart set: " + filename_name(_chosen), make_colour_rgb(0, 255, 255));
    return true;
}

function scr_amiga_kickstart_clear() {
    if (global.amiga_machine == "A600") global.kickstart_path_a600 = "";
    else global.kickstart_path_a1200 = "";
    scr_amiga_machine_settings_save();
    scr_set_status_message(global.amiga_machine + " Kickstart cleared - FS-UAE's AROS ROM will be used.", make_colour_rgb(0, 255, 255));
}

/// Folder FS-UAE keeps its logs, settings and save states in. A private
/// folder (not Documents\FS-UAE) so anti-virus "protected folders" never
/// block it, as ADAM found.
function scr_amiga_fsuae_base_dir() {
    var _base = global.amiga_dev_data_path + "/fs-uae-data";
    if (!directory_exists(_base)) directory_create(_base);
    return _base;
}

/// Command line for booting _adf on the selected machine.
function scr_amiga_fsuae_args(_adf) {
    var _profile = scr_amiga_machine_profile();
    var _args = "--amiga_model=" + _profile.fsuae_model
        + " --chip_memory=" + string(_profile.chip_kb)
        + " --slow_memory=0 --fast_memory=0"
        + " --floppy_drive_0=\"" + _adf + "\""
        + " --floppy_drive_speed=0"
        + " --floppy_drive_volume=0"
        + " --fullscreen=0"
        + " --window_x=500 --window_y=200"
        + " --window_width=960 --window_height=720"
        + " --automatic_input_grab=0 --initial_input_grab=0"
        + " --load_state=0";

    if (global.fsuae_light_mode) {
        // No host vsync spin-wait and no smoothing filter: far less CPU/GPU load.
        _args += " --video_sync=off --texture_filter=nearest";
    }

    // Joystick port 2 (FS-UAE port 1): cursor keys + right Ctrl, or the first gamepad.
    _args += " --joystick_port_1=" + (global.fsuae_joystick_pad ? "auto" : "keyboard");

    // An explicit empty kickstart_file overrides the bundled Default.fs-uae
    // (which points at a dummy file) so FS-UAE falls back to AROS cleanly.
    _args += " --kickstart_file=\"" + scr_amiga_kickstart_current() + "\"";
    _args += " --base_dir=\"" + scr_amiga_fsuae_base_dir() + "\"";
    return _args;
}

/// Closes any FS-UAE an earlier run left open. Asynchronous; launch a few
/// frames later (the manager's build state machine does this).
function scr_amiga_fsuae_close() {
    execute_shell_simple("taskkill.exe", "/F /IM fs-uae.exe", "open", 0);
}

/// Boots _adf in the bundled FS-UAE. Returns true when the launch was started.
function scr_amiga_fsuae_launch(_adf) {
    if (!file_exists(global.fsuae_path)) {
        scr_set_status_message("FS-UAE not found at " + global.fsuae_path, c_red);
        return false;
    }

    if (!file_exists(_adf)) {
        scr_set_status_message("No disk to boot: " + _adf, c_red);
        return false;
    }

    var _fsuae_dir = filename_dir(global.fsuae_path);
    var _started = execute_shell_simple(global.fsuae_path, scr_amiga_fsuae_args(_adf), "open", 5, _fsuae_dir);
    var _profile = scr_amiga_machine_profile();
    scr_set_status_message("FS-UAE booting " + _profile.name + " (" + scr_amiga_kickstart_label() + ") - the program starts by itself.", make_colour_rgb(0, 255, 255));
    return _started;
}
