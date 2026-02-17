// ========================================
// GEM FORGE — Run-based Match-3 with Special Gem Modifiers
// ========================================

#macro GF_COLS 7
#macro GF_ROWS 7
#macro GF_COLORS 5
#macro GF_SWAP_SPD 0.12
#macro GF_CLEAR_FRAMES 12
#macro GF_BASE_MOVES 8
#macro GF_BASE_TARGET 300
#macro GF_TARGET_MULT 1.5

// Special gem types
#macro SP_NONE 0
#macro SP_BOMB 1
#macro SP_LIGHTNING 2
#macro SP_CROSS 3
#macro SP_MULT 4
#macro SP_CASCADE 5

// FX types
#macro FX_RING 0
#macro FX_HFLASH 1
#macro FX_CROSSFLASH 2
#macro FX_SPARKLE 3
#macro FX_POP 4

// --- Game State ---
game_state = 0;
points = 0;
round_num = 1;
round_score = 0;
target_score = GF_BASE_TARGET;
moves_left = GF_BASE_MOVES;
max_moves = GF_BASE_MOVES;
num_colors = 5;
level = 0;

// --- Grid ---
grid = [];
special = [];
gem_y_off = [];
gem_scale = [];
marked = [];
for (var _i = 0; _i < GF_COLS; _i++) {
    grid[_i] = array_create(GF_ROWS, -1);
    special[_i] = array_create(GF_ROWS, SP_NONE);
    gem_y_off[_i] = array_create(GF_ROWS, 0);
    gem_scale[_i] = array_create(GF_ROWS, 1);
    marked[_i] = array_create(GF_ROWS, false);
}

// --- Animation ---
anim_state = 0;
swap_progress = 0;
swap_c1 = 0; swap_r1 = 0;
swap_c2 = 0; swap_r2 = 0;
swap_failed = false;
clear_timer = 0;
combo_count = 0;
match_groups = [];

// --- Input ---
sel_col = -1;
sel_row = -1;
touch_sx = 0; touch_sy = 0;
touch_col = -1; touch_row = -1;
touching = false;

// --- Modifiers (count-based: each pick gives N special gems) ---
active_mods = [];
mod_bomb_count = 0;
mod_lightning_count = 0;
mod_mult_count = 0;
mod_cascade_count = 0;
mod_extra_moves = 0;

// --- Modifier Definitions ---
// [name, description_suffix]
mod_defs = [
    ["Bomb",        "explosive gems (3x3)"],
    ["Lightning",   "row-clearing gems"],
    ["Multiplier",  "score-doubling gems"],
    ["Cascade",     "chain reaction gems"],
    ["Extra Moves", "extra moves"],
];

mod_icon_colors = [
    make_color_rgb(230, 126, 34),  // Bomb - orange
    make_color_rgb(241, 196, 15),  // Lightning - yellow
    make_color_rgb(155, 89, 182),  // Mult - purple
    make_color_rgb(46, 204, 113),  // Cascade - green
    make_color_rgb(52, 152, 219),  // Extra Moves - blue
];

// --- Cards ---
card_options = [];

// --- Visual ---
gem_colors = [
    make_color_rgb(231, 76, 60),
    make_color_rgb(52, 152, 219),
    make_color_rgb(46, 204, 113),
    make_color_rgb(241, 196, 15),
    make_color_rgb(155, 89, 182),
];
gem_sprites = [spr_gem_red, spr_gem_blue, spr_gem_green, spr_gem_yellow, spr_gem_purple];

bg_color = make_color_rgb(24, 24, 36);
popups = [];
combo_text = "";
combo_timer = 0;
round_msg = "";
round_msg_timer = 0;
score_submitted = false;

// Screen shake
shake_x = 0;
shake_y = 0;
shake_timer = 0;
shake_intensity = 0;

// Visual effects
fx = [];
confetti = [];
lt_intersections = [];

// Card animation
selected_card = -1;
card_anim_timer = 0;

scr_w = window_get_width();
scr_h = window_get_height();
cell_size = 1;
grid_x = 0;
grid_y = 0;

// --- Functions ---

function calc_layout() {
    scr_w = window_get_width();
    scr_h = window_get_height();
    var _max_w = scr_w * 0.92;
    var _max_h = scr_h * 0.55;
    cell_size = floor(min(_max_w / GF_COLS, _max_h / GF_ROWS));
    cell_size = max(cell_size, 24);
    grid_x = floor((scr_w - GF_COLS * cell_size) / 2);
    grid_y = floor(scr_h * 0.22);
}

function roll_special() {
    var _total = mod_bomb_count + mod_lightning_count + mod_mult_count + mod_cascade_count;
    if (_total <= 0) return SP_NONE;

    // 18% chance per new gem to be special
    if (random(1) > 0.18) return SP_NONE;

    // Pick proportional to remaining counts
    var _roll = irandom(_total - 1);
    if (_roll < mod_bomb_count) { mod_bomb_count--; return SP_BOMB; }
    _roll -= mod_bomb_count;
    if (_roll < mod_lightning_count) { mod_lightning_count--; return SP_LIGHTNING; }
    _roll -= mod_lightning_count;
    if (_roll < mod_mult_count) { mod_mult_count--; return SP_MULT; }
    _roll -= mod_mult_count;
    if (_roll < mod_cascade_count) { mod_cascade_count--; return SP_CASCADE; }
    return SP_NONE;
}

function has_match_at(_col, _row) {
    var _c = grid[_col][_row];
    if (_c < 0) return false;
    if (_col >= 2 && grid[_col-1][_row] == _c && grid[_col-2][_row] == _c) return true;
    if (_row >= 2 && grid[_col][_row-1] == _c && grid[_col][_row-2] == _c) return true;
    return false;
}

function fill_grid() {
    for (var _col = 0; _col < GF_COLS; _col++) {
        for (var _row = 0; _row < GF_ROWS; _row++) {
            var _tries = 0;
            do {
                grid[_col][_row] = irandom(num_colors - 1);
                _tries++;
            } until (!has_match_at(_col, _row) || _tries > 100);
            special[_col][_row] = roll_special();
            gem_y_off[_col][_row] = 0;
            gem_scale[_col][_row] = 1;
            marked[_col][_row] = false;
        }
    }
}

function fill_grid_cascade() {
    fill_grid();
    for (var _c = 0; _c < GF_COLS; _c++) {
        for (var _r = 0; _r < GF_ROWS; _r++) {
            gem_y_off[_c][_r] = -(_r + 2 + _c * 0.4) * cell_size;
        }
    }
    anim_state = 3;
}

function check_any_match() {
    for (var _r = 0; _r < GF_ROWS; _r++)
        for (var _c = 0; _c < GF_COLS - 2; _c++)
            if (grid[_c][_r] >= 0 && grid[_c][_r] == grid[_c+1][_r] && grid[_c][_r] == grid[_c+2][_r]) return true;
    for (var _c = 0; _c < GF_COLS; _c++)
        for (var _r = 0; _r < GF_ROWS - 2; _r++)
            if (grid[_c][_r] >= 0 && grid[_c][_r] == grid[_c][_r+1] && grid[_c][_r] == grid[_c][_r+2]) return true;
    return false;
}

function has_valid_moves() {
    for (var _c = 0; _c < GF_COLS; _c++) {
        for (var _r = 0; _r < GF_ROWS; _r++) {
            if (_c + 1 < GF_COLS) {
                var _tmp = grid[_c][_r]; grid[_c][_r] = grid[_c+1][_r]; grid[_c+1][_r] = _tmp;
                var _m = check_any_match();
                grid[_c+1][_r] = grid[_c][_r]; grid[_c][_r] = _tmp;
                if (_m) return true;
            }
            if (_r + 1 < GF_ROWS) {
                var _tmp = grid[_c][_r]; grid[_c][_r] = grid[_c][_r+1]; grid[_c][_r+1] = _tmp;
                var _m = check_any_match();
                grid[_c][_r+1] = grid[_c][_r]; grid[_c][_r] = _tmp;
                if (_m) return true;
            }
        }
    }
    return false;
}

function find_and_mark_matches() {
    var _found = false;
    for (var _c = 0; _c < GF_COLS; _c++)
        for (var _r = 0; _r < GF_ROWS; _r++)
            marked[_c][_r] = false;
    match_groups = [];

    // Horizontal
    for (var _row = 0; _row < GF_ROWS; _row++) {
        var _col = 0;
        while (_col < GF_COLS) {
            var _clr = grid[_col][_row];
            if (_clr < 0) { _col++; continue; }
            var _run = 1;
            while (_col + _run < GF_COLS && grid[_col + _run][_row] == _clr) _run++;
            if (_run >= 3) {
                for (var _k = 0; _k < _run; _k++) marked[_col + _k][_row] = true;
                array_push(match_groups, {color: _clr, count: _run, sc: _col, sr: _row, hz: true});
                _found = true;
            }
            _col += _run;
        }
    }
    // Vertical
    for (var _col = 0; _col < GF_COLS; _col++) {
        var _row = 0;
        while (_row < GF_ROWS) {
            var _clr = grid[_col][_row];
            if (_clr < 0) { _row++; continue; }
            var _run = 1;
            while (_row + _run < GF_ROWS && grid[_col][_row + _run] == _clr) _run++;
            if (_run >= 3) {
                for (var _k = 0; _k < _run; _k++) marked[_col][_row + _k] = true;
                array_push(match_groups, {color: _clr, count: _run, sc: _col, sr: _row, hz: false});
                _found = true;
            }
            _row += _run;
        }
    }

    if (!_found) return false;

    // === L/T intersection detection (perpendicular matches) ===
    lt_intersections = [];
    var _h_in = [];
    var _v_in = [];
    for (var _c = 0; _c < GF_COLS; _c++) {
        _h_in[_c] = array_create(GF_ROWS, false);
        _v_in[_c] = array_create(GF_ROWS, false);
    }
    for (var _g = 0; _g < array_length(match_groups); _g++) {
        var _mg = match_groups[_g];
        if (_mg.hz) {
            for (var _k = 0; _k < _mg.count; _k++)
                _h_in[_mg.sc + _k][_mg.sr] = true;
        } else {
            for (var _k = 0; _k < _mg.count; _k++)
                _v_in[_mg.sc][_mg.sr + _k] = true;
        }
    }
    for (var _c = 0; _c < GF_COLS; _c++) {
        for (var _r = 0; _r < GF_ROWS; _r++) {
            if (_h_in[_c][_r] && _v_in[_c][_r]) {
                array_push(lt_intersections, [_c, _r]);
                // 3x3 blast around intersection
                for (var _dc = -1; _dc <= 1; _dc++)
                    for (var _dr = -1; _dr <= 1; _dr++) {
                        var _nc = _c + _dc;
                        var _nr = _r + _dr;
                        if (_nc >= 0 && _nc < GF_COLS && _nr >= 0 && _nr < GF_ROWS)
                            marked[_nc][_nr] = true;
                    }
            }
        }
    }

    // === Activate special gems in marked cells ===
    // Two passes for chain reactions (special triggers special)
    for (var _pass = 0; _pass < 2; _pass++) {
        for (var _c = 0; _c < GF_COLS; _c++) {
            for (var _r = 0; _r < GF_ROWS; _r++) {
                if (!marked[_c][_r]) continue;
                var _sp = special[_c][_r];
                if (_sp == SP_BOMB) {
                    // 3x3 explosion
                    for (var _dc = -1; _dc <= 1; _dc++)
                        for (var _dr = -1; _dr <= 1; _dr++) {
                            var _nc = _c + _dc;
                            var _nr = _r + _dr;
                            if (_nc >= 0 && _nc < GF_COLS && _nr >= 0 && _nr < GF_ROWS)
                                marked[_nc][_nr] = true;
                        }
                }
                if (_sp == SP_LIGHTNING) {
                    // Clear entire row
                    for (var _cc = 0; _cc < GF_COLS; _cc++)
                        marked[_cc][_r] = true;
                }
                if (_sp == SP_CASCADE) {
                    // Destroy 3 random gems elsewhere
                    var _destroyed = 0;
                    var _attempts = 0;
                    while (_destroyed < 3 && _attempts < 30) {
                        var _rc = irandom(GF_COLS - 1);
                        var _rr = irandom(GF_ROWS - 1);
                        if (!marked[_rc][_rr] && grid[_rc][_rr] >= 0) {
                            marked[_rc][_rr] = true;
                            _destroyed++;
                        }
                        _attempts++;
                    }
                }
            }
        }
    }

    // BUILT-IN: 4+ blast adjacent
    var _has_big = false;
    for (var _g = 0; _g < array_length(match_groups); _g++)
        if (match_groups[_g].count >= 4) { _has_big = true; break; }
    if (_has_big) {
        var _to_explode = [];
        for (var _c = 0; _c < GF_COLS; _c++)
            for (var _r = 0; _r < GF_ROWS; _r++)
                if (marked[_c][_r]) array_push(_to_explode, [_c, _r]);
        for (var _e = 0; _e < array_length(_to_explode); _e++) {
            var _ec = _to_explode[_e][0];
            var _er = _to_explode[_e][1];
            for (var _dc = -1; _dc <= 1; _dc++)
                for (var _dr = -1; _dr <= 1; _dr++) {
                    var _nc = _ec + _dc;
                    var _nr = _er + _dr;
                    if (_nc >= 0 && _nc < GF_COLS && _nr >= 0 && _nr < GF_ROWS)
                        marked[_nc][_nr] = true;
                }
        }
    }

    // BUILT-IN: 5+ clears all of that color
    for (var _g = 0; _g < array_length(match_groups); _g++) {
        if (match_groups[_g].count >= 5) {
            var _pc = match_groups[_g].color;
            for (var _c = 0; _c < GF_COLS; _c++)
                for (var _r = 0; _r < GF_ROWS; _r++)
                    if (grid[_c][_r] == _pc) marked[_c][_r] = true;
        }
    }

    return true;
}

function score_matches() {
    var _total = 0;
    for (var _g = 0; _g < array_length(match_groups); _g++) {
        var _mg = match_groups[_g];
        var _base = _mg.count * 10;
        var _casc = 1 + combo_count * 0.25;
        var _score = floor(_base * _casc);

        // Check if any gem in this match group has SP_MULT
        var _has_mult = false;
        if (_mg.hz) {
            for (var _k = 0; _k < _mg.count; _k++)
                if (special[_mg.sc + _k][_mg.sr] == SP_MULT) { _has_mult = true; break; }
        } else {
            for (var _k = 0; _k < _mg.count; _k++)
                if (special[_mg.sc][_mg.sr + _k] == SP_MULT) { _has_mult = true; break; }
        }
        if (_has_mult) _score *= 2;

        _total += _score;
        var _px, _py;
        if (_mg.hz) {
            _px = grid_x + (_mg.sc + _mg.count * 0.5) * cell_size;
            _py = grid_y + _mg.sr * cell_size + cell_size * 0.5;
        } else {
            _px = grid_x + _mg.sc * cell_size + cell_size * 0.5;
            _py = grid_y + (_mg.sr + _mg.count * 0.5) * cell_size;
        }
        var _ptxt = "+" + string(_score);
        if (_has_mult) _ptxt += " x2!";
        array_push(popups, {x: _px, y: _py, txt: _ptxt, t: 50, clr: gem_colors[_mg.color]});
    }
    // Extra cells from specials/built-in blast
    var _marked_total = 0;
    for (var _c = 0; _c < GF_COLS; _c++)
        for (var _r = 0; _r < GF_ROWS; _r++)
            if (marked[_c][_r]) _marked_total++;
    var _group_total = 0;
    for (var _g = 0; _g < array_length(match_groups); _g++) _group_total += match_groups[_g].count;
    var _extra = _marked_total - _group_total;
    if (_extra > 0) _total += _extra * 5;

    round_score += _total;
    points += _total;

    if (combo_count > 0) {
        combo_text = "COMBO x" + string(combo_count + 1);
        combo_timer = 45;
    }
}

function remove_marked() {
    for (var _c = 0; _c < GF_COLS; _c++)
        for (var _r = 0; _r < GF_ROWS; _r++)
            if (marked[_c][_r]) {
                grid[_c][_r] = -1;
                special[_c][_r] = SP_NONE;
                marked[_c][_r] = false;
            }
}

function apply_gravity() {
    for (var _col = 0; _col < GF_COLS; _col++) {
        var _write = GF_ROWS - 1;
        for (var _row = GF_ROWS - 1; _row >= 0; _row--) {
            if (grid[_col][_row] >= 0) {
                if (_write != _row) {
                    grid[_col][_write] = grid[_col][_row];
                    special[_col][_write] = special[_col][_row];
                    grid[_col][_row] = -1;
                    special[_col][_row] = SP_NONE;
                    gem_y_off[_col][_write] = (_row - _write) * cell_size;
                    gem_scale[_col][_write] = 1;
                }
                _write--;
            }
        }
        // Spawn new gems at top
        for (var _row = _write; _row >= 0; _row--) {
            grid[_col][_row] = irandom(num_colors - 1);
            special[_col][_row] = roll_special();
            gem_y_off[_col][_row] = -(_write - _row + 1) * cell_size;
            gem_scale[_col][_row] = 1;
        }
    }
}

function generate_cards() {
    var _avail = [];
    for (var _i = 0; _i < array_length(mod_defs); _i++)
        array_push(_avail, _i);
    for (var _i = array_length(_avail) - 1; _i > 0; _i--) {
        var _j = irandom(_i);
        var _tmp = _avail[_i];
        _avail[_i] = _avail[_j];
        _avail[_j] = _tmp;
    }
    card_options = [];
    for (var _i = 0; _i < min(3, array_length(_avail)); _i++)
        array_push(card_options, _avail[_i]);
}

function get_mod_count(_id, _stacks) {
    // Diminishing gem count: 5, 3, 2, 1
    if (_id == 4) {
        // Extra Moves: 3, 2, 1, 1
        if (_stacks == 0) return 3;
        if (_stacks == 1) return 2;
        return 1;
    }
    if (_stacks == 0) return 5;
    if (_stacks == 1) return 3;
    if (_stacks == 2) return 2;
    return 1;
}

function apply_mod(_id) {
    // Count existing stacks for diminishing returns
    var _stacks = 0;
    for (var _i = 0; _i < array_length(active_mods); _i++)
        if (active_mods[_i] == _id) _stacks++;

    var _count = get_mod_count(_id, _stacks);

    array_push(active_mods, _id);
    switch (_id) {
        case 0: mod_bomb_count += _count; break;
        case 1: mod_lightning_count += _count; break;
        case 2: mod_mult_count += _count; break;
        case 3: mod_cascade_count += _count; break;
        case 4: mod_extra_moves += _count; break;
    }
    max_moves = GF_BASE_MOVES + mod_extra_moves;
}

function start_next_round() {
    round_num++;
    round_score = 0;
    target_score = floor(GF_BASE_TARGET * power(GF_TARGET_MULT, round_num - 1));
    moves_left = max_moves;

    // Progressive color addition: 4 colors rounds 1-2, 5 from round 3+
    var _prev = num_colors;
    num_colors = GF_COLORS;

    if (!has_valid_moves()) fill_grid();
    game_state = 1;

    if (num_colors > _prev)
        round_msg = "Round " + string(round_num) + " — New gem!";
    else
        round_msg = "Round " + string(round_num);
    round_msg_timer = 50;
}

function check_round_end() {
    if (round_score >= target_score) {
        game_state = 5;
        spawn_confetti();
        round_msg = "Round Complete!";
        round_msg_timer = 50;
    } else {
        game_state = 4;
        score_submitted = false;
    }
}

function reset_game() {
    points = 0;
    round_num = 1;
    round_score = 0;
    target_score = GF_BASE_TARGET;
    max_moves = GF_BASE_MOVES;
    moves_left = GF_BASE_MOVES;
    num_colors = 5;
    active_mods = [];
    mod_bomb_count = 0;
    mod_lightning_count = 0;
    mod_mult_count = 0;
    mod_cascade_count = 0;
    mod_extra_moves = 0;
    combo_count = 0;
    sel_col = -1; sel_row = -1;
    anim_state = 0;
    popups = [];
    score_submitted = false;
    for (var _c = 0; _c < GF_COLS; _c++)
        for (var _r = 0; _r < GF_ROWS; _r++)
            special[_c][_r] = SP_NONE;
    fill_grid_cascade();
    game_state = 1;
    alarm[0] = room_speed * 20;
}

// --- FX Functions ---

function add_shake(_intensity, _duration) {
    if (_intensity > shake_intensity || shake_timer <= 0) {
        shake_intensity = _intensity;
        shake_timer = _duration;
    }
}

function spawn_fx(_type, _x, _y, _color, _size, _dur) {
    array_push(fx, {type: _type, x: _x, y: _y, clr: _color, sz: _size, t: 0, mt: _dur});
}

function spawn_confetti() {
    confetti = [];
    for (var _i = 0; _i < 45; _i++) {
        array_push(confetti, {
            x: random(scr_w),
            y: random_range(-scr_h * 0.3, scr_h * 0.15),
            vx: random_range(-2, 2),
            vy: random_range(1, 4),
            rot: random(360),
            rs: random_range(-5, 5),
            sz: random_range(4, 10),
            clr: gem_colors[irandom(array_length(gem_colors) - 1)],
            life: irandom_range(80, 140),
        });
    }
}

function spawn_match_fx() {
    // Base shake scales with combo
    var _base = 3 + combo_count * 2;
    add_shake(_base, 6 + combo_count * 2);

    // FX for 4+ and 5+ match groups
    for (var _g = 0; _g < array_length(match_groups); _g++) {
        var _mg = match_groups[_g];
        var _fx_x, _fx_y;
        if (_mg.hz) {
            _fx_x = grid_x + (_mg.sc + _mg.count * 0.5) * cell_size;
            _fx_y = grid_y + _mg.sr * cell_size + cell_size * 0.5;
        } else {
            _fx_x = grid_x + _mg.sc * cell_size + cell_size * 0.5;
            _fx_y = grid_y + (_mg.sr + _mg.count * 0.5) * cell_size;
        }
        if (_mg.count >= 5) {
            spawn_fx(FX_RING, _fx_x, _fx_y, gem_colors[_mg.color], cell_size * 4, 25);
            add_shake(8, 12);
        } else if (_mg.count >= 4) {
            spawn_fx(FX_RING, _fx_x, _fx_y, gem_colors[_mg.color], cell_size * 2.5, 20);
            add_shake(6, 10);
        }
    }

    // FX for special gems being cleared
    for (var _c = 0; _c < GF_COLS; _c++) {
        for (var _r = 0; _r < GF_ROWS; _r++) {
            if (!marked[_c][_r]) continue;
            var _sp = special[_c][_r];
            if (_sp == SP_NONE) continue;
            var _px = grid_x + _c * cell_size + cell_size * 0.5;
            var _py = grid_y + _r * cell_size + cell_size * 0.5;
            if (_sp == SP_BOMB) {
                spawn_fx(FX_RING, _px, _py, make_color_rgb(255, 165, 0), cell_size * 2, 18);
                add_shake(8, 12);
            } else if (_sp == SP_LIGHTNING) {
                spawn_fx(FX_HFLASH, _px, _py, make_color_rgb(255, 255, 100), 0, 15);
                add_shake(6, 8);
            } else if (_sp == SP_CASCADE) {
                spawn_fx(FX_SPARKLE, _px, _py, make_color_rgb(100, 255, 150), cell_size, 20);
                add_shake(4, 6);
            } else if (_sp == SP_MULT) {
                spawn_fx(FX_RING, _px, _py, make_color_rgb(255, 215, 0), cell_size * 1.5, 15);
            }
        }
    }

    // FX for L/T intersections
    for (var _i = 0; _i < array_length(lt_intersections); _i++) {
        var _ic = lt_intersections[_i][0];
        var _ir = lt_intersections[_i][1];
        var _px = grid_x + _ic * cell_size + cell_size * 0.5;
        var _py = grid_y + _ir * cell_size + cell_size * 0.5;
        var _gem = grid[_ic][_ir];
        var _clr = _gem >= 0 ? gem_colors[_gem] : c_white;
        spawn_fx(FX_RING, _px, _py, _clr, cell_size * 2.5, 20);
        add_shake(7, 10);
    }
}

function spawn_clear_pops() {
    for (var _c = 0; _c < GF_COLS; _c++) {
        for (var _r = 0; _r < GF_ROWS; _r++) {
            if (!marked[_c][_r]) continue;
            var _px = grid_x + _c * cell_size + cell_size * 0.5;
            var _py = grid_y + _r * cell_size + cell_size * 0.5;
            var _gem = grid[_c][_r];
            var _clr = _gem >= 0 ? gem_colors[_gem] : c_white;
            spawn_fx(FX_POP, _px, _py, _clr, cell_size * 0.45, 12);
        }
    }
}

// --- Load State ---
state_loaded = false;
state_data = undefined;
username = "";

api_load_state(function(_status, _ok, _result, _payload) {
    if (_ok && _status >= 200 && _status < 400 && _result != undefined && _result != "") {
        try { self.state_data = json_parse(_result); }
        catch (_ex) { self.state_data = undefined; }
    }
    self.state_loaded = true;
});

calc_layout();
