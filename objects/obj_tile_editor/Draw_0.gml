draw_set_font(font_CyberVerse);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var _texfilter = gpu_get_texfilter();
gpu_set_texfilter(false);

var _col_panel = make_colour_rgb(18, 22, 30);
var _col_header = make_colour_rgb(65, 82, 105);
var _col_button = make_colour_rgb(45, 65, 85);
var _col_button_on = make_colour_rgb(35, 110, 75);
var _col_box = make_colour_rgb(10, 12, 18);
var _col_dim = make_colour_rgb(150, 160, 175);
var _cy = content_y;
var _ax = col_a_x;

// --- window ---------------------------------------------------------------------
draw_set_alpha(0.6);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(0.98);
draw_set_colour(_col_panel);
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);
draw_set_colour(_col_header);
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + header_h, false);
draw_set_colour(c_white);
draw_text(panel_x + 10, panel_y + 5, "TILES & MAPS");
draw_set_colour(_col_dim);
draw_text(panel_x + 200, panel_y + 5, "Esc closes   Ctrl+Z / Ctrl+Y undo / redo   Mouse wheel scrolls lists and tile grids");

// --- lists ---------------------------------------------------------------------------
var _lists = te_lists();
var _l = 0;
while (_l < array_length(_lists)) {
    var _list = _lists[_l];
    var _names = _list.names;
    var _scroll = list_scroll[$ _list.id];
    var _lh = _list.rows * row_h;
    draw_set_colour(c_white);
    draw_text(_list.x, _list.y - 22, _list.title + "  (" + string(array_length(_names)) + ")");
    draw_set_colour(_col_box);
    draw_rectangle(_list.x, _list.y, _list.x + _list.w, _list.y + _lh, false);
    draw_set_colour(c_gray);
    draw_rectangle(_list.x, _list.y, _list.x + _list.w, _list.y + _lh, true);
    var _r = 0;
    while (_r < _list.rows && _scroll + _r < array_length(_names)) {
        var _ry = _list.y + _r * row_h;
        if (_names[_scroll + _r] == _list.selected) {
            draw_set_colour(_col_button_on);
            draw_rectangle(_list.x + 1, _ry + 1, _list.x + _list.w - 1, _ry + row_h - 1, false);
        }
        draw_set_colour(c_white);
        draw_text(_list.x + 6, _ry + 2, _names[_scroll + _r]);
        _r += 1;
    }
    if (array_length(_names) > _list.rows) {
        var _bar_h = _lh * _list.rows / array_length(_names);
        var _bar_y = _list.y + (_lh - _bar_h) * _scroll / max(1, array_length(_names) - _list.rows);
        draw_set_colour(c_gray);
        draw_rectangle(_list.x + _list.w - 6, _bar_y, _list.x + _list.w - 1, _bar_y + _bar_h, false);
    }
    if (array_length(_names) == 0) {
        draw_set_colour(_col_dim);
        draw_text(_list.x + 8, _list.y + 6, "Nothing yet - press NEW");
    }
    _l += 1;
}

// --- tile grids ------------------------------------------------------------------------
var _ts = te_tileset();
var _grids = te_grids();
var _g = 0;
while (_g < array_length(_grids)) {
    var _grid = _grids[_g];
    var _gts = (_grid.id == "picker") ? te_map_tileset() : _ts;
    draw_set_colour(_col_box);
    draw_rectangle(_grid.x, _grid.y, _grid.x + _grid.w, _grid.y + _grid.h, false);
    draw_set_colour(c_gray);
    draw_rectangle(_grid.x, _grid.y, _grid.x + _grid.w, _grid.y + _grid.h, true);
    if (_gts != undefined && te_atlas_prepare(_gts)) {
        var _cols = max(1, _grid.w div grid_cell);
        var _vis_rows = _grid.h div grid_cell;
        var _first = grid_scroll[$ _grid.id] * _cols;
        var _count = array_length(_gts.tiles);
        var _scale = 32 / _gts.tile_size;
        var _t = _first;
        while (_t < _count && _t < _first + _vis_rows * _cols) {
            var _gx = _grid.x + ((_t - _first) mod _cols) * grid_cell + 2;
            var _gy = _grid.y + ((_t - _first) div _cols) * grid_cell + 2;
            te_draw_tile(_gts, _t, _gx, _gy, _scale);
            var _fl = (_t < array_length(_gts.flags)) ? _gts.flags[_t] : 0;
            var _f = 0;
            while (_f < 5) {
                if ((_fl & flag_bits[_f]) != 0) {
                    draw_set_colour(flag_colours[_f]);
                    draw_rectangle(_gx + 1 + _f * 6, _gy + 27, _gx + 4 + _f * 6, _gy + 30, false);
                }
                _f += 1;
            }
            if (_t == _grid.selected) {
                draw_set_colour(c_yellow);
                draw_rectangle(_gx - 2, _gy - 2, _gx + 33, _gy + 33, true);
                draw_rectangle(_gx - 1, _gy - 1, _gx + 32, _gy + 32, true);
            }
            _t += 1;
        }
        var _total_rows = ceil(_count / _cols);
        if (_total_rows > _vis_rows) {
            var _gbar_h = _grid.h * _vis_rows / _total_rows;
            var _gbar_y = _grid.y + (_grid.h - _gbar_h) * grid_scroll[$ _grid.id] / max(1, _total_rows - _vis_rows);
            draw_set_colour(c_gray);
            draw_rectangle(_grid.x + _grid.w - 5, _gbar_y, _grid.x + _grid.w - 1, _gbar_y + _gbar_h, false);
        }
    }
    _g += 1;
}

// --- tab content -----------------------------------------------------------------------
switch (tab) {
    case "TILES":
        if (_ts == undefined) {
            draw_set_colour(_col_dim);
            draw_text(pix_x, pix_y + 10, "No tileset yet. Press NEW (left) to make one: choose a name and a tile size.");
            break;
        }
        te_atlas_prepare(_ts);
        var _size = _ts.tile_size;
        var _count = array_length(_ts.tiles);
        draw_set_colour(c_white);
        draw_text(_ax, _cy + 250, "TILES (" + string(_count) + ")  selected: " + string(tile_sel) + "  " + string(_size) + " px");

        var _pal = array_create(16, c_black);
        var _p = 0;
        while (_p < 16) {
            _pal[_p] = scr_te_palette_colour(_ts, _p);
            _p += 1;
        }

        // Pixel editor.
        var _zoom = te_pix_zoom(_size);
        var _side = _size * _zoom;
        var _pixels = (tile_sel < _count) ? _ts.tiles[tile_sel] : array_create(_size * _size, 0);
        var _y = 0;
        while (_y < _size) {
            var _x = 0;
            while (_x < _size) {
                draw_set_colour(_pal[clamp(_pixels[_y * _size + _x], 0, 15)]);
                draw_rectangle(pix_x + _x * _zoom, pix_y + _y * _zoom, pix_x + (_x + 1) * _zoom - 1, pix_y + (_y + 1) * _zoom - 1, false);
                _x += 1;
            }
            _y += 1;
        }
        // Line / rectangle preview while dragging.
        if (stroke_active && (tool == "LINE" || tool == "RECT")) {
            draw_set_colour(_pal[stroke_colour]);
            draw_set_alpha(0.85);
            if (tool == "LINE") {
                var _lx = stroke_x0, _ly = stroke_y0;
                var _dx = abs(stroke_x1 - _lx), _sx = _lx < stroke_x1 ? 1 : -1;
                var _dy = -abs(stroke_y1 - _ly), _sy = _ly < stroke_y1 ? 1 : -1;
                var _err = _dx + _dy;
                repeat (256) {
                    draw_rectangle(pix_x + _lx * _zoom, pix_y + _ly * _zoom, pix_x + (_lx + 1) * _zoom - 1, pix_y + (_ly + 1) * _zoom - 1, false);
                    if (_lx == stroke_x1 && _ly == stroke_y1) break;
                    var _e2 = 2 * _err;
                    if (_e2 >= _dy) { _err += _dy; _lx += _sx; }
                    if (_e2 <= _dx) { _err += _dx; _ly += _sy; }
                }
            } else {
                var _rl = min(stroke_x0, stroke_x1), _rr = max(stroke_x0, stroke_x1);
                var _rt = min(stroke_y0, stroke_y1), _rb = max(stroke_y0, stroke_y1);
                var _filled = keyboard_check(vk_shift);
                var _yy = _rt;
                while (_yy <= _rb) {
                    var _xx = _rl;
                    while (_xx <= _rr) {
                        if (_filled || _xx == _rl || _xx == _rr || _yy == _rt || _yy == _rb) {
                            draw_rectangle(pix_x + _xx * _zoom, pix_y + _yy * _zoom, pix_x + (_xx + 1) * _zoom - 1, pix_y + (_yy + 1) * _zoom - 1, false);
                        }
                        _xx += 1;
                    }
                    _yy += 1;
                }
            }
            draw_set_alpha(1);
        }
        if (_zoom >= 6) {
            draw_set_colour(c_black);
            draw_set_alpha(0.35);
            var _gl = 1;
            while (_gl < _size) {
                draw_line(pix_x + _gl * _zoom - 1, pix_y, pix_x + _gl * _zoom - 1, pix_y + _side - 1);
                draw_line(pix_x, pix_y + _gl * _zoom - 1, pix_x + _side - 1, pix_y + _gl * _zoom - 1);
                _gl += 1;
            }
            draw_set_alpha(1);
        }
        draw_set_colour(c_gray);
        draw_rectangle(pix_x - 1, pix_y - 1, pix_x + _side, pix_y + _side, true);
        if (point_in_rectangle(mouse_x, mouse_y, pix_x, pix_y, pix_x + _side - 1, pix_y + _side - 1) && dlg_kind == "") {
            var _hx = (mouse_x - pix_x) div _zoom;
            var _hy = (mouse_y - pix_y) div _zoom;
            draw_set_colour(c_white);
            draw_rectangle(pix_x + _hx * _zoom, pix_y + _hy * _zoom, pix_x + (_hx + 1) * _zoom - 1, pix_y + (_hy + 1) * _zoom - 1, true);
        }
        if (tile_sel == 0) {
            draw_set_colour(c_black);
            draw_set_alpha(0.6);
            draw_rectangle(pix_x, pix_y + _side / 2 - 30, pix_x + _side - 1, pix_y + _side / 2 + 30, false);
            draw_set_alpha(1);
            draw_set_colour(c_yellow);
            draw_set_halign(fa_center);
            draw_text(pix_x + _side / 2, pix_y + _side / 2 - 22, "TILE 0 IS THE EMPTY TILE - LOCKED");
            draw_text(pix_x + _side / 2, pix_y + _side / 2, "(always colour 0, no flags)");
            draw_set_halign(fa_left);
        }

        // Palette.
        draw_set_colour(c_white);
        draw_text(tools_x, _cy + 86, "PALETTE - click a colour to paint with it");
        _p = 0;
        while (_p < 16) {
            var _swx = tools_x + (_p mod 8) * 52;
            var _swy = _cy + 110 + (_p div 8) * 52;
            draw_set_colour(_pal[_p]);
            draw_rectangle(_swx, _swy, _swx + 45, _swy + 45, false);
            draw_set_colour(_p == pal_sel ? c_yellow : c_gray);
            draw_rectangle(_swx, _swy, _swx + 45, _swy + 45, true);
            if (_p == pal_sel) draw_rectangle(_swx - 2, _swy - 2, _swx + 47, _swy + 47, true);
            _p += 1;
        }
        draw_set_colour(c_white);
        var _hex = "0123456789ABCDEF";
        draw_text(tools_x, _cy + 222, "COLOUR " + string(pal_sel) + "   $" + string_char_at(_hex, _ts.colour_r[pal_sel] + 1)
            + string_char_at(_hex, _ts.colour_g[pal_sel] + 1) + string_char_at(_hex, _ts.colour_b[pal_sel] + 1));
        var _gun_names = ["R", "G", "B"];
        var _guns = [_ts.colour_r, _ts.colour_g, _ts.colour_b];
        var _gun_cols = [c_red, c_lime, make_colour_rgb(60, 120, 255)];
        var _gi = 0;
        while (_gi < 3) {
            var _by = _cy + 252 + _gi * 30;
            draw_set_colour(c_white);
            draw_text(tools_x + 4, _by + 2, _gun_names[_gi]);
            var _v = 0;
            while (_v < 16) {
                draw_set_colour(_v <= _guns[_gi][pal_sel] ? _gun_cols[_gi] : _col_box);
                draw_rectangle(tools_x + 60 + _v * 18, _by, tools_x + 60 + _v * 18 + 15, _by + 23, false);
                _v += 1;
            }
            draw_set_colour(c_white);
            draw_text(tools_x + 394, _by + 2, string(_guns[_gi][pal_sel]));
            _gi += 1;
        }
        draw_text(tools_x, _cy + 352, "FLAGS OF TILE " + string(tile_sel) + (tile_sel == 0 ? "  (tile 0 is locked)" : ""));

        // Previews.
        var _pvy = _cy + 430;
        draw_set_colour(c_white);
        draw_text(tools_x, _pvy, "PREVIEW 1x");
        draw_text(tools_x + 150, _pvy, "2x");
        draw_text(tools_x + 260, _pvy, "TILED 3 x 3 (2x)");
        te_draw_tile(_ts, tile_sel, tools_x, _pvy + 26, 1);
        te_draw_tile(_ts, tile_sel, tools_x + 150, _pvy + 26, 2);
        var _ty = 0;
        while (_ty < 3) {
            var _tx = 0;
            while (_tx < 3) {
                te_draw_tile(_ts, tile_sel, tools_x + 260 + _tx * _size * 2, _pvy + 26 + _ty * _size * 2, 2);
                _tx += 1;
            }
            _ty += 1;
        }
        draw_set_colour(_col_dim);
        var _hy2 = _pvy + 26 + _size * 6 + 16;
        draw_text(tools_x, _hy2, "Tools: D draw, L line, R rect (Shift = filled), F fill, P pick colour");
        draw_text(tools_x, _hy2 + 22, "Left button paints the selected colour, right button paints colour 0.");
        draw_text(tools_x, _hy2 + 44, "Deleting a tile renumbers every map and metatile that uses this set.");
        break;

    case "METATILES":
        if (_ts == undefined) {
            draw_set_colour(_col_dim);
            draw_text(pix_x, pix_y + 10, "No tileset yet. Make one in the TILES tab first.");
            break;
        }
        te_atlas_prepare(_ts);
        draw_set_colour(c_white);
        draw_text(tools_x, _cy + 14, "TILE PICKER  selected tile " + string(meta_tile) + "  (left paints it, right paints tile 0)");
        var _meta = te_meta(_ts, meta_name);
        if (_meta == undefined) {
            draw_set_colour(_col_dim);
            draw_text(pix_x, pix_y + 10, "No metatile selected. Press NEW to make one (a stamp of several tiles).");
            break;
        }
        var _msize = _ts.tile_size;
        var _cell = te_meta_cell(_meta, _msize);
        draw_set_colour(scr_te_palette_colour(_ts, 0));
        draw_rectangle(pix_x, pix_y, pix_x + _meta.w * _cell - 1, pix_y + _meta.h * _cell - 1, false);
        var _my2 = 0;
        while (_my2 < _meta.h) {
            var _mx2 = 0;
            while (_mx2 < _meta.w) {
                te_draw_tile(_ts, _meta.cells[_my2 * _meta.w + _mx2], pix_x + _mx2 * _cell, pix_y + _my2 * _cell, _cell / _msize);
                _mx2 += 1;
            }
            _my2 += 1;
        }
        draw_set_colour(c_black);
        draw_set_alpha(0.5);
        var _gx2 = 1;
        while (_gx2 < _meta.w) {
            draw_line(pix_x + _gx2 * _cell - 1, pix_y, pix_x + _gx2 * _cell - 1, pix_y + _meta.h * _cell - 1);
            _gx2 += 1;
        }
        var _gy2 = 1;
        while (_gy2 < _meta.h) {
            draw_line(pix_x, pix_y + _gy2 * _cell - 1, pix_x + _meta.w * _cell - 1, pix_y + _gy2 * _cell - 1);
            _gy2 += 1;
        }
        draw_set_alpha(1);
        draw_set_colour(c_gray);
        draw_rectangle(pix_x - 1, pix_y - 1, pix_x + _meta.w * _cell, pix_y + _meta.h * _cell, true);
        if (dlg_kind == "" && mouse_x >= pix_x && mouse_y >= pix_y && (mouse_x - pix_x) div _cell < _meta.w && (mouse_y - pix_y) div _cell < _meta.h) {
            var _hc = (mouse_x - pix_x) div _cell;
            var _hr = (mouse_y - pix_y) div _cell;
            draw_set_colour(c_white);
            draw_rectangle(pix_x + _hc * _cell, pix_y + _hr * _cell, pix_x + (_hc + 1) * _cell - 1, pix_y + (_hr + 1) * _cell - 1, true);
        }
        draw_set_colour(c_white);
        draw_text(pix_x, pix_y + _meta.h * _cell + 10, meta_name + "   " + string(_meta.w) + " x " + string(_meta.h) + " tiles = "
            + string(_meta.w * _msize) + " x " + string(_meta.h * _msize) + " px (max " + string(GK_METATILE_MAX_PX) + " x " + string(GK_METATILE_MAX_PX) + ")");
        draw_set_colour(_col_dim);
        draw_text(pix_x, pix_y + _meta.h * _cell + 34, "On the MAP tab a metatile is stamped with its top-left at the clicked cell; its tile 0 cells are see-through.");
        draw_text(_ax, _cy + 274 + 12 * row_h + 76, "Metatiles of tileset " + ts_name);
        break;

    case "MAP":
        var _map = te_map();
        var _bottom_y = panel_y + panel_h - 28;
        if (_map == undefined) {
            draw_set_colour(_col_dim);
            draw_text(view_x, view_y + 10, array_length(ts_names) == 0
                ? "Make a tileset first (TILES tab), then press NEW here to make a map."
                : "No map yet. Press NEW (left) to make one: a name, a tileset and how many rooms (screens).");
            break;
        }
        var _mts = te_map_tileset();
        var _ok = _mts != undefined && _mts.tile_size * _map.room_cols <= 320 && array_length(_map.cells) == _map.width * _map.height;
        draw_set_colour(c_white);
        draw_text(_ax, _cy + 280, "Tileset: " + _map.tileset + (_mts == undefined ? " (MISSING)" : "  " + string(_mts.tile_size) + " px"));
        draw_text(_ax, _cy + 302, "Rooms " + string(_map.rooms_x) + " x " + string(_map.rooms_y) + ",  room " + string(_map.room_cols) + " x " + string(_map.room_rows) + " tiles");
        draw_text(_ax, _cy + 324, "Map " + string(_map.width) + " x " + string(_map.height) + " tiles,  " + string(array_length(_map.enemies)) + " enemies");
        draw_text(_ax, nav_y - 24, "ROOM " + string(room_x + 1) + "," + string(room_y + 1) + "   (PgUp/PgDn, Ctrl+arrows)");
        draw_set_colour(_col_box);
        draw_rectangle(nav_x, nav_y, nav_x + nav_w, nav_y + nav_h, false);
        if (!_ok) {
            draw_set_colour(c_red);
            draw_text(view_x, view_y + 10, _mts == undefined ? "This map's tileset '" + _map.tileset + "' is missing." : "This map does not match its tileset.");
            break;
        }
        te_atlas_prepare(_mts);
        te_overview_prepare(_map);
        var _msz = _mts.tile_size;
        var _cs = te_view_cell(_msz);
        var _c0 = room_x * _map.room_cols;
        var _r0 = room_y * _map.room_rows;
        var _vw = _map.room_cols * _cs;
        var _vh = _map.room_rows * _cs;

        // Room view.
        draw_set_colour(scr_te_palette_colour(_mts, 0));
        draw_rectangle(view_x, view_y, view_x + 320 * view_zoom - 1, view_y + 256 * view_zoom - 1, false);
        var _vr = 0;
        while (_vr < _map.room_rows) {
            var _vc = 0;
            while (_vc < _map.room_cols) {
                var _tile = scr_gk_map_get(_map, _c0 + _vc, _r0 + _vr);
                if (_tile != 0) te_draw_tile(_mts, _tile, view_x + _vc * _cs, view_y + _vr * _cs, view_zoom);
                _vc += 1;
            }
            _vr += 1;
        }
        if (show_flags) {
            _vr = 0;
            while (_vr < _map.room_rows) {
                var _fc = 0;
                while (_fc < _map.room_cols) {
                    var _ft = scr_gk_map_get(_map, _c0 + _fc, _r0 + _vr);
                    if (_ft > 0 && _ft < array_length(_mts.flags) && _mts.flags[_ft] != 0) {
                        var _fb = 0;
                        while (_fb < 5) {
                            if ((_mts.flags[_ft] & flag_bits[_fb]) != 0) {
                                draw_set_colour(flag_colours[_fb]);
                                var _in = 1 + _fb * 3;
                                draw_rectangle(view_x + _fc * _cs + _in, view_y + _vr * _cs + _in, view_x + (_fc + 1) * _cs - 1 - _in, view_y + (_vr + 1) * _cs - 1 - _in, true);
                            }
                            _fb += 1;
                        }
                    }
                    _fc += 1;
                }
                _vr += 1;
            }
        }
        if (show_grid) {
            draw_set_colour(c_white);
            draw_set_alpha(0.15);
            var _gl2 = 1;
            while (_gl2 < _map.room_cols) {
                draw_line(view_x + _gl2 * _cs, view_y, view_x + _gl2 * _cs, view_y + _vh - 1);
                _gl2 += 1;
            }
            _gl2 = 1;
            while (_gl2 < _map.room_rows) {
                draw_line(view_x, view_y + _gl2 * _cs, view_x + _vw - 1, view_y + _gl2 * _cs);
                _gl2 += 1;
            }
            draw_set_alpha(1);
        }
        draw_set_colour(c_gray);
        draw_rectangle(view_x - 1, view_y - 1, view_x + _vw, view_y + _vh, true);
        if (_vw < 320 * view_zoom || _vh < 256 * view_zoom) {
            // The part of the 320 x 256 screen outside the tile grid.
            draw_set_colour(c_dkgray);
            draw_rectangle(view_x - 1, view_y - 1, view_x + 320 * view_zoom, view_y + 256 * view_zoom, true);
        }

        // Markers: player start and enemies of this room.
        var _room_px = _c0 * _msz;
        var _room_py = _r0 * _msz;
        var _sx2 = view_x + (_map.spawn_x - _room_px) * view_zoom;
        var _sy2 = view_y + (_map.spawn_y - _room_py) * view_zoom;
        if (_map.spawn_x >= _room_px && _map.spawn_x < _room_px + _map.room_cols * _msz && _map.spawn_y >= _room_py && _map.spawn_y < _room_py + _map.room_rows * _msz) {
            draw_set_colour(c_lime);
            draw_rectangle(_sx2, _sy2, _sx2 + 16 * view_zoom - 1, _sy2 + 24 * view_zoom - 1, true);
            draw_rectangle(_sx2 + 1, _sy2 + 1, _sx2 + 16 * view_zoom - 2, _sy2 + 24 * view_zoom - 2, true);
            draw_set_halign(fa_center);
            draw_text(_sx2 + 8 * view_zoom, _sy2 + 12 * view_zoom - 10, "S");
            draw_set_halign(fa_left);
        }
        var _room_index = room_y * _map.rooms_x + room_x;
        var _room_enemies = 0;
        var _e = 0;
        while (_e < array_length(_map.enemies)) {
            var _en = _map.enemies[_e];
            if (scr_te_map_room_of(_map, _msz, _en.x, _en.y) == _room_index) {
                _room_enemies += 1;
                var _ex = view_x + (_en.x - _room_px) * view_zoom;
                var _ey = view_y + (_en.y - _room_py) * view_zoom;
                var _eh = te_enemy_height(_en.animset) * view_zoom;
                draw_set_colour(_e == enemy_sel ? c_yellow : c_orange);
                draw_rectangle(_ex, _ey, _ex + 16 * view_zoom - 1, _ey + _eh - 1, true);
                draw_rectangle(_ex + 1, _ey + 1, _ex + 16 * view_zoom - 2, _ey + _eh - 2, true);
                draw_set_halign(fa_center);
                draw_text(_ex + 8 * view_zoom, _ey + _eh / 2 - 20, "E" + string(_e + 1));
                draw_text(_ex + 8 * view_zoom, _ey + _eh / 2, ">" + string(_en.speed));
                draw_set_halign(fa_left);
            }
            _e += 1;
        }

        // Brush / rectangle preview.
        if (dlg_kind == "") {
            var _hc2 = floor((mouse_x - view_x) / _cs);
            var _hr2 = floor((mouse_y - view_y) / _cs);
            if (map_drag && map_tool == "RECT") {
                var _rl2 = clamp(min(rect_c0, rect_c1) - _c0, 0, _map.room_cols - 1), _rr2 = clamp(max(rect_c0, rect_c1) - _c0, 0, _map.room_cols - 1);
                var _rt2 = clamp(min(rect_r0, rect_r1) - _r0, 0, _map.room_rows - 1), _rb2 = clamp(max(rect_r0, rect_r1) - _r0, 0, _map.room_rows - 1);
                draw_set_colour(map_drag_button == mb_left ? c_yellow : c_red);
                draw_rectangle(view_x + _rl2 * _cs, view_y + _rt2 * _cs, view_x + (_rr2 + 1) * _cs - 1, view_y + (_rb2 + 1) * _cs - 1, true);
                draw_rectangle(view_x + _rl2 * _cs + 1, view_y + _rt2 * _cs + 1, view_x + (_rr2 + 1) * _cs - 2, view_y + (_rb2 + 1) * _cs - 2, true);
            } else if (_hc2 >= 0 && _hr2 >= 0 && _hc2 < _map.room_cols && _hr2 < _map.room_rows && mouse_x >= view_x && mouse_y >= view_y) {
                var _bw = 1, _bh = 1;
                if ((map_tool == "PAINT" || map_tool == "RECT") && map_brush == "META") {
                    var _bmeta = te_meta(_mts, map_meta);
                    if (_bmeta != undefined) {
                        _bw = min(_bmeta.w, _map.room_cols - _hc2);
                        _bh = min(_bmeta.h, _map.room_rows - _hr2);
                        if (map_tool == "PAINT") {
                            draw_set_alpha(0.6);
                            var _by2 = 0;
                            while (_by2 < _bh) {
                                var _bx2 = 0;
                                while (_bx2 < _bw) {
                                    var _bt = _bmeta.cells[_by2 * _bmeta.w + _bx2];
                                    if (_bt != 0) te_draw_tile(_mts, _bt, view_x + (_hc2 + _bx2) * _cs, view_y + (_hr2 + _by2) * _cs, view_zoom);
                                    _bx2 += 1;
                                }
                                _by2 += 1;
                            }
                            draw_set_alpha(1);
                        }
                    }
                } else if (map_tool == "PAINT" && map_brush == "TILE" && map_tile > 0) {
                    draw_set_alpha(0.6);
                    te_draw_tile(_mts, map_tile, view_x + _hc2 * _cs, view_y + _hr2 * _cs, view_zoom);
                    draw_set_alpha(1);
                }
                draw_set_colour(c_white);
                draw_rectangle(view_x + _hc2 * _cs, view_y + _hr2 * _cs, view_x + (_hc2 + _bw) * _cs - 1, view_y + (_hr2 + _bh) * _cs - 1, true);
            }
        }

        // Navigator: one pixel per tile (average colour), rooms outlined.
        var _geom = te_nav_geom(_map);
        if (surface_exists(overview_surface)) {
            draw_surface_stretched(overview_surface, _geom[0], _geom[1], _geom[2] * _map.rooms_x, _geom[3] * _map.rooms_y);
        }
        draw_set_colour(c_dkgray);
        var _rx = 0;
        while (_rx < _map.rooms_x) {
            var _ry2 = 0;
            while (_ry2 < _map.rooms_y) {
                draw_rectangle(_geom[0] + _rx * _geom[2], _geom[1] + _ry2 * _geom[3], _geom[0] + (_rx + 1) * _geom[2] - 1, _geom[1] + (_ry2 + 1) * _geom[3] - 1, true);
                _ry2 += 1;
            }
            _rx += 1;
        }
        draw_set_colour(c_yellow);
        draw_rectangle(_geom[0] + room_x * _geom[2], _geom[1] + room_y * _geom[3], _geom[0] + (room_x + 1) * _geom[2] - 1, _geom[1] + (room_y + 1) * _geom[3] - 1, true);
        var _nscale = _geom[2] / (_map.room_cols * _msz);
        draw_set_colour(c_lime);
        draw_rectangle(_geom[0] + _map.spawn_x * _nscale - 1, _geom[1] + _map.spawn_y * _nscale - 1, _geom[0] + _map.spawn_x * _nscale + 2, _geom[1] + _map.spawn_y * _nscale + 2, false);

        // Right column.
        draw_set_colour(c_white);
        var _brush_text = (map_brush == "META") ? "BRUSH: metatile " + map_meta : "BRUSH: tile " + string(map_tile);
        draw_text(map_col_x, _cy + 80, "TILES   " + _brush_text);
        var _ey2 = _cy + 452 + 5 * row_h + 52;
        draw_text(map_col_x, _ey2 - 26, "ENEMIES  room " + string(_room_enemies) + " / " + string(GK_ENEMIES_PER_ROOM)
            + (enemy_sel >= 0 ? "   editing E" + string(enemy_sel + 1) : "   (settings for new enemies)"));
        draw_text(map_col_x, _ey2 + 2, "ANIM SET");
        draw_set_halign(fa_center);
        draw_text(map_col_x + 283, _ey2 + 2, enemy_animset == "" ? "(none - make one)" : enemy_animset);
        draw_text(map_col_x + 183, _ey2 + 36, string(enemy_speed));
        draw_set_halign(fa_left);
        draw_text(map_col_x, _ey2 + 36, "SPEED px/f");
        draw_set_colour(_col_dim);
        var _help_y = _ey2 + 76;
        switch (map_tool) {
            case "PAINT": draw_text(map_col_x, _help_y, "PAINT: left paints the brush, right erases (tile 0)."); break;
            case "RECT": draw_text(map_col_x, _help_y, "RECT: drag to fill a rectangle (right = erase)."); break;
            case "SPAWN": draw_text(map_col_x, _help_y, "SPAWN: click a tile to put the player start there."); break;
            case "ENEMY": draw_text(map_col_x, _help_y, "ENEMY: click to add, click a marker to select it,"); draw_text(map_col_x, _help_y + 22, "right click or Delete removes it."); break;
        }
        draw_text(map_col_x, _help_y + 48, "G grid   PgUp/PgDn or Ctrl+arrows: rooms");
        var _flag_x = map_col_x;
        var _fi = 0;
        while (_fi < 5) {
            draw_set_colour(flag_colours[_fi]);
            draw_rectangle(_flag_x, _help_y + 82, _flag_x + 10, _help_y + 92, true);
            draw_text(_flag_x + 16, _help_y + 76, flag_labels[_fi]);
            _flag_x += 24 + string_width(flag_labels[_fi]);
            _fi += 1;
        }

        var _problem = scr_gk_map_problem(_map);
        if (_problem != "") {
            draw_set_colour(c_red);
            draw_text(view_x, _bottom_y, "PROBLEM: " + _problem);
        } else {
            draw_set_colour(c_lime);
            draw_text(view_x, _bottom_y, "Map OK");
        }
        break;

    case "ANIMATIONS":
        var _set = te_animset();
        if (_set == undefined) {
            draw_set_colour(_col_dim);
            draw_text(anim_x, _cy + 20, "No animation set yet. Press NEW (left): a name and the sprite height (8..32).");
            draw_text(anim_x, _cy + 44, "A set has idle, run, jump and fall animations made of 16 px wide SPRITE frames.");
            break;
        }
        var _states = GK_ANIM_STATES;
        var _h = clamp(_set.height, 1, 64);
        var _s = 0;
        while (_s < 4) {
            var _st = _states[_s];
            var _state = _set.states[$ _st];
            var _y0 = _cy + 10 + _s * anim_row_h;
            draw_set_colour(_col_box);
            draw_rectangle(anim_x - 6, _y0 - 6, panel_x + panel_w - 12, _y0 + anim_row_h - 12, false);
            draw_set_colour(c_yellow);
            draw_text(anim_x, _y0 + 2, string_upper(_st));
            if (!is_struct(_state)) {
                draw_set_colour(c_red);
                draw_text(anim_x + 130, _y0 + 2, "state missing");
                _s += 1;
                continue;
            }
            draw_set_colour(c_white);
            draw_text(anim_x + 80, _y0 + 2, "RATE");
            draw_set_halign(fa_center);
            draw_text(anim_x + 208, _y0 + 2, string(_state.rate) + " fps");
            draw_set_halign(fa_left);
            var _nf = array_length(_state.frames);
            draw_set_colour(_col_dim);
            draw_text(anim_x + 300, _y0 + 2, string(_nf) + " frame(s)" + ((anim_state == _st && anim_frame >= 0 && anim_frame < _nf) ? "   selected: " + _state.frames[anim_frame] : ""));
            var _f2 = 0;
            while (_f2 < _nf) {
                var _fx = anim_x + _f2 * 40;
                if (_fx + 40 >= anim_preview_x - 20) {
                    draw_set_colour(_col_dim);
                    draw_text(_fx, _y0 + 68, "+" + string(_nf - _f2));
                    break;
                }
                var _fy = _y0 + 68;
                draw_set_colour(c_black);
                draw_rectangle(_fx, _fy, _fx + 35, _fy + _h * 2 + 7, false);
                var _surf = te_sprite_surface(_state.frames[_f2]);
                if (_surf != -1 && surface_exists(_surf)) {
                    draw_surface_ext(_surf, _fx + 2, _fy + 4, 2, 2, 0, c_white, 1);
                    var _fspr = scr_te_find("SPRITE", _state.frames[_f2]);
                    if (_fspr != undefined && _fspr.height != _set.height) {
                        draw_set_colour(c_red);
                        draw_rectangle(_fx, _fy, _fx + 35, _fy + _h * 2 + 7, true);
                    }
                } else {
                    draw_set_colour(c_red);
                    draw_text(_fx + 10, _fy + 4, "?");
                }
                if (anim_state == _st && anim_frame == _f2) {
                    draw_set_colour(c_yellow);
                    draw_rectangle(_fx - 1, _fy - 1, _fx + 36, _fy + _h * 2 + 8, true);
                }
                _f2 += 1;
            }
            if (_nf == 0) {
                draw_set_colour(_col_dim);
                draw_text(anim_x, _y0 + 72, "No frames: ADD FRAME picks an existing sprite, NEW FRAME makes a blank one.");
            }

            // Live preview at 4x, facing right and mirrored (facing left).
            if (_nf > 0) {
                var _index = floor(current_time / (1000 / max(1, _state.rate))) mod _nf;
                var _psurf = te_sprite_surface(_state.frames[_index]);
                var _ppy = _y0 + (anim_row_h - 12 - _h * 4) / 2 - 6;
                draw_set_colour(c_black);
                draw_rectangle(anim_preview_x, _ppy - 4, anim_preview_x + 64 + 8, _ppy + _h * 4 + 4, false);
                draw_rectangle(anim_preview_x + 100, _ppy - 4, anim_preview_x + 100 + 64 + 8, _ppy + _h * 4 + 4, false);
                if (_psurf != -1 && surface_exists(_psurf)) {
                    draw_surface_ext(_psurf, anim_preview_x + 4, _ppy, 4, 4, 0, c_white, 1);
                    draw_surface_ext(_psurf, anim_preview_x + 104 + 64, _ppy, -4, 4, 0, c_white, 1);
                }
                draw_set_colour(_col_dim);
                draw_text(anim_preview_x + 190, _ppy, "right / left");
                draw_text(anim_preview_x + 190, _ppy + 22, "frame " + string(_index + 1));
            }
            _s += 1;
        }
        var _aproblem = scr_gk_animset_problem(_set);
        var _ab = panel_y + panel_h - 28;
        draw_set_colour(_aproblem == "" ? c_lime : c_red);
        draw_text(anim_x, _ab, _aproblem == "" ? "Animation set OK" : "PROBLEM: " + _aproblem);
        draw_set_colour(_col_dim);
        draw_text(_ax, _cy + 24 + 12 * row_h + 48, "Height " + string(_set.height) + " px, 16 px wide.");
        draw_text(_ax, _cy + 24 + 12 * row_h + 70, "Frames are SPRITE assets:");
        draw_text(_ax, _cy + 24 + 12 * row_h + 92, "draw them in SPR-EDIT.");
        draw_text(_ax, _cy + 24 + 12 * row_h + 114, "Colours come from the first");
        draw_text(_ax, _cy + 24 + 12 * row_h + 136, "idle frame. Shift = rate +-5.");
        break;
}

// --- buttons --------------------------------------------------------------------------------
var _buttons = te_controls(false);
var _i = 0;
while (_i < array_length(_buttons)) {
    var _c = _buttons[_i];
    if (_c.id == "close") {
        draw_set_colour(c_red);
        draw_text(_c.x1 + 5, _c.y1 + 1, "X");
    } else {
        var _hover = dlg_kind == "" && point_in_rectangle(mouse_x, mouse_y, _c.x1, _c.y1, _c.x2, _c.y2);
        draw_set_colour(_c.on ? _col_button_on : _col_button);
        draw_set_alpha(_c.enabled ? 1 : 0.4);
        draw_rectangle(_c.x1, _c.y1, _c.x2, _c.y2, false);
        draw_set_colour(_hover && _c.enabled ? c_white : c_gray);
        draw_rectangle(_c.x1, _c.y1, _c.x2, _c.y2, true);
        draw_set_colour(c_white);
        draw_set_halign(fa_center);
        draw_text((_c.x1 + _c.x2) div 2, (_c.y1 + _c.y2) div 2 - 10, _c.label);
        draw_set_halign(fa_left);
        draw_set_alpha(1);
    }
    _i += 1;
}

// Hover information line.
if (hover_text != "" && dlg_kind == "") {
    draw_set_colour(c_white);
    draw_text(tab == "MAP" ? view_x + 980 - string_width(hover_text) : panel_x + panel_w - 20 - string_width(hover_text), panel_y + panel_h - 28, hover_text);
}

// --- dialog -----------------------------------------------------------------------------------
if (dlg_kind != "") {
    draw_set_alpha(0.5);
    draw_set_colour(c_black);
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
    draw_set_alpha(1);
    draw_set_colour(_col_panel);
    draw_rectangle(dlg_x, dlg_y, dlg_x + dlg_w_px, dlg_y + dlg_h_px, false);
    draw_set_colour(_col_header);
    draw_rectangle(dlg_x, dlg_y, dlg_x + dlg_w_px, dlg_y + 28, false);
    draw_set_colour(c_gray);
    draw_rectangle(dlg_x, dlg_y, dlg_x + dlg_w_px, dlg_y + dlg_h_px, true);
    draw_set_colour(c_white);
    draw_text(dlg_x + 10, dlg_y + 5, dlg_title);
    var _dx = dlg_x + 20;
    var _dy = dlg_y + 110;
    if (dlg_has_name) {
        draw_text(_dx, dlg_y + 54, "NAME");
        draw_set_colour(c_black);
        draw_rectangle(_dx + 130, dlg_y + 48, dlg_x + dlg_w_px - 20, dlg_y + 76, false);
        draw_set_colour(c_yellow);
        draw_rectangle(_dx + 130, dlg_y + 48, dlg_x + dlg_w_px - 20, dlg_y + 76, true);
        draw_text(_dx + 138, dlg_y + 53, dlg_name + ((current_time div 400) mod 2 == 0 ? "_" : ""));
    }
    draw_set_colour(c_white);
    switch (dlg_kind) {
        case "ts_new":
            draw_text(_dx, _dy + 4, "TILE SIZE");
            draw_set_colour(_col_dim);
            draw_text(_dx, _dy + 40, "A room (one screen) is " + string(scr_gk_room_cols(dlg_size)) + " x " + string(scr_gk_room_rows(dlg_size))
                + " tiles of " + string(dlg_size) + " px.");
            break;
        case "meta_new":
        case "meta_resize":
            var _dts = te_tileset();
            var _dsz = (_dts == undefined) ? 16 : _dts.tile_size;
            draw_text(_dx, _dy + 4, "WIDTH");
            draw_text(_dx, _dy + 38, "HEIGHT");
            draw_set_halign(fa_center);
            draw_text(_dx + 183, _dy + 4, string(dlg_w));
            draw_text(_dx + 183, _dy + 38, string(dlg_h));
            draw_set_halign(fa_left);
            draw_text(_dx + 260, _dy + 20, "tiles = " + string(dlg_w * _dsz) + " x " + string(dlg_h * _dsz) + " px");
            draw_set_colour(_col_dim);
            draw_text(_dx, _dy + 76, "At most " + string(GK_METATILE_MAX_PX) + " x " + string(GK_METATILE_MAX_PX) + " px. Resizing keeps the cells that still fit.");
            break;
        case "map_new":
            draw_text(_dx, _dy + 4, "TILESET");
            draw_set_halign(fa_center);
            draw_text(_dx + 288, _dy + 4, dlg_tileset == "" ? "(none - make one first)" : dlg_tileset);
            draw_set_halign(fa_left);
            _dy += 34;
            draw_text(_dx, _dy + 4, "ROOMS X");
            draw_text(_dx, _dy + 38, "ROOMS Y");
            draw_set_halign(fa_center);
            draw_text(_dx + 183, _dy + 4, string(dlg_rx));
            draw_text(_dx + 183, _dy + 38, string(dlg_ry));
            draw_set_halign(fa_left);
            draw_set_colour(_col_dim);
            draw_text(_dx + 260, _dy + 20, "one room = one 320 x 256 screen");
            break;
        case "map_resize":
            draw_text(_dx, _dy + 4, "ROOMS X");
            draw_text(_dx, _dy + 38, "ROOMS Y");
            draw_set_halign(fa_center);
            draw_text(_dx + 183, _dy + 4, string(dlg_rx));
            draw_text(_dx + 183, _dy + 38, string(dlg_ry));
            draw_set_halign(fa_left);
            draw_set_colour(_col_dim);
            draw_text(_dx, _dy + 76, "Cells that still fit are kept; enemies outside are removed.");
            break;
        case "anim_new":
            draw_text(_dx, _dy + 4, "HEIGHT");
            draw_set_halign(fa_center);
            draw_text(_dx + 183, _dy + 4, string(dlg_height));
            draw_set_halign(fa_left);
            draw_text(_dx + 260, _dy + 4, "px (16 px wide sprites)");
            break;
        case "frame_pick":
            var _plx = dlg_x + 20;
            var _ply = dlg_y + 70;
            var _prows = 9;
            draw_text(_plx, dlg_y + 44, "Click a sprite to add it (" + string(array_length(dlg_list)) + " with the right height)");
            draw_set_colour(_col_box);
            draw_rectangle(_plx, _ply, _plx + dlg_w_px - 40, _ply + _prows * row_h, false);
            var _pr = 0;
            while (_pr < _prows && dlg_scroll + _pr < array_length(dlg_list)) {
                var _pry = _ply + _pr * row_h;
                if (point_in_rectangle(mouse_x, mouse_y, _plx, _pry, _plx + dlg_w_px - 40, _pry + row_h - 1)) {
                    draw_set_colour(_col_button);
                    draw_rectangle(_plx + 1, _pry + 1, _plx + dlg_w_px - 41, _pry + row_h - 1, false);
                }
                draw_set_colour(c_white);
                draw_text(_plx + 6, _pry + 2, dlg_list[dlg_scroll + _pr]);
                _pr += 1;
            }
            if (array_length(dlg_list) == 0) {
                draw_set_colour(_col_dim);
                draw_text(_plx + 6, _ply + 4, "No sprite of this height yet - use NEW FRAME.");
            }
            break;
    }
    if (dlg_error != "") {
        draw_set_colour(c_red);
        draw_text(dlg_x + 20, dlg_y + dlg_h_px - 80, dlg_error);
    } else if (dlg_has_name) {
        draw_set_colour(_col_dim);
        draw_text(dlg_x + 20, dlg_y + dlg_h_px - 80, "A letter, then letters, digits or _.   Enter = OK, Esc = cancel");
    }
    var _dbuttons = te_controls(true);
    var _di = 0;
    while (_di < array_length(_dbuttons)) {
        var _dc = _dbuttons[_di];
        var _dhover = point_in_rectangle(mouse_x, mouse_y, _dc.x1, _dc.y1, _dc.x2, _dc.y2);
        draw_set_colour(_dc.on ? _col_button_on : _col_button);
        draw_set_alpha(_dc.enabled ? 1 : 0.4);
        draw_rectangle(_dc.x1, _dc.y1, _dc.x2, _dc.y2, false);
        draw_set_colour(_dhover && _dc.enabled ? c_white : c_gray);
        draw_rectangle(_dc.x1, _dc.y1, _dc.x2, _dc.y2, true);
        draw_set_colour(c_white);
        draw_set_halign(fa_center);
        draw_text((_dc.x1 + _dc.x2) div 2, (_dc.y1 + _dc.y2) div 2 - 10, _dc.label);
        draw_set_halign(fa_left);
        draw_set_alpha(1);
        _di += 1;
    }
}

gpu_set_texfilter(_texfilter);
draw_set_alpha(1);
draw_set_colour(c_white);
