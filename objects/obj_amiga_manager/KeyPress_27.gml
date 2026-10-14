// Esc quits only when nothing else is using it: editors close themselves
// with Esc, and node/sprite fields cancel their edit with it. Without this
// guard a single Esc in the code editor would end the whole program.
if (scr_amiga_modal_open()) exit;
if (global.operand_edit_owner_uid != -1) exit;
if (global.sprite_editing_field != "") exit;

var _should_quit = true;
if (global.workspace_dirty) {
    _should_quit = show_question("You have unsaved changes. Quit anyway?");
}
if (_should_quit) game_end();
