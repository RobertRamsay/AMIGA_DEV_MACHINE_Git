// Node identity
uid = irandom(999999);
node_x = 0;
node_y = 0;
node_width = 160;
node_height = 60;

// Interaction state
is_dragging = false;
is_selected = false;
drag_offset_x = 0;
drag_offset_y = 0;
grab_start_x = 0;
grab_start_y = 0;
origin_parent_uid = -1;
origin_child_uid = -1;

is_connected = false;
parent_uid = -1;

wedge_preview_shift_y = 0;
wedge_target_found = false;
wedge_target_parent_uid = -1;
wedge_target_child_uid = -1;
wedge_target_x = 0;
wedge_target_y = 0;

node_label = "";
operand_label_src = "";
operand_label_dst = "";

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

value_box_width = 34;
operand_editing_slot = "";
operand_edit_text = "";