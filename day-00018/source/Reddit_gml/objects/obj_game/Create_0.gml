
// === Voxel Miner — Day 18 ===
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=loading, 1=playing, 2=game_over
game_state = 0;

// --- Block Type Constants ---
EMPTY = 0;
DIRT = 1;
STONE = 2;
COAL = 3;
IRON = 4;
GOLD = 5;
DIAMOND = 6;
LAVA = 7;
BEDROCK = 8;
LADDER = 9;

// --- Grid Setup ---
grid_cols = 10;
grid_rows = 80;

grid = array_create(grid_cols);
durability = array_create(grid_cols);
for (var _c = 0; _c < grid_cols; _c++) {
    grid[_c] = array_create(grid_rows, EMPTY);
    durability[_c] = array_create(grid_rows, 0);
}

// --- Block Point Values ---
block_pts = array_create(10, 0);
block_pts[DIRT] = 1;
block_pts[STONE] = 3;
block_pts[COAL] = 8;
block_pts[IRON] = 15;
block_pts[GOLD] = 30;
block_pts[DIAMOND] = 60;

// --- Block Durability (hits to mine) ---
block_hp = array_create(10, 1);
block_hp[EMPTY] = 0;
block_hp[DIRT] = 1;
block_hp[STONE] = 2;
block_hp[COAL] = 1;
block_hp[IRON] = 2;
block_hp[GOLD] = 2;
block_hp[DIAMOND] = 3;
block_hp[LAVA] = 1;
block_hp[BEDROCK] = 99;
block_hp[LADDER] = 1;

// --- Block Colors (front face) ---
block_color = array_create(10, c_black);
block_color[DIRT] = make_colour_rgb(139, 90, 43);
block_color[STONE] = make_colour_rgb(140, 140, 150);
block_color[COAL] = make_colour_rgb(55, 55, 65);
block_color[IRON] = make_colour_rgb(190, 110, 60);
block_color[GOLD] = make_colour_rgb(230, 190, 50);
block_color[DIAMOND] = make_colour_rgb(80, 220, 240);
block_color[LAVA] = make_colour_rgb(220, 60, 20);
block_color[BEDROCK] = make_colour_rgb(60, 30, 70);
block_color[LADDER] = make_colour_rgb(160, 110, 50);

// Lighter/darker variants for 3D cube faces
block_color_top = array_create(10, c_black);
block_color_dark = array_create(10, c_black);
for (var _i = 1; _i <= 9; _i++) {
    block_color_top[_i] = merge_colour(block_color[_i], c_white, 0.3);
    block_color_dark[_i] = merge_colour(block_color[_i], c_black, 0.35);
}

// --- Ladder Colors ---
col_ladder_rail = make_colour_rgb(100, 65, 25);
col_ladder_rung = make_colour_rgb(180, 130, 60);

// --- Hidden/Fog Block Colors ---
col_hidden = make_colour_rgb(30, 28, 35);
col_hidden_top = make_colour_rgb(40, 38, 45);
col_hidden_dark = make_colour_rgb(20, 18, 25);

// --- Precomputed Colors ---
col_lava_a = make_colour_rgb(180, 40, 10);
col_lava_b = make_colour_rgb(255, 120, 20);
col_hud_depth = make_colour_rgb(180, 200, 255);
col_life = make_colour_rgb(220, 60, 60);
col_life_hi = make_colour_rgb(255, 100, 100);
col_bg_top = make_colour_rgb(15, 20, 35);
col_bg_bot = make_colour_rgb(5, 5, 10);

// Cave background colors per row (precomputed)
cave_bg = array_create(grid_rows, c_black);
for (var _r = 0; _r < grid_rows; _r++) {
    if (_r < 2) {
        cave_bg[_r] = make_colour_rgb(30, 40, 80);
    } else {
        var _shade = clamp((_r - 2) / 60.0, 0, 0.8);
        cave_bg[_r] = merge_colour(make_colour_rgb(25, 20, 15), c_black, _shade);
    }
}

// --- Player ---
player_col = 5;
player_row = 1;
player_draw_col = 5;
player_draw_row = 1;

// --- Digger Character Colors ---
col_digger_hat = make_colour_rgb(240, 200, 40);
col_digger_hat_dark = make_colour_rgb(190, 150, 20);
col_digger_skin = make_colour_rgb(240, 195, 155);
col_digger_skin_dark = make_colour_rgb(200, 155, 115);
col_digger_body = make_colour_rgb(60, 100, 180);
col_digger_body_dark = make_colour_rgb(35, 65, 130);
col_digger_belt = make_colour_rgb(100, 70, 35);
col_digger_eye = make_colour_rgb(30, 30, 50);
col_digger_pick = make_colour_rgb(160, 160, 170);
player_facing = 1; // 1=right, -1=left

// --- Lives ---
lives = 3;

// --- Cave-In Timer ---
collapse_timer = 720;
collapse_max = 720;
collapsing = false;
collapse_flash = 0;

// --- Stalactite Crusher ---
stalactite_y = -3;
stalactite_speed = 0.008;
stalactite_prev_row = -3;
col_stalactite = make_colour_rgb(80, 70, 90);
col_stalactite_tip = make_colour_rgb(120, 100, 130);

// --- Combo ---
combo_type = -1;
combo_count = 0;
combo_timer = 0;

// --- Scrolling ---
scroll_y = 0;
scroll_target = 0;
max_depth = 0;

// --- Screen Shake ---
shake_amount = 0;

// --- Particles ---
p_max = 80;
p_x = array_create(p_max, 0);
p_y = array_create(p_max, 0);
p_vx = array_create(p_max, 0);
p_vy = array_create(p_max, 0);
p_col = array_create(p_max, c_white);
p_life = array_create(p_max, 0);
p_count = 0;

// --- Float Text ---
f_max = 16;
f_x = array_create(f_max, 0);
f_y = array_create(f_max, 0);
f_text = array_create(f_max, "");
f_col = array_create(f_max, c_white);
f_life = array_create(f_max, 0);
f_count = 0;

// --- Animations ---
lava_pulse = 0;
sparkle_time = 0;
flash_alpha = 0;

// --- Display ---
window_width = 0;
window_height = 0;
cell_size = 40;
grid_ox = 0;
grid_oy = 0;
hud_h = 60;
bevel = 5;
visible_rows = 14;

// --- Tap ---
tap_cooldown = 0;

// --- Game Over / Death Animation ---
gameover_timer = 0;
death_x = 0;
death_y = 0;
death_hat_x = 0;
death_hat_y = 0;
death_hat_vx = 0;
death_hat_vy = 0;
death_hat_rot = 0;
death_pick_x = 0;
death_pick_y = 0;
death_pick_vx = 0;
death_pick_vy = 0;
death_pick_rot = 0;
death_ghost_y = 0;

// === Grid Generation Method ===
gen_grid = function() {
    // Clear
    for (var _c = 0; _c < grid_cols; _c++) {
        for (var _r = 0; _r < grid_rows; _r++) {
            grid[_c][_r] = EMPTY;
        }
    }

    // === Phase 1: Block placement ===
    // Row 0-1: sky (EMPTY). Row 2+: underground
    for (var _c = 0; _c < grid_cols; _c++) {
        for (var _r = 2; _r < grid_rows; _r++) {
            var _d = _r - 2;
            var _roll = random(100);

            if (_d < 2) {
                // Surface: generous dirt + empty
                if (_roll < 65) grid[_c][_r] = DIRT;
                else if (_roll < 80) grid[_c][_r] = STONE;
                // else EMPTY (~20%)
            }
            else if (_d < 5) {
                // Near surface: dirt/stone/coal, some empty
                if (_roll < 40) grid[_c][_r] = DIRT;
                else if (_roll < 65) grid[_c][_r] = STONE;
                else if (_roll < 80) grid[_c][_r] = COAL;
                // else EMPTY (~20%)
            }
            else if (_d < 12) {
                // Mid: no lava yet, iron appears
                if (_roll < 10) grid[_c][_r] = DIRT;
                else if (_roll < 35) grid[_c][_r] = STONE;
                else if (_roll < 55) grid[_c][_r] = COAL;
                else if (_roll < 72) grid[_c][_r] = IRON;
                else if (_roll < 80) grid[_c][_r] = BEDROCK;
                // else EMPTY (~20%)
            }
            else if (_d < 20) {
                // Lava starts appearing (low frequency)
                if (_roll < 8) grid[_c][_r] = DIRT;
                else if (_roll < 28) grid[_c][_r] = STONE;
                else if (_roll < 42) grid[_c][_r] = COAL;
                else if (_roll < 58) grid[_c][_r] = IRON;
                else if (_roll < 65) grid[_c][_r] = LAVA;
                else if (_roll < 78) grid[_c][_r] = BEDROCK;
                // else EMPTY (~22%)
            }
            else if (_d < 30) {
                // Gold zone, more lava
                if (_roll < 15) grid[_c][_r] = STONE;
                else if (_roll < 25) grid[_c][_r] = COAL;
                else if (_roll < 42) grid[_c][_r] = IRON;
                else if (_roll < 58) grid[_c][_r] = GOLD;
                else if (_roll < 68) grid[_c][_r] = LAVA;
                else if (_roll < 80) grid[_c][_r] = BEDROCK;
                // else EMPTY (~20%)
            }
            else {
                // Diamond zone
                if (_roll < 10) grid[_c][_r] = STONE;
                else if (_roll < 18) grid[_c][_r] = IRON;
                else if (_roll < 32) grid[_c][_r] = GOLD;
                else if (_roll < 48) grid[_c][_r] = DIAMOND;
                else if (_roll < 60) grid[_c][_r] = LAVA;
                else if (_roll < 75) grid[_c][_r] = BEDROCK;
                // else EMPTY (~25%)
            }
        }
    }

    // === Phase 2: Cave carving — random walk worms ===
    for (var _w = 0; _w < 10; _w++) {
        var _cx = irandom(grid_cols - 1);
        var _cy = irandom_range(5, grid_rows - 5);
        var _steps = irandom_range(15, 35);
        for (var _s = 0; _s < _steps; _s++) {
            if (_cx >= 0 && _cx < grid_cols && _cy >= 2 && _cy < grid_rows) {
                grid[_cx][_cy] = EMPTY;
            }
            var _dir = irandom(3);
            if (_dir == 0) _cx--;
            else if (_dir == 1) _cx++;
            else if (_dir == 2) _cy--;
            else _cy++;
            // Slight downward bias
            if (random(1) < 0.25) _cy++;
        }
    }

    // === Phase 3: Cavern pockets — larger open areas ===
    for (var _p = 0; _p < 8; _p++) {
        var _px = irandom_range(0, grid_cols - 3);
        var _py = irandom_range(4, grid_rows - 6);
        var _pw = irandom_range(2, 3);
        var _ph = irandom_range(2, 3);
        for (var _cx = _px; _cx < min(_px + _pw, grid_cols); _cx++) {
            for (var _cy = _py; _cy < min(_py + _ph, grid_rows); _cy++) {
                if (_cy >= 2) grid[_cx][_cy] = EMPTY;
            }
        }
    }

    // === Phase 4: Ensure surface has a wide opening ===
    // Clear a 6-wide section in the middle of rows 2-3
    var _mid = floor(grid_cols * 0.5) - 3;
    for (var _cx = max(0, _mid); _cx < min(_mid + 6, grid_cols); _cx++) {
        grid[_cx][2] = DIRT;
        grid[_cx][3] = DIRT;
    }
    // Punch some holes in row 3-4 for initial digging room
    for (var _cx = max(0, _mid + 1); _cx < min(_mid + 5, grid_cols); _cx++) {
        if (random(1) < 0.4) grid[_cx][3] = EMPTY;
        if (random(1) < 0.3) grid[_cx][4] = EMPTY;
    }

    // Ensure player start position (col 5, row 1) and the cell below it are set up
    grid[5][0] = EMPTY;
    grid[5][1] = EMPTY;

    // Initialize durability for all blocks
    for (var _c = 0; _c < grid_cols; _c++) {
        for (var _r = 0; _r < grid_rows; _r++) {
            var _type = grid[_c][_r];
            durability[_c][_r] = block_hp[_type];
        }
    }
};

// Generate initial grid
gen_grid();

// === Load State ===
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        points = _state.data.points;
    }
    catch (_ex) {
        api_save_state(0, { points: 0 }, undefined);
    }
    game_state = 1;
    alarm[0] = 60;
});
