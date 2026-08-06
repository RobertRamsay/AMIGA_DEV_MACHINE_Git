/// @desc obj_colour_picker Create
/// Universal modal RGB colour picker — used by SETBKG's own colour and by
/// each individual COPPER_BAR band. Values are 0-15 per channel — OCS/ECS's
/// native 12-bit colour space — using the same slider visual language as
/// the bitmap editor's own palette RGB sliders, just standalone and
/// screen-centred rather than tied to a bitmap palette slot.
///
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
panel_height = 190;
panel_x = (room_width - panel_width) / 2;
panel_y = (room_height - panel_height) / 2;

slider_x = panel_x + 70;
slider_width = 192;
slider_step_width = 12;
slider_height = 18;
slider_r_y = panel_y + 66;
slider_g_y = panel_y + 94;
slider_b_y = panel_y + 122;

close_button_x = panel_x + panel_width - 76;
close_button_y = panel_y + panel_height - 32;
close_button_width = 64;
close_button_height = 24;
