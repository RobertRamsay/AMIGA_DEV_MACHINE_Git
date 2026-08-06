// Node identity
uid = irandom(999999);
node_x = 0;
node_y = 0;
depth = 0;
node_width = 200;
node_height = 60;

// Interaction state
is_dragging = false;
is_selected = false;
drag_offset_x = 0;
drag_offset_y = 0;
prev_x = 0;
prev_y = 0;
was_dragged = false;

is_connected = false;
root_uid = -1;
wedge_y_stored = -1;

wedge_target_found = false;
wedge_target_root_uid = -1;
wedge_target_y = 0;
wedge_target_anchor_x = 0;

node_label = "";
operand_label_src = "";
operand_label_dst = "";

// Macro nodes reference a named asset instead of carrying operands directly
is_macro = false;
macro_type = "";
macro_asset_name = "";
preview_collapsed = true;

// Opcode data — fully populated, no partial/optional fields
opcode_mnemonic = "MOVE";
opcode_size = "W";
addressing_mode_src = "Dn";
addressing_mode_dst = "Dn";
operand_src = 0;
operand_dst = 0;

operand_extra_src = {
    index_register : -1,
    index_register_is_address : false,
    displacement : 0
};

operand_extra_dst = {
    index_register : -1,
    index_register_is_address : false,
    displacement : 0
};

// Connection slots — initialized as real structs, never checked for existence later
src_validity_dot = {
    dot_x : 0,
    dot_y : 0
};

dst_validity_dot = {
    dot_x : 0,
    dot_y : 0
};


// Visuals
node_colour = c_green;

slot_src_is_valid = true;
slot_dst_is_valid = true;

mode_button_width = 70;
mode_button_height = 18;
mode_button_src_x = 0;
mode_button_src_y = 0;
mode_button_dst_x = 0;
mode_button_dst_y = 0;

value_box_width = 70;
operand_editing_slot = "";
operand_edit_text = "";