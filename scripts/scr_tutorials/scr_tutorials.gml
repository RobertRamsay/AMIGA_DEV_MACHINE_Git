/// @desc Tutorial registry. scr_tutorial_defs() describes the ten tutorials
/// (simplest first, ending with a complete platformer); scr_tutorial_load(i)
/// replaces the workspace with tutorial i's node graph and assets (built by
/// scr_tutorial_build_* in scr_tutorial_builders). The opening page
/// (obj_tutorial_home) lists them and the guide panel (obj_tutorial_guide)
/// walks through the steps of the loaded one.
///
/// Each tutorial: { id, title, level ("Beginner" / "Intermediate" / "Advanced"),
///   summary, features[] (what it proves), steps[] { title, text } }

function scr_tutorial_defs() {
    if (is_array(global.tutorial_defs_cache)) return global.tutorial_defs_cache;

    global.tutorial_defs_cache = [
        {
            id : 1, title : "Hello, Amiga", level : "Beginner",
            summary : "One macro and a loop: paint the screen a colour and keep the Amiga busy forever.",
            features : ["INIT root", "SETBKG macro", "labels", "BRA loop", "F5 auto-boot"],
            steps : [
                { title : "The INIT column", text : "Everything under the INIT block runs top to bottom when the Amiga boots. Order is simply position: the higher a node sits, the earlier it runs." },
                { title : "SETBKG", text : "The SETBKG macro writes one 12-bit colour into COLOR00, the background. Click its RGB field to pick a colour." },
                { title : "The core loop", text : "An Amiga program must never end. The NOP is labelled 'forever' (the box on its left) and BRA jumps back to it, so the CPU circles there for ever." },
                { title : "Run it", text : "Press F5 (or RUN). ADM assembles the program, writes a bootable disk and FS-UAE boots straight into it - no Workbench, no typing." }
            ]
        },
        {
            id : 2, title : "Opcodes: colour cycling", level : "Beginner",
            summary : "Real 68000 instructions as nodes: count in a data register and pour it into the background colour.",
            features : ["MOVE / ADDQ / BRA opcode nodes", "addressing modes", "absolute custom-chip address"],
            steps : [
                { title : "A counter in D0", text : "MOVEQ #0,D0 clears data register D0. Each pass of the loop adds one with ADDQ.W." },
                { title : "Write a hardware register", text : "MOVE.W D0,$DFF180 stores the counter into COLOR00. Click a node's mode button to cycle addressing modes, and its value box to type a number (H toggles hex)." },
                { title : "Hover for help", text : "Hover any node: the panel at the bottom explains what the instruction does, its cycles and its size." },
                { title : "Run it", text : "F5: the screen strobes through all 4096 colours as fast as the CPU can count. Try ADDQ #8 for wider bands." }
            ]
        },
        {
            id : 3, title : "Copper sky", level : "Beginner",
            summary : "The Copper changes colours on chosen scanlines for free: a sunset gradient with no CPU work.",
            features : ["CPRBAR macro", "Copper lists", "colour picker"],
            steps : [
                { title : "The Copper", text : "The Copper is a tiny co-processor that waits for a raster line and then writes a register. CPRBAR builds its list for you." },
                { title : "Edit the bands", text : "Click 'Click to edit colours' on the CPRBAR node to set how many bands, which colour register and the colour of each band." },
                { title : "Run it", text : "F5: a smooth gradient fills the screen while the CPU only runs the idle loop." }
            ]
        },
        {
            id : 4, title : "Your first CODE block", level : "Beginner",
            summary : "Write assembly by hand: wait for the vertical blank and scroll raster bars, with autocomplete and live checks.",
            features : ["CODE block editor", "hardware equates", "VBL wait", "live diagnostics"],
            steps : [
                { title : "Open the editor", text : "Click EDIT CODE on the CODE BLOCK node (or double-click its code). The editor colours the syntax and checks every line as you type." },
                { title : "Autocomplete", text : "Type a few letters of an instruction or a register name such as COL and press Ctrl+Space. Hover any word for help." },
                { title : "What it does", text : "The block waits for raster line 0, then changes COLOR00 at a moving line each frame, so a bar slides down the screen." },
                { title : "Run it", text : "F5 builds without closing the editor. If vasm finds a mistake, the line is marked and the node turns red." }
            ]
        },
        {
            id : 5, title : "Tiles and maps (8 x 8)", level : "Intermediate",
            summary : "A Game Kit screen and a tile map: 8 x 8 tiles drawn by the Amiga from a map you paint.",
            features : ["GAME SCREEN", "DRAW MAP", "8x8 tileset", "Tile & Map editor", "WAIT FRAME"],
            steps : [
                { title : "Game Kit", text : "GAME SCREEN takes over the display: 320 x 256, 16 colours from the tileset, sprites in front. DRAW MAP draws the room the player starts in." },
                { title : "The tileset", text : "Open TILE-EDIT. The Tiles tab is a pixel editor for each 8 x 8 tile and its flags: Solid, Platform, Hazard, Collect, Exit." },
                { title : "The map", text : "The Map tab paints tiles - or metatiles, bigger stamps made of tiles - into the rooms of the map." },
                { title : "Run it", text : "F5: the Amiga draws every tile itself from the map data." }
            ]
        },
        {
            id : 6, title : "A hero with a 4-frame idle", level : "Intermediate",
            summary : "Put an animated hardware sprite on the map: four idle frames, played by the Game Kit.",
            features : ["PLAYER", "ANIMATE", "DRAW SPRITES", "ANIMSET (4 frames per state)", "16x16 tiles"],
            steps : [
                { title : "Animation sets", text : "The hero is an ANIMSET: idle, run, jump and fall, each with four sprite frames. Open SPR-EDIT to change any frame; TILE-EDIT's Animations tab picks the frames and speed of each state." },
                { title : "PLAYER", text : "PLAYER puts the hero at the map's start point (the S marker in the map editor)." },
                { title : "The game loop", text : "WAIT FRAME syncs to the 50 Hz display, ANIMATE steps the frames and DRAW SPRITES moves the hardware sprite. BRA closes the loop." },
                { title : "Run it", text : "F5: the hero breathes on the platform." }
            ]
        },
        {
            id : 7, title : "Run with the joystick", level : "Intermediate",
            summary : "Read the joystick and let gravity and solid tiles do the rest, on a 32 x 32 tile map.",
            features : ["READ JOYSTICK", "PHYSICS", "tile collision", "32x32 tiles", "run animation"],
            steps : [
                { title : "READ JOYSTICK", text : "Reads the joystick in port 2. In FS-UAE the cursor keys are the stick and right Ctrl is fire." },
                { title : "PHYSICS", text : "Moves the hero with gravity and stops it at Solid tiles. Its steppers set run speed, jump power and gravity." },
                { title : "Run it", text : "F5, then hold left or right: the run animation plays and the hero falls off ledges." }
            ]
        },
        {
            id : 8, title : "Jump! Four animation states", level : "Intermediate",
            summary : "Jumping and one-way platforms built from metatiles, with idle, run, jump and fall animations.",
            features : ["jump", "one-way Platform tiles", "metatiles", "idle/run/jump/fall states", "16x16 tiles"],
            steps : [
                { title : "Jump", text : "Fire or up jumps. Let go early for a small hop - PHYSICS cuts the jump short." },
                { title : "Platforms", text : "Platform tiles are one-way: jump up through them, land on top. The floating ledges are metatiles stamped from the Map tab." },
                { title : "Four states", text : "ANIMATE chooses Idle, Run, Jump (going up) or Fall (going down), each four frames, mirrored when facing left." },
                { title : "Run it", text : "F5 and climb to the top ledge." }
            ]
        },
        {
            id : 9, title : "Pickups, hazards and enemies", level : "Advanced",
            summary : "Two flip-screen rooms of 24 x 24 tiles with gems to collect, spikes and patrolling enemies.",
            features : ["TILE EVENTS", "ENEMIES", "flip-screen rooms", "24x24 tiles", "respawn"],
            steps : [
                { title : "TILE EVENTS", text : "Collect tiles vanish when touched, Hazard tiles (and falling out of the map) send the hero back to the start." },
                { title : "ENEMIES", text : "Enemies are placed in the map editor (E markers). They patrol, turn at walls and ledges, and hurt the hero." },
                { title : "Rooms", text : "Walk off the right edge: the next room flips in. Each room is one screen of 13 x 10 tiles of 24 pixels." },
                { title : "Run it", text : "F5 and collect every gem in both rooms." }
            ]
        },
        {
            id : 10, title : "The complete platformer", level : "Advanced",
            summary : "Six rooms, music, sound effects, 64 and 128 pixel metatiles and an exit door: a whole little game.",
            features : ["PLAY MOD", "jump / collect / hurt sound effects", "3 x 2 rooms", "128x128 metatiles", "EXIT tile", "every Game Kit node"],
            steps : [
                { title : "Music", text : "PLAY MOD starts the soundtrack (import your own .mod in SND-EDIT; the tutorial makes a short tune). TILE EVENTS and PHYSICS play the jump, pickup and hurt effects." },
                { title : "The world", text : "Six rooms (3 x 2) are built from 64 x 64 and 128 x 128 metatiles - open TILE-EDIT's Map tab to see and stamp them." },
                { title : "The goal", text : "Collect the gems, then reach the Exit door: the screen flashes and the level starts again." },
                { title : "Make it yours", text : "Repaint tiles, redraw the hero's frames in SPR-EDIT, move enemies and the start point, tune PHYSICS, and press F5." }
            ]
        }
    ];
    return global.tutorial_defs_cache;
}

/// Replaces the workspace with tutorial _index (0-based). Returns true on success.
function scr_tutorial_load(_index) {
    var _defs = scr_tutorial_defs();
    if (_index < 0 || _index >= array_length(_defs)) return false;

    if (global.workspace_dirty) {
        if (!show_question("Load tutorial " + string(_index + 1) + "? Unsaved changes in the current workspace will be replaced (it is still in the temporary autosave until the next autosave).")) return false;
    }

    scr_tutorial_reset_workspace();
    var _ok = scr_tutorial_build(_index + 1);
    global.tutorial_current = _ok ? _index : -1;
    global.tutorial_step = 0;
    global.workspace_dirty = false;
    global.autosave_due_time = -1;
    global.undo_stack = [];
    global.redo_stack = [];
    if (_ok) {
        scr_set_status_message("Tutorial " + string(_index + 1) + ": " + _defs[_index].title + " loaded - press F5 to build and run it.", make_colour_rgb(0, 255, 255));
    }
    return _ok;
}

/// Clears nodes, roots and tutorial-owned assets, leaving a fresh INIT root.
function scr_tutorial_reset_workspace() {
    global.operand_edit_owner_uid = -1;
    with (obj_opcode_node) instance_destroy();
    with (obj_amiga_root_node) instance_destroy();
    global.asset_list = [];
    global.pan_x = 0;
    global.pan_y = 0;

    // The defaults a fresh start has (other editors expect them).
    scr_asset_define_copper_bar("SunriseWater", 4, 44, 110, 13, 2, 0, 15, 12, 6, 4, 110, 200, 15, 8, 4, 0, 1, 6);
    with (obj_amiga_manager) sprite_editor_commit_asset();
}
