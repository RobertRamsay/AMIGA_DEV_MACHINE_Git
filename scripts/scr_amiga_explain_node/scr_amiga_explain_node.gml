/// @desc scr_amiga_explain_node(_node)
/// Central semantic lookup for hover help. Returns a plain-English explanation
/// for known Amiga hardware operations, or an empty string when the node has
/// no explanation yet. Extend this function as new macros/registers are added.
function scr_amiga_explain_node(_node) {
    if (_node.is_macro) {
        if (_node.macro_type == "COPPER_BAR") {
            var _asset = scr_asset_find_by_name(_node.macro_asset_name);
            var _band_text = "its configured colour bands";

            if (_asset != undefined && _asset.type == "COPPER_BAR") {
                _band_text = string(array_length(_asset.bands)) + " timed colour bands";
            }

            return "Builds a Copper display list containing " + _band_text
                + ". The Copper waits for chosen raster lines, changes COLOR00,"
                + " then repeats the list every video frame.";
        }

        if (_node.macro_type == "SPRITE_DISPLAY") {
            var _asset = scr_asset_find_by_name(_node.macro_asset_name);
            var _sprite_text = "the selected hardware sprite";

            if (_asset != undefined && _asset.type == "SPRITE") {
                _sprite_text = "hardware sprite " + string(_asset.channel)
                    + " at $" + scr_number_to_hex_string(_asset.address)
                    + ", " + string(_asset.height) + " rows high";
            }

            return "Creates a 320x256 PAL low-resolution display and uploads "
                + _sprite_text + ". It programs the sprite's three 12-bit colours"
                + " and uses the Copper to restore sprite and bitplane pointers each frame.";
        }

        if (_node.macro_type == "BITMAP_DISPLAY") {
            return "Converts TestBitmap into five native Amiga bitplanes, allocates chip RAM, uploads all 32 programmable 12-bit colours and opens a stable 320x256 PAL display. A Copper list restores all five bitplane pointers every frame.";
        }

        return "";
    }

    if (_node.opcode_mnemonic == "BRA" && _node.addressing_mode_src == "LABEL") {
        return "Branches back to '" + _node.operand_label_src
            + "'. In the test programs this forms the permanent idle loop after hardware setup.";
    }

    if (_node.opcode_mnemonic == "NOP" && _node.node_label != "") {
        return "Does no processor work. The label '" + _node.node_label
            + "' provides a safe target for the program's idle loop.";
    }

    if (_node.opcode_mnemonic != "MOVE" || _node.addressing_mode_src != "#imm" || _node.addressing_mode_dst != "abs.L") {
        return "";
    }

    var _value = _node.operand_src;
    var _address = _node.operand_dst;

    // Core DMA and interrupt controls.
    if (_address == 14676118) {
        if (_value == 32767) {
            return "DMACON: clears all DMA channels before changing display hardware.";
        }

        var _dma_parts = [];
        if (_value & 512) array_push(_dma_parts, "master DMA");
        if (_value & 256) array_push(_dma_parts, "bitplane DMA");
        if (_value & 128) array_push(_dma_parts, "Copper DMA");
        if (_value & 32) array_push(_dma_parts, "sprite DMA");

        var _dma_text = "selected DMA channels";
        if (array_length(_dma_parts) > 0) {
            _dma_text = _dma_parts[0];
            var _dma_index = 1;

            while (_dma_index < array_length(_dma_parts)) {
                _dma_text += ", " + _dma_parts[_dma_index];
                _dma_index += 1;
            }
        }

        return "DMACON: enables " + _dma_text + ". Bit 15 selects SET rather than CLEAR.";
    }

    if (_address == 14676122) {
        if (_value == 32767) {
            return "INTENA: disables all Amiga hardware interrupts while the test owns the machine.";
        }
        return "INTENA: changes which Amiga hardware interrupt sources are enabled.";
    }

    // Copper and display pointers.
    if (_address == 14676096) {
        return "COP1LC: points the Copper at its display list in chip RAM, address $"
            + scr_number_to_hex_string(_value) + ".";
    }

    if (_address == 14676192) {
        return "BPL1PTH/PTL: points bitplane 1 at chip RAM address $"
            + scr_number_to_hex_string(_value) + ".";
    }

    if (_address >= 14676256 && _address <= 14676284 && ((_address - 14676256) mod 4 == 0)) {
        var _sprite_channel = (_address - 14676256) div 4;
        return "SPR" + string(_sprite_channel) + "PTH/PTL: points hardware sprite "
            + string(_sprite_channel) + " at chip RAM address $" + scr_number_to_hex_string(_value) + ".";
    }

    // Display geometry and mode registers.
    if (_address == 14676110) {
        return "DIWSTRT: sets the display window's top-left start position to $"
            + scr_number_to_hex_string(_value) + ".";
    }

    if (_address == 14676112) {
        return "DIWSTOP: sets the display window's bottom-right stop position to $"
            + scr_number_to_hex_string(_value) + ".";
    }

    if (_address == 14676114) {
        return "DDFSTRT: starts bitplane data fetching at horizontal position $"
            + scr_number_to_hex_string(_value) + ".";
    }

    if (_address == 14676116) {
        return "DDFSTOP: stops bitplane data fetching at horizontal position $"
            + scr_number_to_hex_string(_value) + ".";
    }

    if (_address == 14676224) {
        if (_value == 4608) {
            return "BPLCON0: selects a low-resolution display with one active bitplane (320 pixels wide).";
        }
        if (_value == 512) {
            return "BPLCON0: selects a low-resolution display with zero bitplanes.";
        }
        return "BPLCON0: controls display resolution, bitplane count, HAM, dual-playfield and interlace.";
    }

    if (_address == 14676226) return "BPLCON1: sets horizontal scrolling for the playfield. Zero means no scroll.";
    if (_address == 14676228) return "BPLCON2: controls sprite/playfield priority. Zero uses the standard priority order.";
    if (_address == 14676230) return "BPLCON3: clears advanced ECS/AGA display-bank and border options.";
    if (_address == 14676232) return "BPL1MOD: sets the byte skip after each bitplane row. Zero means tightly packed rows.";
    if (_address == 14676236) return "BPLCON4: selects AGA sprite palette offsets. $0011 preserves COLOR17-31 compatibility.";
    if (_address == 14676476) return "FMODE: selects standard-width AGA fetch and sprite data modes.";

    // Palette registers, COLOR00 through COLOR31.
    if (_address >= 14676352 && _address <= 14676414 && ((_address - 14676352) mod 2 == 0)) {
        var _colour_index = (_address - 14676352) div 2;
        var _r = (_value >> 8) & 15;
        var _g = (_value >> 4) & 15;
        var _b = _value & 15;
        var _digits = "0123456789ABCDEF";
        var _rgb = string_char_at(_digits, _r + 1)
            + string_char_at(_digits, _g + 1)
            + string_char_at(_digits, _b + 1);
        return "COLOR" + string(_colour_index) + ": programs Amiga 12-bit colour #" + _rgb + ".";
    }

    // Copper test data written into its chip-RAM display list.
    if (_address >= 131072 && _address < 135168 && _node.opcode_size == "L") {
        var _high_word = floor(_value / 65536) & 65535;
        var _low_word = _value & 65535;

        if (_value == 4294967294) {
            return "Copper end marker: stops list processing safely until the next video frame.";
        }

        if (_low_word == 65280) {
            var _raster_line = (_high_word >> 8) & 255;
            return "Copper WAIT instruction: pauses the Copper until raster line "
                + string(_raster_line) + ".";
        }

        if (_high_word == 384) {
            var _r = (_low_word >> 8) & 15;
            var _g = (_low_word >> 4) & 15;
            var _b = _low_word & 15;
            var _digits = "0123456789ABCDEF";
            var _rgb = string_char_at(_digits, _r + 1)
                + string_char_at(_digits, _g + 1)
                + string_char_at(_digits, _b + 1);
            return "Copper MOVE instruction: changes background COLOR00 to Amiga colour #" + _rgb + ".";
        }

        return "Writes one encoded Copper instruction into the display list in chip RAM.";
    }

    return "";
}
