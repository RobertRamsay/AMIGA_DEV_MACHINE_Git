// -admvideo: plays the showreel (scr_video_segments) on a real-time timeline
// for screen recording, with captions and an end card drawn on top.
depth = -1000000;
segments = scr_video_segments();
seg_index = -1;
seg_start_us = 0;
start_us = get_timer();
caption = "";
caption_sub = "";
caption_since = 0;
end_card = false;
marks = "";
global.video_fired = {};
global.video_sprite_target = [];
global.video_typed = 0;

// The recorder waits for this file to line the recording up with segment times.
var _file = file_text_open_write(global.amiga_dev_data_path + "/video_started.txt");
file_text_write_string(_file, "started");
file_text_close(_file);
