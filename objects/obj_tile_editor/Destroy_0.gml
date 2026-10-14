// Free every cached surface and buffer; drop half-typed dialog text.
if (surface_exists(atlas_surface)) surface_free(atlas_surface);
if (buffer_exists(atlas_buffer)) buffer_delete(atlas_buffer);
if (surface_exists(overview_surface)) surface_free(overview_surface);
if (buffer_exists(overview_buffer)) buffer_delete(overview_buffer);
var _names = variable_struct_get_names(sprite_cache);
var _i = 0;
while (_i < array_length(_names)) {
    var _entry = sprite_cache[$ _names[_i]];
    if (is_struct(_entry) && surface_exists(_entry.surf)) surface_free(_entry.surf);
    _i += 1;
}
sprite_cache = {};
keyboard_string = "";
