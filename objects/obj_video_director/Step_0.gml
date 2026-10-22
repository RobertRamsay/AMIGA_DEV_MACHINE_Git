var _now = get_timer();
if (seg_index < 0 || (_now - seg_start_us) / 1000000 >= segments[seg_index].secs) {
    seg_index += 1;
    if (seg_index >= array_length(segments)) {
        marks += "end " + string_format((_now - start_us) / 1000000, 0, 3) + "\n";
        var _file = file_text_open_write(global.amiga_dev_data_path + "/video_marks.txt");
        file_text_write_string(_file, marks);
        file_text_close(_file);
        scr_amiga_selftest_note("video: " + string(array_length(segments)) + " segments played");
        scr_amiga_selftest_finish(true);
        exit;
    }
    seg_start_us = _now;
    global.video_fired = {};
    marks += segments[seg_index].name + " " + string_format((_now - start_us) / 1000000, 0, 3) + "\n";
    segments[seg_index].run(0, true);
} else {
    segments[seg_index].run((_now - seg_start_us) / 1000000, false);
}
