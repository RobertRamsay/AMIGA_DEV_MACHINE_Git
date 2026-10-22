/// @desc Editor tour: opening the editors (scr_tour_show) and their steps
/// (scr_tour_editor_categories). Every editor's Step yields while the tour
/// exists, so the tour can open them, switch their tabs and highlight their
/// panels without any click or key reaching them.
///
/// Views: "main", "home", "sprite", "bitmap", "bob", "colour", "cprbar",
/// "code", "code:find", "audio:mod", "audio:sample", "tile:TILES",
/// "tile:METATILES", "tile:MAP", "tile:ANIMATIONS".

/// Closes every editor without committing anything.
function scr_tour_close_view_editors() {
    scr_tour_close_except("");
}

function scr_tour_close_except(_kind) {
    if (_kind != "home") with (obj_tutorial_home) instance_destroy();
    if (_kind != "guide" && instance_exists(obj_tutorial_guide)) {
        with (obj_tutorial_guide) instance_destroy();
        global.tutorial_current = -1;
    }
    if (_kind != "code") with (obj_code_editor) ed_close(false);
    if (_kind != "audio") with (obj_audio_editor) instance_destroy();
    if (_kind != "tracker") with (obj_tracker_editor) instance_destroy();
    if (_kind != "tile") with (obj_tile_editor) instance_destroy();
    if (_kind != "bitmap") with (obj_bitmap_editor) instance_destroy();
    if (_kind != "bob") with (obj_bob_editor) instance_destroy();
    if (_kind != "colour") with (obj_colour_picker) instance_destroy();
    if (_kind != "cprbar") with (obj_cprbar_editor) instance_destroy();
    if (_kind != "sprite") {
        global.sprite_editor_open = false;
        global.sprite_anim_playing = false;
        global.sprite_editor_dragging = false;
        global.sprite_editing_field = "";
    }
}

/// Puts the screen into view _view ("kind" or "kind:sub").
function scr_tour_show(_view) {
    var _parts = string_split(_view, ":");
    var _kind = _parts[0];
    var _sub = array_length(_parts) > 1 ? _parts[1] : "";
    scr_tour_close_except(_kind);

    switch (_kind) {
        case "home":
            if (!instance_exists(obj_tutorial_home)) scr_tutorial_home_open(false);
            break;

        case "guide":
            // The demo is tutorial 10: show its guide on the first step.
            if (!instance_exists(obj_tutorial_guide)) {
                global.tutorial_current = 9;
                global.tutorial_step = 0;
                global.tutorial_guide_collapsed = false;
                scr_tutorial_guide_open();
            }
            break;

        case "sprite":
            if (!global.sprite_editor_open) {
                global.sprite_editor_x = 380;
                global.sprite_editor_y = 60;
                with (obj_amiga_manager) {
                    global.sprite_editor_open = true;
                    sprite_editor_rebuild_assets();
                    var _index = 0;
                    var _i = 0;
                    while (_i < array_length(global.sprite_asset_names)) {
                        if (global.sprite_asset_names[_i] == "Hero_run_1") _index = _i;
                        _i += 1;
                    }
                    global.sprite_asset_index = _index;
                    if (array_length(global.sprite_asset_names) > 0) sprite_editor_load_asset(global.sprite_asset_names[_index]);
                }
            }
            break;

        case "bitmap":
            if (!instance_exists(obj_bitmap_editor)) instance_create_layer(0, 0, "Instances", obj_bitmap_editor);
            break;

        case "bob":
            if (!instance_exists(obj_bob_editor)) instance_create_layer(0, 0, "Instances", obj_bob_editor);
            break;

        case "colour":
            if (!instance_exists(obj_colour_picker)) {
                var _bkg = scr_tour_find_node("SETBKG");
                if (_bkg != noone) scr_colour_picker_open(_bkg, "macro_asset_name", -1, "SETBKG colour");
            }
            break;

        case "cprbar":
            if (!instance_exists(obj_cprbar_editor)) {
                var _bar = scr_tour_find_node("COPPER_BAR");
                if (_bar != noone) {
                    var _editor = instance_create_layer(0, 0, "Instances", obj_cprbar_editor);
                    _editor.target_node_id = _bar;
                }
            }
            break;

        case "code":
            if (!instance_exists(obj_code_editor)) {
                var _code = scr_tour_find_node("CODE");
                if (_code != noone) scr_code_editor_open(_code);
            }
            with (obj_code_editor) {
                if (_sub == "find") {
                    if (!find_open) ed_open_find(false);
                } else if (find_open || goto_open) {
                    ed_close_bars();
                }
                ed_layout();
            }
            break;

        case "audio":
            if (!instance_exists(obj_audio_editor)) scr_audio_editor_open();
            with (obj_audio_editor) {
                audio_editor_refresh();
                focus_kind = _sub == "sample" ? "SAMPLE" : "MOD";
                if (array_contains(mod_names, "TutorialTune")) mod_selected = "TutorialTune";
                if (array_contains(smp_names, "Jump")) smp_selected = "Jump";
                controls = audio_editor_controls();
            }
            break;

        case "tracker":
            // The demo's TutorialTune (Pixel Hearts) on the hook: lead, echo, bass, drums.
            if (!instance_exists(obj_tracker_editor)) {
                var _tracker = scr_tracker_open("");
                with (_tracker) {
                    if (scr_asset_find_by_name("TutorialTune") != undefined) tracker_load("TutorialTune");
                    cur_pos = min(2, array_length(song.order) - 1);
                    cur_row = 8;
                    cur_inst = 1;
                }
            }
            break;

        case "tile":
            if (!instance_exists(obj_tile_editor)) scr_tile_editor_open();
            with (obj_tile_editor) {
                te_refresh();
                tab = _sub == "" ? "TILES" : _sub;
                stroke_active = false;
                map_drag = false;
                meta_painting = false;
                if (array_contains(ts_names, "Tiles16")) ts_name = "Tiles16";
                if (array_contains(map_names, "Adventure")) map_name = "Adventure";
                if (array_contains(anim_names, "Hero")) anim_name = "Hero";
                meta_name = "pyramid128";
                tile_sel = TB_T_GEM;
                room_x = 0;
                room_y = 0;
                te_refresh();
                controls = te_controls(false);
            }
            break;
    }
}

function scr_tour_inst(_object) {
    return instance_exists(_object) ? instance_find(_object, 0) : noone;
}

// ---------------------------------------------------------------------------
// Rectangles inside editors.

function scr_tour_sprite_rect(_part) {
    if (!global.sprite_editor_open) return undefined;
    var _l = scr_sprite_editor_layout();
    switch (_part) {
        case "panel": return [_l.panel_x, _l.panel_y, _l.panel_x + _l.panel_width, _l.panel_y + _l.panel_height];
        case "assets": return [_l.asset_prev_x, _l.asset_row_y, _l.asset_add_x + _l.asset_add_width, _l.asset_row_y + 20];
        case "fields": return [_l.panel_x + 6, _l.channel_row_y - 2, _l.addr_field_x + 160, _l.addr_row_y + 18];
        case "swatches": return [_l.swatch_x, _l.swatch_row_y, _l.swatch_x + 3 * 46 + _l.swatch_width, _l.swatch_row_y + _l.swatch_height + 16];
        case "grid": return [_l.grid_x, _l.grid_y, _l.grid_x + _l.grid_width, _l.grid_y + _l.grid_height];
        case "tools": return [_l.tool_x, _l.tool_y, _l.tool_x + _l.tool_width, _l.tool_y + (_l.tool_count - 1) * _l.tool_step + _l.tool_height];
        case "anim": return [_l.anim_x, _l.anim_play_y, _l.anim_x + _l.anim_width, _l.anim_end_y + _l.anim_height];
        case "colours": return [_l.palette_preview_x, _l.palette_y, _l.slider_x + _l.slider_width + 24, _l.slider_b_y + _l.slider_height];
    }
    return undefined;
}

function scr_tour_bitmap_rect(_part) {
    var _e = scr_tour_inst(obj_bitmap_editor);
    if (_e == noone) return undefined;
    var _l = scr_bitmap_editor_layout(_e);
    var _left_w = 262;
    switch (_part) {
        case "canvas": return [_l.canvas_x, _l.canvas_y, _l.canvas_x + _l.canvas_width, _l.canvas_y + _l.canvas_height];
        case "view": return [_l.left_x, _l.zoom_y - 4, _l.left_x + _left_w, _l.grid_toggle_y + 24];
        case "tools": return [_l.left_x, _l.tool_y, _l.left_x + _left_w, _l.shape_tool_y + _l.tool_height];
        case "dither": return [_l.left_x, _l.dither_tool_y, _l.left_x + _left_w, _l.transparency_lock_y + _l.tool_height];
        case "gradient": return [_l.left_x, _l.gradient_tool_y, _l.left_x + _left_w, _l.gradient_edge_y + _l.tool_height];
        case "files": return [_l.left_x, _l.flip_y, _l.left_x + _left_w, _l.output_y + _l.utility_button_height];
        case "palette": return [_l.right_x, _l.swatch_y, _l.right_x + 4 * 56, _l.slider_b_y + _l.slider_height];
        case "preview": return [_e.bitmap_preview_window_x, _e.bitmap_preview_window_y, _e.bitmap_preview_window_x + _e.bitmap_preview_window_width, _e.bitmap_preview_window_y + _e.bitmap_preview_window_height];
    }
    return undefined;
}

function scr_tour_bob_rect(_part) {
    var _e = scr_tour_inst(obj_bob_editor);
    if (_e == noone) return undefined;
    var _px = _e.panel_x;
    var _py = _e.panel_y;
    var _pal = _px + _e.column_x_offset;
    var _pal_x2 = _pal + _e.column_width;
    switch (_part) {
        case "panel": return [_px, _py, _px + _e.panel_w, _py + _e.panel_h];
        case "grid": return [_px + 24, _py + 48, _px + 536, _py + 560];
        case "palette": return [_pal, _py + 34, _pal_x2, _py + 250 + 2 * 42 + 20];
        case "assets": return [_pal, _py + 370, _pal_x2, _py + 396];
        case "tools": return [_pal, _py + 410, _pal_x2, _py + 560];
        case "tests": return [_pal, _py + 570, _pal_x2, _py + 654];
    }
    return undefined;
}

function scr_tour_picker_rect(_part) {
    var _e = scr_tour_inst(obj_colour_picker);
    if (_e == noone) return undefined;
    switch (_part) {
        case "panel": return [_e.panel_x, _e.panel_y, _e.panel_x + _e.panel_width, _e.panel_y + _e.panel_height];
        case "sliders": return [_e.slider_x - 22, _e.slider_r_y - 2, _e.slider_x + 214, _e.slider_b_y + 20];
        case "recent": return [_e.recent_row_x, _e.recent_row_y - 22, _e.recent_row_x + 8 * 32, _e.recent_row_y + 20];
        case "close": return [_e.close_button_x, _e.close_button_y, _e.close_button_x + 64, _e.close_button_y + 24];
    }
    return undefined;
}

function scr_tour_cprbar_rect(_part) {
    var _e = scr_tour_inst(obj_cprbar_editor);
    if (_e == noone) return undefined;
    var _px = _e.panel_x;
    var _py = _e.panel_y;
    switch (_part) {
        case "panel": return [_px, _py, _px + 480, _py + 490];
        case "settings": return [_px + 12, _py + 36, _px + 468, _py + 164];
        case "bands":
            var _count = instance_exists(_e.target_node_id) ? _e.target_node_id.macro_cprbar_band_count : 4;
            return [_e.swatch_bar_x, _e.swatch_area_y, _e.swatch_label_x + 132, _e.swatch_area_y + 16 * _count];
        case "close": return [_e.close_button_x, _e.close_button_y, _e.close_button_x + 64, _e.close_button_y + 24];
    }
    return undefined;
}

function scr_tour_code_rect(_part) {
    var _e = scr_tour_inst(obj_code_editor);
    if (_e == noone) return undefined;
    switch (_part) {
        case "panel": return [_e.panel_x1, _e.panel_y1, _e.panel_x2, _e.panel_y2];
        case "text": return [_e.text_x - 4, _e.text_top, _e.text_right, _e.text_bottom];
        case "gutter": return [_e.gutter_x, _e.text_top, _e.gutter_x + _e.gutter_w, _e.text_bottom];
        case "status": return [_e.panel_x1, _e.status_y1, _e.panel_x2, _e.panel_y2];
        case "findbar": return [_e.panel_x1, _e.findbar_y1, _e.panel_x2, _e.findbar_y2];
        case "title_buttons":
        case "snippets":
            var _rect = undefined;
            var _i = 0;
            while (_i < array_length(_e.buttons)) {
                var _b = _e.buttons[_i];
                var _is_snippet = string_copy(_b.id, 1, 4) == "snip";
                var _is_title = array_contains(["find", "replace", "goto", "build", "close"], _b.id);
                if ((_part == "snippets" && _is_snippet) || (_part == "title_buttons" && _is_title)) _rect = scr_tour_rect_union(_rect, [_b.x1, _b.y1, _b.x2, _b.y2]);
                _i += 1;
            }
            return _rect;
    }
    return undefined;
}

function scr_tour_audio_rect(_part) {
    var _e = scr_tour_inst(obj_audio_editor);
    if (_e == noone) return undefined;
    var _px = _e.panel_x;
    var _py = _e.panel_y;
    switch (_part) {
        case "panel": return [_px, _py, _px + _e.panel_w, _py + _e.panel_h];
        case "import": return [_px + 10, _py + 32, _px + 522, _py + 62];
        case "mods": return [_px + 10, _py + 68, _px + 314, _py + 472];
        case "samples": return [_px + 324, _py + 68, _px + 628, _py + 472];
        case "details": return [_px + 640, _py + 66, _px + _e.panel_w - 12, _py + _e.panel_h - 12];
        case "instruments": return [_px + 646, _py + 200, _px + _e.panel_w - 16, _py + _e.panel_h - 196];
        case "channels": return [_px + 646, _py + _e.panel_h - 194, _px + 652 + 4 * 142, _py + _e.panel_h - 24];
        case "wave":
            var _w = _e.audio_editor_wave_rect();
            return [_w[0] - 4, _w[1] - 26, _w[2] + 4, _w[3] + 4];
        case "sample_settings": return [_px + 646, _py + 332, _px + 652 + 568, _py + 434];
        case "sample_ops": return [_px + 646, _py + 438, _px + 652 + 568, _py + 506];
    }
    return undefined;
}

function scr_tour_tracker_rect(_part) {
    var _e = scr_tour_inst(obj_tracker_editor);
    if (_e == noone) return undefined;
    var _l = _e.tracker_layout();
    switch (_part) {
        case "panel": return [_l.x1, _l.y1, _l.x2, _l.y2];
        case "song": return _l.song;
        case "order": return _l.order;
        case "insts": return _l.insts;
        case "inst": return _l.inst;
        case "transport": return [_l.transport[0] - 4, _l.transport[1] - 4, _l.transport[2], _l.tools[3] + 4];
        case "pattern": return [_l.pattern[0], _l.pattern[1], _l.pattern[2], _l.pattern[3] + 40];
    }
    return undefined;
}

function scr_tour_tile_rect(_part) {
    var _e = scr_tour_inst(obj_tile_editor);
    if (_e == noone) return undefined;
    switch (_part) {
        case "tabs": return [28, 52, 28 + 3 * 196 + 188, 80];
        case "lists": return [24, 88, 332, 326];
        case "tile_grid": return [24, 334, 332, 974];
        case "pixels":
            var _ts = _e.te_tileset();
            if (_ts == undefined) return undefined;
            var _side = _ts.tile_size * _e.te_pix_zoom(_ts.tile_size);
            return [_e.pix_x, _e.pix_y, _e.pix_x + _side, _e.pix_y + _side];
        case "tools": return [1142, 94, 1146 + 5 * 116, 164];
        case "palette": return [1142, 170, 1560, 432];
        case "flags": return [1142, 436, 1146 + 5 * 146, 496];
        case "previews": return [1142, 514, 1890, 760];
        case "meta_list": return [24, 336, 332, 700];
        case "meta_canvas":
            var _mts = _e.te_tileset();
            if (_mts == undefined) return undefined;
            var _meta = _e.te_meta(_mts, _e.meta_name);
            if (_meta == undefined) return [_e.pix_x, _e.pix_y, _e.pix_x + 760, _e.pix_y + 760];
            var _cell = _e.te_meta_cell(_meta, _mts.tile_size);
            return [_e.pix_x, _e.pix_y, _e.pix_x + _meta.w * _cell, _e.pix_y + _meta.h * _cell];
        case "meta_picker": return [1142, 98, 1890, 744];
        case "map_list": return [24, 88, 332, 354];
        case "navigator": return [24, 440, 332, 750];
        case "map_view": return [342, 94, 1310, 870];
        case "map_tools": return [1332, 94, 1896, 164];
        case "brushes": return [1332, 164, 1896, 656];
        case "enemies": return [1332, 670, 1896, 770];
        case "anim_list": return [24, 88, 332, 414];
        case "anim_row": return [350, 92, 1892, 300];
        case "anim_rate": return [430, 94, 646, 128];
        case "anim_frames": return [352, 128, 1500, 300];
        case "anim_preview": return [1510, 92, 1700, 300];
    }
    return undefined;
}

function scr_tour_guide_rect() {
    var _g = scr_tour_inst(obj_tutorial_guide);
    if (_g == noone) return undefined;
    return [_g.guide_hit_x1, _g.guide_hit_y1, _g.guide_hit_x2, _g.guide_hit_y2];
}

/// The main panel of whichever windowed editor is open (the tour's own panel
/// keeps clear of it when it can).
function scr_tour_editor_panel_rect() {
    if (global.sprite_editor_open) return scr_tour_sprite_rect("panel");
    if (instance_exists(obj_colour_picker)) return scr_tour_picker_rect("panel");
    if (instance_exists(obj_cprbar_editor)) return scr_tour_cprbar_rect("panel");
    if (instance_exists(obj_bob_editor)) return scr_tour_bob_rect("panel");
    return undefined;
}

function scr_tour_home_rect(_part = "cards") {
    if (!instance_exists(obj_tutorial_home)) return undefined;
    switch (_part) {
        case "cards":
            var _home = instance_find(obj_tutorial_home, 0);
            return [_home.home_list_x - 2, _home.home_list_top - 6, _home.home_list_x + _home.home_list_w + 2, _home.home_list_bottom + 2];
        case "start":
            var _rect = undefined;
            with (obj_tutorial_home) {
                var _i = 0;
                while (_i < array_length(home_controls)) {
                    var _c = home_controls[_i];
                    if (_c.kind == "start" || _c.kind == "check") _rect = scr_tour_rect_union(_rect, [_c.x1 - 4, _c.y1 - 4, _c.x2 + 4, _c.y2 + 4]);
                    _i += 1;
                }
            }
            return _rect;
    }
    return undefined;
}

// ---------------------------------------------------------------------------
// The editor categories.

function scr_tour_editor_categories() {
    return [
        {
            id : "sprite", title : "Sprite editor (SPR-EDIT)",
            summary : "Hardware sprites: frames, channel colours, pixels, tools and animation preview.",
            steps : [
                { title : "Hardware sprites", show : "sprite", rect : function() { return scr_tour_sprite_rect("panel"); },
                  text : "SPR-EDIT draws hardware sprites: 16 pixels wide, up to 64 high, 3 colours plus transparent, drawn by the Amiga on top of everything for free. Drag the header to move the panel; the X closes it. Here: frame 2 of the hero's run." },
                { title : "Frames", show : "sprite", rect : function() { return scr_tour_sprite_rect("assets"); },
                  text : "< and > step through the sprite assets - they double as animation frames (A / D on the keyboard, W adds one). ADD SPRITE makes a new blank sprite." },
                { title : "Channel, height and address", show : "sprite", rect : function() { return scr_tour_sprite_rect("fields"); },
                  text : "The channel (0-7) is the hardware sprite it uses; pairs of channels share their three colours. HEIGHT sets the rows; ADDR is the chip RAM address the sprite data goes to. Click a field to type, Enter to apply." },
                { title : "Colours", show : "sprite", rect : function() { return scr_tour_sprite_rect("swatches"); },
                  text : "Colour 0 is transparent; 1 to 3 are the sprite's colours. Pick one to paint with - it is also the colour the sliders below edit." },
                { title : "Pixels", show : "sprite", rect : function() { return scr_tour_sprite_rect("grid"); },
                  text : "Paint here: left button with the selected colour, right button erases." },
                { title : "Tools", show : "sprite", rect : function() { return scr_tour_sprite_rect("tools"); },
                  text : "DRAW paints freehand, LINE draws from press to release, FILL floods an area. CIRCLE and FILL CIRCLE: press for the centre, drag for the radius." },
                { title : "Animation preview", show : "sprite", rect : function() { return scr_tour_sprite_rect("anim"); },
                  text : "PLAY runs the frames from START to END at RATE frames per second, LOOP repeats. Click the left half of RATE / START / END to lower, the right half to raise. S starts and stops." },
                { title : "Palette", show : "sprite", rect : function() { return scr_tour_sprite_rect("colours"); },
                  text : "R, G and B set the selected colour in 16 steps each - the Amiga's 4096-colour palette. Changes apply to every sprite on the same channel pair." }
            ]
        },
        {
            id : "bitmap", title : "Bitmap editor (BMP-EDIT)",
            summary : "320 x 256 pictures: canvas, zoom, brushes, tools, dithering, gradients, palette and files.",
            steps : [
                { title : "The canvas", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("canvas"); },
                  text : "A full 320 x 256 Amiga screen. Left button paints, right paints colour 0, Alt+click picks a colour. The wheel zooms around the mouse; Space or the middle button pans." },
                { title : "Zoom, clear, grid, brush", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("view"); },
                  text : "Zoom from 1x to 16x, CLEAR fills with colour 0, GRID cycles an overlay of 4 to 32 pixels, and BRUSH picks the pen size 1 to 9 ([ and ] also change it)." },
                { title : "Tools", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("tools"); },
                  text : "DRAW (D), LINE (L) and FILL (F); CIRCLE and FILLED CIRCLE take the centre from the press and the radius from the drag. Lines and shapes keep their end on the edge if the pointer leaves the canvas." },
                { title : "Dithering and lock", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("dither"); },
                  text : "USE DITHER mixes COL1 and COL2 (or COL1 and transparent) in a pattern: checker, interlace or Bayer. INVERT flips the pattern. TRANSPARENCY LOCK (T) only paints over pixels that are already coloured." },
                { title : "Gradients", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("gradient"); },
                  text : "GRADIENT FILL (G) fills an area from COL1 to COL2 along your drag, dithered. A custom gradient uses up to 12 colours of your choice; EAT / KEEP EDGE decides whether the outline is filled too." },
                { title : "Flip, undo and files", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("files"); },
                  text : "FLIP X mirrors the picture (X key). UNDO / REDO (Ctrl+Z / Ctrl+Y). Load and save the native format, IFF ILBM, or export a PNG. TEST BITMAP builds a program that shows it on the Amiga." },
                { title : "Palette", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("palette"); },
                  text : "32 colours shared by bitmaps and BOBs. Left-click picks the pen (and COL1), right-click sets COL2. The sliders edit the selected colour." },
                { title : "1:1 preview", show : "bitmap", rect : function() { return scr_tour_bitmap_rect("preview"); },
                  text : "The picture at its real size. Drag its header to move it out of the way." }
            ]
        },
        {
            id : "bob", title : "BOB editor (BOB-EDIT)",
            summary : "Blitter objects: the 32 x 32 grid, shared palette, frames, tools, animation and tests.",
            steps : [
                { title : "Blitter objects", show : "bob", rect : function() { return scr_tour_bob_rect("panel"); },
                  text : "BOBs are graphics the blitter copies into the screen: any colours of the shared palette, as many as you like, but they cost blitter time (sprites are free but limited)." },
                { title : "Pixels", show : "bob", rect : function() { return scr_tour_bob_rect("grid"); },
                  text : "A 32 x 32 frame. Left button paints with the pen, right button paints transparent." },
                { title : "Shared palette", show : "bob", rect : function() { return scr_tour_bob_rect("palette"); },
                  text : "The same 32 colours as the bitmap editor. Pick the pen; the sliders change that colour for every bitmap and BOB." },
                { title : "Frames", show : "bob", rect : function() { return scr_tour_bob_rect("assets"); },
                  text : "< > step through BOB assets (animation frames), ADD BOB makes a new one. A / D / W / Q / E work as in the sprite editor." },
                { title : "Tools and animation", show : "bob", rect : function() { return scr_tour_bob_rect("tools"); },
                  text : "DRAW, LINE, FILL, CIRCLE and FILLED CIRCLE (press for the centre, drag for the radius); PLAY, LOOP, RATE, START and END preview the animation." },
                { title : "Clear and test", show : "bob", rect : function() { return scr_tour_bob_rect("tests"); },
                  text : "CLEAR empties the frame. TEST BOB-BMP and TEST SPR-BMP build test programs that move this BOB (or a sprite) over the bitmap on the Amiga." }
            ]
        },
        {
            id : "colour", title : "Colour picker",
            summary : "The 12-bit colour picker used by SETBKG and Copper bands.",
            steps : [
                { title : "Choosing a colour", show : "colour", rect : function() { return scr_tour_picker_rect("panel"); },
                  text : "Opened from a SETBKG node or a Copper band. The swatch shows the colour and its #RGB value." },
                { title : "R, G and B", show : "colour", rect : function() { return scr_tour_picker_rect("sliders"); },
                  text : "Drag each slider over its 16 steps (0 to F): 16 x 16 x 16 = the Amiga's 4096 colours." },
                { title : "Recent colours", show : "colour", rect : function() { return scr_tour_picker_rect("recent"); },
                  text : "The last colours you chose - click one to load it." },
                { title : "Close or cancel", show : "colour", rect : function() { return scr_tour_picker_rect("close"); },
                  text : "Close (or Enter) keeps the colour (Ctrl+Z undoes it). Esc or a right-click cancels." }
            ]
        },
        {
            id : "cprbar", title : "Copper bar editor",
            summary : "Bands, target colour register, raster range and per-band colours.",
            steps : [
                { title : "The Copper", show : "cprbar", rect : function() { return scr_tour_cprbar_rect("panel"); },
                  text : "The Copper waits for screen lines and changes registers - here one colour register - so a single colour becomes a gradient with no CPU time. This editor sets up a CPRBAR node." },
                { title : "Bands, register and range", show : "cprbar", rect : function() { return scr_tour_cprbar_rect("settings"); },
                  text : "BANDS: how many colour steps (1 to 16). TARGET: which COLORxx register changes (COLOR00 is the background). EQUIDISTANT spreads the bands over the whole screen; turn it off to set the first and last raster line yourself." },
                { title : "Band colours", show : "cprbar", rect : function() { return scr_tour_cprbar_rect("bands"); },
                  text : "One row per band, top of the screen first. Click a row to choose its colour in the colour picker." },
                { title : "Close", show : "cprbar", rect : function() { return scr_tour_cprbar_rect("close"); },
                  text : "Changes apply straight away; Close (or Esc) returns to the workspace." }
            ]
        },
        {
            id : "code", title : "Code editor (CODE blocks)",
            summary : "Writing assembly: text area, snippets, find, live checks, autocomplete and build.",
            steps : [
                { title : "The code editor", show : "code", rect : function() { return scr_tour_code_rect("panel"); },
                  text : "A full-screen editor for a CODE block's 68000 assembly (Motorola syntax, assembled by vasm). Esc or Ctrl+Enter applies and closes." },
                { title : "Editing", show : "code", rect : function() { return scr_tour_code_rect("text"); },
                  text : "Syntax colouring, hover help on any instruction or register, Tab or Ctrl+Space autocompletes; after an instruction a MODE list offers its addressing forms (Up / Down, Tab), F12 or Ctrl+click jumps to a label. Ctrl+D duplicates a line, Ctrl+/ comments, Alt+Up/Down moves lines, Ctrl+wheel resizes the font." },
                { title : "Line numbers", show : "code", rect : function() { return scr_tour_code_rect("gutter"); },
                  text : "Lines with problems are marked here. Click a number to select the line." },
                { title : "Snippets", show : "code", rect : function() { return scr_tour_code_rect("snippets"); },
                  text : "Insert ready-made code: wait for the vertical blank, wait for the blitter, take over the system, a Copper list, a main loop, read the joystick." },
                { title : "Find, replace, go to, build", show : "code", rect : function() { return scr_tour_code_rect("title_buttons"); },
                  text : "FIND (Ctrl+F), REPLACE (Ctrl+H), GO TO a line (Ctrl+G), BUILD (F5) applies the code and runs the program without leaving the editor, CLOSE applies and closes." },
                { title : "The find bar", show : "code:find", rect : function() { return scr_tour_code_rect("findbar"); },
                  text : "Type to search as you go; F3 / Shift+F3 jump between matches, Aa makes it case-sensitive, Esc closes the bar." },
                { title : "Problems and status", show : "code", rect : function() { return scr_tour_code_rect("status"); },
                  text : "Every line is checked as you type: errors and warnings for the current line appear here, with the line / column and a count. F8 jumps to the next problem. Errors from vasm itself are marked on their line after a build." }
            ]
        },
        {
            id : "tracker", title : "Music tracker (TRACKER)",
            summary : "Composing 4-channel ProTracker music: song, order, instruments, synth sounds, patterns and the note keys.",
            steps : [
                { title : "Music tracker", show : "tracker", rect : function() { return scr_tour_tracker_rect("panel"); },
                  text : "Write your own music, ProTracker / OctaMED style. Four channels (Paula's four voices), 64 rows a pattern. Songs are saved as MOD assets, so a PLAY MUSIC node plays them on the Amiga. Opened from TRACKER under ORG, or from SND-EDIT." },
                { title : "Song", show : "tracker", rect : function() { return scr_tour_tracker_rect("song"); },
                  text : "NAME is the MOD asset (and assembler label), TITLE goes in the module. NEW SONG starts one with a lead, bass, pad and drum kit ready; SAVE stores it; SAVE + F5 also builds and runs. OPEN loads any MOD, imported ones too." },
                { title : "Order", show : "tracker", rect : function() { return scr_tour_tracker_rect("order"); },
                  text : "The order list plays patterns in sequence. INS repeats the pattern, DEL removes the position, NEW adds an empty pattern, CLONE a copy of this one, and < PATTERN > changes which pattern this position plays." },
                { title : "Instruments", show : "tracker", rect : function() { return scr_tour_tracker_rect("insts"); },
                  text : "31 instrument slots. Click one (or Numpad + / -) to use it for new notes." },
                { title : "Making sounds", show : "tracker", rect : function() { return scr_tour_tracker_rect("inst"); },
                  text : "Name, volume, finetune and loop of the instrument. The SYNTH buttons make classic chip sounds and drums with no sample files at all; FROM SAMPLE uses a sound imported in SND-EDIT. TO SAMPLE turns an instrument into a sound effect for PLAY SFX." },
                { title : "Play and edit", show : "tracker", rect : function() { return scr_tour_tracker_rect("transport"); },
                  text : "PLAY SONG (Shift+Enter), PLAY PATTERN (Enter), STOP or Space. EDIT ON records notes, FOLLOW keeps the cursor on the playing row. OCTAVE, STEP (rows moved after each note), SPEED and BPM; track and pattern copy, paste, clear and transpose." },
                { title : "Patterns", show : "tracker", rect : function() { return scr_tour_tracker_rect("pattern"); },
                  text : "Each cell is note, instrument and effect (C-2 01 C20). Play notes on the computer keyboard like a piano: Z to M is one octave, Q to P the next. Type hex digits in the instrument and effect columns; the line below explains the effect under the cursor. MUTE silences a channel while you listen." }
            ]
        },
        {
            id : "audio", title : "Sound and music (SND-EDIT)",
            summary : "Importing MODs and samples, previewing, tuning, looping and editing sound effects.",
            steps : [
                { title : "Sound and music", show : "audio:mod", rect : function() { return scr_tour_audio_rect("panel"); },
                  text : "Music (ProTracker MODs) and sound effects (samples) for PLAY MOD, PLAY SFX and the Game Kit. The demo has a tune and three effects made by tutorial 10." },
                { title : "Import settings", show : "audio:mod", rect : function() { return scr_tour_audio_rect("import"); },
                  text : "The sample rate WAV files are converted to (lower uses less chip RAM), and whether they are normalised to full volume on import." },
                { title : "Music", show : "audio:mod", rect : function() { return scr_tour_audio_rect("mods"); },
                  text : "Your modules. IMPORT a 4-channel .mod, PLAY previews it here, RENAME, DELETE or EXPORT .MOD." },
                { title : "Module details", show : "audio:mod", rect : function() { return scr_tour_audio_rect("instruments"); },
                  text : "Title, size, song length, patterns and the instruments inside the module." },
                { title : "Channels", show : "audio:mod", rect : function() { return scr_tour_audio_rect("channels"); },
                  text : "While a module previews, the four Paula channels show what each one plays." },
                { title : "Samples", show : "audio:sample", rect : function() { return scr_tour_audio_rect("samples"); },
                  text : "Sound effects: IMPORT a WAV, IFF 8SVX or raw file, PLAY, RENAME, DELETE." },
                { title : "Waveform", show : "audio:sample", rect : function() { return scr_tour_audio_rect("wave"); },
                  text : "Drag to select part of the sample; drag the yellow flags at the top to set where a looping sound repeats." },
                { title : "Rate, volume, loop", show : "audio:sample", rect : function() { return scr_tour_audio_rect("sample_settings"); },
                  text : "RATE sets the playback period (<< >> jump by musical notes, Shift for bigger steps), VOLUME 0 to 64, LOOP makes it repeat." },
                { title : "Editing", show : "audio:sample", rect : function() { return scr_tour_audio_rect("sample_ops"); },
                  text : "TRIM to the selection, NORMALISE, REVERSE, FADE IN and FADE OUT - on the selection, or the whole sample when nothing is selected." }
            ]
        },
        {
            id : "tile", title : "Tiles and maps (TILE-EDIT)",
            summary : "Tilesets and tile flags, metatiles, room maps with enemies, and animation sets.",
            steps : [
                { title : "Four tabs", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("tabs"); },
                  text : "TILE-EDIT makes everything the Game Kit draws: TILES (8 x 8 to 32 x 32 pixels), METATILES (stamps up to 128 x 128), MAP (flip-screen rooms) and ANIMATIONS (the hero and enemies)." },
                { title : "Tilesets", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("lists"); },
                  text : "Each tileset has one tile size and its own 16 colours. NEW, RENAME and DELETE manage them." },
                { title : "Tiles", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("tile_grid"); },
                  text : "The tiles of the set; click one to edit it. Tile 0 is always empty. ADD, DUPLICATE, CLEAR and DELETE (maps that use a deleted tile are fixed for you)." },
                { title : "Drawing a tile", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("pixels"); },
                  text : "Left button paints the selected colour, right button colour 0." },
                { title : "Tools", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("tools"); },
                  text : "DRAW, LINE, RECT (Shift fills it), FILL and PICK - or D, L, R, F, P. UNDO / REDO per tile, and < TILE / TILE > to step through them." },
                { title : "Palette", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("palette"); },
                  text : "The set's 16 colours: click one to paint with it, and set it with the R, G, B bars." },
                { title : "Tile flags", show : "tile:TILES", rect : function() { return scr_tour_tile_rect("flags"); },
                  text : "What the tile does in the game: SOLID blocks, PLATFORM can be jumped through from below, HAZARD hurts, COLLECT is picked up, EXIT ends the level." },
                { title : "Metatiles", show : "tile:METATILES", rect : function() { return scr_tour_tile_rect("meta_list"); },
                  text : "Stamps made of tiles - ledges, hills, a 128 x 128 pyramid - so whole structures can be painted onto maps in one click. NEW, RENAME, RESIZE, DELETE." },
                { title : "Building a metatile", show : "tile:METATILES", rect : function() { return scr_tour_rect_union(scr_tour_tile_rect("meta_canvas"), scr_tour_tile_rect("meta_picker")); },
                  text : "Pick a tile on the right and paint it into the metatile's cells; right button clears a cell." },
                { title : "Maps and rooms", show : "tile:MAP", rect : function() { return scr_tour_tile_rect("navigator"); },
                  text : "A map is a grid of rooms, each one screen. Click a room in the overview (or PgUp / PgDn, Ctrl+arrows) to edit it; RESIZE ROOMS sets how many." },
                { title : "Painting the map", show : "tile:MAP", rect : function() { return scr_tour_tile_rect("map_view"); },
                  text : "The room at 3x. Paint tiles or metatiles with the left button, erase with the right. S marks the player's start, E the enemies." },
                { title : "Map tools", show : "tile:MAP", rect : function() { return scr_tour_rect_union(scr_tour_tile_rect("map_tools"), scr_tour_tile_rect("brushes")); },
                  text : "PAINT, RECT, SPAWN and ENEMY; GRID (G) and FLAGS overlays; map UNDO / REDO. Pick the brush below: a tile or a metatile." },
                { title : "Enemies", show : "tile:MAP", rect : function() { return scr_tour_tile_rect("enemies"); },
                  text : "With the ENEMY tool, click to add one (up to 6 per room), click a marker to select it, Delete removes it. Choose its animation set and walking speed here." },
                { title : "Animation sets", show : "tile:ANIMATIONS", rect : function() { return scr_tour_tile_rect("anim_list"); },
                  text : "The hero and the enemies: each set has idle, run, jump and fall states, every frame a 16-pixel-wide sprite." },
                { title : "A state", show : "tile:ANIMATIONS", rect : function() { return scr_tour_tile_rect("anim_row"); },
                  text : "One row per state: its RATE in frames per second, its frames, and a live preview facing right and (mirrored) left." },
                { title : "Frames", show : "tile:ANIMATIONS", rect : function() { return scr_tour_tile_rect("anim_frames"); },
                  text : "ADD FRAME uses an existing sprite, NEW FRAME makes a blank one to draw in SPR-EDIT, REMOVE and < > reorder. Click a frame to select it." }
            ]
        }
    ];
}
