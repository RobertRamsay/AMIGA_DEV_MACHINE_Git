/// @desc scr_load_layout()
function scr_load_layout() {
    var _save_path = global.current_project_path + "/autosave_layout.json";

    if (!file_exists(_save_path)) {
        show_debug_message("No saved layout found at " + _save_path);
        return;
    }

    var _file = file_text_open_read(_save_path);
    var _json_text = "";

    while (!file_text_eof(_file)) {
        _json_text += file_text_read_string(_file);
        file_text_readln(_file);
    }

    file_text_close(_file);

    var _save_data = json_parse(_json_text);

    with (obj_opcode_node) {
        instance_destroy();
    }

    with (obj_amiga_root_node) {
        instance_destroy();
    }

    var _root_array = _save_data.roots;
    var _root_count = array_length(_root_array);
    var _r = 0;

    while (_r < _root_count) {
        var _root_data = _root_array[_r];
        var _new_root = instance_create_layer(_root_data.node_x, _root_data.node_y, "Instances", obj_amiga_root_node);

        _new_root.uid = _root_data.uid;
        _new_root.root_type = _root_data.root_type;
        _new_root.node_x = _root_data.node_x;
        _new_root.node_y = _root_data.node_y;

        _r += 1;
    }

    var _node_array = _save_data.nodes;
    var _node_count = array_length(_node_array);
    var _n = 0;

    while (_n < _node_count) {
        var _node_data = _node_array[_n];
        var _new_node = instance_create_layer(_node_data.node_x, _node_data.node_y, "Instances", obj_opcode_node);

        _new_node.uid = _node_data.uid;
        _new_node.node_x = _node_data.node_x;
        _new_node.node_y = _node_data.node_y;
        _new_node.is_connected = _node_data.is_connected;
        _new_node.root_uid = _node_data.root_uid;
        _new_node.opcode_mnemonic = _node_data.opcode_mnemonic;
        _new_node.opcode_size = _node_data.opcode_size;
        _new_node.addressing_mode_src = _node_data.addressing_mode_src;
        _new_node.addressing_mode_dst = _node_data.addressing_mode_dst;
        _new_node.operand_src = _node_data.operand_src;
        _new_node.operand_dst = _node_data.operand_dst;
        _new_node.operand_label_src = _node_data.operand_label_src;
        _new_node.operand_label_dst = _node_data.operand_label_dst;
        _new_node.node_label = _node_data.node_label;

        _new_node.operand_extra_src.displacement = _node_data.displacement_src;
        _new_node.operand_extra_src.index_register = _node_data.index_register_src;
        _new_node.operand_extra_src.index_register_is_address = _node_data.index_register_is_address_src;

        _new_node.operand_extra_dst.displacement = _node_data.displacement_dst;
        _new_node.operand_extra_dst.index_register = _node_data.index_register_dst;
        _new_node.operand_extra_dst.index_register_is_address = _node_data.index_register_is_address_dst;

        _n += 1;
    }

    show_debug_message("Loaded layout from " + _save_path);
}