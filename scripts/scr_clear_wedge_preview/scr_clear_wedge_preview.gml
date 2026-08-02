/// @desc scr_clear_wedge_preview()
/// Resets every node's temporary wedge-insert preview offset back to zero.
function scr_clear_wedge_preview() {
    with (obj_opcode_node) {
        wedge_preview_shift_y = 0;
    }
}
