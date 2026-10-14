/// @desc Auto-boot disk writer, ADAM-style.
/// The disk is [hunkboot.bin][main.bin] written raw: the bootblock
/// (datafiles/boot/hunkboot.s) streams the Hunk executable in with
/// trackdisk.device, relocates it and jumps in. No AmigaDOS, no
/// Startup-Sequence and no xdftool, so the build boots straight into the
/// program on any Kickstart, including FS-UAE's built-in AROS ROM.
/// tools/make_adf.ps1 is the same writer in PowerShell, for testing disks
/// without GameMaker.

#macro AMIGA_ADF_SIZE 901120
#macro AMIGA_BOOT_RESERVE_ADDR 131072   // $20000 - the fixed chip RAM the macros poke
#macro AMIGA_BOOT_RESERVE_SIZE 327680   // up to $70000 (sprite data, copper lists, test bitplanes)

/// Path of the loader that ships in Included Files.
function scr_amiga_boot_loader_path() {
    return working_directory + "boot/hunkboot.bin";
}

/// Standard Amiga bootblock checksum over the first 1024 bytes of _buffer
/// (the checksum long at offset 4 must already be 0).
function scr_amiga_boot_checksum(_buffer) {
    var _sum = 0;
    var _i = 0;

    while (_i < 1024) {
        buffer_seek(_buffer, buffer_seek_start, _i);
        var _long = (buffer_read(_buffer, buffer_u8) << 24)
            | (buffer_read(_buffer, buffer_u8) << 16)
            | (buffer_read(_buffer, buffer_u8) << 8)
            | buffer_read(_buffer, buffer_u8);
        _sum += _long;
        if (_sum > 0xFFFFFFFF) _sum = (_sum & 0xFFFFFFFF) + 1;
        _i += 4;
    }

    return 0xFFFFFFFF - _sum;
}

/// Big-endian long into a buffer (GML buffers are little-endian).
function scr_amiga_buffer_poke_long(_buffer, _offset, _value) {
    buffer_poke(_buffer, _offset, buffer_u8, (_value >> 24) & 255);
    buffer_poke(_buffer, _offset + 1, buffer_u8, (_value >> 16) & 255);
    buffer_poke(_buffer, _offset + 2, buffer_u8, (_value >> 8) & 255);
    buffer_poke(_buffer, _offset + 3, buffer_u8, _value & 255);
}

/// Writes an auto-booting ADF for the Hunk executable at _bin_path.
/// Returns { ok, message, program_bytes }.
function scr_amiga_write_boot_adf(_bin_path, _adf_path) {
    var _result = { ok : false, message : "", program_bytes : 0 };
    var _loader_path = scr_amiga_boot_loader_path();

    if (!file_exists(_loader_path)) {
        _result.message = "Boot loader missing: " + _loader_path;
        return _result;
    }

    if (!file_exists(_bin_path)) {
        _result.message = "vasm produced no program (" + _bin_path + ")";
        return _result;
    }

    var _loader = buffer_load(_loader_path);
    var _program = buffer_load(_bin_path);
    var _loader_size = buffer_get_size(_loader);
    var _program_size = buffer_get_size(_program);
    _result.program_bytes = _program_size;

    if (_loader_size > 1024) {
        buffer_delete(_loader);
        buffer_delete(_program);
        _result.message = "Boot loader is larger than a bootblock.";
        return _result;
    }

    if (_program_size < 4 || buffer_peek(_program, 0, buffer_u8) != 0 || buffer_peek(_program, 3, buffer_u8) != 0xF3) {
        buffer_delete(_loader);
        buffer_delete(_program);
        _result.message = "main.bin is not an Amiga Hunk executable.";
        return _result;
    }

    if (1024 + _program_size > AMIGA_ADF_SIZE) {
        buffer_delete(_loader);
        buffer_delete(_program);
        _result.message = "Program is " + string(_program_size div 1024) + " KB - more than one 880 KB floppy holds.";
        return _result;
    }

    var _disk = buffer_create(AMIGA_ADF_SIZE, buffer_fixed, 1);
    buffer_fill(_disk, 0, buffer_u8, 0, AMIGA_ADF_SIZE);
    buffer_copy(_loader, 0, _loader_size, _disk, 0);

    // Find the "ADMB" tag the loader keeps its patchable fields after.
    var _tag = -1;
    var _scan = 0;
    while (_scan < 1020) {
        if (buffer_peek(_disk, _scan, buffer_u8) == 65 && buffer_peek(_disk, _scan + 1, buffer_u8) == 68
            && buffer_peek(_disk, _scan + 2, buffer_u8) == 77 && buffer_peek(_disk, _scan + 3, buffer_u8) == 66) {
            _tag = _scan;
            break;
        }
        _scan += 2;
    }

    if (_tag < 0) {
        buffer_delete(_loader);
        buffer_delete(_program);
        buffer_delete(_disk);
        _result.message = "Boot loader has no ADMB tag.";
        return _result;
    }

    var _read_size = ((_program_size + 511) div 512) * 512;
    scr_amiga_buffer_poke_long(_disk, _tag + 4, _read_size);
    scr_amiga_buffer_poke_long(_disk, _tag + 8, AMIGA_BOOT_RESERVE_ADDR);
    scr_amiga_buffer_poke_long(_disk, _tag + 12, AMIGA_BOOT_RESERVE_SIZE);
    scr_amiga_buffer_poke_long(_disk, 4, 0);
    scr_amiga_buffer_poke_long(_disk, 4, scr_amiga_boot_checksum(_disk));

    buffer_copy(_program, 0, _program_size, _disk, 1024);

    // Write under a temporary name, then publish: a half-written disk.adf
    // must never reach FS-UAE.
    var _working_path = _adf_path + ".writing";
    if (file_exists(_working_path)) file_delete(_working_path);
    buffer_save(_disk, _working_path);

    buffer_delete(_loader);
    buffer_delete(_program);
    buffer_delete(_disk);

    if (!file_exists(_working_path)) {
        _result.message = "Could not write " + _working_path;
        return _result;
    }

    if (file_exists(_adf_path)) file_delete(_adf_path);
    file_rename(_working_path, _adf_path);

    if (!file_exists(_adf_path)) {
        _result.message = "Could not write " + _adf_path + " (is FS-UAE still holding it?)";
        return _result;
    }

    _result.ok = true;
    _result.message = "Auto-boot disk written: " + string(_program_size) + " bytes of program.";
    return _result;
}
