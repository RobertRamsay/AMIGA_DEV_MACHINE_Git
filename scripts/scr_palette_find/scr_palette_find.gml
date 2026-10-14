/// Type to find in the palette (global.palette_find, typed by the manager
/// Step while the mouse is over the palette): matching, match count and
/// scrolling the list to the matches.

/// True when the palette label starts with the letters typed so far.
function scr_palette_find_match(_label) {
    var _find = global.palette_find;
    if (_find == "") return false;
    return string_upper(string_copy(_label, 1, string_length(_find))) == _find;
}

/// Number of scrolling palette entries that match.
function scr_palette_find_count() {
    var _count = 0;
    with (obj_opcode_palette_item) {
        if (!palette_top_strip && scr_palette_find_match(palette_display_label)) _count += 1;
    }
    return _count;
}

/// Scrolls the palette so the matches are on screen: when they are not all
/// visible already, the row of the first match goes to the top of the list.
function scr_palette_find_scroll() {
    var _list_top = infinity;
    var _list_bottom = -infinity;
    var _first = infinity;
    var _last = -infinity;
    with (obj_opcode_palette_item) {
        if (palette_top_strip) continue;
        _list_top = min(_list_top, base_palette_y);
        _list_bottom = max(_list_bottom, base_palette_y + palette_height);
        if (scr_palette_find_match(palette_display_label)) {
            _first = min(_first, base_palette_y);
            _last = max(_last, base_palette_y + palette_height);
        }
    }
    if (_first == infinity) return;
    var _top = global.palette_panel_bounds.top;
    var _bottom = global.palette_panel_bounds.bottom;
    var _scroll = global.palette_scroll_y;
    if (_first + _scroll >= _top && _last + _scroll <= _bottom) return;
    // Never past the end of the list (the last entry stays above the bottom).
    var _min_scroll = min(0, _bottom - 4 - _list_bottom);
    global.palette_scroll_y = clamp(_list_top - _first, _min_scroll, 0);
}
