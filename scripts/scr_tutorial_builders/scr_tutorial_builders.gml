/// @desc Node graphs and assets for the ten tutorials (see scr_tutorials).

/// Builds tutorial _number (1..10) into the cleared workspace. Returns true on success.
function scr_tutorial_build(_number) {
    var _init = scr_tutorial_make_init();
    return _init != noone;
}

/// Fresh INIT root at the usual place; returns it.
function scr_tutorial_make_init() {
    var _init_x = (room_width / 2) - 80;
    var _init_y = room_height / 4;
    var _init = instance_create_layer(_init_x, _init_y, "Instances", obj_amiga_root_node);
    _init.root_type = "INIT";
    _init.node_x = scr_snap_to_grid(_init_x, global.grid_size);
    _init.node_y = scr_snap_to_grid(_init_y, global.grid_size);
    return _init;
}
