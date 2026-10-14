/// @desc Tutorial registry. scr_tutorial_defs() describes the tutorials
/// (1-10: from one node to a complete Game Kit platformer; 11-15: how macros
/// work, bitmaps, sprites, BOBs, music and sound; 16: write a tracker song);
/// scr_tutorial_load(i) replaces the workspace with tutorial i's node graph
/// and assets (built by scr_tutorial_build_* in scr_tutorial_builders). The
/// opening page (obj_tutorial_home) lists them and the guide panel
/// (obj_tutorial_guide) walks through the steps of the loaded one.
///
/// Each tutorial: { id, title, level ("Beginner" / "Intermediate" / "Advanced"),
///   summary, features[] (what it proves), steps[] { title, text } }
/// A step may add song_stage (+ hint): the guide then shows SHOW ME IN THE
/// TRACKER, which builds the song to that stage (scr_tutorial_song_show).

/// Number of tutorials (the length of scr_tutorial_defs(); -admtutorials builds them all).
#macro TUTORIAL_COUNT 16

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
                { title : "Find an instruction", text : "With the mouse over the palette, type its first letters: N lights up NEG, NOP, NOT..., then O narrows it to NOP and NOT. A third letter starts a new search; the list scrolls to the matches." },
                { title : "Hover for help", text : "Hover any node: the panel at the bottom says what it does in plain English with your values, what each addressing mode means, its size and cost, and which hardware register an address is." },
                { title : "Run it", text : "F5: the screen strobes through all 4096 colours as fast as the CPU can count. Try ADDQ #8 for wider bands." }
            ]
        },
        {
            id : 3, title : "Copper sky", level : "Beginner",
            summary : "The Copper changes colours on chosen scanlines for free: a sunset gradient with no CPU work.",
            features : ["CPRBAR macro", "Copper lists", "colour picker"],
            steps : [
                { title : "The Copper", text : "The Copper is a tiny co-processor that waits for a raster line and then writes a register. CPRBAR builds its list for you." },
                { title : "Edit the bands", text : "Click EDIT COLOURS on the COPPER BAR node to set how many bands, which colour register and the colour of each band." },
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
                { title : "Music", text : "PLAY MOD starts the soundtrack with Pixel Hearts, a song written in the TRACKER (EDIT on the node opens it; import your own .mod in SND-EDIT). TILE EVENTS and PHYSICS play the jump, pickup and hurt effects." },
                { title : "The world", text : "Six rooms (3 x 2) are built from 64 x 64 and 128 x 128 metatiles - open TILE-EDIT's Map tab to see and stamp them." },
                { title : "The goal", text : "Collect the gems, then reach the Exit door: the screen flashes and the level starts again." },
                { title : "Make it yours", text : "Repaint tiles, redraw the hero's frames in SPR-EDIT, move enemies and the start point, tune PHYSICS, and press F5." }
            ]
        },
        {
            id : 11, title : "How macros work", level : "Beginner",
            summary : "What a macro node is, how its rows and EDIT buttons work, the program preview, labels and ORG columns.",
            features : ["macro vs opcode", "program preview", "node rows + EDIT buttons", "ORG column", "labels", "hover help"],
            steps : [
                { title : "One node, many instructions", text : "SETBKG and COPPER BAR are macros: each node writes many lines of 68000 code for you. The program preview on the right lists every line - click a macro's title line there to fold or unfold it, and any line to jump to its node." },
                { title : "Rows are settings", text : "Each row under a node's title is one setting. A row with < and > steps: click its left half to go down, its right half to go up. Teal rows are buttons: EDIT COLOURS on COPPER BAR opens its colour editor, and the EDIT buttons of other nodes open the picture, sprite, BOB, map, code or song they use. SETBKG's RGB row opens a colour picker." },
                { title : "Order and columns", text : "Nodes run from top to bottom. An ORG block carries the program on in a new column: it continues the column to its left, and the glowing flow line shows the way. The box on a node's left is its label - BRA forever jumps back to the NOP labelled forever." },
                { title : "Checks and help", text : "The dots beside a node turn red when a setting is wrong, and a failed build outlines the node in red with the reason. Hover any node to read what it does. Ctrl+Z undoes any change." },
                { title : "Run it", text : "F5: SETBKG sets the background, the Copper paints six colour bands down the screen, and the CPU waits in the forever loop." }
            ]
        },
        {
            id : 12, title : "A bitmap picture", level : "Beginner",
            summary : "Show a 320 x 256 picture in 32 colours and open it in the bitmap editor with one click.",
            features : ["BITMAP DISPLAY", "EDIT BITMAP", "5 bitplanes, 32 colours", "bitmap editor", "PNG / IFF import"],
            steps : [
                { title : "Bitplanes", text : "BITMAP DISPLAY shows a 320 x 256 picture with 32 colours. The Amiga keeps it as five bitplanes - each holds one bit of every pixel's colour number - and DMA reads them as the beam draws the screen." },
                { title : "Edit the picture", text : "Click EDIT BITMAP on the BITMAP DISPLAY node. The bitmap editor has pencil, line, circle, fill and gradient tools, 32 palette slots with 12-bit colour sliders, and imports PNG and IFF pictures. Esc closes it." },
                { title : "Run it", text : "F5: the sunset fills the screen. Repaint it, close the editor and press F5 again." }
            ]
        },
        {
            id : 13, title : "Hardware sprites", level : "Intermediate",
            summary : "A four-frame bird flaps across a moonlit bitmap: hardware sprites moved and animated by macros.",
            features : ["SPRITE BITMAP TEST", "MOVE SPR", "ANIM SPR", "SPR-EDIT", "sprite colours 17-19"],
            steps : [
                { title : "Sprites", text : "A hardware sprite is a 16 pixel wide picture the display chip draws over the bitmap by itself - no CPU drawing at all. SPRITE BITMAP TEST shows the night sky and puts the bird on sprite channel 0." },
                { title : "Sprite colours", text : "A sprite pixel is colour 1, 2 or 3 (0 is see-through). Sprite channels 0 and 1 take their colours from palette entries 17-19 of the bitmap, so the bird's orange lives in the bitmap's palette." },
                { title : "Move and animate", text : "MOVE SPR adds its X and Y speed every frame and wraps at the edges. ANIM SPR steps through frames START to END at RATE frames a second - frames count every sprite, in SPR-EDIT's order. Both use runtime ID 0, so they work on the same sprite." },
                { title : "Draw the frames", text : "Click EDIT FRAMES on ANIM SPR (or EDIT SPRITE on SPRITE BITMAP TEST): SPR-EDIT opens on Bird_0, and its < > step through the other frames." },
                { title : "Run it", text : "F5: the bird flaps across the sky above the hills." }
            ]
        },
        {
            id : 14, title : "BOBs: blitter objects", level : "Intermediate",
            summary : "A spaceship drawn into the bitmap by the Blitter, its background saved and put back every frame.",
            features : ["GET BITMAP BOB", "DRAW BOB", "REPLACE BITMAP BOB", "MOVE BOB", "ANIM BOB", "BOB editor"],
            steps : [
                { title : "BOBs", text : "A BOB (blitter object) is drawn into the bitmap itself by the Blitter, so it can be any size and use all 32 colours. The price: the program must put the background back before the BOB moves." },
                { title : "The loop", text : "GET BITMAP BOB opens the screen and prepares BOB 0. Every frame DRAW BOB saves the background under the ship and cuts the ship in; REPLACE BITMAP BOB waits for the next frame and puts that background back; MOVE BOB moves it on." },
                { title : "Animate", text : "ANIM BOB cycles the four ship frames - the engine flame flickers. Frames count every BOB in the BOB editor's order, and the frames of one animation must all be the same size." },
                { title : "Edit the ship", text : "Click EDIT BOB on DRAW BOB, or EDIT FRAMES on ANIM BOB: the BOB editor opens on that frame. It shares the bitmap's 32 colours." },
                { title : "Run it", text : "F5: the ship glides over the sunset and never leaves a trail." }
            ]
        },
        {
            id : 15, title : "Music and sound effects", level : "Intermediate",
            summary : "A song written in the TRACKER plays in the background; the fire button plays a sound effect over it.",
            features : ["TRACKER", "PLAY MOD", "PLAY SFX", "CODE: joystick fire", "SND-EDIT"],
            steps : [
                { title : "The tracker", text : "The song Chiptune (Pixel Hearts) was written in the TRACKER: four channels, 64 rows a pattern, built-in synth instruments - a lead with an echo channel, chord stabs, bass and drums. Click EDIT on PLAY MOD to open it - Enter plays a pattern, the Z-M and Q-P keys play notes, Esc saves and closes." },
                { title : "PLAY MOD", text : "PLAY MOD starts the music from its song position and it keeps playing by itself (ptplayer on a CIA timer interrupt) while the program runs. PLAY and STOP on the node preview it here." },
                { title : "Sound effects", text : "PLAY SFX plays the sample Zap on a free channel, mixed in with the music. Samples come from SND-EDIT (import WAV, IFF 8SVX or raw files) or from a tracker instrument with TO SAMPLE." },
                { title : "Fire!", text : "The CODE block Wait for fire waits for the joystick button (right Ctrl in FS-UAE) and flashes the background; Wait for release waits for it to be let go. BRA shoot repeats it for ever. STOP MUSIC would end the music and effects." },
                { title : "Run it", text : "F5, wait for the music to start, then press fire." }
            ]
        },
        {
            id : 16, title : "Write a tracker song", level : "Advanced",
            summary : "Build Pixel Hearts in the TRACKER layer by layer - drums, bass, hook, echo, chords - with SHOW ME at every step.",
            features : ["TRACKER", "drums + octave bass", "hook + echo channel", "vibrato, fades, cuts", "arpeggio chords", "SHOW ME"],
            steps : [
                { title : "The plan", song_stage : 1, hint : "Step 1: the kit (01-07) and 140 BPM. Write the hook in pattern 02 first.",
                  text : "You will write Pixel Hearts - the song of tutorials 10 and 15 - one layer at a time, hook first, the way classic Amiga musicians did. Each step says what to type. SHOW ME IN THE TRACKER rebuilds the song MySong to the end of that step and opens it, so you can copy it, compare or just listen: Enter plays the pattern, Space stops, Esc saves and closes." },
                { title : "Kit and tempo", song_stage : 1, hint : "Kit: 01 lead, 02 bass, 04 kick, 05 snare, 06 hat, 07 stab (SQUARE, VOL 22). BPM 140.",
                  text : "Click EDIT on the PLAY MOD node to open the TRACKER. A new song comes with a starter kit: 01 pulse lead, 02 synth bass, 04 kick, 05 snare, 06 hi-hat. Make 07 the chord stab: select it, click SQUARE, set VOL 22. Set BPM to 140. At speed 6 a row is a sixteenth note, so 4 rows are a beat, 16 rows a bar and a 64-row pattern four bars." },
                { title : "Drums", song_stage : 2, hint : "Drums, channel 4: kick 0, 8, 11 - snare 4, 12 - hats 2, 6, 10, 14 (+15 soft).",
                  text : "Chip style, one channel holds the whole kit (channel 4). Every hit is the note C-2. Kick (04) on rows 0 and 8 plus a syncopated kick on 11; snare (05) on 4 and 12 - the backbeat; hi-hats (06) on 2, 6, 10 and 14 and a ghost hat on 15. Type a volume in the effect column for accents: C40 full, C24 a hat, C0E the ghost. Repeat the bar four times. Enter plays it." },
                { title : "Octave bass", song_stage : 3, hint : "Bass, channel 3: every 2 rows, root then octave up. C G A F, one chord a bar.",
                  text : "Channel 3: the synth bass (02) on every eighth note (every 2 rows), bouncing between the root and the same note an octave up - the trick of Space Debris and Elysium. The chords are C, G, Am and F, one bar each. Low notes get C2E, high ones C20, so the bounce pulses." },
                { title : "The hook", song_stage : 4, hint : "Hook, channel 1: E E D C . D E | D B G . G A B, then the answer. Notes ring on!",
                  text : "Channel 1, instrument 01: the call - E E D C, D E, then D B G, G A B - and the answer over Am and F: C C B A, E D, C A C. Short repeats and small steps make a tune catchy. Now play it: the held notes ring on. The lead is a tiny looping wave, so a note sounds until something stops it." },
                { title : "Vibrato, fades and cuts", song_stage : 5, hint : "Fades: A08 on a note's last row, C00 after. Long notes: 4A2, 400, then 608.",
                  text : "Stop the ringing: on the last row of every note type A08 (volume slide down - a fade) and on the row after it C00 (volume 0 - a cut). Long notes get a light vibrato from their third row: 4A2 (speed A, depth 2 - fast and shallow), 400 to keep it going, and 608 on the last row (vibrato and fade together)." },
                { title : "The echo channel", song_stage : 6, hint : "Echo, channel 2: the lead 3 rows later at C10, fades A03, the same cuts.",
                  text : "Channel 2 plays the lead again three rows later at C10 - a quarter of the volume - with gentler fades (A03) and the same cuts. That is the echo trick of Elysium: one channel of delay makes the lead sound wide and twice as busy." },
                { title : "The answer pattern", song_stage : 7, hint : "Pattern 03: the same call, a climbing answer and a snare roll in the last bar.",
                  text : "Use COPY PATTERN, make a NEW pattern and PASTE: pattern 03 keeps the call but its answer climbs - C C B A, E G A, then G F E D - and the drums finish with a rising snare roll (snares on 58-63 with growing Cxx). Add 03 to the order list after 02." },
                { title : "The B section", song_stage : 8, hint : "B section 04-05: stabs 07 with 047 / 037 on channel 2, cut by C00.",
                  text : "Patterns 04 and 05 change the chords to F G Em Am and F G C G with longer, higher lead notes. Channel 2 now plays chord stabs: instrument 07 with arpeggio 047 (major) or 037 (minor) - one channel playing a whole chord - on rows 0, 3, 6, 10 and 12, each cut two rows later with C00. In 05 the lead slides up to B with 328 (tone portamento)." },
                { title : "Intro and order list", song_stage : 9, hint : "The whole song: 00 01 02 03 04 05 02 06, looping to the hook. Shift+Enter!",
                  text : "Pattern 00 builds up: stabs over hats, long bass notes, then kicks and a roll. 01 is the full groove with a pick-up into the hook, 06 the last hook over the stabs. The order list is 00 01 02 03 04 05 02 06, and the song loops back to the hook. Shift+Enter plays it all - that is Pixel Hearts." },
                { title : "Run it", text : "Esc saves MySong. PLAY on the PLAY MOD node previews it, F5 plays it on the Amiga. Then make it yours: change a note, a chord, the tempo or an instrument." }
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
