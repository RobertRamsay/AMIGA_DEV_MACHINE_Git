/// @desc scr_bitmap_editor_layout(_editor)
/// Shared responsive geometry for bitmap-editor Step and Draw events.
function scr_bitmap_editor_layout(_editor) {
    _editor.panel_width = min(1280, room_width - 40);
    _editor.panel_height = min(1024, room_height - 40);
    _editor.panel_x = clamp(_editor.panel_x, 0, room_width - _editor.panel_width);
    _editor.panel_y = clamp(_editor.panel_y, 0, room_height - 20);

    var _left_width = 150;
    var _right_width = 250;
    var _canvas_x = _editor.panel_x + _left_width + 10;
    var _canvas_y = _editor.panel_y + 42;
    var _canvas_width = _editor.panel_width - _left_width - _right_width - 30;
    var _canvas_height = _editor.panel_height - 58;
    var _content_width = 320 * _editor.bitmap_zoom;
    var _content_height = 256 * _editor.bitmap_zoom;
    var _max_scroll_x = max(0, _content_width - _canvas_width);
    var _max_scroll_y = max(0, _content_height - _canvas_height);

    _editor.bitmap_scroll_x = clamp(_editor.bitmap_scroll_x, 0, _max_scroll_x);
    _editor.bitmap_scroll_y = clamp(_editor.bitmap_scroll_y, 0, _max_scroll_y);

    return {
        panel_x : _editor.panel_x,
        panel_y : _editor.panel_y,
        panel_width : _editor.panel_width,
        panel_height : _editor.panel_height,
        header_x : _editor.panel_x,
        header_y : _editor.panel_y,
        header_width : _editor.panel_width,
        header_height : 24,
        close_x : _editor.panel_x + _editor.panel_width - 22,
        close_y : _editor.panel_y + 3,
        left_x : _editor.panel_x + 10,
        left_y : _editor.panel_y + 42,
        right_x : _editor.panel_x + _editor.panel_width - _right_width + 10,
        right_y : _editor.panel_y + 42,
        canvas_x : _canvas_x,
        canvas_y : _canvas_y,
        canvas_width : _canvas_width,
        canvas_height : _canvas_height,
        content_width : _content_width,
        content_height : _content_height,
        max_scroll_x : _max_scroll_x,
        max_scroll_y : _max_scroll_y,
        display_x : _canvas_x + max(0, (_canvas_width - _content_width) / 2),
        display_y : _canvas_y + max(0, (_canvas_height - _content_height) / 2),
        zoom_x : _editor.panel_x + 10,
        zoom_y : _editor.panel_y + 76,
        clear_x : _editor.panel_x + 10,
        clear_y : _editor.panel_y + 116,
        swatch_x : _editor.panel_x + _editor.panel_width - _right_width + 10,
        swatch_y : _editor.panel_y + 66,
        swatch_width : 52,
        swatch_height : 24,
        swatch_gap : 4,
        slider_x : _editor.panel_x + _editor.panel_width - _right_width + 34,
        slider_width : 192,
        slider_step_width : 12,
        slider_height : 18,
        slider_r_y : _editor.panel_y + 330,
        slider_g_y : _editor.panel_y + 358,
        slider_b_y : _editor.panel_y + 386,
        preview_x : _editor.panel_x + _editor.panel_width - _right_width + 10,
        preview_y : _editor.panel_y + 330,
        preview_width : 18,
        preview_height : 74
    };
}
