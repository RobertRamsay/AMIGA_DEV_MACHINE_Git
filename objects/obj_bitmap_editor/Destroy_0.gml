if (surface_exists(bitmap_surface)) {
    surface_free(bitmap_surface);
}

if (buffer_exists(bitmap_buffer)) {
    buffer_delete(bitmap_buffer);
}

// Restore the normal node workspace when the modal editor closes.
with (obj_amiga_manager) visible = true;
with (obj_opcode_node) visible = true;
with (obj_amiga_root_node) visible = true;
with (obj_opcode_palette_item) visible = true;
