/// @desc obj_cprbar_editor Create
/// Modal editor for a single COPPER_BAR node's own fields — band count,
/// which COLOR register the bar targets, the raster range, and up to 16
/// individual band colours (each opens the universal colour picker via
/// scr_colour_picker_open). Reads and writes target_node_id's fields
/// directly and live — there is no separate scratch copy, so Close is a
/// plain dismiss, not a commit; the undo snapshot taken when this editor
/// opens covers the whole editing session in one Ctrl+Z if needed.
target_node_id = noone;

panel_width = 460;
panel_height = 440;
panel_x = (room_width - panel_width) / 2;
panel_y = (room_height - panel_height) / 2;

stepper_width = 24;
stepper_height = 24;

row_band_count_y = panel_y + 40;
row_target_register_y = panel_y + 72;
row_equidistant_y = panel_y + 104;
row_vp_y = panel_y + 136;

band_count_minus_x = panel_x + 150;
band_count_plus_x = panel_x + 260;

target_register_minus_x = panel_x + 150;
target_register_plus_x = panel_x + 260;

equidistant_toggle_x = panel_x + 150;
equidistant_toggle_width = 100;
equidistant_toggle_height = 24;

vp_start_minus_x = panel_x + 140;
vp_start_plus_x = panel_x + 210;
vp_end_minus_x = panel_x + 280;
vp_end_plus_x = panel_x + 350;

swatch_area_x = panel_x + 20;
swatch_area_y = panel_y + 172;
swatch_columns = 4;
swatch_size = 44;
swatch_gap = 10;

close_button_width = 64;
close_button_height = 24;
close_button_x = panel_x + panel_width - close_button_width - 16;
close_button_y = panel_y + panel_height - close_button_height - 16;
