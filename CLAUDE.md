# Amiga Dev Machine — Claude Code guide

Amiga Dev Machine (ADM) is a node-based 68000 assembler editor for the Amiga, written in
GameMaker (GML, IDE 2026.0 LTS) by Bob / Polytricity Ltd. Users stack opcode and macro nodes
under an INIT root (and continuing ORG roots), press F5, and ADM writes `main.s`, assembles it
with vasm, writes a bootable ADF and boots it in the bundled FS-UAE. It is a separate product
from ADAM (`D:/POLYTRICITY/ADAM`, the no-code game maker), which shares its auto-boot and
ptplayer approach.

## Conventions (follow the surrounding code)

- K&R braces, 4-space indent, `_underscore` locals, `global.` for shared state. Ternaries are fine here (unlike ADAM).
- Initialise every instance variable in Create; new node fields go in `obj_opcode_node/Create_0.gml`.
- All drawing is in the normal Draw event in room coordinates (room 1920x1080, no views); `obj_opcode_node/Draw_64` is the only GUI-layer drawing.
- Status messages: `scr_set_status_message(text, colour)`. Unsaved changes: `scr_mark_workspace_dirty()`. Graph undo: `scr_push_undo_snapshot()` before a change.
- One feature per commit, clear message. Bob reviews diffs.

## UI style (scr_ui_style)

- Buttons, fields, tabs, panels, cards, node bodies: `scr_ui_box` / `scr_ui_box_fill` / `scr_ui_box_outline` / `scr_ui_button` - top-left and bottom-right corners cut at 45 degrees (30% of the shorter side, max 14 px) and a slight diagonal tone (darker bottom-left, lighter top-right). Keep plain rectangles for data: pixel grids, canvases, swatches, map / tile views, waveforms, the code text area, slider cells, scrollbar tracks, dim overlays.
- Fonts by role: `UI_FONT` (tool text), `UI_FONT_SMALL` (nodes, palette, toolbar labels), `UI_FONT_TITLE` (headings), `UI_FONT_GUIDE` (smaller FutureNow body text of the walkthrough panels: opening page, step guide, tour). **Every Draw event sets its font first** - draw state is global, so an event that doesn't inherits the last object's font.
- Centre button labels with `scr_ui_button` / `scr_ui_text_centred`; vertically centre row labels with `scr_ui_text_mid`; `scr_ui_fit_label` shortens text to a width; `scr_ui_header_band` fills a header strip that follows the box's cut.
- Shared drawing helpers elsewhere: `scr_node_row` (+ `NODE_ROW_INSET_L/R`, `NODE_TEXT_PAD`) in `scr_gk_node_ui` draws the inset field rows of every node; `scr_te_rect_in_bevel` (in `scr_tile_editor`) clips square selection rows / scroll thumbs so they stay inside a bevelled list box; `scr_tutorial_ui_draw_panel` / `_draw_badge` / `_draw_checkbox` / `_button_h` for the walkthrough panels; `scr_bitmap_editor_button` / `_contrast` for the bitmap editor.
- Geometry is shared between Step (hit tests), Draw and the tour's rectangle helpers (`scr_editor_tour_editors`): layout functions (`scr_sprite_editor_layout`, `scr_bitmap_editor_layout`, the code editor's `ed_layout`, tile editor `te_controls` / `te_lists` / `te_grids`, audio `audio_editor_controls`) or Create variables (BOB editor `column_x_offset` / `button_step` ..., copper bar and colour picker positions). Move a control in one place only through those, and re-check the tour.
- Check layouts with `-admtour`: it saves an in-game screenshot of every screen and editor to `<data>/tour_shots/` (3840x2160). Never check layouts with desktop screenshots.

## Build and check

- **Compile with Igor** (zero errors required). Runtime `C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23`, user dir from `%APPDATA%\GameMakerStudio2-LTS2026\<name>_<id>`:
  `Igor.exe -j=8 --project=AMIGA_DEV_MACHINE.yyp --user=<user dir> --runtimePath=<rt> --temp=<tmp> --cache=<cache> --of=<out>\ADM.win --tf=<out>\ADM.zip --runtime=VM -- Windows PackageZip`
  The log is UTF-16. `--tf` is required or packaging fails after a successful compile.
- **Igor does not report calls to undefined functions or unknown object names** (they become runtime errors). After adding code, grep every `scr_*(` / `obj_*` you reference against `function` definitions and `objects/`.
- **End-to-end self test** (no clicking needed): run the built exe with
  `-admselftest "C:\path\song.mod"` — runs `scr_asm_lang_selftest` and `scr_audio_selftest`, imports the MOD, builds PLAY MOD + PLAY SFX + two CODE blocks, presses F5 for real and writes `%LOCALAPPDATA%\AmigaDevMachine\selftest_result.txt` (RESULT: PASS/FAIL), then quits. FS-UAE shows a green screen while Paula audio DMA runs (music playing). `-admselftesterr` instead plants an error on line 3 of a CODE block and checks it is mapped back to that line. The self test autosaves to its own file, never the user's recovery file.
- The self test also runs `scr_tile_editor_selftest`. **Tutorial self test:** `-admtutorials` loads and builds all ten tutorials (no emulator: `global.build_skip_launch`) and checks vasm + the disk writer for each; `-admtutorial N` builds tutorial N and boots it in FS-UAE. **Tour self test:** `-admtour` walks all tour steps (screenshot of each to `<data>/tour_shots/`), checks auto-play and that the user's workspace is restored. Same result file. Run `-admtour`, `-admtutorials` and `-admselftest` before merging UI or build changes.
- **Disk without GameMaker:** `powershell -File tools\make_adf.ps1 -Hunk main.bin -Out test.adf [-Run] [-Model A1200]` (same writer as `scr_amiga_write_boot_adf`).
- The machine/ROM/boot settings live in `%LOCALAPPDATA%\AMIGA_DEV_MACHINE\settings.ini` (`[machine] model`, `boot_mode`, `[paths] kickstart_a600/a1200`). Build output: `%LOCALAPPDATA%\AmigaDevMachine\build_output\build\` (`main.s`, `vasm.log`, `main.bin`, `disk.adf`).

## Architecture

| Piece | Role |
|---|---|
| `obj_amiga_manager` | Bootstrap (Create), toolbar (`top_ui_*` columns: SYSTEM, workspace, TEST MACROS, MACROS, AUDIO / CODE, EDITORS, ORG, AMIGA machine / RUN, GAME KIT = TILE-EDIT / TOUR (F1) / TUTORIALS), palette scroll, preview panel, the SPR-EDIT sprite editor panel (`global.sprite_editor_open`, geometry in `scr_sprite_editor_layout`), build state machine (Step), opening page at startup, Esc-to-quit guard (KeyPress_27). |
| `obj_flashSplash` | Start-up logo fade; afterwards it draws the small logo, copyright, version and FPS in the footer of the preview panel. |
| `obj_opcode_node` / `obj_amiga_root_node` | Program nodes and INIT/ORG roots. Program order = Y position under a root (`scr_amiga_collect_program_nodes`). |
| `obj_opcode_palette_item` | Opcode palette (Game Kit nodes first, then the 68000 opcodes) and the top-strip macro buttons (`palette_top_strip = true`: sized like the other toolbar buttons, not scrolled); dropping one creates a node. |
| `scr_emit_opcode_line` → `scr_emit_macro_line` | Node → assembler text `{ text, is_valid }`. |
| `scr_amiga_trigger_build` → `scr_amiga_start_build` | F5 / RUN / INIT click / F5 in the code editor. |
| Modal editors | `obj_bitmap_editor`, `obj_bob_editor`, `obj_colour_picker`, `obj_cprbar_editor`, `obj_code_editor`, `obj_audio_editor`, `obj_tile_editor`, `obj_tutorial_home`, `obj_editor_tour`. **Always test with `scr_amiga_modal_open()`** — add any new modal object there, and give it the editor-tour guard (see Editor tour). |
| Persistence | Node fields must be added to `scr_capture_snapshot`, `scr_node_restore_extra_fields` (in `scr_restore_snapshot`), `scr_save_workspace_to_path`, `scr_clone_opcode_node`. `global.asset_list` is saved whole with `json_stringify`, so assets must be plain JSON data. |
| `scr_macro_node_defaults` | `scr_macro_node_height(type)` (palette + load use it), `scr_macro_node_init` for audio/CODE nodes. |

### Build pipeline (F5)

1. `scr_amiga_start_build` writes `main.s`: `SECTION code,CODE`, the hardware equates (only if a CODE block exists), every node, then the runtime footer (`scr_amiga_build_runtime`). It records a **line map** (main.s line → node, and CODE-block line) for error reporting. Every program is a Hunk executable: `vasm -Fhunkexe -kick1hunks -nosym -m68000` (A600) or `-m68020` (A1200).
2. vasm runs inside `build_asm.bat` (launched with native backslash paths) which captures `vasm.log` and writes `asm.done` (`exit N`).
3. The manager polls `asm.done` (this state machine runs **above** the modal-editor `exit`, so builds started inside the code editor progress), then `scr_amiga_vasm_report` maps errors to nodes (`build_error_text` → red outline + hover message) and to CODE lines (`global.code_editor_build_errors` = `{ node_uid, line (0-based), message }`).
4. On success: close FS-UAE, wait ~20 frames, write the disk, launch.

### Auto-boot disks (ADAM-style)

- `datafiles/boot/hunkboot.s` → `hunkboot.bin` (assemble: `vasmm68k_mot -Fbin -pic -m68000 -o hunkboot.bin hunkboot.s`). A trackdisk bootblock: streams the Hunk file through a 512-byte buffer, allocates every hunk in **chip RAM, cleared** (MEMF_REVERSE on V36+), applies HUNK_RELOC32, skips SYMBOL/DEBUG, jumps to hunk 0 with `a6` = ExecBase, `a1` = IORequest. Needs only the program's size in chip RAM. Solid red screen on any failure.
- It AllocAbs-reserves `$20000`–`$6FFFF` first (best effort), because macros poke fixed chip addresses there (copper lists, sprite data at `$40000`, test bitplanes).
- `scr_amiga_boot_adf` writes `[bootblock][main.bin]` raw into a 901120-byte ADF, patches `readsize` / `resv_addr` / `resv_size` after the `"ADMB"` tag, fixes the checksum. No xdftool. Max program ≈ 879 KB.
- **BOOT: DOS** mode (toolbar) keeps the old xdftool OFS disk + `S/Startup-Sequence` path (`scr_amiga_start_adf_build`); it only auto-runs with a real Kickstart.
- Boot time in FS-UAE: ~10 s small programs, ~30 s with a 300 KB MOD.

### FS-UAE launch (`scr_amiga_fsuae`)

- Machines: **A600** (OCS/ECS, 1 MB chip, 68000) and **A1200** (AGA, 2 MB chip, 68020); `global.current_chipset_mode` follows the machine. Toolbar: MACH, RUN (F5), ROM (left click choose Kickstart for this machine, right click back to AROS), BOOT (AUTO/DOS).
- Args mirror ADAM's: `--amiga_model`, `--chip_memory`, no fast/slow RAM, `--floppy_drive_speed=0`, no input grab, joystick port 1 keyboard (or `auto` gamepad), `--kickstart_file=""` = AROS, private `--base_dir` under `%LOCALAPPDATA%\AmigaDevMachine\fs-uae-data`.

### Music and sound effects

- Assets in `global.asset_list` (look up by name, never keep struct references):
  - `SAMPLE { name, data_b64 (signed 8-bit), length (even, ≤131070), period, volume 0-64, loop, loop_start, loop_length, source_name }`
  - `MOD { name, data_b64 (original file), length, title, positions, patterns, samples_used, source_name }` — 4-channel only (M.K., M!K!, FLT4, 4CHN).
- Scripts: `scr_audio_core` (init, define/list/rename/delete, base64, period/note helpers), `scr_audio_import` (MOD, WAV 8/16/24/32-bit + float, IFF 8SVX, raw), `scr_audio_player` (GML ProTracker player ported from ADAM's `scr_music`, preview), `scr_audio_sample_ops`, `scr_audio_selftest`. `scr_audio_init()` is called in the manager Create. `obj_audio_service` (persistent, created lazily) runs preview Step + Async Audio Playback. `obj_audio_editor` = SND-EDIT.
- Nodes: **PLAY_MOD** (asset + song position), **STOP_MOD** ("STOP MUSIC": music and all effects), **PLAY_SFX** (asset, channel AUTO/0-3, volume SAMPLE/0-64). Node rows: `<`/`>` ends cycle assets, the middle third previews.
- Runtime (footer): `__adm_audio_init` installs ptplayer once (VBR via `Supervisor` on 68010+, PAL flag from `VBlankFrequency`) and turns the INTENA master back on, so music survives macros that write INTENA `$7FFF`. Then `INCLUDE datafiles/audio/ptplayer.asm` (Frank Wille, public domain, `end` commented out), and a `DATA_C` section with `INCBIN`ed MODs (`__mod_<name>`), samples (`__smp_<name>`, each preceded by a zero word; looped ones also `__smpl_<name>` = the loop part only, played with `_mt_loopfx`) and one SfxStructure per PLAY_SFX node (`__sfxnode_<uid>`). Asset files are written to `build/assets/`.
- **ptplayer defines its own EQUs (`CUSTOM`, `DMACON`, `INTENA`, `CIAB`, …).** When audio is used, `scr_amiga_build_header_text` drops those names from the hardware equates (`scr_amiga_ptplayer_equ_names`), or vasm reports duplicate symbols.

### CODE blocks

- Node `macro_type "CODE"`, text in `macro_code_text`. EDIT CODE button or double-click opens `scr_code_editor_open(node)` → `obj_code_editor` (full-screen modal; commits on Esc / Ctrl+Enter / CLOSE, pushes one undo snapshot if changed; F5 commits and builds with the editor open; Ctrl+S commits).
- `scr_asm_lang`: 68000 mnemonics (all condition families), vasm directives, registers, custom-chip/CIA register **offsets** + `CUSTOM`/`CIAA`/`CIAB`, exec/graphics `_LVO*`, `MEMF_*`/`DMAF_*`/`INTF_*`. Public: `scr_asm_tokenize_line`, `scr_asm_validate(text, external_symbols)` (cached; never blocks a build — vasm is the judge), `scr_asm_collect_labels`, `scr_asm_normalise_for_emit` (indents column-1 mnemonics; vasm reads column-1 words as labels), `scr_asm_hardware_equates_text`, `scr_asm_global_symbols`, `scr_asm_completions`, `scr_asm_symbol_help`, `scr_asm_lang_selftest`.
- Editor: Consolas (falls back to Courier New, Lucida Console, then fixed cells), syntax colours, live diagnostics (12 frames after the last edit) + vasm build errors, autocomplete (Ctrl+Space), hover help, find/replace (Ctrl+F/H), go to line (Ctrl+G), go to definition (F12 / Ctrl+click), next problem (F8), comment toggle (Ctrl+/), duplicate (Ctrl+D), move lines (Alt+Up/Down), delete line (Ctrl+Shift+K), font size (Ctrl+= / - / 0 / wheel), snippet buttons (VBL WAIT, BLIT WAIT, TAKE SYSTEM, COPPER LIST, MAIN LOOP, JOYSTICK).
- Hardware symbols are case-sensitive in vasm (`DMACON`, not `dmacon`).
- `scr_amiga_has_core_loop` accepts a CODE block containing an unconditional `BRA`/`JMP` as the program's core loop.

### Game Kit (platformer runtime)

- Data model `scr_gamekit_assets` (assets in `global.asset_list`, plain JSON): **TILESET** (8/16/24/32 px tiles, 16-colour palette, flags `GK_FLAG_SOLID/PLATFORM/HAZARD/COLLECT/EXIT`, metatiles up to 128x128 px), **TILEMAP** (each room is one screen = `320 div size` x `256 div size` tiles, up to 8x8 rooms, spawn point, ≤6 enemies per room), **ANIMSET** (idle/run/jump/fall, each a list of 16 px wide SPRITE asset names + rate). Validation: `scr_gk_map_problem`, `scr_gk_animset_problem`.
- Ten node types (`GK_NODE_TYPES` in `scr_gamekit_emit`): GAME SCREEN, DRAW MAP, PLAYER, WAIT FRAME, READ JOYSTICK, PHYSICS, TILE EVENTS, ENEMIES, ANIMATE, DRAW SPRITES. Each emits `MOVEM` save → params → `JSR gk_*` → restore. Generic node fields `macro_param_a/b/c`, `macro_param_text_a/b` (meaning per node: see the file header). Row input, drawing and hover help: `scr_gk_node_ui`.
- Runtime `datafiles/gamekit/gamekit.s`, INCLUDEd once by the footer (`SECTION adm_gamekit,CODE`); baked data goes in `adm_gkdata,DATA_C` as `__gkmap_` / `__gkts_` / `__gkanim_` / `__gksfx_<uid>_<a|b>`. 320x256, 4 planes, its own copper list, 8 sprite buffers; hero = sprite 0 (left-facing frames mirrored at bake time), enemies = sprites 2-7. Positions are room-local; the hero's are in 1/16 px. `gk_screen` turns OS interrupts off but keeps EXTER, so ptplayer music keeps playing; `GK_AUDIO` is defined when sound is used. The data layouts are documented at the top of `gamekit.s`: keep the bake functions in step with them.
- Typical graph: SCREEN, MAP, PLAYER, then `WAIT FRAME` (labelled), INPUT, PHYSICS, EVENTS, ENEMIES, ANIMATE, DRAW SPRITES, `BRA label`.
- **TILE-EDIT** (`scr_tile_editor_open` → `obj_tile_editor`, helpers `scr_te_*` in `scr_tile_editor`): Tiles / Metatiles / Map / Animations tabs. Renames carry through to maps, enemies and DRAW MAP / PLAYER nodes.

### Tutorials

- `scr_tutorials`: `scr_tutorial_defs()` (ten tutorials: id, title, level, summary, features, steps), `scr_tutorial_load(i)`, `scr_tutorial_reset_workspace()`. `scr_tutorial_builders`: `scr_tutorial_build(n)` builds each node graph and **generates every asset** (tile art at any size via `scr_tb_tile_colour`, metatiles, maps, hero and slime with 4 frames per state, a 2-pattern M.K. tune and three sfx for tutorial 10).
- UI (`scr_tutorial_ui`): `obj_tutorial_home` is the opening page, shown after the splash unless switched off (`[ui] show_home` in settings.ini). Its CONTINUE LAST SESSION replaces the old automatic recovery. `obj_tutorial_guide` is the step panel over the preview; it highlights nodes named in capitals. The workspace and preview ignore clicks under it (`scr_tutorial_guide_mouse_over()`). Done flags: `[tutorials] done_<id>`. Toolbar: GAME KIT column (TILE-EDIT, TUTORIALS). Loading any workspace sets `global.tutorial_current = -1`, which closes the guide.

### Editor tour

- `obj_editor_tour` (depth -900000), opened by TOUR / F1 / EDITOR TOUR on the opening page (`scr_tour_open`). A category picker (16 categories, ALL / NONE, auto-play delay `[tour] delay` in settings.ini), then steps with PREV / NEXT / SKIP CATEGORY / AUTO / END TOUR (keys: arrows, Space, Tab, A, + / -, Esc).
- It runs on a demo workspace (`scr_tour_build_demo`: tutorial 10 plus an ORG column of classic nodes). `scr_tour_stash_workspace` saves the user's work to `tour_stash_workspace.json` (and autosaves the recovery file first); END / Esc / Destroy restore it, including dirty flag, undo stacks, pan and the loaded tutorial. Autosave is off while the tour exists.
- Content: `scr_editor_tour_steps` (main-screen categories, demo) and `scr_editor_tour_editors` (`scr_tour_show(view)` opens / closes editors and switches their tabs; per-editor rectangle helpers). A step is `{ title, text, show, rect }`; `rect` is a **function** evaluated every frame (GML function literals do not capture locals — use globals / instance lookups inside them).
- The tour is modal: listed in `scr_amiga_modal_open`, and every editor's Step starts with `if (instance_exists(obj_editor_tour)) exit;` (after its layout code). New editors need the same guard. For 3 frames after the demo is built `global.tour_settling` lets the graph Step once (preview, ORG links, operand rows).
- `-admtour` self test: runs every step, saves a screenshot of each to `<data>/tour_shots/`, checks auto-play and that the user's workspace comes back unchanged.

## Adding a macro node type — checklist

`scr_macro_node_height` / `scr_macro_node_init`, palette button (manager Create + the top-strip list in `obj_opcode_palette_item/Step_0`), node Step (input) and Draw (rows with `scr_node_row`), `scr_emit_macro_line` dispatch + emitter, `scr_amiga_describe_node`, `scr_amiga_explain_node` (hover help), persistence (see table above), and `scr_amiga_build_preview_lines` if the emitted text is huge. Game Kit nodes instead go in `GK_NODE_TYPES` and the `scr_gk_*` functions of `scr_gamekit_emit` / `scr_gk_node_ui`. Mention the node in the tour (`scr_editor_tour_steps`) and, if it belongs to a lesson, a tutorial.

## Adding an editor or panel — checklist

Its own object with a depth below the manager (-300000) if it must draw over it; add it to `scr_amiga_modal_open`; start its Step with `if (instance_exists(obj_editor_tour)) exit;` (after any layout code Draw relies on); handle Esc itself (the manager's Esc quits only when no modal is open); set the font first in Draw and use the `scr_ui_*` style; keep geometry in one layout function or Create variables shared by Step and Draw; add a toolbar button; add a tour category in `scr_tour_editor_categories` with a view in `scr_tour_show` and a rectangle helper; check it with `-admtour`.

## Pitfalls already hit

- `"\b..."` in a GML string is a backspace escape — write `"\\build_asm.bat"`.
- cmd: `echo %errorlevel%> file` becomes `echo 0> file` (handle redirect, empty file). Use `> file echo exit %errorlevel%`.
- ShellExecute (`execute_shell_simple`) fails on mixed `\` and `/` paths — normalise to backslashes for cmd/working directories.
- Key-press events run before Step: the manager's Esc handler must bail while any editor or text field is active (it does), or Esc quits the app.
- vasm: local labels (`.x`) are scoped to the previous global label; cross-section PC-relative references are not allowed; prefer unsized branches and let vasm size them.
- PowerShell 5.1 reads `0xFFFFFFFF` as Int32 −1 — use `[UInt64]4294967295`.
- A Copper WAIT holds only 8 bits of the line: lines ≥256 need a `$FFDFFFFE` wait first (handled in `scr_emit_macro_copper_bar`).
- Perl one-liners expand `\t` / `\n` inside GML string literals; use the Edit tool for lines with escapes.
- Never test with the user's own autosave: `temp_autosave_workspace.json` is the crash-recovery file that is auto-loaded at start.
