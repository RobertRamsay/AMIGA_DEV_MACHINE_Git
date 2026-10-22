/// scr_asm_lang
/// 68000 / vasm (Motorola syntax, vasmm68k_mot) language module shared by the
/// CODE block editor (obj_code_editor) and the build emitter.
///
/// Public API
///   scr_asm_lang_data()                         -> internal tables (lazy, cached)
///   scr_asm_tokenize_line(_line)                -> [{kind, text, start_col, field}]
///   scr_asm_validate(_text, _external_symbols)  -> [{line, col, len, message, severity}]
///   scr_asm_analyse_lines(_lines, _external)    -> {diagnostics, labels, locals, macros, label_names, defined}
///   scr_asm_collect_labels(_text)               -> [label names]
///   scr_asm_normalise_for_emit(_text)           -> string
///   scr_asm_hardware_equates_text()             -> string of "NAME<tab>equ<tab>value" lines
///   scr_asm_global_symbols([_exclude_node])     -> [names]
///   scr_asm_completions(_prefix, _context, [_mnemonic], [_local_names], [_global_symbols]) -> [{text, kind, detail}]
///   scr_asm_symbol_help(_word)                  -> help string ("" when unknown)
///   scr_asm_lang_selftest()                     -> [failure strings] (empty = all passed)
///
/// All columns / lines are 0-based. Token arrays returned by the tokenizer
/// and diagnostic arrays returned by scr_asm_validate are cached and shared:
/// callers must treat them as read-only. Per-line analysis is cached by the
/// line string, so re-validating mostly-unchanged text is cheap.

// Script-level globals are initialised at game start, before any room.
global.__asm_lang = undefined;
global.__asm_tok_cache = { map : {}, count : 0 };
global.__asm_val_cache = { map : {}, count : 0 };
global.__asm_label_cache = { map : {}, count : 0 };
global.__asm_gs_cache = { time : -1, exclude : noone, result : [] };

// vasm mot syntax (without -spaces): a blank after a complete operand field
// starts the comment field. Mirror that so trailing comments are not
// reported as undefined symbols.
global.asm_lang_blank_starts_comment = true;

#region character classes (char codes)

function __asm_cc_space(_c) {
    return _c == 32 || _c == 9;
}

function __asm_cc_digit(_c) {
    return _c >= 48 && _c <= 57;
}

function __asm_cc_hex(_c) {
    return (_c >= 48 && _c <= 57) || (_c >= 65 && _c <= 70) || (_c >= 97 && _c <= 102);
}

function __asm_cc_alpha(_c) {
    return (_c >= 65 && _c <= 90) || (_c >= 97 && _c <= 122) || _c == 95;
}

/// Characters allowed inside a symbol after the first one.
function __asm_cc_ident(_c) {
    return (_c >= 65 && _c <= 90) || (_c >= 97 && _c <= 122) || (_c >= 48 && _c <= 57)
        || _c == 95 || _c == 36 || _c == 64 || _c == 92;
}

function __asm_is_size_letter(_c) {
    // b w l s (either case)
    return _c == 66 || _c == 87 || _c == 76 || _c == 83 || _c == 98 || _c == 119 || _c == 108 || _c == 115;
}

function __asm_is_plain_word(_s) {
    var _n = string_length(_s);
    if (_n == 0) return false;
    var _i = 1;
    while (_i <= _n) {
        var _o = ord(string_char_at(_s, _i));
        if (!__asm_cc_ident(_o) && !(_o == 46 && _i > 1)) return false;
        _i += 1;
    }
    return true;
}

function __asm_hex(_value, _digits) {
    var _neg = _value < 0;
    var _v = abs(floor(_value));
    var _chars = "0123456789abcdef";
    var _out = "";
    do {
        _out = string_char_at(_chars, (_v mod 16) + 1) + _out;
        _v = _v div 16;
    } until (_v == 0);
    while (string_length(_out) < _digits) _out = "0" + _out;
    return (_neg ? "-$" : "$") + _out;
}

#endregion

#region language tables

function __asm_lang_add_mn(_map, _name, _sizes, _min, _max, _help_key, _branch) {
    _map[$ _name] = {
        name : _name,
        sizes : _sizes,
        min_ops : _min,
        max_ops : _max,
        help_key : _help_key,
        branch : _branch,
        detail : undefined
    };
}

function __asm_lang_add_dir(_map, _name, _sizes, _max_ops, _check_syms, _detail) {
    _map[$ _name] = {
        name : _name,
        sizes : _sizes,
        max_ops : _max_ops,
        check_syms : _check_syms,
        detail : _detail
    };
}

function __asm_lang_add_hw(_lang, _name, _value, _equ_text, _kind, _desc) {
    if (variable_struct_exists(_lang.hw, _name)) return;
    _lang.hw[$ _name] = { name : _name, value : _value, equ_text : _equ_text, kind : _kind, desc : _desc };
    array_push(_lang.hw_order, _name);
}

function __asm_lang_add_custom(_lang, _name, _offset, _desc) {
    __asm_lang_add_hw(_lang, _name, _offset, __asm_hex(_offset, 3), "custom",
        "$" + string_upper(string_delete(__asm_hex($DFF000 + _offset, 6), 1, 1)) + "  " + _desc);
}

function __asm_lang_build() {
    var _lang = {
        mnemonics : {},
        directives : {},
        registers : {},
        hw : {},
        hw_order : [],
        builtin_symbols : {},
        opmap_merged : false,
        pool_mnemonic : undefined,
        pool_operand : undefined
    };

    var _bwl = ["B", "W", "L"];
    var _wl = ["W", "L"];
    var _m = _lang.mnemonics;

    // --- Complete MC68000 instruction set -------------------------------
    __asm_lang_add_mn(_m, "ABCD", ["B"], 2, 2, "abcd", false);
    __asm_lang_add_mn(_m, "ADD", _bwl, 2, 2, "add", false);
    __asm_lang_add_mn(_m, "ADDA", _wl, 2, 2, "adda", false);
    __asm_lang_add_mn(_m, "ADDI", _bwl, 2, 2, "addi", false);
    __asm_lang_add_mn(_m, "ADDQ", _bwl, 2, 2, "addq", false);
    __asm_lang_add_mn(_m, "ADDX", _bwl, 2, 2, "addx", false);
    __asm_lang_add_mn(_m, "AND", _bwl, 2, 2, "and", false);
    __asm_lang_add_mn(_m, "ANDI", _bwl, 2, 2, "andi", false);
    __asm_lang_add_mn(_m, "ASL", _bwl, 1, 2, "asl", false);
    __asm_lang_add_mn(_m, "ASR", _bwl, 1, 2, "asr", false);
    __asm_lang_add_mn(_m, "BCHG", ["B", "L"], 2, 2, "bchg", false);
    __asm_lang_add_mn(_m, "BCLR", ["B", "L"], 2, 2, "bclr", false);
    __asm_lang_add_mn(_m, "BSET", ["B", "L"], 2, 2, "bset", false);
    __asm_lang_add_mn(_m, "BTST", ["B", "L"], 2, 2, "btst", false);
    __asm_lang_add_mn(_m, "BRA", ["B", "S", "W"], 1, 1, "bra", true);
    __asm_lang_add_mn(_m, "BSR", ["B", "S", "W"], 1, 1, "bsr", true);
    __asm_lang_add_mn(_m, "CHK", ["W"], 2, 2, "chk", false);
    __asm_lang_add_mn(_m, "CLR", _bwl, 1, 1, "clr", false);
    __asm_lang_add_mn(_m, "CMP", _bwl, 2, 2, "cmp", false);
    __asm_lang_add_mn(_m, "CMPA", _wl, 2, 2, "cmpa", false);
    __asm_lang_add_mn(_m, "CMPI", _bwl, 2, 2, "cmpi", false);
    __asm_lang_add_mn(_m, "CMPM", _bwl, 2, 2, "cmpm", false);
    __asm_lang_add_mn(_m, "DIVS", ["W"], 2, 2, "divs", false);
    __asm_lang_add_mn(_m, "DIVU", ["W"], 2, 2, "divu", false);
    __asm_lang_add_mn(_m, "EOR", _bwl, 2, 2, "eor", false);
    __asm_lang_add_mn(_m, "EORI", _bwl, 2, 2, "eori", false);
    __asm_lang_add_mn(_m, "EXG", ["L"], 2, 2, "exg", false);
    __asm_lang_add_mn(_m, "EXT", _wl, 1, 1, "ext", false);
    __asm_lang_add_mn(_m, "ILLEGAL", [], 0, 0, "illegal", false);
    __asm_lang_add_mn(_m, "JMP", [], 1, 1, "jmp", false);
    __asm_lang_add_mn(_m, "JSR", [], 1, 1, "jsr", false);
    __asm_lang_add_mn(_m, "LEA", ["L"], 2, 2, "lea", false);
    __asm_lang_add_mn(_m, "LINK", ["W"], 2, 2, "link", false);
    __asm_lang_add_mn(_m, "LSL", _bwl, 1, 2, "lsl", false);
    __asm_lang_add_mn(_m, "LSR", _bwl, 1, 2, "lsr", false);
    __asm_lang_add_mn(_m, "MOVE", _bwl, 2, 2, "move", false);
    __asm_lang_add_mn(_m, "MOVEA", _wl, 2, 2, "movea", false);
    __asm_lang_add_mn(_m, "MOVEM", _wl, 2, 2, "movem", false);
    __asm_lang_add_mn(_m, "MOVEP", _wl, 2, 2, "movep", false);
    __asm_lang_add_mn(_m, "MOVEQ", ["L"], 2, 2, "moveq", false);
    __asm_lang_add_mn(_m, "MULS", ["W"], 2, 2, "muls", false);
    __asm_lang_add_mn(_m, "MULU", ["W"], 2, 2, "mulu", false);
    __asm_lang_add_mn(_m, "NBCD", ["B"], 1, 1, "nbcd", false);
    __asm_lang_add_mn(_m, "NEG", _bwl, 1, 1, "neg", false);
    __asm_lang_add_mn(_m, "NEGX", _bwl, 1, 1, "negx", false);
    __asm_lang_add_mn(_m, "NOP", [], 0, 0, "nop", false);
    __asm_lang_add_mn(_m, "NOT", _bwl, 1, 1, "not", false);
    __asm_lang_add_mn(_m, "OR", _bwl, 2, 2, "or", false);
    __asm_lang_add_mn(_m, "ORI", _bwl, 2, 2, "ori", false);
    __asm_lang_add_mn(_m, "PEA", ["L"], 1, 1, "pea", false);
    __asm_lang_add_mn(_m, "RESET", [], 0, 0, "reset", false);
    __asm_lang_add_mn(_m, "ROL", _bwl, 1, 2, "rol", false);
    __asm_lang_add_mn(_m, "ROR", _bwl, 1, 2, "ror", false);
    __asm_lang_add_mn(_m, "ROXL", _bwl, 1, 2, "roxl", false);
    __asm_lang_add_mn(_m, "ROXR", _bwl, 1, 2, "roxr", false);
    __asm_lang_add_mn(_m, "RTE", [], 0, 0, "rte", false);
    __asm_lang_add_mn(_m, "RTR", [], 0, 0, "rtr", false);
    __asm_lang_add_mn(_m, "RTS", [], 0, 0, "rts", false);
    __asm_lang_add_mn(_m, "SBCD", ["B"], 2, 2, "sbcd", false);
    __asm_lang_add_mn(_m, "STOP", [], 1, 1, "stop", false);
    __asm_lang_add_mn(_m, "SUB", _bwl, 2, 2, "sub", false);
    __asm_lang_add_mn(_m, "SUBA", _wl, 2, 2, "suba", false);
    __asm_lang_add_mn(_m, "SUBI", _bwl, 2, 2, "subi", false);
    __asm_lang_add_mn(_m, "SUBQ", _bwl, 2, 2, "subq", false);
    __asm_lang_add_mn(_m, "SUBX", _bwl, 2, 2, "subx", false);
    __asm_lang_add_mn(_m, "SWAP", ["W"], 1, 1, "swap", false);
    __asm_lang_add_mn(_m, "TAS", ["B"], 1, 1, "tas", false);
    __asm_lang_add_mn(_m, "TRAP", [], 1, 1, "trap", false);
    __asm_lang_add_mn(_m, "TRAPV", [], 0, 0, "trapv", false);
    __asm_lang_add_mn(_m, "TST", _bwl, 1, 1, "tst", false);
    __asm_lang_add_mn(_m, "UNLK", [], 1, 1, "unlk", false);

    // Condition families. HS/LO are the vasm-accepted aliases of CC/CS.
    var _cc = ["HI", "LS", "CC", "CS", "NE", "EQ", "VC", "VS", "PL", "MI", "GE", "LT", "GT", "LE", "HS", "LO"];
    var _i = 0;
    while (_i < array_length(_cc)) {
        var _cond = _cc[_i];
        __asm_lang_add_mn(_m, "B" + _cond, ["B", "S", "W"], 1, 1, "bcc", true);
        __asm_lang_add_mn(_m, "DB" + _cond, ["W"], 2, 2, "dbcc", false);
        __asm_lang_add_mn(_m, "S" + _cond, ["B"], 1, 1, "scc", false);
        _i += 1;
    }
    __asm_lang_add_mn(_m, "DBT", ["W"], 2, 2, "dbcc", false);
    __asm_lang_add_mn(_m, "DBF", ["W"], 2, 2, "dbra", false);
    __asm_lang_add_mn(_m, "DBRA", ["W"], 2, 2, "dbra", false);
    __asm_lang_add_mn(_m, "ST", ["B"], 1, 1, "scc", false);
    __asm_lang_add_mn(_m, "SF", ["B"], 1, 1, "scc", false);

    // --- vasm directives (Motorola syntax module) ------------------------
    var _d = _lang.directives;
    __asm_lang_add_dir(_d, "DC", _bwl, -1, true, "Define constant data: DC.size value,...");
    __asm_lang_add_dir(_d, "DS", _bwl, -1, true, "Reserve zeroed storage: DS.size count");
    __asm_lang_add_dir(_d, "DCB", _bwl, -1, true, "Define constant block: DCB.size count,value");
    __asm_lang_add_dir(_d, "BLK", _bwl, -1, true, "Define constant block (alias of DCB)");
    __asm_lang_add_dir(_d, "DX", _bwl, -1, true, "Reserve storage in the BSS part of a data section");
    __asm_lang_add_dir(_d, "EVEN", [], 0, false, "Align to an even (word) address");
    __asm_lang_add_dir(_d, "ODD", [], 0, false, "Align to an odd address");
    __asm_lang_add_dir(_d, "CNOP", [], -1, true, "Align: CNOP offset,alignment (e.g. CNOP 0,4)");
    __asm_lang_add_dir(_d, "ALIGN", [], -1, true, "Align to 2^n bytes");
    __asm_lang_add_dir(_d, "SECTION", [], -1, false, "Start a section: SECTION name,type (CODE/DATA/BSS[_C|_F|_P])");
    __asm_lang_add_dir(_d, "CODE", [], 0, false, "Start an unnamed code section");
    __asm_lang_add_dir(_d, "DATA", [], 0, false, "Start an unnamed data section");
    __asm_lang_add_dir(_d, "BSS", [], 0, false, "Start an unnamed BSS section");
    __asm_lang_add_dir(_d, "CODE_C", [], 0, false, "Start a code section in chip RAM");
    __asm_lang_add_dir(_d, "DATA_C", [], 0, false, "Start a data section in chip RAM");
    __asm_lang_add_dir(_d, "BSS_C", [], 0, false, "Start a BSS section in chip RAM");
    __asm_lang_add_dir(_d, "CODE_F", [], 0, false, "Start a code section in fast RAM");
    __asm_lang_add_dir(_d, "DATA_F", [], 0, false, "Start a data section in fast RAM");
    __asm_lang_add_dir(_d, "BSS_F", [], 0, false, "Start a BSS section in fast RAM");
    __asm_lang_add_dir(_d, "CODE_P", [], 0, false, "Start a code section in public RAM");
    __asm_lang_add_dir(_d, "DATA_P", [], 0, false, "Start a data section in public RAM");
    __asm_lang_add_dir(_d, "BSS_P", [], 0, false, "Start a BSS section in public RAM");
    __asm_lang_add_dir(_d, "INCBIN", [], -1, false, "Include a binary file: INCBIN \"file\"[,offset[,length]]");
    __asm_lang_add_dir(_d, "INCLUDE", [], -1, false, "Include a source file: INCLUDE \"file\"");
    __asm_lang_add_dir(_d, "INCDIR", [], -1, false, "Add an include search path");
    __asm_lang_add_dir(_d, "EQU", [], -1, true, "Assign a constant: name EQU value");
    __asm_lang_add_dir(_d, "SET", [], -1, true, "Assign a redefinable value: name SET value");
    __asm_lang_add_dir(_d, "=", [], -1, true, "Assign a constant: name = value");
    __asm_lang_add_dir(_d, "EQUR", [], -1, false, "Register alias: name EQUR Dn/An");
    __asm_lang_add_dir(_d, "REG", [], -1, false, "Register list alias: name REG d0-d7/a0-a6");
    __asm_lang_add_dir(_d, "MACRO", [], -1, false, "Start a macro definition: name MACRO");
    __asm_lang_add_dir(_d, "ENDM", [], 0, false, "End a macro definition");
    __asm_lang_add_dir(_d, "MEXIT", [], 0, false, "Leave the current macro expansion");
    __asm_lang_add_dir(_d, "REPT", [], -1, true, "Repeat a block: REPT count ... ENDR");
    __asm_lang_add_dir(_d, "ENDR", [], 0, false, "End a REPT block");
    __asm_lang_add_dir(_d, "IF", [], -1, true, "Assemble if expression is non-zero");
    __asm_lang_add_dir(_d, "IFD", [], -1, false, "Assemble if symbol is defined");
    __asm_lang_add_dir(_d, "IFND", [], -1, false, "Assemble if symbol is not defined");
    __asm_lang_add_dir(_d, "IFEQ", [], -1, true, "Assemble if expression == 0");
    __asm_lang_add_dir(_d, "IFNE", [], -1, true, "Assemble if expression != 0");
    __asm_lang_add_dir(_d, "IFGT", [], -1, true, "Assemble if expression > 0");
    __asm_lang_add_dir(_d, "IFGE", [], -1, true, "Assemble if expression >= 0");
    __asm_lang_add_dir(_d, "IFLT", [], -1, true, "Assemble if expression < 0");
    __asm_lang_add_dir(_d, "IFLE", [], -1, true, "Assemble if expression <= 0");
    __asm_lang_add_dir(_d, "IFC", [], -1, false, "Assemble if two strings are equal");
    __asm_lang_add_dir(_d, "IFNC", [], -1, false, "Assemble if two strings differ");
    __asm_lang_add_dir(_d, "IFB", [], -1, false, "Assemble if operand is blank");
    __asm_lang_add_dir(_d, "IFNB", [], -1, false, "Assemble if operand is not blank");
    __asm_lang_add_dir(_d, "ELSE", [], 0, false, "Conditional assembly: else branch");
    __asm_lang_add_dir(_d, "ELSEIF", [], -1, true, "Conditional assembly: else-if branch");
    __asm_lang_add_dir(_d, "ENDIF", [], 0, false, "End a conditional block");
    __asm_lang_add_dir(_d, "ENDC", [], 0, false, "End a conditional block");
    __asm_lang_add_dir(_d, "XDEF", [], -1, false, "Export symbols");
    __asm_lang_add_dir(_d, "XREF", [], -1, false, "Import external symbols");
    __asm_lang_add_dir(_d, "PUBLIC", [], -1, false, "Export/import symbols");
    __asm_lang_add_dir(_d, "GLOBAL", [], -1, false, "Export/import symbols");
    __asm_lang_add_dir(_d, "RS", _bwl, -1, true, "Structure offset: name RS.size count");
    __asm_lang_add_dir(_d, "RSRESET", [], 0, false, "Reset the RS counter to 0");
    __asm_lang_add_dir(_d, "RSSET", [], -1, true, "Set the RS counter");
    __asm_lang_add_dir(_d, "SO", _bwl, -1, true, "Structure offset (alias of RS)");
    __asm_lang_add_dir(_d, "FO", _bwl, -1, true, "Negative frame offset");
    __asm_lang_add_dir(_d, "CLRSO", [], 0, false, "Reset the SO counter");
    __asm_lang_add_dir(_d, "CLRFO", [], 0, false, "Reset the FO counter");
    __asm_lang_add_dir(_d, "SETSO", [], -1, true, "Set the SO counter");
    __asm_lang_add_dir(_d, "SETFO", [], -1, true, "Set the FO counter");
    __asm_lang_add_dir(_d, "OFFSET", [], -1, true, "Start an offset (dummy) section");
    __asm_lang_add_dir(_d, "END", [], 0, false, "End of source");
    __asm_lang_add_dir(_d, "ORG", [], -1, true, "Set the absolute program counter");
    __asm_lang_add_dir(_d, "RORG", [], -1, true, "Relocatable origin");
    __asm_lang_add_dir(_d, "OPT", [], -1, false, "Assembler options (e.g. OPT O+)");
    __asm_lang_add_dir(_d, "MACHINE", [], -1, false, "Select CPU type");
    __asm_lang_add_dir(_d, "MC68000", [], 0, false, "Select 68000 CPU");
    __asm_lang_add_dir(_d, "FAIL", [], -1, false, "Abort assembly with an error message");
    __asm_lang_add_dir(_d, "PRINTT", [], -1, false, "Print text during assembly");
    __asm_lang_add_dir(_d, "PRINTV", [], -1, true, "Print a value during assembly");
    __asm_lang_add_dir(_d, "ECHO", [], -1, false, "Print text during assembly");
    __asm_lang_add_dir(_d, "ASSERT", [], -1, true, "Fail assembly if expression is false");
    __asm_lang_add_dir(_d, "LIST", [], 0, false, "Listing on");
    __asm_lang_add_dir(_d, "NOLIST", [], 0, false, "Listing off");
    __asm_lang_add_dir(_d, "PAGE", [], 0, false, "Listing page break");
    __asm_lang_add_dir(_d, "NOPAGE", [], 0, false, "No listing page breaks");
    __asm_lang_add_dir(_d, "TTL", [], -1, false, "Listing title");
    __asm_lang_add_dir(_d, "IDNT", [], -1, false, "Set module name");
    __asm_lang_add_dir(_d, "OUTPUT", [], -1, false, "Set output file name");
    __asm_lang_add_dir(_d, "INLINE", [], 0, false, "Start an inline local-label scope");
    __asm_lang_add_dir(_d, "EINLINE", [], 0, false, "End an inline local-label scope");

    // --- Registers (keyed lower case; matched case-insensitively) --------
    var _r = _lang.registers;
    _i = 0;
    while (_i < 8) {
        _r[$ "d" + string(_i)] = "Data register D" + string(_i) + " (32-bit)";
        _r[$ "a" + string(_i)] = (_i == 7) ? "Address register A7 = stack pointer (SP)" : "Address register A" + string(_i) + " (32-bit pointer)";
        _i += 1;
    }
    _r[$ "sp"] = "Stack pointer (= A7)";
    _r[$ "pc"] = "Program counter (PC-relative addressing)";
    _r[$ "sr"] = "Status register (system byte + CCR, privileged writes)";
    _r[$ "ccr"] = "Condition code register (X N Z V C)";
    _r[$ "usp"] = "User stack pointer (privileged)";

    // --- Symbols vasm itself predefines ----------------------------------
    var _b = _lang.builtin_symbols;
    _b[$ "NARG"] = true;
    _b[$ "CARG"] = true;
    _b[$ "REPTN"] = true;
    _b[$ "__RS"] = true;
    _b[$ "__SO"] = true;
    _b[$ "__FO"] = true;
    _b[$ "__VASM"] = true;
    _b[$ "__LINE__"] = true;

    // --- Hardware equates -------------------------------------------------
    __asm_lang_add_hw(_lang, "CUSTOM", $DFF000, "$dff000", "base", "Custom chip register base ($DFF000)");
    __asm_lang_add_hw(_lang, "CIAA", $BFE001, "$bfe001", "base", "CIA-A base ($BFE001, odd bytes): /FIR1 /FIR0 /RDY /TK0 /WPRO /CHNG /LED OVL");
    __asm_lang_add_hw(_lang, "CIAB", $BFD000, "$bfd000", "base", "CIA-B base ($BFD000, even bytes): serial/parallel control, disk select");

    var _custom = [
        ["BLTDDAT", $000, "Blitter destination early read (dummy address)"],
        ["DMACONR", $002, "DMA control (and blitter status) read"],
        ["VPOSR", $004, "Read vertical MSB and frame flop (bits 8-14 Agnus ID)"],
        ["VHPOSR", $006, "Read vertical and horizontal beam position"],
        ["DSKDATR", $008, "Disk data early read (dummy address)"],
        ["JOY0DAT", $00A, "Joystick/mouse counters, port 1"],
        ["JOY1DAT", $00C, "Joystick/mouse counters, port 2"],
        ["CLXDAT", $00E, "Collision data (read and clear)"],
        ["ADKCONR", $010, "Audio, disk, UART control read"],
        ["POT0DAT", $012, "Pot counter pair 0 data"],
        ["POT1DAT", $014, "Pot counter pair 1 data"],
        ["POTGOR", $016, "Pot port data read (right mouse button bits)"],
        ["POTINP", $016, "Pot port data read (alias of POTGOR)"],
        ["SERDATR", $018, "Serial port data and status read"],
        ["DSKBYTR", $01A, "Disk data byte and status read"],
        ["INTENAR", $01C, "Interrupt enable bits read"],
        ["INTREQR", $01E, "Interrupt request bits read"],
        ["DSKPT", $020, "Disk DMA pointer (long)"],
        ["DSKPTH", $020, "Disk DMA pointer high"],
        ["DSKPTL", $022, "Disk DMA pointer low"],
        ["DSKLEN", $024, "Disk DMA length"],
        ["DSKDAT", $026, "Disk DMA data write"],
        ["REFPTR", $028, "Refresh pointer"],
        ["VPOSW", $02A, "Write vertical MSB and frame flop"],
        ["VHPOSW", $02C, "Write vertical and horizontal beam position"],
        ["COPCON", $02E, "Copper control (CDANG)"],
        ["SERDAT", $030, "Serial port data and stop bits write"],
        ["SERPER", $032, "Serial port period and control"],
        ["POTGO", $034, "Pot port data write and start"],
        ["JOYTEST", $036, "Write to all four joystick/mouse counters"],
        ["STREQU", $038, "Strobe for horizontal sync with VB and EQU"],
        ["STRVBL", $03A, "Strobe for horizontal sync with VB"],
        ["STRHOR", $03C, "Strobe for horizontal sync"],
        ["STRLONG", $03E, "Strobe for identification of long horizontal line"],
        ["BLTCON0", $040, "Blitter control 0 (shift A, channel enables, minterm)"],
        ["BLTCON1", $042, "Blitter control 1 (shift B, line/fill mode)"],
        ["BLTAFWM", $044, "Blitter first-word mask for source A"],
        ["BLTALWM", $046, "Blitter last-word mask for source A"],
        ["BLTCPT", $048, "Blitter source C pointer (long)"],
        ["BLTCPTH", $048, "Blitter source C pointer high"],
        ["BLTCPTL", $04A, "Blitter source C pointer low"],
        ["BLTBPT", $04C, "Blitter source B pointer (long)"],
        ["BLTBPTH", $04C, "Blitter source B pointer high"],
        ["BLTBPTL", $04E, "Blitter source B pointer low"],
        ["BLTAPT", $050, "Blitter source A pointer (long)"],
        ["BLTAPTH", $050, "Blitter source A pointer high"],
        ["BLTAPTL", $052, "Blitter source A pointer low"],
        ["BLTDPT", $054, "Blitter destination D pointer (long)"],
        ["BLTDPTH", $054, "Blitter destination D pointer high"],
        ["BLTDPTL", $056, "Blitter destination D pointer low"],
        ["BLTSIZE", $058, "Blitter start and size (height<<6 | width in words)"],
        ["BLTCON0L", $05A, "Blitter control 0, lower 8 bits (minterms) (ECS)"],
        ["BLTSIZV", $05C, "Blitter vertical size (ECS big blits)"],
        ["BLTSIZH", $05E, "Blitter horizontal size and start (ECS big blits)"],
        ["BLTCMOD", $060, "Blitter modulo for source C"],
        ["BLTBMOD", $062, "Blitter modulo for source B"],
        ["BLTAMOD", $064, "Blitter modulo for source A"],
        ["BLTDMOD", $066, "Blitter modulo for destination D"],
        ["BLTCDAT", $070, "Blitter source C data"],
        ["BLTBDAT", $072, "Blitter source B data"],
        ["BLTADAT", $074, "Blitter source A data"],
        ["SPRHDAT", $078, "Ext. logic UHRES sprite pointer and data (ECS)"],
        ["BPLHDAT", $07A, "Ext. logic UHRES bitplane identifier (AGA)"],
        ["DENISEID", $07C, "Denise/Lisa chip revision ID (ECS/AGA)"],
        ["LISAID", $07C, "Lisa chip revision ID (alias of DENISEID)"],
        ["DSKSYNC", $07E, "Disk sync pattern for disk read"],
        ["COP1LC", $080, "Copper list 1 location (long)"],
        ["COP1LCH", $080, "Copper list 1 location high"],
        ["COP1LCL", $082, "Copper list 1 location low"],
        ["COP2LC", $084, "Copper list 2 location (long)"],
        ["COP2LCH", $084, "Copper list 2 location high"],
        ["COP2LCL", $086, "Copper list 2 location low"],
        ["COPJMP1", $088, "Copper restart at list 1 (strobe)"],
        ["COPJMP2", $08A, "Copper restart at list 2 (strobe)"],
        ["COPINS", $08C, "Copper instruction fetch identify"],
        ["DIWSTRT", $08E, "Display window start (upper-left vertical/horizontal)"],
        ["DIWSTOP", $090, "Display window stop (lower-right vertical/horizontal)"],
        ["DDFSTRT", $092, "Display bitplane data fetch start (horizontal)"],
        ["DDFSTOP", $094, "Display bitplane data fetch stop (horizontal)"],
        ["DMACON", $096, "DMA control write (bit 15 = set/clear)"],
        ["CLXCON", $098, "Collision control"],
        ["INTENA", $09A, "Interrupt enable bits write (bit 15 = set/clear)"],
        ["INTREQ", $09C, "Interrupt request bits write (bit 15 = set/clear)"],
        ["ADKCON", $09E, "Audio, disk, UART control write"],
        ["BPLCON0", $100, "Bitplane control 0 (planes, HIRES, HAM, colour enable)"],
        ["BPLCON1", $102, "Bitplane control 1 (horizontal scroll)"],
        ["BPLCON2", $104, "Bitplane control 2 (video priority)"],
        ["BPLCON3", $106, "Bitplane control 3 (enhanced features) (ECS/AGA)"],
        ["BPL1MOD", $108, "Bitplane modulo, odd planes"],
        ["BPL2MOD", $10A, "Bitplane modulo, even planes"],
        ["BPLCON4", $10C, "Bitplane control 4 (bitplane/sprite colour XOR) (AGA)"],
        ["CLXCON2", $10E, "Extended collision control (AGA)"],
        ["HTOTAL", $1C0, "Highest horizontal colour clock count (ECS)"],
        ["HSSTOP", $1C2, "Horizontal sync stop (ECS)"],
        ["HBSTRT", $1C4, "Horizontal blank start (ECS)"],
        ["HBSTOP", $1C6, "Horizontal blank stop (ECS)"],
        ["VTOTAL", $1C8, "Highest numbered vertical line (ECS)"],
        ["VSSTOP", $1CA, "Vertical sync stop (ECS)"],
        ["VBSTRT", $1CC, "Vertical blank start (ECS)"],
        ["VBSTOP", $1CE, "Vertical blank stop (ECS)"],
        ["SPRHSTRT", $1D0, "UHRES sprite vertical start (AGA)"],
        ["SPRHSTOP", $1D2, "UHRES sprite vertical stop (AGA)"],
        ["BPLHSTRT", $1D4, "UHRES bitplane vertical start (AGA)"],
        ["BPLHSTOP", $1D6, "UHRES bitplane vertical stop (AGA)"],
        ["HHPOSW", $1D8, "DUAL mode hires horizontal position write (AGA)"],
        ["HHPOSR", $1DA, "DUAL mode hires horizontal position read (AGA)"],
        ["BEAMCON0", $1DC, "Beam counter control (PAL/NTSC, programmable sync) (ECS)"],
        ["HSSTRT", $1DE, "Horizontal sync start (ECS)"],
        ["VSSTRT", $1E0, "Vertical sync start (ECS)"],
        ["HCENTER", $1E2, "Horizontal position for Vsync on interlace (ECS)"],
        ["DIWHIGH", $1E4, "Display window upper bits (ECS)"],
        ["BPLHMOD", $1E6, "UHRES bitplane modulo (AGA)"],
        ["SPRHPTH", $1E8, "UHRES sprite pointer high (AGA)"],
        ["SPRHPTL", $1EA, "UHRES sprite pointer low (AGA)"],
        ["BPLHPTH", $1EC, "UHRES bitplane pointer high (AGA)"],
        ["BPLHPTL", $1EE, "UHRES bitplane pointer low (AGA)"],
        ["FMODE", $1FC, "Fetch mode: bitplane/sprite fetch width (AGA)"],
        ["NOOP", $1FE, "No operation (NULL register)"]
    ];

    _i = 0;
    while (_i < array_length(_custom)) {
        var _entry = _custom[_i];
        __asm_lang_add_custom(_lang, _entry[0], _entry[1], _entry[2]);
        _i += 1;
    }

    // Audio channels 0-3: $0A0 + n*$10
    var _n = 0;
    while (_n < 4) {
        var _base = $0A0 + _n * $10;
        var _ch = "AUD" + string(_n);
        __asm_lang_add_custom(_lang, _ch + "LC", _base, "Audio channel " + string(_n) + " sample location (long)");
        __asm_lang_add_custom(_lang, _ch + "LCH", _base, "Audio channel " + string(_n) + " location high");
        __asm_lang_add_custom(_lang, _ch + "LCL", _base + 2, "Audio channel " + string(_n) + " location low");
        __asm_lang_add_custom(_lang, _ch + "LEN", _base + 4, "Audio channel " + string(_n) + " length (words)");
        __asm_lang_add_custom(_lang, _ch + "PER", _base + 6, "Audio channel " + string(_n) + " period");
        __asm_lang_add_custom(_lang, _ch + "VOL", _base + 8, "Audio channel " + string(_n) + " volume (0-64)");
        __asm_lang_add_custom(_lang, _ch + "DAT", _base + 10, "Audio channel " + string(_n) + " data");
        _n += 1;
    }

    // Bitplane pointers 1-8: $0E0 + (n-1)*4, data $110 + (n-1)*2
    _n = 1;
    while (_n <= 8) {
        var _pt = $0E0 + (_n - 1) * 4;
        var _bp = "BPL" + string(_n);
        __asm_lang_add_custom(_lang, _bp + "PT", _pt, "Bitplane " + string(_n) + " pointer (long)");
        __asm_lang_add_custom(_lang, _bp + "PTH", _pt, "Bitplane " + string(_n) + " pointer high");
        __asm_lang_add_custom(_lang, _bp + "PTL", _pt + 2, "Bitplane " + string(_n) + " pointer low");
        __asm_lang_add_custom(_lang, _bp + "DAT", $110 + (_n - 1) * 2, "Bitplane " + string(_n) + " data (parallel-to-serial)");
        _n += 1;
    }

    // Sprites 0-7: pointers $120 + n*4, control block $140 + n*8
    _n = 0;
    while (_n < 8) {
        var _sp = "SPR" + string(_n);
        var _spt = $120 + _n * 4;
        var _sblk = $140 + _n * 8;
        __asm_lang_add_custom(_lang, _sp + "PT", _spt, "Sprite " + string(_n) + " pointer (long)");
        __asm_lang_add_custom(_lang, _sp + "PTH", _spt, "Sprite " + string(_n) + " pointer high");
        __asm_lang_add_custom(_lang, _sp + "PTL", _spt + 2, "Sprite " + string(_n) + " pointer low");
        __asm_lang_add_custom(_lang, _sp + "POS", _sblk, "Sprite " + string(_n) + " vertical/horizontal start");
        __asm_lang_add_custom(_lang, _sp + "CTL", _sblk + 2, "Sprite " + string(_n) + " vertical stop and control");
        __asm_lang_add_custom(_lang, _sp + "DATA", _sblk + 4, "Sprite " + string(_n) + " image data register A");
        __asm_lang_add_custom(_lang, _sp + "DATB", _sblk + 6, "Sprite " + string(_n) + " image data register B");
        _n += 1;
    }

    // Colour registers 00-31: $180 + n*2
    _n = 0;
    while (_n < 32) {
        var _cn = (_n < 10) ? "0" + string(_n) : string(_n);
        __asm_lang_add_custom(_lang, "COLOR" + _cn, $180 + _n * 2, "Colour register " + string(_n) + " ($0RGB)");
        _n += 1;
    }

    // CIA register offsets (add to CIAA or CIAB base).
    var _cia = [
        ["CIAPRA", $0000, "Peripheral data register A"],
        ["CIAPRB", $0100, "Peripheral data register B"],
        ["CIADDRA", $0200, "Data direction register A"],
        ["CIADDRB", $0300, "Data direction register B"],
        ["CIATALO", $0400, "Timer A low byte"],
        ["CIATAHI", $0500, "Timer A high byte"],
        ["CIATBLO", $0600, "Timer B low byte"],
        ["CIATBHI", $0700, "Timer B high byte"],
        ["CIATODLOW", $0800, "Event counter (TOD) bits 7-0"],
        ["CIATODMID", $0900, "Event counter (TOD) bits 15-8"],
        ["CIATODHI", $0A00, "Event counter (TOD) bits 23-16"],
        ["CIASDR", $0C00, "Serial data register"],
        ["CIAICR", $0D00, "Interrupt control register"],
        ["CIACRA", $0E00, "Control register A"],
        ["CIACRB", $0F00, "Control register B"]
    ];
    _i = 0;
    while (_i < array_length(_cia)) {
        var _ce = _cia[_i];
        __asm_lang_add_hw(_lang, _ce[0], _ce[1], __asm_hex(_ce[1], 4), "cia", "CIA offset +" + __asm_hex(_ce[1], 4) + "  " + _ce[2] + " (e.g. CIAA+" + _ce[0] + ")");
        _i += 1;
    }
    __asm_lang_add_hw(_lang, "CIAB_GAMEPORT1", 7, "7", "const", "CIAA PRA bit 7: /FIR1 - port 2 fire button (0 = pressed)");
    __asm_lang_add_hw(_lang, "CIAB_GAMEPORT0", 6, "6", "const", "CIAA PRA bit 6: /FIR0 - port 1 fire / left mouse button (0 = pressed)");
    __asm_lang_add_hw(_lang, "CIAB_LED", 1, "1", "const", "CIAA PRA bit 1: power LED / audio filter (1 = dim/off)");

    // exec.library LVOs (call with A6 = ExecBase, e.g. jsr _LVOForbid(a6)).
    var _exec = [
        ["Supervisor", -30], ["Disable", -120], ["Enable", -126], ["Forbid", -132], ["Permit", -138],
        ["SuperState", -150], ["UserState", -156], ["SetIntVector", -162], ["AddIntServer", -168],
        ["RemIntServer", -174], ["AllocMem", -198], ["AllocAbs", -204], ["FreeMem", -210], ["AvailMem", -216],
        ["FindTask", -294], ["SetTaskPri", -300], ["SetSignal", -306], ["Wait", -318], ["Signal", -324],
        ["AllocSignal", -330], ["FreeSignal", -336], ["PutMsg", -366], ["GetMsg", -372], ["ReplyMsg", -378],
        ["WaitPort", -384], ["FindPort", -390], ["OldOpenLibrary", -408], ["CloseLibrary", -414],
        ["SetFunction", -420], ["OpenDevice", -444], ["CloseDevice", -450], ["DoIO", -456], ["SendIO", -462],
        ["WaitIO", -474], ["AbortIO", -480], ["OpenResource", -498], ["RawDoFmt", -522], ["TypeOfMem", -534],
        ["OpenLibrary", -552], ["CopyMem", -624], ["CopyMemQuick", -630], ["CacheClearU", -636]
    ];
    _i = 0;
    while (_i < array_length(_exec)) {
        var _ee = _exec[_i];
        __asm_lang_add_hw(_lang, "_LVO" + _ee[0], _ee[1], string(_ee[1]), "lvo", "exec.library " + _ee[0] + "() offset " + string(_ee[1]) + " (A6 = ExecBase)");
        _i += 1;
    }

    // graphics.library LVOs (A6 = GfxBase).
    var _gfx = [
        ["LoadView", -222], ["WaitBlit", -228], ["WaitTOF", -270], ["OwnBlitter", -456], ["DisownBlitter", -462],
        ["LoadRGB4", -192], ["SetRGB4", -288], ["WaitBOVP", -402], ["VBeamPos", -384], ["InitBitMap", -390],
        ["BltClear", -300], ["BltBitMap", -30], ["QBlit", -276]
    ];
    _i = 0;
    while (_i < array_length(_gfx)) {
        var _ge = _gfx[_i];
        __asm_lang_add_hw(_lang, "_LVO" + _ge[0], _ge[1], string(_ge[1]), "lvo", "graphics.library " + _ge[0] + "() offset " + string(_ge[1]) + " (A6 = GfxBase)");
        _i += 1;
    }

    __asm_lang_add_hw(_lang, "AbsExecBase", 4, "4", "const", "Address holding the ExecBase pointer: move.l 4.w,a6");
    __asm_lang_add_hw(_lang, "gb_ActiView", 34, "34", "const", "GfxBase offset of the active View pointer");
    __asm_lang_add_hw(_lang, "gb_copinit", 38, "38", "const", "GfxBase offset of the system copper list (copinit)");

    __asm_lang_add_hw(_lang, "MEMF_ANY", 0, "0", "const", "AllocMem: any memory");
    __asm_lang_add_hw(_lang, "MEMF_PUBLIC", 1, "$1", "const", "AllocMem: public memory");
    __asm_lang_add_hw(_lang, "MEMF_CHIP", 2, "$2", "const", "AllocMem: chip RAM (reachable by DMA)");
    __asm_lang_add_hw(_lang, "MEMF_FAST", 4, "$4", "const", "AllocMem: fast RAM (CPU only)");
    __asm_lang_add_hw(_lang, "MEMF_CLEAR", $10000, "$10000", "const", "AllocMem: clear the block to zero");
    __asm_lang_add_hw(_lang, "MEMF_LARGEST", $20000, "$20000", "const", "AvailMem: largest free block");

    // DMACON bits (hardware/dmabits.i)
    var _dmaf = [
        ["DMAF_SETCLR", $8000, "Set (1) or clear (0) the other written bits"],
        ["DMAF_BLTDONE", $4000, "Blitter busy status (read)"],
        ["DMAF_BLTNZERO", $2000, "Blitter logic zero status (read)"],
        ["DMAF_BLITHOG", $0400, "Blitter has priority over the CPU"],
        ["DMAF_MASTER", $0200, "Master DMA enable"],
        ["DMAF_RASTER", $0100, "Bitplane DMA enable"],
        ["DMAF_COPPER", $0080, "Copper DMA enable"],
        ["DMAF_BLITTER", $0040, "Blitter DMA enable"],
        ["DMAF_SPRITE", $0020, "Sprite DMA enable"],
        ["DMAF_DISK", $0010, "Disk DMA enable"],
        ["DMAF_AUD3", $0008, "Audio channel 3 DMA enable"],
        ["DMAF_AUD2", $0004, "Audio channel 2 DMA enable"],
        ["DMAF_AUD1", $0002, "Audio channel 1 DMA enable"],
        ["DMAF_AUD0", $0001, "Audio channel 0 DMA enable"],
        ["DMAF_ALL", $01FF, "All DMA channels"]
    ];
    _i = 0;
    while (_i < array_length(_dmaf)) {
        var _de = _dmaf[_i];
        __asm_lang_add_hw(_lang, _de[0], _de[1], __asm_hex(_de[1], 4), "const", "DMACON bit " + __asm_hex(_de[1], 4) + "  " + _de[2]);
        _i += 1;
    }

    // INTENA / INTREQ bits (hardware/intbits.i)
    var _intf = [
        ["INTF_SETCLR", $8000, "Set (1) or clear (0) the other written bits"],
        ["INTF_INTEN", $4000, "Master interrupt enable"],
        ["INTF_EXTER", $2000, "CIA-B / external, level 6"],
        ["INTF_DSKSYNC", $1000, "Disk sync found, level 5"],
        ["INTF_RBF", $0800, "Serial receive buffer full, level 5"],
        ["INTF_AUD3", $0400, "Audio channel 3 block done, level 4"],
        ["INTF_AUD2", $0200, "Audio channel 2 block done, level 4"],
        ["INTF_AUD1", $0100, "Audio channel 1 block done, level 4"],
        ["INTF_AUD0", $0080, "Audio channel 0 block done, level 4"],
        ["INTF_BLIT", $0040, "Blitter finished, level 3"],
        ["INTF_VERTB", $0020, "Start of vertical blank, level 3"],
        ["INTF_COPER", $0010, "Copper interrupt, level 3"],
        ["INTF_PORTS", $0008, "CIA-A / I/O ports, level 2"],
        ["INTF_SOFTINT", $0004, "Software interrupt, level 1"],
        ["INTF_DSKBLK", $0002, "Disk block finished, level 1"],
        ["INTF_TBE", $0001, "Serial transmit buffer empty, level 1"]
    ];
    _i = 0;
    while (_i < array_length(_intf)) {
        var _ie = _intf[_i];
        __asm_lang_add_hw(_lang, _ie[0], _ie[1], __asm_hex(_ie[1], 4), "const", "INTENA/INTREQ bit " + __asm_hex(_ie[1], 4) + "  " + _ie[2]);
        _i += 1;
    }

    // Upper-cased lookup so "dmacon" can suggest "DMACON".
    _lang.hw_upper = {};
    _i = 0;
    while (_i < array_length(_lang.hw_order)) {
        var _hn = _lang.hw_order[_i];
        _lang.hw_upper[$ string_upper(_hn)] = _hn;
        _i += 1;
    }

    return _lang;
}

/// Adds any mnemonic present in global.opcode_map but not in the built-in
/// table, and adopts the opcode table's size list (plus .S for branches).
function __asm_lang_merge_opcode_map(_lang) {
    _lang.opmap_merged = true;
    var _keys = variable_struct_get_names(global.opcode_map);
    var _i = 0;

    while (_i < array_length(_keys)) {
        var _key = _keys[_i];
        _i += 1;

        if (string_pos("_", _key) > 0) continue;

        var _entry = global.opcode_map[$ _key];
        if (!is_struct(_entry)) continue;

        var _sizes = variable_struct_exists(_entry, "sizes") && is_array(_entry.sizes) ? _entry.sizes : [];
        var _ops = variable_struct_exists(_entry, "operand_count") ? _entry.operand_count : -1;
        var _upper = string_upper(_key);
        var _existing = _lang.mnemonics[$ _upper];

        if (_existing == undefined) {
            var _help = string_lower(_upper);
            var _family = scr_opcode_condition_family_key(_help);
            if (_family != "") _help = _family;
            __asm_lang_add_mn(_lang.mnemonics, _upper, _sizes, max(0, _ops), max(0, _ops), _help, false);
        } else if (array_length(_sizes) > 0) {
            var _merged = [];
            var _s = 0;
            while (_s < array_length(_sizes)) {
                array_push(_merged, string_upper(_sizes[_s]));
                _s += 1;
            }
            if (_existing.branch && !array_contains(_merged, "S")) array_push(_merged, "S");
            _existing.sizes = _merged;
        }
    }

    _lang.pool_mnemonic = undefined;

    // size lists may have changed: drop cached per-line results
    global.__asm_info_cache = { map : {}, count : 0 };
    global.__asm_val_cache = { map : {}, count : 0 };
    global.__asm_label_cache = { map : {}, count : 0 };
}

/// Returns the shared language tables, building them on first use.
function scr_asm_lang_data() {
    var _lang = global.__asm_lang;

    if (_lang == undefined) {
        _lang = __asm_lang_build();
        global.__asm_lang = _lang;
    }

    if (!_lang.opmap_merged && variable_global_exists("opcode_map") && is_struct(global.opcode_map)) {
        __asm_lang_merge_opcode_map(_lang);
    }

    return _lang;
}

/// True if _word (any case, no size suffix) is a mnemonic or directive.
function __asm_is_op_word(_lang, _word) {
    var _u = string_upper(_word);
    return variable_struct_exists(_lang.mnemonics, _u) || variable_struct_exists(_lang.directives, _u);
}

#endregion

#region tokenizer

function __asm_tok(_tokens, _kind, _line, _start, _end, _field) {
    var _t = { kind : _kind, text : string_copy(_line, _start + 1, _end - _start), start_col : _start, field : _field };
    array_push(_tokens, _t);
    return _t;
}

/// Scans a symbol starting at _p (first char already validated). Returns end index.
function __asm_scan_ident(_c, _p, _len) {
    var _q = _p + 1;
    while (_q < _len && __asm_cc_ident(_c[_q])) _q += 1;
    return _q;
}

/// Decides whether a column-1 word is really an instruction/directive (vasm
/// would read it as a label; the emitter indents it). A column-1 known word is
/// treated as a label when the next word is itself an operation (e.g.
/// "data dc.b 1" or "end equ 3") or an assignment.
function __asm_col1_word_is_op(_lang, _line, _c, _len, _w_end, _word) {
    if (!__asm_is_op_word(_lang, _word)) return false;

    var _q = _w_end;

    if (_q < _len && _c[_q] == 46) {
        _q += 1;
        while (_q < _len && __asm_cc_ident(_c[_q])) _q += 1;
    }

    if (_q < _len && !__asm_cc_space(_c[_q]) && _c[_q] != 59) return false;

    while (_q < _len && __asm_cc_space(_c[_q])) _q += 1;

    if (_q >= _len || _c[_q] == 59) return true;
    if (_c[_q] == 61) return false;

    var _r = _q;
    while (_r < _len && !__asm_cc_space(_c[_r]) && _c[_r] != 59) _r += 1;

    var _next = string_copy(_line, _q + 1, _r - _q);
    var _dot = string_pos(".", _next);
    var _base = (_dot > 1) ? string_copy(_next, 1, _dot - 1) : _next;

    if (__asm_is_plain_word(_next) && __asm_is_op_word(_lang, _base)) return false;

    return true;
}

function __asm_tokenize_uncached(_line, _len) {
    var _lang = scr_asm_lang_data();
    var _c = array_create(_len, 0);
    var _k = 0;

    if (string_byte_length(_line) == _len) {
        // pure ASCII: byte access is O(1)
        while (_k < _len) {
            _c[_k] = string_byte_at(_line, _k + 1);
            _k += 1;
        }
    } else {
        while (_k < _len) {
            _c[_k] = ord(string_char_at(_line, _k + 1));
            _k += 1;
        }
    }

    var _t = [];

    // '*' or ';' in column 1: whole-line comment.
    if (_c[0] == 42 || _c[0] == 59) {
        __asm_tok(_t, "comment", _line, 0, _len, "comment");
        return _t;
    }

    var _p = 0;
    var _state = 0;          // 0 = expecting operation, 1 = operand field
    var _depth = 0;
    var _prev_sig = -1;      // last significant char code in the operand field
    var _prev_value = false; // last operand token was a value (for % @ . disambiguation)
    var _no_operands = false;
    var _blank_comment = global.asm_lang_blank_starts_comment;

    // --- label field (column 1) ---
    if (!__asm_cc_space(_c[0])) {
        var _c0 = _c[0];

        if (__asm_cc_alpha(_c0) || _c0 == 46 || __asm_cc_digit(_c0) || _c0 == 92) {
            var _w_end = __asm_scan_ident(_c, 0, _len);
            var _word = string_copy(_line, 1, _w_end);
            var _colon_end = _w_end;

            while (_colon_end < _len && _c[_colon_end] == 58) _colon_end += 1;

            var _is_op = false;

            if (_colon_end == _w_end && !__asm_cc_digit(_c0) && _c0 != 46) {
                _is_op = __asm_col1_word_is_op(_lang, _line, _c, _len, _w_end, _word);
            }

            if (!_is_op) {
                __asm_tok(_t, "label", _line, 0, _colon_end, "label");
                _p = _colon_end;
            }
        } else {
            // Not a valid label start: mark and treat the rest as operation/operands.
            __asm_tok(_t, "unknown", _line, 0, 1, "label");
            _p = 1;
        }
    }

    while (_p < _len) {
        var _ch = _c[_p];

        // --- whitespace ---
        if (__asm_cc_space(_ch)) {
            var _q = _p;
            while (_q < _len && __asm_cc_space(_c[_q])) _q += 1;

            var _ends_field = false;

            if (_state == 1 && _q < _len && _c[_q] != 59) {
                if (_no_operands) {
                    _ends_field = true;
                } else if (_blank_comment && _depth == 0 && _prev_sig != -1 && _prev_sig != 44) {
                    _ends_field = true;
                }
            }

            __asm_tok(_t, "whitespace", _line, _p, _q, (_state == 0) ? "op" : "operand");
            _p = _q;

            if (_ends_field) {
                __asm_tok(_t, "comment", _line, _p, _len, "comment");
                _p = _len;
            }
            continue;
        }

        // --- comment ---
        if (_ch == 59) {
            __asm_tok(_t, "comment", _line, _p, _len, "comment");
            break;
        }

        // --- operation field ---
        if (_state == 0) {
            if (_ch == 61) {
                __asm_tok(_t, "directive", _line, _p, _p + 1, "op");
                _p += 1;
                _state = 1;
                continue;
            }

            if (__asm_cc_alpha(_ch) || _ch == 46 || _ch == 92) {
                var _o_end = __asm_scan_ident(_c, _p, _len);

                // Indented "name:" is a label too.
                if (_o_end < _len && _c[_o_end] == 58) {
                    var _lc_end = _o_end;
                    while (_lc_end < _len && _c[_lc_end] == 58) _lc_end += 1;
                    __asm_tok(_t, "label", _line, _p, _lc_end, "label");
                    _p = _lc_end;
                    continue;
                }

                var _op_word = string_copy(_line, _p + 1, _o_end - _p);
                var _op_upper = string_upper(_op_word);
                var _op_kind = "unknown";
                var _mn = _lang.mnemonics[$ _op_upper];

                if (_mn != undefined) {
                    _op_kind = "mnemonic";
                    _no_operands = (_mn.max_ops == 0);
                } else {
                    var _dir = _lang.directives[$ _op_upper];
                    if (_dir != undefined) {
                        _op_kind = "directive";
                        _no_operands = (_dir.max_ops == 0);
                    }
                }

                __asm_tok(_t, _op_kind, _line, _p, _o_end, "op");
                _p = _o_end;

                if (_p < _len && _c[_p] == 46) {
                    var _s_end = _p + 1;
                    while (_s_end < _len && __asm_cc_ident(_c[_s_end])) _s_end += 1;
                    __asm_tok(_t, "size", _line, _p, _s_end, "op");
                    _p = _s_end;
                }

                _state = 1;
                continue;
            }

            // Anything else: fall into operand scanning.
            _state = 1;
            continue;
        }

        // --- operand field ---
        if (_ch == 35) {
            __asm_tok(_t, "immediate_prefix", _line, _p, _p + 1, "operand");
            _p += 1;
            _prev_sig = _ch;
            _prev_value = false;
            continue;
        }

        if (_ch == 34 || _ch == 39) {
            var _sq = _p + 1;
            var _closed = false;

            while (_sq < _len) {
                if (_c[_sq] == _ch) {
                    if (_sq + 1 < _len && _c[_sq + 1] == _ch) {
                        _sq += 2;
                        continue;
                    }
                    _sq += 1;
                    _closed = true;
                    break;
                }
                _sq += 1;
            }

            var _st = __asm_tok(_t, "string", _line, _p, _sq, "operand");
            _st.closed = _closed;
            _p = _sq;
            _prev_sig = _ch;
            _prev_value = true;
            continue;
        }

        if (_ch == 36) {
            var _hq = _p + 1;
            while (_hq < _len && __asm_cc_hex(_c[_hq])) _hq += 1;

            if (_hq > _p + 1) {
                __asm_tok(_t, "number", _line, _p, _hq, "operand");
                _p = _hq;
                _prev_value = true;
            } else {
                __asm_tok(_t, "unknown", _line, _p, _p + 1, "operand");
                _p += 1;
                _prev_value = false;
            }
            _prev_sig = _ch;
            continue;
        }

        if ((_ch == 37 || _ch == 64) && !_prev_value) {
            var _bq = _p + 1;
            if (_ch == 37) {
                while (_bq < _len && (_c[_bq] == 48 || _c[_bq] == 49)) _bq += 1;
            } else {
                while (_bq < _len && _c[_bq] >= 48 && _c[_bq] <= 55) _bq += 1;
            }

            if (_bq > _p + 1) {
                __asm_tok(_t, "number", _line, _p, _bq, "operand");
                _p = _bq;
                _prev_sig = _ch;
                _prev_value = true;
                continue;
            }
        }

        if (__asm_cc_digit(_ch)) {
            var _dq = _p;
            while (_dq < _len && __asm_cc_digit(_c[_dq])) _dq += 1;

            if (_dq < _len && _c[_dq] == 36) {
                _dq += 1;
                __asm_tok(_t, "symbol", _line, _p, _dq, "operand");
            } else {
                __asm_tok(_t, "number", _line, _p, _dq, "operand");
            }
            _p = _dq;
            _prev_sig = _ch;
            _prev_value = true;
            continue;
        }

        // ".w" style size after a value: ($1234).w, d0.w, label.l
        if (_ch == 46 && _prev_value && _p + 1 < _len && __asm_is_size_letter(_c[_p + 1])
            && (_p + 2 >= _len || !__asm_cc_ident(_c[_p + 2]))) {
            __asm_tok(_t, "size", _line, _p, _p + 2, "operand");
            _p += 2;
            _prev_sig = _ch;
            _prev_value = true;
            continue;
        }

        if (__asm_cc_alpha(_ch) || _ch == 46 || _ch == 92) {
            var _iq = __asm_scan_ident(_c, _p, _len);
            var _word2 = string_copy(_line, _p + 1, _iq - _p);
            var _kind2 = "symbol";

            if (variable_struct_exists(_lang.registers, string_lower(_word2))) {
                _kind2 = "register";
            } else if (variable_struct_exists(_lang.hw, _word2)) {
                _kind2 = "hwreg";
            }

            __asm_tok(_t, _kind2, _line, _p, _iq, "operand");
            _p = _iq;
            _prev_sig = _ch;
            _prev_value = true;
            continue;
        }

        // operators and punctuation
        if (_ch == 44 || _ch == 40 || _ch == 41 || _ch == 43 || _ch == 45 || _ch == 42 || _ch == 47
            || _ch == 38 || _ch == 124 || _ch == 94 || _ch == 126 || _ch == 33 || _ch == 60 || _ch == 62
            || _ch == 61 || _ch == 37 || _ch == 64 || _ch == 58) {
            __asm_tok(_t, "operator", _line, _p, _p + 1, "operand");
            if (_ch == 40) _depth += 1;
            if (_ch == 41) _depth -= 1;
            _prev_sig = _ch;
            // ')' and '*' (current PC) behave like values for a following .size
            _prev_value = (_ch == 41) || (_ch == 42 && !_prev_value);
            _p += 1;
            continue;
        }

        __asm_tok(_t, "unknown", _line, _p, _p + 1, "operand");
        _prev_sig = _ch;
        _prev_value = false;
        _p += 1;
    }

    return _t;
}

/// Tokenises one source line. Returns a cached, read-only array of
/// {kind, text, start_col, field}. kind is one of label, mnemonic, size,
/// directive, register, number, immediate_prefix, symbol, hwreg, string,
/// operator, comment, whitespace, unknown. field is label/op/operand/comment.
/// String tokens also carry .closed (false when the quote is unterminated).
function scr_asm_tokenize_line(_line) {
    if (!is_string(_line)) _line = string(_line);

    var _len = string_length(_line);
    if (_len == 0) return [];

    var _cache = global.__asm_tok_cache;
    var _hit = _cache.map[$ _line];
    if (_hit != undefined) return _hit;

    var _tokens;
    try {
        _tokens = __asm_tokenize_uncached(_line, _len);
    } catch (_err) {
        _tokens = [{ kind : "unknown", text : _line, start_col : 0, field : "operand" }];
    }

    if (_cache.count > 12000) {
        _cache.map = {};
        _cache.count = 0;
    }

    _cache.map[$ _line] = _tokens;
    _cache.count += 1;
    return _tokens;
}

#endregion

#region analysis / validation

function __asm_split_lines(_text) {
    if (!is_string(_text)) _text = string(_text);
    _text = string_replace_all(_text, "\r\n", "\n");
    _text = string_replace_all(_text, "\r", "\n");
    return string_split(_text, "\n");
}

function __asm_symbol_set(_names) {
    var _set = {};
    if (!is_array(_names)) return _set;
    var _i = 0;
    while (_i < array_length(_names)) {
        var _nm = _names[_i];
        if (is_string(_nm) && _nm != "") _set[$ _nm] = true;
        _i += 1;
    }
    return _set;
}

function __asm_ext_key(_names) {
    if (!is_array(_names)) return "";
    var _n = array_length(_names);
    if (_n == 0) return "";
    var _key = string(_n);
    var _i = 0;
    while (_i < _n) {
        _key += "," + string(_names[_i]);
        _i += 1;
    }
    return _key;
}

function __asm_strip_colons(_s) {
    while (string_length(_s) > 0 && string_char_at(_s, string_length(_s)) == ":") {
        _s = string_copy(_s, 1, string_length(_s) - 1);
    }
    return _s;
}

function __asm_is_local_name(_s) {
    return string_length(_s) > 0 && (string_char_at(_s, 1) == "." || string_char_at(_s, string_length(_s)) == "$");
}

function __asm_diag(_list, _line, _col, _len, _message, _severity) {
    array_push(_list, { line : _line, col : _col, len : max(1, _len), message : _message, severity : _severity });
}

/// Finds the label token, op token and size token of a token array.
function __asm_line_parts(_tk) {
    var _parts = { label : undefined, op : undefined, size : undefined };
    var _i = 0;
    var _n = array_length(_tk);
    while (_i < _n) {
        var _t = _tk[_i];
        if (_t.field == "label" && _t.kind == "label" && _parts.label == undefined) {
            _parts.label = _t;
        } else if (_t.field == "op" && _t.kind != "whitespace") {
            if (_t.kind == "size") {
                if (_parts.size == undefined) _parts.size = _t;
            } else if (_parts.op == undefined) {
                _parts.op = _t;
            }
        }
        _i += 1;
    }
    return _parts;
}

function __asm_is_cond_open(_u) {
    return _u == "IF" || _u == "IFD" || _u == "IFND" || _u == "IFEQ" || _u == "IFNE" || _u == "IFGT"
        || _u == "IFGE" || _u == "IFLT" || _u == "IFLE" || _u == "IFC" || _u == "IFNC" || _u == "IFB" || _u == "IFNB";
}

function __asm_info_diag(_list, _col, _len, _message, _severity) {
    array_push(_list, { col : _col, len : max(1, _len), message : _message, severity : _severity });
}

/// Context-free facts about one line, cached by the line string:
/// label/op/size, operand symbols and every diagnostic that does not depend
/// on other lines (strings, parentheses, sizes, operand counts, column 1).
function __asm_compute_line_info(_line) {
    var _lang = scr_asm_lang_data();
    var _tk = scr_asm_tokenize_line(_line);
    var _pt = __asm_line_parts(_tk);
    var _tn = array_length(_tk);
    var _info = {
        label : "",
        label_col : 0,
        op_u : "",
        op_text : "",
        op_kind : "",
        op_col : 0,
        first_operand : "",
        syms : [],
        check_syms : true,
        diags : []
    };

    if (_pt.label != undefined) {
        _info.label = __asm_strip_colons(_pt.label.text);
        _info.label_col = _pt.label.start_col;
    }

    var _op = _pt.op;
    if (_op != undefined) {
        _info.op_u = string_upper(_op.text);
        _info.op_text = _op.text;
        _info.op_kind = _op.kind;
        _info.op_col = _op.start_col;
    }

    var _diags = _info.diags;
    var _depth = 0;
    var _paren_reported = false;
    var _first_open_col = -1;
    var _commas = 0;
    var _seen_operand = false;
    var _k = 0;

    while (_k < _tn) {
        var _t = _tk[_k];
        _k += 1;

        if (_t.field != "operand" || _t.kind == "whitespace") continue;

        _seen_operand = true;

        if (_t.kind == "string") {
            if (variable_struct_exists(_t, "closed") && !_t.closed) {
                __asm_info_diag(_diags, _t.start_col, string_length(_t.text), "Unterminated string (missing closing quote)", "error");
            }
        } else if (_t.kind == "operator") {
            var _ot = _t.text;
            if (_ot == "(") {
                if (_depth == 0) _first_open_col = _t.start_col;
                _depth += 1;
            } else if (_ot == ")") {
                _depth -= 1;
                if (_depth < 0) {
                    if (!_paren_reported) {
                        __asm_info_diag(_diags, _t.start_col, 1, "Unbalanced ')' (no matching '(')", "error");
                        _paren_reported = true;
                    }
                    _depth = 0;
                }
            } else if (_ot == "," && _depth == 0) {
                _commas += 1;
            }
        } else if (_t.kind == "symbol" || _t.kind == "hwreg") {
            if (_info.first_operand == "") _info.first_operand = _t.text;
            if (_t.kind == "symbol" && string_pos("\\", _t.text) == 0) {
                array_push(_info.syms, _t);
            }
        }
    }

    if (_depth > 0) {
        __asm_info_diag(_diags, _first_open_col, 1, "Missing ')' - unbalanced parentheses", "error");
    }

    if (_op == undefined) return _info;

    var _op_u = _info.op_u;

    if (_op.start_col == 0 && (_op.kind == "mnemonic" || _op.kind == "directive") && _op.text != "=") {
        __asm_info_diag(_diags, 0, string_length(_op.text),
            "'" + _op.text + "' in column 1 will be auto-indented (vasm reads column-1 words as labels)", "warning");
    }

    if (_op.kind == "mnemonic") {
        var _mn = _lang.mnemonics[$ _op_u];
        if (_mn == undefined) _mn = { sizes : [], min_ops : 0, max_ops : 99 };

        if (_pt.size != undefined) {
            var _sz = string_upper(string_delete(_pt.size.text, 1, 1));
            if (array_length(_mn.sizes) == 0) {
                __asm_info_diag(_diags, _pt.size.start_col, string_length(_pt.size.text), _op_u + " does not take a size suffix", "error");
            } else if (!array_contains(_mn.sizes, _sz)) {
                __asm_info_diag(_diags, _pt.size.start_col, string_length(_pt.size.text),
                    "Invalid size '." + _sz + "' for " + _op_u + " (allowed: ." + string_join_ext(" .", _mn.sizes) + ")", "error");
            }
        }

        var _count = _seen_operand ? _commas + 1 : 0;
        if (_count < _mn.min_ops || _count > _mn.max_ops) {
            var _expect = (_mn.min_ops == _mn.max_ops) ? string(_mn.min_ops) : string(_mn.min_ops) + "-" + string(_mn.max_ops);
            __asm_info_diag(_diags, _op.start_col, string_length(_op.text),
                _op_u + " expects " + _expect + " operand" + ((_mn.max_ops == 1) ? "" : "s") + ", found " + string(_count), "error");
        }
    } else if (_op.kind == "directive") {
        var _dir = _lang.directives[$ _op_u];
        if (_dir == undefined) _dir = { sizes : [], check_syms : false };

        if (_pt.size != undefined) {
            var _dsz = string_upper(string_delete(_pt.size.text, 1, 1));
            if (array_length(_dir.sizes) == 0) {
                __asm_info_diag(_diags, _pt.size.start_col, string_length(_pt.size.text), _op_u + " does not take a size suffix", "error");
            } else if (!array_contains(_dir.sizes, _dsz)) {
                __asm_info_diag(_diags, _pt.size.start_col, string_length(_pt.size.text),
                    "Invalid size '." + _dsz + "' for " + _op_u + " (allowed: ." + string_join_ext(" .", _dir.sizes) + ")", "error");
            }
        }

        if (!_dir.check_syms) _info.check_syms = false;

        if ((_op_u == "EQU" || _op_u == "SET" || _op_u == "=") && _pt.label == undefined) {
            __asm_info_diag(_diags, _op.start_col, string_length(_op.text), _op_u + " needs a symbol name in column 1", "error");
        }
    } else {
        // unknown operation (macro call?) - arguments are not checked
        _info.check_syms = false;
    }

    return _info;
}

global.__asm_info_empty = {
    label : "", label_col : 0, op_u : "", op_text : "", op_kind : "", op_col : 0,
    first_operand : "", syms : [], check_syms : false, diags : []
};
global.__asm_info_cache = { map : {}, count : 0 };

function __asm_line_info(_line) {
    if (_line == "") return global.__asm_info_empty;
    var _cache = global.__asm_info_cache;
    var _hit = _cache.map[$ _line];
    if (_hit != undefined) return _hit;

    var _info;
    try {
        _info = __asm_compute_line_info(_line);
    } catch (_err) {
        _info = global.__asm_info_empty;
    }

    if (_cache.count > 12000) {
        _cache.map = {};
        _cache.count = 0;
    }
    _cache.map[$ _line] = _info;
    _cache.count += 1;
    return _info;
}

function __asm_analyse_into(_lines, _external_symbols, _res) {
    var _lang = scr_asm_lang_data();
    var _n = array_length(_lines);
    var _infos = array_create(_n);
    var _ext = __asm_symbol_set(_external_symbols);
    var _diags = _res.diagnostics;
    var _labels = _res.labels;
    var _locals = _res.locals;
    var _macros = _res.macros;
    var _defined = _res.defined;
    var _hw = _lang.hw;

    // ---------- pass 1: definitions ----------
    var _scope = "";
    var _in_macro = 0;
    var _cond = 0;
    var _local_defs = {};
    var _i = 0;

    while (_i < _n) {
        var _line = _lines[_i];
        if (!is_string(_line)) _line = string(_line);

        var _info = __asm_line_info(_line);
        _infos[_i] = _info;
        var _op_up = _info.op_u;

        if (_op_up == "MACRO") {
            var _mname = (_info.label != "") ? _info.label : _info.first_operand;
            if (_mname != "" && _in_macro == 0) {
                if (variable_struct_exists(_macros, _mname)) {
                    __asm_diag(_diags, _i, 0, string_length(_mname), "Duplicate macro '" + _mname + "'", "error");
                } else {
                    _macros[$ _mname] = _i;
                    _defined[$ _mname] = true;
                    array_push(_res.label_names, _mname);
                }
            }
            _in_macro += 1;
            _i += 1;
            continue;
        }

        if (_op_up == "ENDM") {
            _in_macro = max(0, _in_macro - 1);
            _i += 1;
            continue;
        }

        if (_in_macro > 0) {
            _i += 1;
            continue;
        }

        if (_op_up == "ENDIF" || _op_up == "ENDC") {
            _cond = max(0, _cond - 1);
        }

        var _name = _info.label;

        if (_name != "" && string_pos("\\", _name) == 0) {
            if (__asm_is_local_name(_name)) {
                var _lkey = _scope + "|" + _name;
                if (variable_struct_exists(_local_defs, _lkey)) {
                    if (_cond == 0) {
                        __asm_diag(_diags, _i, _info.label_col, string_length(_name),
                            "Duplicate local label '" + _name + "' (first defined on line " + string(_local_defs[$ _lkey] + 1) + ")", "error");
                    }
                } else {
                    _local_defs[$ _lkey] = _i;
                }
                if (!variable_struct_exists(_locals, _name)) _locals[$ _name] = _i;
            } else {
                if (variable_struct_exists(_hw, _name)) {
                    __asm_diag(_diags, _i, _info.label_col, string_length(_name),
                        "'" + _name + "' is already a predefined hardware equate", "error");
                } else if (variable_struct_exists(_labels, _name)) {
                    if (_op_up != "SET" && _cond == 0) {
                        __asm_diag(_diags, _i, _info.label_col, string_length(_name),
                            "Duplicate label '" + _name + "' (first defined on line " + string(_labels[$ _name] + 1) + ")", "error");
                    }
                } else {
                    _labels[$ _name] = _i;
                    array_push(_res.label_names, _name);
                }
                _defined[$ _name] = true;

                if (_op_up != "EQU" && _op_up != "SET" && _op_up != "=" && _op_up != "EQUR" && _op_up != "REG"
                    && _op_up != "RS" && _op_up != "SO" && _op_up != "FO") {
                    _scope = _name;
                }
            }
        }

        if (_op_up != "" && __asm_is_cond_open(_op_up)) {
            _cond += 1;
        }

        if (_op_up == "XREF" || _op_up == "PUBLIC" || _op_up == "GLOBAL") {
            var _xs = _info.syms;
            var _xk = 0;
            while (_xk < array_length(_xs)) {
                _defined[$ _xs[_xk].text] = true;
                _xk += 1;
            }
        }

        _i += 1;
    }

    // ---------- pass 2: per-line checks ----------
    var _builtins = _lang.builtin_symbols;
    var _hw_upper = _lang.hw_upper;
    _in_macro = 0;
    _i = 0;

    while (_i < _n) {
        var _inf = _infos[_i];

        var _ld = _inf.diags;
        var _dk = 0;
        while (_dk < array_length(_ld)) {
            var _src = _ld[_dk];
            array_push(_diags, { line : _i, col : _src.col, len : _src.len, message : _src.message, severity : _src.severity });
            _dk += 1;
        }

        var _op_u = _inf.op_u;

        if (_op_u == "MACRO") {
            _in_macro += 1;
            _i += 1;
            continue;
        }

        if (_op_u == "ENDM") {
            _in_macro = max(0, _in_macro - 1);
            _i += 1;
            continue;
        }

        if (_inf.op_kind == "unknown") {
            var _word = _inf.op_text;
            if (string_pos("\\", _word) == 0 && !variable_struct_exists(_macros, _word) && !variable_struct_exists(_ext, _word)) {
                __asm_diag(_diags, _i, _inf.op_col, string_length(_word), "Unknown mnemonic or directive '" + _word + "'", "error");
            }
        }

        if (_in_macro == 0 && _inf.check_syms) {
            var _syms = _inf.syms;
            var _k = 0;
            while (_k < array_length(_syms)) {
                var _st = _syms[_k];
                var _sym = _st.text;
                _k += 1;

                if (variable_struct_exists(_defined, _sym) || variable_struct_exists(_locals, _sym)
                    || variable_struct_exists(_ext, _sym) || variable_struct_exists(_builtins, _sym)) continue;

                var _hint = _hw_upper[$ string_upper(_sym)];
                if (_hint != undefined) {
                    __asm_diag(_diags, _i, _st.start_col, string_length(_sym),
                        "Undefined symbol '" + _sym + "' (symbols are case-sensitive - did you mean '" + _hint + "'?)", "error");
                } else {
                    __asm_diag(_diags, _i, _st.start_col, string_length(_sym), "Undefined symbol '" + _sym + "'", "error");
                }
            }
        }

        _i += 1;
    }

    array_sort(_diags, function(_a, _b) {
        if (_a.line != _b.line) return _a.line - _b.line;
        return _a.col - _b.col;
    });
}

/// Full analysis of an array of line strings. Never throws.
/// Returns {diagnostics, labels (name->line), locals (name->first line),
/// macros (name->line), label_names (array, definition order), defined (set)}.
function scr_asm_analyse_lines(_lines, _external_symbols = []) {
    var _res = { diagnostics : [], labels : {}, locals : {}, macros : {}, label_names : [], defined : {} };

    try {
        if (is_array(_lines)) __asm_analyse_into(_lines, _external_symbols, _res);
    } catch (_err) {
        show_debug_message("scr_asm_analyse_lines failed: " + string(_err));
    }

    return _res;
}

/// Validates vasm source text. Returns [{line, col, len, message, severity}]
/// (0-based line/col, severity "error"/"warning"). Cached by text +
/// external symbol list; never throws.
function scr_asm_validate(_text, _external_symbols = []) {
    try {
        if (!is_string(_text)) _text = string(_text);

        var _key = __asm_ext_key(_external_symbols) + chr(1) + _text;
        var _cache = global.__asm_val_cache;
        var _hit = _cache.map[$ _key];
        if (_hit != undefined) return _hit;

        var _res = scr_asm_analyse_lines(__asm_split_lines(_text), _external_symbols);

        if (_cache.count > 48) {
            _cache.map = {};
            _cache.count = 0;
        }
        _cache.map[$ _key] = _res.diagnostics;
        _cache.count += 1;
        return _res.diagnostics;
    } catch (_err) {
        show_debug_message("scr_asm_validate failed: " + string(_err));
        return [];
    }
}

/// Returns the non-local labels, EQU/SET names and macro names defined in _text.
function scr_asm_collect_labels(_text) {
    try {
        if (!is_string(_text)) _text = string(_text);
        var _cache = global.__asm_label_cache;
        var _hit = _cache.map[$ _text];
        if (_hit != undefined) return _hit;

        var _res = scr_asm_analyse_lines(__asm_split_lines(_text), []);
        var _names = _res.label_names;

        if (_cache.count > 64) {
            _cache.map = {};
            _cache.count = 0;
        }
        _cache.map[$ _text] = _names;
        _cache.count += 1;
        return _names;
    } catch (_err) {
        return [];
    }
}

/// Text ready for vasm: CR/CRLF -> LF, and any line whose column-1 word is a
/// known mnemonic/directive (not a "label:") gets a leading tab.
function scr_asm_normalise_for_emit(_text) {
    try {
        var _lines = __asm_split_lines(_text);
        var _i = 0;
        var _n = array_length(_lines);

        while (_i < _n) {
            var _line = _lines[_i];
            if (string_length(_line) > 0) {
                var _tk = scr_asm_tokenize_line(_line);
                var _k = 0;
                while (_k < array_length(_tk)) {
                    var _t = _tk[_k];
                    if (_t.kind != "whitespace") {
                        if (_t.field == "op" && _t.start_col == 0 && (_t.kind == "mnemonic" || _t.kind == "directive") && _t.text != "=") {
                            _lines[_i] = "\t" + _line;
                        }
                        break;
                    }
                    _k += 1;
                }
            }
            _i += 1;
        }

        return string_join_ext("\n", _lines);
    } catch (_err) {
        return is_string(_text) ? _text : "";
    }
}

/// vasm source defining every hardware/system name as an equate.
/// Custom chip names are OFFSETS from CUSTOM ($dff000): move.w #$7fff,DMACON(a6).
function scr_asm_hardware_equates_text() {
    var _lang = scr_asm_lang_data();
    var _out = "; ---- ADM hardware equates (custom offsets from CUSTOM=$dff000) ----\n";
    var _i = 0;
    var _n = array_length(_lang.hw_order);

    while (_i < _n) {
        var _h = _lang.hw[$ _lang.hw_order[_i]];
        _out += _h.name + "\tequ\t" + _h.equ_text + "\n";
        _i += 1;
    }

    _out += "; ---- end of hardware equates ----\n";
    return _out;
}

#endregion

#region global symbols / completion / help

/// Names usable from any CODE block: node labels plus labels of every CODE
/// node (except _exclude_node, normally the block being edited). Cached per frame.
function scr_asm_global_symbols(_exclude_node = noone) {
    var _cache = global.__asm_gs_cache;
    if (_cache.time == current_time && _cache.exclude == _exclude_node) return _cache.result;

    var _out = [];
    var _seen = {};

    try {
        with (obj_opcode_node) {
            if (variable_instance_exists(id, "node_label") && is_string(node_label) && node_label != "") {
                if (!variable_struct_exists(_seen, node_label)) {
                    _seen[$ node_label] = true;
                    array_push(_out, node_label);
                }
            }

            if (id != _exclude_node && variable_instance_exists(id, "is_macro") && is_macro
                && variable_instance_exists(id, "macro_type") && macro_type == "CODE"
                && variable_instance_exists(id, "macro_code_text")) {
                var _labels = scr_asm_collect_labels(macro_code_text);
                var _j = 0;
                while (_j < array_length(_labels)) {
                    var _lb = _labels[_j];
                    if (!variable_struct_exists(_seen, _lb)) {
                        _seen[$ _lb] = true;
                        array_push(_out, _lb);
                    }
                    _j += 1;
                }
            }
        }
        // Every SPR-EDIT sprite can be used by name (scr_amiga_code_sprites_text).
        var _a = 0;
        while (_a < array_length(global.asset_list)) {
            if (global.asset_list[_a].type == "SPRITE") {
                var _sl = "spr_" + scr_amiga_label_safe(global.asset_list[_a].name);
                if (!variable_struct_exists(_seen, _sl)) {
                    _seen[$ _sl] = true;
                    array_push(_out, _sl, _sl + "_h", _sl + "_colours");
                }
            }
            _a += 1;
        }
    } catch (_err) {
        show_debug_message("scr_asm_global_symbols failed: " + string(_err));
    }

    _cache.time = current_time;
    _cache.exclude = _exclude_node;
    _cache.result = _out;
    return _out;
}

/// One-line help for a mnemonic (opcode table), register, hardware name or directive.
function scr_asm_symbol_help(_word) {
    if (!is_string(_word) || _word == "") return "";
    var _lang = scr_asm_lang_data();
    var _u = string_upper(_word);

    var _mn = _lang.mnemonics[$ _u];
    if (_mn != undefined) return __asm_mnemonic_detail(_mn, true);

    var _dir = _lang.directives[$ _u];
    if (_dir != undefined) return _u + " - " + _dir.detail;

    var _reg = _lang.registers[$ string_lower(_word)];
    if (_reg != undefined) return _u + " - " + _reg;

    var _hw = _lang.hw[$ _word];
    if (_hw != undefined) return _hw.name + " = " + _hw.equ_text + "  " + _hw.desc;

    return "";
}

function __asm_mnemonic_detail(_mn, _long) {
    if (_mn.detail == undefined) {
        var _info = undefined;
        try {
            _info = scr_opcode_lookup(_mn.help_key);
        } catch (_err) {
            _info = undefined;
        }

        var _sizes = (array_length(_mn.sizes) > 0) ? " ." + string_join_ext("/.", _mn.sizes) : "";
        if (is_struct(_info)) {
            _mn.detail = {
                short : string(_info.format),
                long : string(_info.format) + "  -  " + string(_info.use) + "  (~" + string(_info.cycles) + " cycles, " + string(_info.bytes) + "+ bytes)"
            };
        } else {
            _mn.detail = { short : _mn.name + _sizes, long : _mn.name + _sizes };
        }
    }
    return _long ? _mn.detail.long : _mn.detail.short;
}

function __asm_completion_pools(_lang) {
    if (_lang.pool_mnemonic == undefined) {
        var _pm = [];
        var _names = variable_struct_get_names(_lang.mnemonics);
        var _i = 0;
        while (_i < array_length(_names)) {
            array_push(_pm, { text : _names[_i], kind : "mnemonic", src : _lang.mnemonics[$ _names[_i]] });
            _i += 1;
        }
        _names = variable_struct_get_names(_lang.directives);
        _i = 0;
        while (_i < array_length(_names)) {
            if (_names[_i] != "=") {
                array_push(_pm, { text : _names[_i], kind : "directive", src : _lang.directives[$ _names[_i]] });
            }
            _i += 1;
        }
        _lang.pool_mnemonic = _pm;
    }

    if (_lang.pool_operand == undefined) {
        var _po = [];
        var _regs = ["D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "SP", "PC", "SR", "CCR", "USP"];
        var _r = 0;
        while (_r < array_length(_regs)) {
            array_push(_po, { text : _regs[_r], kind : "register", src : _lang.registers[$ string_lower(_regs[_r])] });
            _r += 1;
        }
        var _h = 0;
        while (_h < array_length(_lang.hw_order)) {
            var _hw = _lang.hw[$ _lang.hw_order[_h]];
            array_push(_po, { text : _hw.name, kind : (_hw.kind == "lvo") ? "lvo" : ((_hw.kind == "const") ? "const" : "hwreg"), src : _hw });
            _h += 1;
        }
        _lang.pool_operand = _po;
    }
}

function __asm_completion_detail(_item) {
    switch (_item.kind) {
        case "mnemonic": return __asm_mnemonic_detail(_item.src, false);
        case "directive": return _item.src.detail;
        case "register": return _item.src;
        case "hwreg":
        case "lvo":
        case "const": return _item.src.equ_text + "  " + _item.src.desc;
        default: return is_string(_item.src) ? _item.src : "";
    }
}

/// Ranked completion candidates.
///   _context "mnemonic": mnemonics + directives
///   _context "size":     valid sizes for _mnemonic
///   _context "operand":  registers, _local_names, _global_symbols, hardware names, LVOs, constants
/// Prefix matches rank before substring matches (case-insensitive); text keeps canonical case.
function scr_asm_completions(_prefix, _context, _mnemonic = "", _local_names = undefined, _global_symbols = undefined) {
    var _out = [];

    try {
        var _lang = scr_asm_lang_data();
        __asm_completion_pools(_lang);
        if (!is_string(_prefix)) _prefix = "";
        var _pu = string_upper(_prefix);
        var _plen = string_length(_pu);

        if (_context == "size") {
            var _mu = string_upper(_mnemonic);
            var _src = _lang.mnemonics[$ _mu];
            if (_src == undefined) _src = _lang.directives[$ _mu];
            if (_src == undefined) return _out;

            var _names = { B : "byte (8-bit)", W : "word (16-bit)", L : "long (32-bit)", S : "short branch (8-bit displacement)" };
            var _s = 0;
            while (_s < array_length(_src.sizes)) {
                var _sz = _src.sizes[_s];
                if (_plen == 0 || string_pos(_pu, _sz) == 1) {
                    var _sd = _names[$ _sz];
                    array_push(_out, { text : _sz, kind : "size", detail : (_sd == undefined) ? "" : _sd });
                }
                _s += 1;
            }
            return _out;
        }

        var _cands = [];

        if (_context == "mnemonic") {
            _cands = _lang.pool_mnemonic;
        } else if (_context == "operand") {
            var _extra = [];
            var _seen = {};

            if (is_array(_local_names)) {
                var _l = 0;
                while (_l < array_length(_local_names)) {
                    var _ln = _local_names[_l];
                    if (is_string(_ln) && !variable_struct_exists(_seen, _ln)) {
                        _seen[$ _ln] = true;
                        array_push(_extra, { text : _ln, kind : "label", src : "label in this block" });
                    }
                    _l += 1;
                }
            }

            if (is_array(_global_symbols)) {
                var _g = 0;
                while (_g < array_length(_global_symbols)) {
                    var _gn = _global_symbols[_g];
                    if (is_string(_gn) && !variable_struct_exists(_seen, _gn)) {
                        _seen[$ _gn] = true;
                        array_push(_extra, { text : _gn, kind : "symbol", src : "global symbol (other node)" });
                    }
                    _g += 1;
                }
            }

            _cands = array_concat(_extra, _lang.pool_operand);
        } else {
            return _out;
        }

        var _kind_rank = {};
        _kind_rank[$ "label"] = 0;
        _kind_rank[$ "symbol"] = 1;
        _kind_rank[$ "register"] = 2;
        _kind_rank[$ "hwreg"] = 3;
        _kind_rank[$ "const"] = 4;
        _kind_rank[$ "lvo"] = 5;
        _kind_rank[$ "mnemonic"] = 0;
        _kind_rank[$ "directive"] = 1;
        var _scored = [];
        var _i = 0;
        var _cn = array_length(_cands);

        while (_i < _cn) {
            var _cand = _cands[_i];
            var _cu = string_upper(_cand.text);
            var _pos = (_plen == 0) ? 1 : string_pos(_pu, _cu);

            // substring (non-prefix) matches only once the prefix is specific enough
            if (_pos > 1 && _plen < 3) _pos = 0;

            if (_pos > 0) {
                var _cls = (_pos == 1) ? ((_cu == _pu) ? 0 : 1) : 2;
                var _kr = _kind_rank[$ _cand.kind];
                if (_kr == undefined) _kr = 6;
                array_push(_scored, { item : _cand, score : _cls * 100000 + _kr * 1000 + min(999, string_length(_cu)) });
            }
            _i += 1;
        }

        array_sort(_scored, function(_a, _b) {
            if (_a.score != _b.score) return _a.score - _b.score;
            if (_a.item.text == _b.item.text) return 0;
            return (_a.item.text < _b.item.text) ? -1 : 1;
        });

        var _limit = min(array_length(_scored), 200);
        _i = 0;
        while (_i < _limit) {
            var _it = _scored[_i].item;
            array_push(_out, { text : _it.text, kind : _it.kind, detail : __asm_completion_detail(_it) });
            _i += 1;
        }
    } catch (_err) {
        show_debug_message("scr_asm_completions failed: " + string(_err));
    }

    return _out;
}

#endregion

#region self test

function __asm_test_kinds(_fails, _line, _expected) {
    var _tk = scr_asm_tokenize_line(_line);
    var _kinds = [];
    var _i = 0;
    while (_i < array_length(_tk)) {
        array_push(_kinds, _tk[_i].kind);
        _i += 1;
    }
    var _got = string_join_ext(",", _kinds);
    var _want = string_join_ext(",", _expected);
    if (_got != _want) array_push(_fails, "tokenize '" + _line + "': got [" + _got + "] want [" + _want + "]");
}

function __asm_test_diag(_fails, _text, _needle, _severity, _line) {
    var _d = scr_asm_validate(_text, ["ext_label"]);
    var _i = 0;
    while (_i < array_length(_d)) {
        if (string_pos(_needle, _d[_i].message) > 0 && _d[_i].severity == _severity && (_line < 0 || _d[_i].line == _line)) return;
        _i += 1;
    }
    var _msgs = [];
    _i = 0;
    while (_i < array_length(_d)) {
        array_push(_msgs, string(_d[_i].line) + ":" + _d[_i].message);
        _i += 1;
    }
    array_push(_fails, "validate expected " + _severity + " '" + _needle + "' for [" + string_replace_all(_text, "\n", "\\n") + "] got [" + string_join_ext(" | ", _msgs) + "]");
}

function __asm_test_clean(_fails, _text) {
    var _d = scr_asm_validate(_text, ["ext_label"]);
    if (array_length(_d) > 0) {
        var _msgs = [];
        var _i = 0;
        while (_i < array_length(_d)) {
            array_push(_msgs, string(_d[_i].line) + ":" + string(_d[_i].col) + ":" + _d[_i].message);
            _i += 1;
        }
        array_push(_fails, "validate expected clean: " + string_join_ext(" | ", _msgs));
    }
}

/// Runs the pure-function self test. Returns an array of failure strings.
function scr_asm_lang_selftest() {
    var _fails = [];

    try {
        // ---- tokenizer ----
        __asm_test_kinds(_fails, "loop:\tmove.w\t#$10,d0 ; c",
            ["label", "whitespace", "mnemonic", "size", "whitespace", "immediate_prefix", "number", "operator", "register", "whitespace", "comment"]);
        __asm_test_kinds(_fails, "* full comment", ["comment"]);
        __asm_test_kinds(_fails, "; full comment", ["comment"]);
        __asm_test_kinds(_fails, "start  rts", ["label", "whitespace", "mnemonic"]);
        __asm_test_kinds(_fails, "rts", ["mnemonic"]);
        __asm_test_kinds(_fails, "rts  trailing words", ["mnemonic", "whitespace", "comment"]);
        __asm_test_kinds(_fails, "  move.w #$7fff,DMACON(a6)",
            ["whitespace", "mnemonic", "size", "whitespace", "immediate_prefix", "number", "operator", "hwreg", "operator", "register", "operator"]);
        __asm_test_kinds(_fails, "  dc.b 'it''s',0", ["whitespace", "directive", "size", "whitespace", "string", "operator", "number"]);
        __asm_test_kinds(_fails, "data dc.b 1", ["label", "whitespace", "directive", "size", "whitespace", "number"]);
        __asm_test_kinds(_fails, "  section code,code_c", ["whitespace", "directive", "whitespace", "symbol", "operator", "symbol"]);
        __asm_test_kinds(_fails, "FOO = 5", ["label", "whitespace", "directive", "whitespace", "number"]);
        __asm_test_kinds(_fails, "  bne.s .loop", ["whitespace", "mnemonic", "size", "whitespace", "symbol"]);
        __asm_test_kinds(_fails, "  move.w d0,d1 copy it", ["whitespace", "mnemonic", "size", "whitespace", "register", "operator", "register", "whitespace", "comment"]);
        __asm_test_kinds(_fails, "  move.l ($4).w,a6", ["whitespace", "mnemonic", "size", "whitespace", "operator", "number", "operator", "size", "operator", "register"]);
        __asm_test_kinds(_fails, "  movem.l d0-d7/a0-a6,-(sp)",
            ["whitespace", "mnemonic", "size", "whitespace", "register", "operator", "register", "operator", "register", "operator", "register", "operator", "operator", "operator", "register", "operator"]);
        __asm_test_kinds(_fails, "  and.b #%1010,d0", ["whitespace", "mnemonic", "size", "whitespace", "immediate_prefix", "number", "operator", "register"]);
        __asm_test_kinds(_fails, "  bra 1$", ["whitespace", "mnemonic", "whitespace", "symbol"]);
        __asm_test_kinds(_fails, "  dc.b \"open", ["whitespace", "directive", "size", "whitespace", "string"]);
        __asm_test_kinds(_fails, "    .inner:", ["whitespace", "label"]);

        // ---- validator ----
        __asm_test_diag(_fails, "  moov d0,d1", "Unknown mnemonic", "error", 0);
        __asm_test_diag(_fails, "  move.q d0,d1", "Invalid size", "error", 0);
        __asm_test_diag(_fails, "  rts.w", "does not take a size", "error", 0);
        __asm_test_diag(_fails, "  lea foo,a0", "Undefined symbol 'foo'", "error", 0);
        __asm_test_diag(_fails, "  move.w #1,dmacon(a6)", "did you mean 'DMACON'", "error", 0);
        __asm_test_diag(_fails, "x: nop\nx: nop", "Duplicate label", "error", 1);
        __asm_test_diag(_fails, "rts", "auto-indented", "warning", 0);
        __asm_test_diag(_fails, "  move.w d0", "expects 2 operands", "error", 0);
        __asm_test_diag(_fails, "  move.w (a0,d1", "Missing ')'", "error", 0);
        __asm_test_diag(_fails, "  move.w a0),d1", "Unbalanced ')'", "error", 0);
        __asm_test_diag(_fails, "  dc.b \"abc", "Unterminated string", "error", 0);
        __asm_test_diag(_fails, "  dc.q 1", "Invalid size", "error", 0);
        __asm_test_diag(_fails, "a:\n.l: nop\n.l: nop", "Duplicate local label", "error", 2);
        __asm_test_diag(_fails, "DMACON: nop", "predefined hardware equate", "error", 0);

        __asm_test_clean(_fails,
            "start:\n"
            + "\tlea\tCUSTOM,a6\n"
            + "\tmove.w\t#$7fff,DMACON(a6)\n"
            + "\tmove.l\t#copper,COP1LC(a6)\n"
            + ".wait:\tbtst\t#6,CIAA+CIAPRA\n"
            + "\tbne.s\t.wait\n"
            + "\tmoveq\t#7,d7\n"
            + "loop\tdbra\td7,loop\n"
            + "\tbsr\text_label\n"
            + "\tmovem.l\td0-d7/a0-a6,-(sp)\n"
            + "\tmove.l\t4.w,a6\n"
            + "\tjsr\t_LVOForbid(a6)\n"
            + "\tlsl.w\t#2,d0\n"
            + "\tasl.w\t(a0)\n"
            + "\tbeq.s\t1$\n"
            + "1$\trts\n"
            + "COUNT\tequ\t10\n"
            + "\tmove.w\t#COUNT-1,d0\n"
            + "mymac\tmacro\n"
            + "\tmove.w\t\\1,d0\n"
            + "\tendm\n"
            + "\tmymac\t#3\n"
            + "\tdc.w\tCOLOR00,$0f00\n"
            + "\tdc.b\t\"hi\",0\n"
            + "\teven\n"
            + "copper:\tdc.w\t$ffff,$fffe\n");

        // ---- collect / normalise ----
        var _labels = scr_asm_collect_labels("start:\n.loc: nop\nCOUNT equ 3\n  bra start\nmm macro\n endm\n");
        if (!array_contains(_labels, "start") || !array_contains(_labels, "COUNT") || !array_contains(_labels, "mm") || array_contains(_labels, ".loc")) {
            array_push(_fails, "collect_labels got [" + string_join_ext(",", _labels) + "]");
        }

        var _norm = scr_asm_normalise_for_emit("rts\r\nloop: nop\nmove.w d0,d1\nfoo equ 1\n\tnop\ndata dc.b 1");
        var _want_norm = "\trts\nloop: nop\n\tmove.w d0,d1\nfoo equ 1\n\tnop\ndata dc.b 1";
        if (_norm != _want_norm) array_push(_fails, "normalise got [" + string_replace_all(_norm, "\n", "\\n") + "]");

        // ---- completions ----
        var _cm = scr_asm_completions("mo", "mnemonic");
        if (array_length(_cm) == 0 || _cm[0].text != "MOVE") array_push(_fails, "completions('mo') first should be MOVE");
        var _cs = scr_asm_completions("", "size", "MOVEQ");
        if (array_length(_cs) != 1 || _cs[0].text != "L") array_push(_fails, "completions size MOVEQ should be [L]");
        var _cs2 = scr_asm_completions("", "size", "bra");
        if (array_length(_cs2) < 2) array_push(_fails, "completions size BRA should include B/S/W");
        var _co = scr_asm_completions("DMAC", "operand", "", ["dmac_label"], []);
        var _has_dmacon = false;
        var _has_dmaconr = false;
        var _ci = 0;
        while (_ci < array_length(_co)) {
            if (_co[_ci].text == "DMACON") _has_dmacon = true;
            if (_co[_ci].text == "DMACONR") _has_dmaconr = true;
            _ci += 1;
        }
        if (!_has_dmacon || !_has_dmaconr) array_push(_fails, "completions('DMAC') missing DMACON/DMACONR");
        if (array_length(_co) == 0 || _co[0].text != "dmac_label") array_push(_fails, "completions('DMAC') local label should rank first");
        var _csub = scr_asm_completions("CON0", "operand");
        if (array_length(_csub) == 0) array_push(_fails, "completions substring 'CON0' empty");

        // ---- hardware table sanity ----
        var _eq = scr_asm_hardware_equates_text();
        var _needles = ["DMACON\tequ\t$096", "DMACONR\tequ\t$002", "COLOR00\tequ\t$180", "COLOR31\tequ\t$1be", "BPLCON0\tequ\t$100",
            "BPL1PTH\tequ\t$0e0", "BPL6PTL\tequ\t$0f6", "SPR7DATB\tequ\t$17e", "AUD3DAT\tequ\t$0da", "COP1LC\tequ\t$080",
            "BLTSIZE\tequ\t$058", "FMODE\tequ\t$1fc", "BEAMCON0\tequ\t$1dc", "CUSTOM\tequ\t$dff000", "CIAA\tequ\t$bfe001",
            "_LVOForbid\tequ\t-132", "_LVOOpenLibrary\tequ\t-552", "_LVOOwnBlitter\tequ\t-456", "MEMF_CLEAR\tequ\t$10000",
            "CIAICR\tequ\t$0d00", "INTENA\tequ\t$09a", "BPL2MOD\tequ\t$10a", "SPR0PTH\tequ\t$120", "BLTDMOD\tequ\t$066"];
        var _ni = 0;
        while (_ni < array_length(_needles)) {
            if (string_pos(_needles[_ni] + "\n", _eq) == 0) array_push(_fails, "equates missing '" + string_replace_all(_needles[_ni], "\t", " ") + "'");
            _ni += 1;
        }

        var _lang = scr_asm_lang_data();
        var _hi = 0;
        while (_hi < array_length(_lang.hw_order)) {
            var _h = _lang.hw[$ _lang.hw_order[_hi]];
            if (_h.kind == "custom" && ((_h.value mod 2) != 0 || _h.value < 0 || _h.value > $1FE)) {
                array_push(_fails, "custom register " + _h.name + " has bad offset");
            }
            if (__asm_is_op_word(_lang, _h.name) || variable_struct_exists(_lang.registers, string_lower(_h.name))) {
                array_push(_fails, "hardware name collides with a reserved word: " + _h.name);
            }
            _hi += 1;
        }

        // Mnemonic coverage
        var _must = ["BEQ", "BNE", "BHS", "BLO", "DBRA", "DBF", "DBT", "DBNE", "SEQ", "ST", "SF", "ABCD", "NBCD", "SBCD", "TAS", "MOVEP", "CMPM"];
        var _mi = 0;
        while (_mi < array_length(_must)) {
            if (!variable_struct_exists(_lang.mnemonics, _must[_mi])) array_push(_fails, "missing mnemonic " + _must[_mi]);
            _mi += 1;
        }

        // Robustness: odd input must not throw.
        scr_asm_validate("", []);
        scr_asm_validate("\n\n\n", undefined);
        scr_asm_validate("  move.w ((((", []);
        scr_asm_validate(":::\n#\n\"\n'\n\\\n.\n$\n%\n@", []);
        scr_asm_tokenize_line(" ");
        scr_asm_completions("", "operand");
        scr_asm_completions("x", "bogus");
    } catch (_err) {
        array_push(_fails, "selftest threw: " + string(_err));
    }

    return _fails;
}

#endregion
