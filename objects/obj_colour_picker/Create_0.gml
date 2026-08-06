/// @desc obj_colour_picker Create
/// Modal RGB colour picker for macro nodes storing a raw hex colour
/// (SETBKG today). Values are 0-15 per channel — OCS/ECS's native 12-bit
/// colour space — using the same slider visual language as the bitmap
/// editor's own palette RGB sliders, just standalone and screen-centred
/// rather than tied to a bitmap palette slot.
target_instance_id = noone;
colour_r = 0;
colour_g = 0;
colour_b = 0;

panel_width = 280;
panel_height = 200;
panel_x = (room_width - panel_width) / 2;
panel_y = (room_height - panel_height) / 2;

slider_x = panel_x + 70;
slider_width = 192;
slider_step_width = 12;
slider_height = 18;
slider_r_y = panel_y + 70;
slider_g_y = panel_y + 98;
slider_b_y = panel_y + 126;

close_button_x = panel_x + panel_width - 76;
close_button_y = panel_y + panel_height - 34;
close_button_width = 64;
close_button_height = 24;
