/// @desc scr_sprite_editor_layout()
/// Computes every position the sprite editor panel needs, once, so Step
/// (click detection) and Draw (rendering) always agree — the same lesson
/// as scr_amiga_find_insert_point: one shared implementation, not two that
/// could quietly drift out of sync with each other.
function scr_sprite_editor_layout() {
    var _panel_x = global.sprite_editor_x;
    var _panel_y = global.sprite_editor_y;
    var _panel_width = 260;
    var _cell_size = 14;
    var _grid_x = _panel_x + 18;
    var _grid_y = _panel_y + 112;
    var _grid_width = 16 * _cell_size;
    var _grid_height = global.sprite_height * _cell_size;
    var _palette_y = _grid_y + _grid_height + 28;
    var _slider_x = _panel_x + 32;
    var _slider_width = 192;
    var _slider_step_width = _slider_width / 16;
    var _panel_height = (_palette_y - _panel_y) + 126;

    var _layout = {
        panel_x : _panel_x,
        panel_y : _panel_y,
        panel_width : _panel_width,
        panel_height : _panel_height,
        header_x : _panel_x,
        header_y : _panel_y,
        header_width : _panel_width,
        header_height : 20,
        cell_size : _cell_size,
        grid_x : _grid_x,
        grid_y : _grid_y,
        grid_width : _grid_width,
        grid_height : _grid_height,
        close_x : _panel_x + _panel_width - 20,
        close_y : _panel_y + 2,
        channel_minus_x : _panel_x + 90,
        channel_plus_x : _panel_x + 130,
        channel_row_y : _panel_y + 24,
        height_field_x : _panel_x + 90,
        height_row_y : _panel_y + 44,
        addr_field_x : _panel_x + 90,
        addr_row_y : _panel_y + 64,
        swatch_row_y : _panel_y + 88,
        swatch_width : 40,
        swatch_height : 18,
        swatch_x : _panel_x + 12,
        palette_y : _palette_y,
        palette_preview_x : _panel_x + 12,
        palette_preview_y : _palette_y + 18,
        palette_preview_width : 40,
        palette_preview_height : 64,
        slider_x : _slider_x,
        slider_width : _slider_width,
        slider_height : 16,
        slider_step_width : _slider_step_width,
        slider_r_y : _palette_y + 18,
        slider_g_y : _palette_y + 42,
        slider_b_y : _palette_y + 66
    };

    return _layout;
}
