/// @desc The 68K course: 100 lessons and 5 exams, played in order (each one
/// unlocks the next). Content lives in datafiles/course/course_<1-5>.txt;
/// lessons are written in the CODE editor (course mode) and checked by
/// assembling with vasm and running the result in the 68000 simulator
/// (scr_m68k_sim) against the lesson's tests.
///
/// File format (one block of 20 lessons + its exam per file):
///   === UNIT 3: Logic and bits          unit name for the lessons that follow
///   === LESSON 21: AND, OR and EOR      a lesson (number: 1-100)
///   @summary   one line for the course map
///   @text      the explanation: paragraphs separated by blank lines; lines
///              indented by 4 spaces or a tab are code, "## " a heading
///   @task      what to write
///   @start     the code the editor starts with
///   @solution  a working answer (-admcourse checks it passes every test)
///   @hint      shown after the first failed run
///   @data      assembly appended after the user's code (tables to work on)
///   @cpu 68020 assemble and simulate as a 68020
///   @step      a type-along step: its title after @step, then the explanation;
///              "> line" = a line to type, "< line" = a line to take out,
///              "^ line" = TYPE IT FOR ME puts the lines after this one
///              (default: at the end of the code, or where the "<" line was)
///   @test Name of the test
///   setup: ... / expect: ... / call: label   (scr_m68k_spec strings)
///   @quiz      questions: "? question", "> code line" (under the question),
///              "+ right answer", "- wrong answer", "! why" (shown once answered)
///   === EXAM 1: Foundations             an exam: @summary, @pass 80, @quiz
/// A lesson passes when every test passes and every quiz question has been
/// answered correctly; an exam when the score reaches its pass mark.
///
/// Steps tick off as their lines appear in the learner's code: a line counts
/// once the caret has left it (Enter), so there is time to add a comment.
/// Lines are compared by scr_course_line_keys (no comments, spaces or case).
///
/// The program: hardware equates, ORG $1000, __adm_code:, the user's code,
/// __adm_end: RTS, @data. A test starts at __adm_code (or its call: label)
/// with a return address pushed, so the run ends at the final RTS or when
/// the code runs off its end. Supervisor mode, SR $2700, unless set up.
///
/// settings.ini [course] done_L<n> / done_E<n> = 1, complete_date. The
/// learner's code: <data>/course/code_L<n>.s.

#macro COURSE_FILES 5
#macro COURSE_EDITOR_UID -77
#macro COURSE_EXAM_PASS 80

function scr_course_init() {
    global.course_items_cache = undefined;
    global.course_done_cache = {};
    global.course_job = undefined;
    global.course_dir = global.amiga_dev_data_path + "/course";
    if (!directory_exists(global.course_dir)) directory_create(global.course_dir);
}

// ---------------------------------------------------------------- content

/// Every lesson and exam in course order (cached).
function scr_course_items() {
    if (is_array(global.course_items_cache)) return global.course_items_cache;
    var _items = [];
    for (var _f = 1; _f <= COURSE_FILES; _f += 1) {
        scr_course_parse(scr_course_read_text(working_directory + "course/course_" + string(_f) + ".txt"), _items);
    }
    for (var _i = 0; _i < array_length(_items); _i += 1) _items[_i].index = _i;
    global.course_items_cache = _items;
    return _items;
}

/// A text file's contents without CRs ("" if missing or empty).
function scr_course_read_text(_path) {
    if (!file_exists(_path)) return "";
    var _buf = buffer_load(_path);
    if (_buf < 0) return "";
    var _text = buffer_get_size(_buf) > 0 ? buffer_read(_buf, buffer_text) : "";
    buffer_delete(_buf);
    return string_replace_all(_text, "\r", "");
}

function scr_course_new_item(_kind, _number, _title, _unit) {
    return {
        kind : _kind, number : _number, title : _title, unit : _unit,
        id : (_kind == "exam" ? "E" : "L") + string(_number), index : -1,
        summary : "", text : "", task : "", start : "", solution : "", hint : "", data : "",
        cpu : 0, pass : COURSE_EXAM_PASS, tests : [], quiz : [], steps : []
    };
}

/// Appends the items of one course file to _items.
function scr_course_parse(_text, _items) {
    var _lines = string_split(_text, "\n");
    var _unit = "";
    var _item = undefined;
    var _section = "";
    var _test = undefined;
    var _q = undefined;
    var _step = undefined;
    for (var _i = 0; _i < array_length(_lines); _i += 1) {
        var _line = string_replace_all(_lines[_i], "\r", "");
        if (string_copy(_line, 1, 4) == "=== ") {
            var _head = string_delete(_line, 1, 4);
            var _colon = string_pos(":", _head);
            var _kw = string_upper(string_trim(string_copy(_head, 1, _colon - 1)));
            var _title = string_trim(string_delete(_head, 1, _colon));
            var _parts = string_split(_kw, " ", true);
            if (_parts[0] == "UNIT") {
                _unit = _title;
                continue;
            }
            _item = scr_course_new_item(_parts[0] == "EXAM" ? "exam" : "lesson", real(_parts[1]), _title, _unit);
            array_push(_items, _item);
            _section = "";
            continue;
        }
        if (_item == undefined) continue;
        if (string_char_at(_line, 1) == "@") {
            var _sp = string_pos(" ", _line);
            var _key = string_lower(_sp > 0 ? string_copy(_line, 2, _sp - 2) : string_delete(_line, 1, 1));
            var _rest = _sp > 0 ? string_trim(string_delete(_line, 1, _sp)) : "";
            _section = _key;
            switch (_key) {
                case "summary": _item.summary = _rest; break;
                case "cpu": _item.cpu = string_pos("020", _rest) > 0 ? 2 : 0; break;
                case "pass": _item.pass = real(_rest); break;
                case "test":
                    _test = { name : _rest, setup : "", expect : "", call : "" };
                    array_push(_item.tests, _test);
                    break;
                case "step":
                    _step = { title : _rest, text : "", add : [], remove : [], after : "", need : {}, most : {} };
                    array_push(_item.steps, _step);
                    break;
            }
            continue;
        }
        switch (_section) {
            case "text": case "task": case "start": case "solution": case "hint": case "data":
                _item[$ _section] += (_item[$ _section] == "" ? "" : "\n") + _line;
                break;
            case "step":
                var _sm = string_char_at(_line, 1);
                if (_sm == ">" || _sm == "<" || _sm == "^") {
                    var _sl = string_delete(_line, 1, 1);
                    if (string_char_at(_sl, 1) == " ") _sl = string_delete(_sl, 1, 1);
                    if (_sm == ">") array_push(_step.add, _sl);
                    else if (_sm == "<") array_push(_step.remove, _sl);
                    else _step.after = _sl;
                } else {
                    _step.text += (_step.text == "" ? "" : "\n") + _line;
                }
                break;
            case "test":
                var _t = string_trim(_line);
                if (string_copy(_t, 1, 6) == "setup:") _test.setup += " " + string_trim(string_delete(_t, 1, 6));
                else if (string_copy(_t, 1, 7) == "expect:") _test.expect += " " + string_trim(string_delete(_t, 1, 7));
                else if (string_copy(_t, 1, 5) == "call:") _test.call = string_trim(string_delete(_t, 1, 5));
                break;
            case "quiz":
                var _qt = string_trim(_line);
                if (_qt == "") break;
                var _mark = string_char_at(_qt, 1);
                var _body = string_trim(string_delete(_qt, 1, 1));
                if (_mark == "?") {
                    _q = { question : _body, code : [], options : [], answer : -1, why : "" };
                    array_push(_item.quiz, _q);
                } else if (_q != undefined && (_mark == "+" || _mark == "-")) {
                    if (_mark == "+") _q.answer = array_length(_q.options);
                    array_push(_q.options, _body);
                } else if (_q != undefined && _mark == ">") {
                    // keep the indentation after "> " (tabs become spaces)
                    var _code = string_replace_all(string_delete(_qt, 1, 1), "\t", "    ");
                    if (string_char_at(_code, 1) == " ") _code = string_delete(_code, 1, 1);
                    array_push(_q.code, _code);
                } else if (_q != undefined && _mark == "!") {
                    _q.why += (_q.why == "" ? "" : " ") + _body;
                }
                break;
        }
    }
    // Trim the blank lines around each text section.
    for (var _k = 0; _k < array_length(_items); _k += 1) {
        var _it = _items[_k];
        _it.text = scr_course_trim_block(_it.text);
        _it.task = scr_course_trim_block(_it.task);
        _it.start = scr_course_trim_block(_it.start);
        _it.solution = scr_course_trim_block(_it.solution);
        _it.hint = scr_course_trim_block(_it.hint);
        _it.data = scr_course_trim_block(_it.data);
        for (var _s = 0; _s < array_length(_it.steps); _s += 1) _it.steps[_s].text = scr_course_trim_block(_it.steps[_s].text);
        scr_course_steps_prepare(_it);
    }
}

// ---------------------------------------------------------------- type-along steps

/// What a source line says, for comparing typed lines with a step's: up to
/// two keys, "label:name" and the instruction (lower case, no spaces or
/// comment). A label on its own line and on the instruction's line match.
function scr_course_line_keys(_line) {
    var _out = [];
    var _tk = scr_asm_tokenize_line(string_replace_all(_line, "\r", ""));
    var _op = "";
    for (var _i = 0; _i < array_length(_tk); _i += 1) {
        var _t = _tk[_i];
        if (_t.kind == "whitespace" || _t.kind == "comment" || _t.field == "comment") continue;
        if (_t.field == "label") {
            var _name = string_lower(string_replace_all(string_trim(_t.text), ":", ""));
            if (_name != "") array_push(_out, "label:" + _name);
        } else {
            _op += string_lower(string_replace_all(_t.text, " ", ""));
        }
    }
    if (_op != "") array_push(_out, _op);
    return _out;
}

/// How many times each key occurs in an array of lines (struct), skipping line _skip.
function scr_course_keys_of(_lines, _skip = -1) {
    var _set = {};
    for (var _i = 0; _i < array_length(_lines); _i += 1) {
        if (_i == _skip) continue;
        var _k = scr_course_line_keys(_lines[_i]);
        for (var _j = 0; _j < array_length(_k); _j += 1) _set[$ _k[_j]] = (_set[$ _k[_j]] ?? 0) + 1;
    }
    return _set;
}

/// Works out what each step needs (scr_course_parse calls it): step.need =
/// key -> count every added key must reach, step.most = key -> count every
/// taken-out key must drop to, both as in @start with the steps up to this
/// one typed in. So a step that types a second "add.w d0,d0" needs two.
function scr_course_steps_prepare(_item) {
    var _lines = string_split(_item.start, "\n");
    for (var _s = 0; _s < array_length(_item.steps); _s += 1) {
        var _st = _item.steps[_s];
        _lines = scr_course_step_apply(_lines, _st).lines;
        var _counts = scr_course_keys_of(_lines);
        _st.need = {};
        _st.most = {};
        for (var _i = 0; _i < array_length(_st.add); _i += 1) {
            var _k = scr_course_line_keys(_st.add[_i]);
            for (var _j = 0; _j < array_length(_k); _j += 1) _st.need[$ _k[_j]] = _counts[$ _k[_j]] ?? 1;
        }
        for (var _r = 0; _r < array_length(_st.remove); _r += 1) {
            var _rk = scr_course_line_keys(_st.remove[_r]);
            // the instruction key decides (a label may stay on its own line)
            if (array_length(_rk) > 0) _st.most[$ _rk[array_length(_rk) - 1]] = _counts[$ _rk[array_length(_rk) - 1]] ?? 0;
        }
    }
}

/// A step is done when every line it adds is in _counted often enough and
/// every line it takes out is rare enough in _all (key counts of the whole text).
function scr_course_step_done(_step, _counted, _all) {
    var _need = struct_get_names(_step.need);
    for (var _i = 0; _i < array_length(_need); _i += 1) if ((_counted[$ _need[_i]] ?? 0) < _step.need[$ _need[_i]]) return false;
    var _most = struct_get_names(_step.most);
    for (var _r = 0; _r < array_length(_most); _r += 1) if ((_all[$ _most[_r]] ?? 0) > _step.most[$ _most[_r]]) return false;
    return true;
}

/// The first line of _lines whose keys hold every key of _want (-1: none).
function scr_course_find_line(_lines, _want) {
    var _wk = scr_course_line_keys(_want);
    if (array_length(_wk) == 0) return -1;
    for (var _i = 0; _i < array_length(_lines); _i += 1) {
        var _k = scr_course_line_keys(_lines[_i]);
        var _all = true;
        for (var _j = 0; _j < array_length(_wk); _j += 1) if (!array_contains(_k, _wk[_j])) _all = false;
        if (_all) return _i;
    }
    return -1;
}

/// TYPE IT FOR ME: _lines with the step applied. Returns { lines, last }
/// (last = index of the last line put in). The "<" lines come out and the
/// new ones go where the first of them was; otherwise after the "^" line,
/// else after the last line that is not blank.
function scr_course_step_apply(_lines, _step) {
    var _out = [];
    array_copy(_out, 0, _lines, 0, array_length(_lines));
    var _at = -1;
    for (var _r = 0; _r < array_length(_step.remove); _r += 1) {
        var _f = scr_course_find_line(_out, _step.remove[_r]);
        if (_f < 0) continue;
        array_delete(_out, _f, 1);
        if (_at < 0 || _f < _at) _at = _f;
    }
    if (_at < 0 && _step.after != "") {
        var _a = scr_course_find_line(_out, _step.after);
        if (_a >= 0) _at = _a + 1;
    }
    if (_at < 0) {
        _at = array_length(_out);
        while (_at > 0 && string_trim(_out[_at - 1]) == "") _at -= 1;
    }
    for (var _i = 0; _i < array_length(_step.add); _i += 1) array_insert(_out, _at + _i, _step.add[_i]);
    return { lines : _out, last : _at + array_length(_step.add) - 1 };
}

/// The @start code with every step typed in (what TYPE IT FOR ME gives).
function scr_course_steps_code(_item) {
    var _lines = string_split(_item.start, "\n");
    for (var _s = 0; _s < array_length(_item.steps); _s += 1) _lines = scr_course_step_apply(_lines, _item.steps[_s]).lines;
    return string_join_ext("\n", _lines);
}

/// Drops leading and trailing blank lines (keeps indentation).
function scr_course_trim_block(_s) {
    var _lines = string_split(_s, "\n");
    var _a = 0;
    var _b = array_length(_lines) - 1;
    while (_a <= _b && string_trim(_lines[_a]) == "") _a += 1;
    while (_b >= _a && string_trim(_lines[_b]) == "") _b -= 1;
    if (_a > _b) return "";
    var _out = _lines[_a];
    for (var _i = _a + 1; _i <= _b; _i += 1) _out += "\n" + _lines[_i];
    return _out;
}

/// "LESSON 12" / "EXAM 1".
function scr_course_item_label(_item) {
    return (_item.kind == "exam" ? "EXAM " : "LESSON ") + string(_item.number);
}

// ---------------------------------------------------------------- progress

function scr_course_is_done(_item) {
    var _key = "done_" + _item.id;
    if (!variable_struct_exists(global.course_done_cache, _key)) {
        ini_open("settings.ini");
        global.course_done_cache[$ _key] = ini_read_real("course", _key, 0) != 0;
        ini_close();
    }
    return global.course_done_cache[$ _key];
}

function scr_course_mark_done(_item) {
    var _key = "done_" + _item.id;
    global.course_done_cache[$ _key] = true;
    ini_open("settings.ini");
    ini_write_real("course", _key, 1);
    var _items = scr_course_items();
    if (_item.index == array_length(_items) - 1 && ini_read_string("course", "complete_date", "") == "") {
        ini_write_string("course", "complete_date", string(current_day) + "/" + string(current_month) + "/" + string(current_year));
    }
    ini_close();
}

/// The date the final exam was passed ("" = not yet).
function scr_course_complete_date() {
    ini_open("settings.ini");
    var _d = ini_read_string("course", "complete_date", "");
    ini_close();
    return _d;
}

/// An item is open when it is the first or the one before it is done.
function scr_course_unlocked(_index) {
    if (_index <= 0) return true;
    var _items = scr_course_items();
    return scr_course_is_done(_items[_index - 1]);
}

function scr_course_done_count() {
    var _items = scr_course_items();
    var _n = 0;
    for (var _i = 0; _i < array_length(_items); _i += 1) if (scr_course_is_done(_items[_i])) _n += 1;
    return _n;
}

/// The first item not done yet (the last one when everything is done).
function scr_course_next_index() {
    var _items = scr_course_items();
    for (var _i = 0; _i < array_length(_items); _i += 1) if (!scr_course_is_done(_items[_i])) return _i;
    return array_length(_items) - 1;
}

/// Forgets every pass (the saved code stays).
function scr_course_reset_progress() {
    ini_open("settings.ini");
    ini_section_delete("course");
    ini_close();
    global.course_done_cache = {};
}

// ---------------------------------------------------------------- the learner's code

function scr_course_code_path(_item) {
    return global.course_dir + "/code_" + _item.id + ".s";
}

/// The saved code for a lesson, or its @start code.
function scr_course_load_code(_item) {
    var _path = scr_course_code_path(_item);
    if (file_exists(_path)) return scr_course_read_text(_path);
    return _item.start;
}

function scr_course_save_code(_item, _text) {
    var _buf = buffer_create(string_byte_length(_text) + 1, buffer_fixed, 1);
    buffer_write(_buf, buffer_text, _text);
    buffer_save_ext(_buf, scr_course_code_path(_item), 0, string_byte_length(_text));
    buffer_delete(_buf);
}

// ---------------------------------------------------------------- assembling

/// Starts vasm on _code for _item. Returns the job struct the caller polls
/// with scr_course_job_poll; job.state: "assembling", then "assembled" /
/// "asm_failed" / "error".
function scr_course_assemble(_item, _code, _dir = "") {
    if (_dir == "") _dir = global.course_dir + "/build";
    if (!directory_exists(_dir)) directory_create(_dir);
    var _header = scr_asm_hardware_equates_text() + "\torg\t$1000\n__adm_code:\n";
    var _first = string_count("\n", _header) + 1;           // 1-based line of the first user line
    var _user = scr_asm_normalise_for_emit(_code);
    var _src = _header + _user + "\n__adm_end:\n\trts\n" + (_item.data != "" ? scr_asm_normalise_for_emit(_item.data) + "\n" : "");
    var _job = {
        item : _item, code : _code, state : "assembling", timer : 0,
        dir : _dir, user_first : _first, user_lines : string_count("\n", _user) + 1,
        errors : [], results : [], test_index : 0, cpu : undefined, symbols : {}, line_addr : [],
        message : "", passed : false
    };
    var _f = file_text_open_write(_dir + "/lesson.s");
    file_text_write_string(_f, _src);
    file_text_close(_f);
    var _names = ["lesson.bin", "lesson.lst", "vasm.log", "asm.done"];
    for (var _i = 0; _i < array_length(_names); _i += 1) if (file_exists(_dir + "/" + _names[_i])) file_delete(_dir + "/" + _names[_i]);
    var _vasm_native = string_replace_all(global.vasm_path, "/", "\\");
    var _args = "-Fbin " + (_item.cpu >= 2 ? "-m68020" : "-m68000") + " -L lesson.lst -o lesson.bin lesson.s";
    // One cmd /C line, started minimised: the same pattern as the build (no batch files).
    var _command = "/D /V:ON /S /C \"\"" + _vasm_native + "\" " + _args + " > vasm.log 2>&1 & > asm.done echo exit !errorlevel!\"";
    if (!execute_shell_simple("cmd.exe", _command, "open", 7, string_replace_all(_dir, "/", "\\"))) {
        _job.state = "error";
        _job.message = "Could not start cmd.exe to run vasm.";
    }
    return _job;
}

/// Call every frame while job.state == "assembling".
function scr_course_job_poll(_job) {
    if (_job.state != "assembling") return;
    _job.timer += 1;
    var _done = _job.dir + "/asm.done";
    if (!file_exists(_done)) {
        if (_job.timer > 1200) {
            _job.state = "error";
            _job.message = "vasm did not finish.";
        }
        return;
    }
    var _f = file_text_open_read(_done);
    var _digits = _f >= 0 ? string_digits(file_text_read_string(_f)) : "";
    if (_f >= 0) file_text_close(_f);
    if (_digits == "") return;      // marker not written completely yet
    scr_course_read_log(_job);
    if (real(_digits) != 0 || array_length(_job.errors) > 0 || !file_exists(_job.dir + "/lesson.bin")) {
        _job.state = "asm_failed";
        if (array_length(_job.errors) == 0) array_push(_job.errors, { line : -1, message : "vasm failed (see " + _job.dir + "/vasm.log)" });
        _job.message = string(array_length(_job.errors)) + " assembler error(s): fix the red lines.";
    } else {
        scr_course_read_listing(_job);
        _job.state = "assembled";
    }
    // Errors on the learner's lines go to the editor.
    global.code_editor_build_errors = [];
    for (var _i = 0; _i < array_length(_job.errors); _i += 1) {
        var _e = _job.errors[_i];
        if (_e.line >= 0) array_push(global.code_editor_build_errors, { node_uid : COURSE_EDITOR_UID, line : _e.line, message : _e.message });
    }
}

/// vasm.log -> job.errors [{ line (0-based in the learner's code, -1 elsewhere), message }].
function scr_course_read_log(_job) {
    var _path = _job.dir + "/vasm.log";
    if (!file_exists(_path)) return;
    var _f = file_text_open_read(_path);
    while (!file_text_eof(_f)) {
        var _l = string_trim(file_text_read_string(_f));
        file_text_readln(_f);
        if (string_pos("error ", _l) != 1 && string_pos("fatal error", _l) != 1) continue;
        var _colon = string_pos("\": ", _l);
        var _msg = _colon > 0 ? string_copy(_l, _colon + 3, string_length(_l)) : _l;
        var _n = scr_amiga_vasm_line_number(_l);
        var _line = _n - _job.user_first;
        if (_n < 0 || _line < 0 || _line >= _job.user_lines) {
            _line = -1;
            if (_n >= _job.user_first + _job.user_lines) _msg = "In the lesson's data: " + _msg;
        }
        array_push(_job.errors, { line : _line, message : _msg });
    }
    file_text_close(_f);
}

/// lesson.lst -> job.symbols (name -> address) and job.line_addr ([address, 0-based user line]).
function scr_course_read_listing(_job) {
    var _path = _job.dir + "/lesson.lst";
    if (!file_exists(_path)) return;
    var _f = file_text_open_read(_path);
    var _in_symbols = false;
    while (!file_text_eof(_f)) {
        var _raw = file_text_read_string(_f);
        file_text_readln(_f);
        if (string_pos("Symbols by name:", _raw) == 1) {
            _in_symbols = true;
            continue;
        }
        if (string_pos("Labels by address:", _raw) == 1) break;
        if (_in_symbols) {
            var _parts = string_split(_raw, " ", true);
            if (array_length(_parts) >= 2 && string_pos("A:", _parts[1]) == 1) {
                _job.symbols[$ _parts[0]] = scr_m68k_parse_hex(string_delete(_parts[1], 1, 2));
            }
            continue;
        }
        // "00:00001008 7001            \t     5: \tmoveq #1,d0"
        if (string_char_at(_raw, 3) != ":" || string_length(_raw) < 12) continue;
        var _tab = string_pos("\t", _raw);
        if (_tab <= 0) continue;
        var _after = string_delete(_raw, 1, _tab);
        var _c = string_pos(":", _after);
        if (_c <= 0) continue;
        var _num = string_digits(string_copy(_after, 1, _c - 1));
        if (_num == "") continue;
        var _user_line = real(_num) - _job.user_first;
        if (_user_line < 0 || _user_line >= _job.user_lines) continue;
        array_push(_job.line_addr, [scr_m68k_parse_hex(string_copy(_raw, 4, 8)), _user_line]);
    }
    file_text_close(_f);
}

/// The learner's line (0-based) holding address _pc, or -1.
function scr_course_pc_line(_job, _pc) {
    var _best = -1;
    var _best_addr = -1;
    for (var _i = 0; _i < array_length(_job.line_addr); _i += 1) {
        var _e = _job.line_addr[_i];
        if (_e[0] <= _pc && _e[0] > _best_addr) {
            _best_addr = _e[0];
            _best = _e[1];
        }
    }
    if (_best_addr < 0 || _pc - _best_addr > 10) return -1;
    return _best;
}

// ---------------------------------------------------------------- running the tests

/// Gets the job ready to run its tests (state "testing").
function scr_course_tests_begin(_job) {
    _job.cpu = scr_m68k_new($80000, _job.item.cpu);
    _job.test_index = 0;
    _job.results = [];
    _job.started = false;
    _job.state = array_length(_job.item.tests) > 0 ? "testing" : "tested";
    _job.code_size = variable_struct_exists(_job.symbols, "__adm_end") ? _job.symbols.__adm_end - $1000 : 0;
}

/// Runs tests for up to _ms milliseconds; call every frame while state == "testing".
function scr_course_tests_step(_job, _ms = 12) {
    if (_job.state != "testing") return;
    var _t_end = get_timer() + _ms * 1000;
    var _tests = _job.item.tests;
    while (get_timer() < _t_end && _job.state == "testing") {
        var _test = _tests[_job.test_index];
        var _cpu = _job.cpu;
        if (!_job.started) {
            scr_m68k_reset(_cpu);
            if (scr_m68k_load_file(_cpu, $1000, _job.dir + "/lesson.bin") < 0) {
                scr_course_test_result(_job, false, ["The assembled program could not be loaded."]);
                continue;
            }
            var _entry = _test.call == "" ? "__adm_code" : _test.call;
            if (!variable_struct_exists(_job.symbols, _entry)) {
                scr_course_test_result(_job, false, ["Your code needs a label called " + _entry + "."]);
                continue;
            }
            _job.max = scr_m68k_spec_setup(_cpu, _test.setup, _job.symbols[$ _entry], -1, 300000);
            _job.started = true;
        }
        var _n = 0;
        while (_n < 2000 && _cpu.status == "running" && _cpu.instructions < _job.max) {
            scr_m68k_step(_cpu);
            _n += 1;
        }
        if (_cpu.status == "running" && _cpu.instructions < _job.max) continue;
        if (_cpu.status == "running") {
            _cpu.status = "timeout";
            _cpu.message = "Still running after " + string(_job.max) + " instructions - is there an endless loop?";
        }
        var _problems = [];
        var _wants_status = string_pos("status=", _test.expect) > 0;
        if (!_wants_status && _cpu.status != "done") {
            var _line = scr_course_pc_line(_job, _cpu.pc);
            array_push(_problems, _cpu.message + (_line >= 0 ? " (line " + string(_line + 1) + ")" : ""));
        } else {
            _problems = scr_m68k_spec_check(_cpu, _test.expect, { source : _job.code, code_size : _job.code_size });
        }
        scr_course_test_result(_job, array_length(_problems) == 0, _problems);
    }
}

function scr_course_test_result(_job, _ok, _problems) {
    var _cpu = _job.cpu;
    var _d = array_create(8, 0);
    var _a = array_create(8, 0);
    array_copy(_d, 0, _cpu.d, 0, 8);
    array_copy(_a, 0, _cpu.a, 0, 8);
    array_push(_job.results, {
        name : _job.item.tests[_job.test_index].name, ok : _ok, problems : _problems,
        d : _d, a : _a, sr : _cpu.sr, pc : _cpu.pc, cycles : _cpu.cycles, instructions : _cpu.instructions
    });
    _job.test_index += 1;
    _job.started = false;
    if (_job.test_index >= array_length(_job.item.tests)) {
        _job.state = "tested";
        scr_m68k_free(_job.cpu);
        var _passed = 0;
        for (var _i = 0; _i < array_length(_job.results); _i += 1) if (_job.results[_i].ok) _passed += 1;
        _job.passed = _passed == array_length(_job.results);
        _job.message = string(_passed) + " of " + string(array_length(_job.results)) + " tests passed.";
    }
}

// ---------------------------------------------------------------- opening

function scr_course_open() {
    if (instance_exists(obj_course)) return;
    instance_create_depth(0, 0, -350000, obj_course);
}

// ---------------------------------------------------------------- -admcourse self test

/// Checks the content (100 lessons in order, 5 exams of 30-50 questions,
/// answers present), then assembles every lesson's @solution (must pass all
/// its tests) and its @start code (must fail at least one, or the tests
/// would pass without any work). Returns failures through _fail when done.
function scr_course_selftest_begin() {
    global.course_items_cache = undefined;
    var _items = scr_course_items();
    var _fail = [];
    var _lessons = 0;
    var _exams = 0;
    for (var _i = 0; _i < array_length(_items); _i += 1) {
        var _it = _items[_i];
        var _name = scr_course_item_label(_it);
        if (_it.kind == "lesson") {
            _lessons += 1;
            if (_it.number != _lessons) array_push(_fail, _name + ": expected lesson " + string(_lessons) + " here");
            if (array_length(_it.tests) == 0 && array_length(_it.quiz) == 0) array_push(_fail, _name + ": no tests and no quiz");
            if (array_length(_it.tests) > 0 && _it.solution == "") array_push(_fail, _name + ": tests but no @solution");
            if (_it.text == "" || _it.summary == "" || _it.unit == "") array_push(_fail, _name + ": missing text, summary or unit");
            if (_lessons mod 20 == 0 && (_i + 1 >= array_length(_items) || _items[_i + 1].kind != "exam")) array_push(_fail, _name + ": an exam should follow");
            if (array_length(_it.tests) > 0 && array_length(_it.steps) == 0) array_push(_fail, _name + ": tests but no @step");
            // Each step must be something to do, not done yet in @start, and
            // done once TYPE IT FOR ME has typed it.
            var _code = string_split(_it.start, "\n");
            var _start_keys = scr_course_keys_of(_code);
            for (var _s = 0; _s < array_length(_it.steps); _s += 1) {
                var _st = _it.steps[_s];
                var _sname = _name + " step " + string(_s + 1);
                var _has = array_length(_st.remove) > 0;
                for (var _a = 0; _a < array_length(_st.add); _a += 1) if (array_length(scr_course_line_keys(_st.add[_a])) > 0) _has = true;
                if (!_has) array_push(_fail, _sname + ": no line to type");
                if (_st.title == "" || _st.text == "") array_push(_fail, _sname + ": needs a title and an explanation");
                if (_has && scr_course_step_done(_st, _start_keys, _start_keys)) array_push(_fail, _sname + ": already done in @start");
                if (_st.after != "" && scr_course_find_line(_code, _st.after) < 0) array_push(_fail, _sname + ": its ^ line is not in the code yet");
                for (var _r = 0; _r < array_length(_st.remove); _r += 1) {
                    if (scr_course_find_line(_code, _st.remove[_r]) < 0) array_push(_fail, _sname + ": its < line is not in the code");
                }
                _code = scr_course_step_apply(_code, _st).lines;
                var _keys = scr_course_keys_of(_code);
                if (_has && !scr_course_step_done(_st, _keys, _keys)) array_push(_fail, _sname + ": not done after TYPE IT FOR ME");
            }
        } else {
            _exams += 1;
            if (_it.number != _exams) array_push(_fail, _name + ": expected exam " + string(_exams));
            var _n = array_length(_it.quiz);
            if (_n < 30 || _n > 50) array_push(_fail, _name + ": " + string(_n) + " questions (30-50 wanted)");
        }
        for (var _q = 0; _q < array_length(_it.quiz); _q += 1) {
            var _qq = _it.quiz[_q];
            if (_qq.answer < 0 || array_length(_qq.options) < 2) array_push(_fail, _name + " question " + string(_q + 1) + ": needs options and a + answer");
        }
    }
    // A typed line waits for Enter: lesson 1's first step with its line under
    // the caret (and a comment of the learner's own) is not done until the caret leaves.
    if (array_length(_items) > 0 && array_length(_items[0].steps) > 0) {
        var _typed = [_items[0].start, "    moveq   #42,D0   ; my own note"];
        var _all = scr_course_keys_of(_typed);
        if (scr_course_step_done(_items[0].steps[0], scr_course_keys_of(_typed, 1), _all)) array_push(_fail, "a step ticks before Enter leaves its line");
        if (!scr_course_step_done(_items[0].steps[0], _all, _all)) array_push(_fail, "a typed step (with a comment, upper case) does not tick after Enter");
    }
    if (_lessons != 100) array_push(_fail, string(_lessons) + " lessons (100 wanted)");
    if (_exams != 5) array_push(_fail, string(_exams) + " exams (5 wanted)");
    global.course_selftest = { fail : _fail, index : 0, phase : 0, job : undefined, checked : 0, t0 : get_timer() };
}

/// One frame of the self test; returns true when finished (failures in global.course_selftest.fail).
function scr_course_selftest_step() {
    var _st = global.course_selftest;
    var _items = scr_course_items();
    while (_st.index < array_length(_items) && (_items[_st.index].kind != "lesson" || array_length(_items[_st.index].tests) == 0)) _st.index += 1;
    if (_st.index >= array_length(_items)) return true;
    var _it = _items[_st.index];
    if (_st.job == undefined) {
        var _src = _st.phase == 0 ? _it.solution : (_st.phase == 1 ? _it.start : scr_course_steps_code(_it));
        _st.job = scr_course_assemble(_it, _src, global.course_dir + "/selftest");
        return false;
    }
    var _job = _st.job;
    if (_job.state == "assembling") scr_course_job_poll(_job);
    if (_job.state == "assembled") scr_course_tests_begin(_job);
    if (_job.state == "testing") scr_course_tests_step(_job, 40);
    var _finished = _job.state == "tested" || _job.state == "asm_failed" || _job.state == "error";
    if (!_finished) return false;
    var _name = scr_course_item_label(_it);
    if (_st.phase == 0 || _st.phase == 2) {
        var _what = _st.phase == 0 ? " solution" : " with every step typed in";
        if (_job.state != "tested") {
            var _e = array_length(_job.errors) > 0 ? _job.errors[0] : { line : -1, message : _job.message };
            array_push(_st.fail, _name + _what + " does not assemble: line " + string(_e.line + 1) + ": " + _e.message);
        } else if (!_job.passed) {
            for (var _r = 0; _r < array_length(_job.results); _r += 1) {
                if (!_job.results[_r].ok) array_push(_st.fail, _name + _what + " fails \"" + _job.results[_r].name + "\": " + string_join_ext("; ", _job.results[_r].problems));
            }
        }
        if (_st.phase == 0) _st.checked += 1;
    } else {
        if (_job.state == "tested" && _job.passed) array_push(_st.fail, _name + ": the @start code already passes every test");
    }
    _st.phase += 1;
    if (_st.phase == 2 && array_length(_it.steps) == 0) _st.phase = 3;
    if (_st.phase >= 3) {
        _st.phase = 0;
        _st.index += 1;
    }
    _st.job = undefined;
    return false;
}
