/// @desc scr_amiga_restore_wedge_shifts()
/// Every node that was live-shifted for a wedge preview gets its real
/// position put back, every frame, before the preview is recomputed fresh.
function scr_amiga_restore_wedge_shifts() {
    with (obj_opcode_node) {
        if (wedge_y_stored >= 0) {
            node_y = wedge_y_stored;
            wedge_y_stored = -1;
        }
    }
}
