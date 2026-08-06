if (surface_exists(bitmap_surface)) {
    surface_free(bitmap_surface);
}

if (buffer_exists(bitmap_buffer)) {
    buffer_delete(bitmap_buffer);
}
