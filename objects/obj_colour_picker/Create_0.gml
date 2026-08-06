/// @desc obj_colour_picker Create
/// Universal modal RGB colour picker — used by SETBKG's own colour and by
/// each individual COPPER_BAR band. Values are 0-15 per channel — OCS/ECS's
/// native 12-bit colour space — using the same slider visual language as
/// the bitmap editor's own palette RGB sliders, just standalone and
/// screen-centred rather than tied to a bitmap palette slot.
///
/// depth is set deeper than obj_bitmap_editor/obj_cprbar_editor's own
/// -100000 so this always draws on top even when opened from within one
/// of those — without this, whichever one happened to draw last (implicit,
/// unreliable order) would paint its own backdrop straight over the picker.
depth = -200000;

/// Write-back is generic: target_instance_id + target_variable_name name a
/// plain instance variable to write the committed hex string into, unless
/// target_array_index is >= 0, in which case that variable is treated as
/// an array and only that slot is written. Callers should use
/// scr_colour_picker_open() rather than setting these fields by hand.
target_instance_id = noone;
target_variable_name = "";
target_array_index = -1;
picker_title = "Colour to set";
colour_r = 0;
colour_g = 0;
colour_b = 0;

panel_width = 280;
panel_height = 222;
panel_x = (room_width - panel_width) / 2;
panel_y = (room_height - panel_height) / 2;

slider_x = panel_x + 70;
slider_width = 192;
slider_step_width = 12;
slider_height = 18;
slider_r_y = panel_y + 66;
slider_g_y = panel_y + 94;
slider_b_y = panel_y + 122;

// Global recent-colours row — up to 8 swatches, clicking one recalls it
// into colour_r/g/b for further editing (does not commit by itself).
recent_row_y = panel_y + 154;
recent_swatch_width = 28;
recent_swatch_height = 20;
recent_swatch_gap = 4;
recent_row_x = panel_x + 12;

close_button_x = panel_x + panel_width - 76;
close_button_y = panel_y + panel_height - 32;
close_button_width = 64;
close_button_height = 24;
