/// @desc scr_asset_find_by_name(_name)
/// Looks up a named asset in global.asset_list, matching C64DM's
/// obj_asset_manager.asset_list lookup pattern. Returns the asset struct,
/// or undefined if no asset with that name exists.
function scr_asset_find_by_name(_name) {
    var _count = array_length(global.asset_list);
    var _i = 0;

    while (_i < _count) {
        if (global.asset_list[_i].name == _name) {
            return global.asset_list[_i];
        }

        _i += 1;
    }

    return undefined;
}
