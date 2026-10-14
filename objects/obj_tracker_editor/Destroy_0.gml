// Stop the song or a jammed note when the tracker closes.
if (global.audio_preview_kind == "TRACKER" || global.audio_preview_kind == "JAM") scr_audio_preview_stop();
keyboard_string = "";
