
username = "";
level = 0;
points = 0;
prev_points = 0;

game_state = 0; // 0=loading, 1=title, 2=playing, 3=animating, 4=wave_clear, 5=game_over, 6=level_up

// --- Grid ---
grid_w = 7;
grid_h = 7;

// Terrain heights
var _heights = [
    0, 0, 1, 1, 1, 0, 0,
    0, 0, 0, 1, 0, 0, 0,
    1, 0, 0, 0, 0, 0, 1,
    1, 1, 0, 0, 0, 1, 2,
    1, 0, 0, 0, 0, 0, 1,
    0, 0, 0, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 0, 0
];

for (var _i = 0; _i < grid_w * grid_h; _i++) {
    tile_height[_i] = _heights[_i];
}

// --- Units ---
max_units = 20;
unit_count = 0;

for (var _i = 0; _i < max_units; _i++) {
    unit_gx[_i] = 0;
    unit_gy[_i] = 0;
    unit_class[_i] = 0;
    unit_hp[_i] = 0;
    unit_max_hp[_i] = 0;
    unit_atk[_i] = 0;
    unit_def[_i] = 0;
    unit_move_range[_i] = 0;
    unit_atk_range[_i] = 0;
    unit_spd[_i] = 0;
    unit_ct[_i] = 0;
    unit_team[_i] = 0;
    unit_alive[_i] = false;
    unit_facing[_i] = 0;
    unit_acted[_i] = false;
    unit_moved[_i] = false;
}

// Class stats: [hp, atk, def, move, atk_range, spd]
// 0=Knight, 1=BlackMage, 2=Archer, 3=Goblin, 4=EnemyArcher
class_hp[0] = 6; class_atk[0] = 3; class_def[0] = 1; class_mov[0] = 3; class_rng[0] = 1; class_spd[0] = 4;
class_hp[1] = 3; class_atk[1] = 4; class_def[1] = 0; class_mov[1] = 2; class_rng[1] = 3; class_spd[1] = 3;
class_hp[2] = 4; class_atk[2] = 3; class_def[2] = 0; class_mov[2] = 3; class_rng[2] = 4; class_spd[2] = 5;
class_hp[3] = 3; class_atk[3] = 2; class_def[3] = 0; class_mov[3] = 3; class_rng[3] = 1; class_spd[3] = 3;
class_hp[4] = 3; class_atk[4] = 2; class_def[4] = 0; class_mov[4] = 2; class_rng[4] = 3; class_spd[4] = 4;

class_name[0] = "Knight";
class_name[1] = "B.Mage";
class_name[2] = "Archer";
class_name[3] = "Goblin";
class_name[4] = "E.Arch";

// --- Turn state ---
active_unit = -1;
turn_phase = 0; // 0=select_action, 1=select_move, 2=select_attack
menu_option = 0;
ct_running = true;

// Valid move/attack tiles (flat arrays of gx*grid_w+gy)
valid_move_count = 0;
valid_attack_count = 0;
for (var _i = 0; _i < 49; _i++) {
    valid_moves[_i] = -1;
    valid_attacks[_i] = -1;
}

// --- Charge queue (for BlackMage delayed spells) ---
charge_count = 0;
for (var _i = 0; _i < 8; _i++) {
    charge_source[_i] = -1;
    charge_target[_i] = -1;
    charge_timer[_i] = 0;
}

// --- Crystal drops ---
crystal_count = 0;
for (var _i = 0; _i < 12; _i++) {
    crystal_gx[_i] = -1;
    crystal_gy[_i] = -1;
    crystal_timer[_i] = 0;
}

// --- Damage popups ---
popup_count = 0;
for (var _i = 0; _i < 16; _i++) {
    popup_x[_i] = 0;
    popup_y[_i] = 0;
    popup_val[_i] = 0;
    popup_timer[_i] = 0;
    popup_is_heal[_i] = false;
}

// --- Wave system ---
wave_num = 1;
wave_clear_timer = 0;

// --- Level-up system ---
levelup_unit = -1;       // which player unit to upgrade (-1 = picking)
levelup_phase = 0;       // 0 = pick unit, 1 = pick upgrade
levelup_opt0 = 0;        // upgrade option IDs (3 options)
levelup_opt1 = 0;
levelup_opt2 = 0;
levelup_selected = -1;   // tapped option index (-1 = none selected)

// Upgrade names
upgrade_name[0] = "+2 Max HP";
upgrade_name[1] = "+1 ATK";
upgrade_name[2] = "+1 DEF";
upgrade_name[3] = "+1 MOV";
upgrade_name[4] = "+1 RNG";
upgrade_name[5] = "+1 SPD";
upgrade_name[6] = "Full Heal";
upgrade_name[7] = "+1 ATK&SPD";
upgrade_name[8] = "+1 DEF&HP";

// Upgrade descriptions
upgrade_desc[0] = "Increase max HP by 2 and heal 2";
upgrade_desc[1] = "Increase attack power by 1";
upgrade_desc[2] = "Increase defense by 1";
upgrade_desc[3] = "Increase move range by 1";
upgrade_desc[4] = "Increase attack range by 1";
upgrade_desc[5] = "Increase speed by 1";
upgrade_desc[6] = "Restore HP to maximum";
upgrade_desc[7] = "Boost attack and speed by 1";
upgrade_desc[8] = "Boost defense by 1 and max HP by 2";

// --- Animation ---
camera_shake = 0;
anim_timer = 0;
anim_timer_max = 1;
anim_type = 0; // 0=none, 1=move, 2=attack
anim_unit = -1;
anim_start_gx = 0;
anim_start_gy = 0;
anim_end_gx = 0;
anim_end_gy = 0;
anim_attack_target = -1;

// --- UI ---
selected_tile_gx = -1;
selected_tile_gy = -1;
info_unit = -1;
title_pulse = 0;

// --- Rendering ---
play_ox = 0;
play_oy = 0;
play_w = 0;
play_h = 0;

// --- Colors (FFT palette) ---
col_ui_bg = make_colour_rgb(24, 24, 72);
col_ui_border = make_colour_rgb(80, 80, 160);
col_ui_text = make_colour_rgb(220, 220, 255);
col_ui_highlight = make_colour_rgb(255, 200, 60);

col_tile_light = make_colour_rgb(140, 160, 100);
col_tile_dark = make_colour_rgb(120, 140, 80);
col_tile_side = make_colour_rgb(80, 100, 50);
col_tile_side2 = make_colour_rgb(60, 80, 40);
col_tile_move = make_colour_rgb(60, 100, 200);
col_tile_attack = make_colour_rgb(200, 60, 60);

col_knight = make_colour_rgb(60, 120, 200);
col_mage = make_colour_rgb(140, 60, 180);
col_archer = make_colour_rgb(60, 180, 100);
col_goblin = make_colour_rgb(180, 100, 40);
col_enemy_archer = make_colour_rgb(200, 60, 60);

// Window
window_width = 0;
window_height = 0;

// Debug
debug_tap_gx = -1;
debug_tap_gy = -1;
debug_tap_mx = 0;
debug_tap_my = 0;

// --- Spawn player units ---
// Knight at (1,5)
unit_gx[0] = 1; unit_gy[0] = 5; unit_class[0] = 0; unit_team[0] = 0; unit_alive[0] = true; unit_facing[0] = 2;
unit_hp[0] = class_hp[0]; unit_max_hp[0] = class_hp[0]; unit_atk[0] = class_atk[0]; unit_def[0] = class_def[0];
unit_move_range[0] = class_mov[0]; unit_atk_range[0] = class_rng[0]; unit_spd[0] = class_spd[0]; unit_ct[0] = 0;
unit_acted[0] = false; unit_moved[0] = false;

// BlackMage at (1,6)
unit_gx[1] = 1; unit_gy[1] = 6; unit_class[1] = 1; unit_team[1] = 0; unit_alive[1] = true; unit_facing[1] = 2;
unit_hp[1] = class_hp[1]; unit_max_hp[1] = class_hp[1]; unit_atk[1] = class_atk[1]; unit_def[1] = class_def[1];
unit_move_range[1] = class_mov[1]; unit_atk_range[1] = class_rng[1]; unit_spd[1] = class_spd[1]; unit_ct[1] = 0;
unit_acted[1] = false; unit_moved[1] = false;

// Archer at (0,6)
unit_gx[2] = 0; unit_gy[2] = 6; unit_class[2] = 2; unit_team[2] = 0; unit_alive[2] = true; unit_facing[2] = 2;
unit_hp[2] = class_hp[2]; unit_max_hp[2] = class_hp[2]; unit_atk[2] = class_atk[2]; unit_def[2] = class_def[2];
unit_move_range[2] = class_mov[2]; unit_atk_range[2] = class_rng[2]; unit_spd[2] = class_spd[2]; unit_ct[2] = 0;
unit_acted[2] = false; unit_moved[2] = false;

unit_count = 3;

// --- Spawn wave 1 enemies ---
// Goblin at (5,0)
unit_gx[3] = 5; unit_gy[3] = 0; unit_class[3] = 3; unit_team[3] = 1; unit_alive[3] = true; unit_facing[3] = 0;
unit_hp[3] = class_hp[3]; unit_max_hp[3] = class_hp[3]; unit_atk[3] = class_atk[3]; unit_def[3] = class_def[3];
unit_move_range[3] = class_mov[3]; unit_atk_range[3] = class_rng[3]; unit_spd[3] = class_spd[3]; unit_ct[3] = 0;
unit_acted[3] = false; unit_moved[3] = false;

// Goblin at (6,1)
unit_gx[4] = 6; unit_gy[4] = 1; unit_class[4] = 3; unit_team[4] = 1; unit_alive[4] = true; unit_facing[4] = 0;
unit_hp[4] = class_hp[3]; unit_max_hp[4] = class_hp[3]; unit_atk[4] = class_atk[3]; unit_def[4] = class_def[3];
unit_move_range[4] = class_mov[3]; unit_atk_range[4] = class_rng[3]; unit_spd[4] = class_spd[3]; unit_ct[4] = 0;
unit_acted[4] = false; unit_moved[4] = false;

unit_count = 5;

game_state = 1;
alarm[0] = 60;

api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        if (variable_struct_exists(_state, "username")) {
            other.username = _state.username;
        }
        if (variable_struct_exists(_state, "data") && is_struct(_state.data)) {
            if (variable_struct_exists(_state.data, "points")) {
                other.points = _state.data.points;
            }
            if (variable_struct_exists(_state.data, "wave_num")) {
                other.wave_num = _state.data.wave_num;
            }
        }
    }
    catch (_ex) {
        // First load — no saved state, that's fine
    }
});
