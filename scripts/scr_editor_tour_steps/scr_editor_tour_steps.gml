/// @desc Editor tour content: the demo workspace, the views a step can ask
/// for (scr_tour_show) and every category with its steps (scr_tour_categories).
/// Rectangles are functions so they follow the live UI (pan, scroll, panels
/// that compute their layout every frame).

/// Tutorial 10 (every Game Kit node + PLAY MOD) plus an ORG column with the
/// classic nodes: SETBKG, CPRBAR, a labelled opcode, a CODE block, PLAY SFX.
function scr_tour_build_demo() {
    scr_tutorial_reset_workspace();
    scr_tutorial_build(10);
    global.tutorial_current = -1;

    var _init = noone;
    with (obj_amiga_root_node) if (root_type == "INIT") _init = id;
    var _org = instance_create_layer(_init.node_x + 300, _init.node_y, "Instances", obj_amiga_root_node);
    _org.root_type = "ORG";
    _org.node_x = _init.node_x + 300;
    _org.node_y = _init.node_y;
    var _chain = { root : _org, y : _org.node_y + _org.node_height };
    var _bkg = scr_tb_macro(_chain, "SETBKG");
    _bkg.macro_asset_name = "05C";
    var _bar = scr_tb_macro(_chain, "COPPER_BAR");
    _bar.macro_cprbar_band_count = 8;
    var _sunset = ["014", "026", "238", "538", "947", "C64", "F93", "FD7"];
    var _b = 0;
    while (_b < 8) {
        _bar.macro_cprbar_bands[_b] = _sunset[_b];
        _b += 1;
    }
    var _move = scr_tb_op(_chain, "MOVE", "W", "#imm", $0F80, "abs.L", $DFF180);
    _move.node_label = "flash";
    var _code = scr_tb_macro(_chain, "CODE");
    _code.macro_code_text = scr_tb_raster_code_text();
    _code.macro_code_name = "Raster bar";
    var _sfx = scr_tb_macro(_chain, "PLAY_SFX");
    _sfx.macro_asset_name = "Pickup";

    global.pan_x = 0;
    global.pan_y = -80;             // the whole demo column clears the message log
    global.palette_scroll_y = 0;
    global.preview_scroll_y = 0;
    global.undo_stack = [];
    global.redo_stack = [];
    global.workspace_dirty = false;
    global.autosave_due_time = -1;
}

// ---------------------------------------------------------------------------
// Views.

/// Closes every editor and panel the tour may have opened.
function scr_tour_close_editors() {
    with (obj_tutorial_home) instance_destroy();
    scr_tour_close_view_editors();
}

/// Rectangle of a top-strip palette button (CPRBAR, CODE, ORG ...).
function scr_tour_palette_item_rect(_mnemonic) {
    var _rect = undefined;
    with (obj_opcode_palette_item) {
        if (palette_mnemonic == _mnemonic && _rect == undefined) _rect = [palette_x, palette_y, palette_x + palette_width, palette_y + palette_height];
    }
    return _rect;
}

/// The Game Kit block at the top of the opcode palette.
function scr_tour_palette_gk_rect() {
    var _rect = undefined;
    var _types = GK_NODE_TYPES;
    with (obj_opcode_palette_item) {
        if (array_contains(_types, palette_mnemonic)) _rect = scr_tour_rect_union(_rect, [palette_x, palette_y, palette_x + palette_width, palette_y + palette_height]);
    }
    return _rect;
}

function scr_tour_preview_rect() {
    return [room_width - 360, 72, room_width - 10, room_height - 2];
}

// ---------------------------------------------------------------------------
// Categories.

function scr_tour_categories() {
    if (is_array(global.tour_categories_cache)) return global.tour_categories_cache;

    var _categories = [];

    array_push(_categories, {
        id : "layout", title : "The screen at a glance",
        summary : "Where everything is: toolbar, opcode palette, workspace, code preview and messages.",
        steps : [
            { title : "Welcome", show : "main", rect : undefined,
              text : "Amiga Dev Machine builds real Amiga programs from blocks. You stack instructions and ready-made macros into columns, press F5, and ADM assembles them, writes a bootable floppy and starts it in the FS-UAE emulator. This tour shows a demo project; your own work comes back when it ends." },
            { title : "The toolbar", show : "main", rect : function() { return [4, 0, 1826, 64]; },
              text : "Across the top: system and file buttons, test programs, the macro buttons (drag one into the workspace), the editors, the machine and run controls, and the Game Kit column. The 'Toolbar' category goes through every button." },
            { title : "The opcode palette", show : "main", rect : function() { return [4, 76, 266, 1076]; },
              text : "Every 68000 instruction, plus the Game Kit nodes in orange at the top. Click one and drag it into the workspace to make a node. The mouse wheel scrolls the list." },
            { title : "The workspace", show : "main", rect : function() { return [300, 64, 1552, 950]; },
              text : "Your program lives here as columns of nodes. INIT is where the program starts; the nodes under it run from top to bottom. Hold Space or the middle mouse button and move the mouse to pan around." },
            { title : "The compiled program", show : "main", rect : function() { return scr_tour_preview_rect(); },
              text : "The assembly ADM will feed to the assembler, rebuilt live as you edit. Click a macro's header line to expand or collapse its code; the wheel or the scrollbar scrolls." },
            { title : "Messages and help", show : "main", rect : function() { return [272, 850, 1552, 1080]; },
              text : "Hovering a node or a palette entry explains it here. Below, the message log shows what happened last: builds, errors, saves." }
        ]
    });

    array_push(_categories, {
        id : "toolbar", title : "The toolbar",
        summary : "Every top-strip button: files, tests, macros, audio and code, editors, machine, run and Game Kit.",
        steps : [
            { title : "QUIT and KILL FSUAE", show : "main", rect : function() { return [10, 20, 110, 60]; },
              text : "QUIT closes ADM (it asks first when there are unsaved changes; Esc does the same). KILL FSUAE closes the emulator if it is still open." },
            { title : "Load and save", show : "main", rect : function() { return [114, 20, 264, 60]; },
              text : "LOAD WORKSPACE and SAVE WORKSPACE read and write a whole project - nodes, graphics, maps and sounds - as one JSON file. ADM also autosaves a recovery copy a few seconds after every change." },
            { title : "Test programs", show : "main", rect : function() { return [310, 20, 514, 60]; },
              text : "Ready-made test setups that load a small program into the workspace: a basic setup, a sprite test, and BOB / sprite bitmap tests. Handy to see a feature working before building your own." },
            { title : "Macros", show : "main", rect : function() { return [530, 20, 818, 64]; },
              text : "Macros are nodes that write many instructions for you. CPRBAR makes a Copper colour gradient, SETBKG sets the background colour, MOVE / ANIM BOB and SPR move and animate graphic objects. Drag a button into the workspace. Nodes that use a picture, sprite, BOB or map have an EDIT button that opens it in its editor; tutorial 11 explains macros step by step." },
            { title : "Audio and CODE", show : "main", rect : function() { return [842, 20, 1046, 64]; },
              text : "PLAY MOD starts music, STOP MUSIC stops it and all effects, PLAY SFX plays a sound sample. CODE BLOCK is a node you fill with your own assembly in a full code editor." },
            { title : "Editors", show : "main", rect : function() { return [1062, 20, 1386, 62]; },
              text : "SPR-EDIT draws hardware sprites, BMP-EDIT draws bitmaps, BOB-EDIT cuts BOBs (blitter objects) from them, SND-EDIT imports music and sound effects and TRACKER (under ORG) composes music. Each has its own category in this tour." },
            { title : "ORG", show : "main", rect : function() { return scr_tour_palette_item_rect("ORG"); },
              text : "ORG starts a new column. Code in an ORG column continues on from the column to its left, so long programs can be laid out side by side. The O key drops one at the mouse." },
            { title : "Machine and run", show : "main", rect : function() { return [1398, 2, 1602, 60]; },
              text : "MACH switches between an A600 (68000, 1 MB chip RAM) and an A1200 (68020, AGA, 2 MB). RUN (or F5) builds and boots the program. ROM picks a Kickstart ROM file (right-click: back to the free AROS ROM). BOOT chooses the auto-boot floppy or a DOS disk." },
            { title : "Game Kit, tutorials and tour", show : "main", rect : function() { return [1618, 2, 1826, 60]; },
              text : "TILE-EDIT opens the tile, map and animation editor for the Game Kit, TUTORIALS opens the tutorials page, TOUR (F1) starts this walkthrough, and WINDOWED / FULL SCREEN (F11) switches between a resizable window and full screen." }
        ]
    });

    array_push(_categories, {
        id : "palette", title : "The opcode palette",
        summary : "Making nodes: Game Kit nodes, 68000 instructions, scrolling and hover help.",
        steps : [
            { title : "Game Kit nodes", show : "main", rect : function() { return scr_tour_palette_gk_rect(); },
              text : "The orange entries are the Game Kit: whole game building blocks - a game screen, a tile map, a player, joystick, physics, enemies and sprite drawing. Tutorials 5 to 10 build a platformer from them." },
            { title : "68000 instructions", show : "main", rect : function() { return [4, 176, 266, 900]; },
              text : "Below them, every 68000 instruction in alphabetical order. Drag one into a column to make an instruction node; then set its size and operands on the node itself." },
            { title : "Scroll and hover", show : "main", rect : function() { return [4, 76, 266, 1076]; },
              text : "The mouse wheel over the palette scrolls the list. Type the first one or two letters of an instruction to light up the matches (a third letter starts again). Hover an instruction to read what it does, its sizes and its addressing modes in the help box at the bottom." }
        ]
    });

    array_push(_categories, {
        id : "nodes", title : "Nodes and the program graph",
        summary : "Columns, instruction nodes, operands, labels, connecting, moving, cloning and deleting.",
        steps : [
            { title : "INIT: where the program starts", show : "main", rect : function() { return scr_tour_root_rect("INIT"); },
              text : "INIT is the start of your program. Clicking it builds and runs, like F5. Everything connected under it runs from top to bottom: order is simply position." },
            { title : "A column", show : "main", rect : function() { return scr_tour_column_rect("INIT"); },
              text : "This column is the complete platformer from tutorial 10: music, the Game Kit set-up, then a game loop that ends with BRA jumping back up. An Amiga program never ends, so every program has such a loop." },
            { title : "ORG columns", show : "main", rect : function() { return scr_tour_column_rect("ORG"); },
              text : "An ORG column continues the program from the column to its left. Drag ORG's body to move the whole column; a red 'not connected' means there is no column to its left." },
            { title : "An instruction node", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("MOVE", true)); },
              text : "An instruction node: the header shows the instruction and its size (.B, .W or .L). Drag the header to move it. Hover it: the help box says what it does with its values in plain English, explains each addressing mode and names any hardware register it writes." },
            { title : "Addressing modes", show : "main", rect : function() { var _n = scr_tour_find_node("MOVE", true); var _r = scr_tour_node_rect(_n, 20, 58); if (_r != undefined) _r[2] = _r[0] + _n.node_width - _n.value_box_width; return _r; },
              text : "The left part of each operand row is its addressing mode - Dn, An, (An), #imm, abs.L, a label ... Click it to cycle through the modes the instruction allows." },
            { title : "Operand values", show : "main", rect : function() { var _n = scr_tour_find_node("MOVE", true); var _r = scr_tour_node_rect(_n, 20, 58); if (_r != undefined) _r[0] = _r[2] - _n.value_box_width; return _r; },
              text : "The right part is the value: a register number, a constant or an address. Click it and type; Enter accepts, Esc cancels. H switches every value between hex and decimal." },
            { title : "Validity dots", show : "main", rect : function() { var _n = scr_tour_find_node("MOVE", true); var _r = scr_tour_node_rect(_n); if (_r == undefined) return undefined; return [_r[0] - 20, _r[1] + 22, _r[0] - 4, _r[1] + 58]; },
              text : "Green dots mean each operand is valid for this instruction; red means the combination is not allowed (or a macro's asset is missing). Fix every red dot before building." },
            { title : "Labels", show : "main", rect : function() { var _n = scr_tour_find_node("MOVE", true); var _r = scr_tour_node_rect(_n); if (_r == undefined) return undefined; return [_r[0] - 86, _r[1] - 2, _r[0] - 2, _r[1] + 22]; },
              text : "The box left of a node is its label - a name that branches (BRA, BNE, DBF ...) jump to. Click left of any node (or Alt+click its header) to type one: letters, digits and _." },
            { title : "Connecting and moving", show : "main", rect : function() { return scr_tour_column_rect("ORG"); },
              text : "Drag a node near a column: a gap opens where it will go and a yellow outline confirms it. Drop it to insert; drag it out to detach (the column closes up). Ctrl+drag a header to copy a node." },
            { title : "Deleting, undo and keys", show : "main", rect : function() { return [300, 64, 1552, 950]; },
              text : "Right-click a node twice within a second to delete it. Ctrl+Z undoes, Ctrl+Y redoes (hold Ctrl to see how many steps are left). Space or the middle mouse button pans; Ctrl+S / Ctrl+L quick-save and quick-load the layout." }
        ]
    });

    array_push(_categories, {
        id : "macros", title : "Macro, audio and CODE nodes",
        summary : "SETBKG, the Copper bar, CODE blocks, PLAY SFX and PLAY MOD on the node itself.",
        steps : [
            { title : "SETBKG", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("SETBKG")); },
              text : "SETBKG sets the background colour (COLOR00). Click its RGB row to pick a colour with the colour picker." },
            { title : "Copper bar", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("COPPER_BAR")); },
              text : "CPRBAR makes the Copper change a colour on chosen screen lines - gradients and bars for free. EDIT COLOURS opens its editor; the line below summarises the bands." },
            { title : "CODE block", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("CODE")); },
              text : "A CODE block holds your own assembly. EDIT CODE (or a double-click on the code) opens the code editor; the first lines are shown on the node. Assembler errors outline the node in red." },
            { title : "PLAY SFX", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("PLAY_SFX")); },
              text : "PLAY SFX plays a sample. The < and > ends of the first row choose the sample and the middle plays it here; the next rows pick the Paula channel (AUTO lets the player choose) and the volume." },
            { title : "PLAY MOD", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("PLAY_MOD")); },
              text : "PLAY MOD starts a ProTracker module (music keeps playing while your program runs). Choose the module with < and > and the song position to start from. PLAY and STOP preview it; EDIT opens it in the TRACKER (or starts a new song for this node)." }
        ]
    });

    array_push(_categories, {
        id : "gamekit_nodes", title : "Game Kit nodes",
        summary : "The platformer building blocks and the settings on each node.",
        steps : [
            { title : "Set-up", show : "main", rect : function() { return scr_tour_rect_union(scr_tour_node_rect(scr_tour_find_node("GK_SCREEN")), scr_tour_node_rect(scr_tour_find_node("GK_PLAYER"))); },
              text : "GAME SCREEN takes over the display (320 x 256, 16 colours, sprites), DRAW MAP draws the first room of a tile map and PLAYER puts the hero at the map's start point. The < > row on MAP and PLAYER chooses which map or hero; their EDIT MAP / EDIT HERO row opens it in TILE-EDIT." },
            { title : "The game loop", show : "main", rect : function() { return scr_tour_rect_union(scr_tour_node_rect(scr_tour_find_node("GK_WAIT")), scr_tour_node_rect(scr_tour_find_node("BRA", true))); },
              text : "Every frame: WAIT FRAME syncs to the 50 Hz display, READ JOYSTICK, PHYSICS, TILE EVENTS, ENEMIES, ANIMATE and DRAW SPRITES, then BRA jumps back to the labelled WAIT FRAME." },
            { title : "PHYSICS settings", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("GK_PHYSICS")); },
              text : "Run speed, jump power, gravity and the jump sound. Click the left half of a row to lower a value, the right half to raise it." },
            { title : "TILE EVENTS settings", show : "main", rect : function() { return scr_tour_node_rect(scr_tour_find_node("GK_EVENTS")); },
              text : "The pickup and hurt sounds, and whether the exit door needs every pickup collected first. Tiles get their behaviour (solid, platform, hazard, pickup, exit) in TILE-EDIT." }
        ]
    });

    array_push(_categories, {
        id : "build", title : "Build and run",
        summary : "F5, the emulator, the machine settings, the code preview and build errors.",
        steps : [
            { title : "RUN (F5)", show : "main", rect : function() { return scr_tour_toolbar_rect(obj_amiga_manager.top_ui_machine_x, obj_amiga_manager.top_ui_row_2_y); },
              text : "F5 (or RUN, or clicking INIT) assembles the program with vasm, writes an auto-boot floppy and boots it in FS-UAE - no Workbench, nothing to type. The button shows BUILDING.. while it works." },
            { title : "Machine and ROM", show : "main", rect : function() { return [obj_amiga_manager.top_ui_machine_x, obj_amiga_manager.top_ui_row_1_y, obj_amiga_manager.top_ui_machine_2_x + obj_amiga_manager.top_ui_button_width, obj_amiga_manager.top_ui_row_1_y + obj_amiga_manager.top_ui_button_height]; },
              text : "MACH chooses the Amiga to build for: A600 (68000, OCS) or A1200 (68020, AGA). ROM uses the free AROS ROM unless you pick a real Kickstart file for that machine." },
            { title : "Boot mode", show : "main", rect : function() { return scr_tour_toolbar_rect(obj_amiga_manager.top_ui_machine_2_x, obj_amiga_manager.top_ui_row_2_y); },
              text : "AUTO writes a self-booting floppy that runs on any ROM. DOS writes a normal AmigaDOS disk with a Startup-Sequence that you can also open on Workbench (it needs a real Kickstart to start by itself)." },
            { title : "The compiled program", show : "main", rect : function() { return scr_tour_preview_rect(); },
              text : "This is exactly what is assembled. When vasm finds a problem, the node that produced the line is outlined in red; hover it for the message. In a CODE block the faulty line itself is marked." },
            { title : "Messages", show : "main", rect : function() { return [272, 958, 1552, 1080]; },
              text : "The log shows each build step: assembled size, disk written, emulator started - or what went wrong and where the full vasm log is." },
            { title : "The emulator", show : "main", rect : function() { return [10, 44, 110, 60]; },
              text : "In FS-UAE the cursor keys and right Ctrl are the joystick in port 2. A new build closes the old emulator first; KILL FSUAE closes it any time." }
        ]
    });

    // Editor categories (scr_editor_tour_steps_editors).
    var _editors = scr_tour_editor_categories();
    var _e = 0;
    while (_e < array_length(_editors)) {
        array_push(_categories, _editors[_e]);
        _e += 1;
    }

    array_push(_categories, {
        id : "help", title : "Tutorials and this tour",
        summary : "The tutorials page, the step guide and how to come back to this tour.",
        steps : [
            { title : "The tutorials page", show : "home", rect : function() { return scr_tour_home_rect("cards"); },
              text : "Sixteen tutorials: from a one-node program to a complete platformer, then how macros work, bitmaps, sprites, BOBs, music and sound, and writing a whole song in the tracker. Click a card to load it: the nodes and every asset are made for you, ready for F5." },
            { title : "Getting started", show : "home", rect : function() { return scr_tour_home_rect("start"); },
              text : "The page opens at start-up: carry on with your last session, start an empty workspace, open a saved one, or take this tour. Untick 'Show this page at startup' to go straight to the workspace; TUTORIALS on the toolbar brings it back." },
            { title : "The step guide", show : "guide", rect : function() { return scr_tour_guide_rect(); },
              text : "With a tutorial loaded, its steps appear in this panel over the code preview. NEXT / PREV walk through them, the nodes each step talks about pulse, BUILD & RUN tries it, and the bar collapses to a small tab." },
            { title : "Coming back here", show : "main", rect : function() { return [obj_amiga_manager.top_ui_tutorial_x + obj_amiga_manager.top_ui_button_width + 4, obj_amiga_manager.top_ui_row_1_y, obj_amiga_manager.top_ui_tutorial_x + 2 * obj_amiga_manager.top_ui_button_width + 4, obj_amiga_manager.top_ui_row_1_y + obj_amiga_manager.top_ui_button_height]; },
              text : "TOUR (or F1) opens this tour again. Pick any categories, or all of them; NEXT / PREV or the arrow keys step, SKIP CATEGORY (Tab) jumps on, and AUTO (A) plays it by itself with the delay you set (+ / -)." }
        ]
    });

    global.tour_categories_cache = _categories;
    return _categories;
}
