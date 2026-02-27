/// First Person Tower Defense
/// Pseudo-3D corridor, enemies approach, tap to shoot, place towers

username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=loading, 1=playing, 2=game_over
game_state = 0;

// Screen
scr_w = 640;
scr_h = 960;

// Player
player_hp = 20;
player_hp_max = 20;
gold = 75;
shoot_cooldown = 0;
shoot_cd_max = 12;

// Wave system
wave = 0;
wave_active = false;
wave_timer = 0;
wave_delay = 150;
enemies_to_spawn = 0;
spawn_timer = 0;
spawn_interval = 35;
wave_enemies_alive = 0;
total_kills = 0;

// Enemies: pool of 40
enemy_max = 40;
for (var i = 0; i < enemy_max; i++) {
    enemy_active[i] = false;
    enemy_lane[i] = 0;
    enemy_depth[i] = 0;
    enemy_hp[i] = 1;
    enemy_hp_max[i] = 1;
    enemy_speed[i] = 0.003;
    enemy_type[i] = 0;
    enemy_hit[i] = 0;
    enemy_x_off[i] = 0;
}

// Towers: 6 fixed slots (3 left, 3 right)
tower_count = 6;
for (var i = 0; i < tower_count; i++) {
    tower_side[i] = (i mod 2 == 0) ? -1 : 1;
    tower_slot_depth[i] = 0.35 + (i div 2) * 0.2;
    tower_has[i] = false;
    tower_level[i] = 0;
    tower_timer[i] = 0;
    tower_fire_rate[i] = 45;
    tower_range[i] = 0.35;
    tower_damage[i] = 1;
}
tower_cost = 50;

// Projectiles
proj_max = 20;
for (var i = 0; i < proj_max; i++) {
    proj_active[i] = false;
    proj_sx[i] = 0;
    proj_sy[i] = 0;
    proj_tx[i] = 0;
    proj_ty[i] = 0;
    proj_life[i] = 0;
    proj_life_max[i] = 8;
}

// Tap flash effects
tap_fx_max = 10;
for (var i = 0; i < tap_fx_max; i++) {
    tap_fx_active[i] = false;
    tap_fx_x[i] = 0;
    tap_fx_y[i] = 0;
    tap_fx_life[i] = 0;
}

// Float text
float_max = 15;
for (var i = 0; i < float_max; i++) {
    float_active[i] = false;
    float_x[i] = 0;
    float_y[i] = 0;
    float_text[i] = "";
    float_life[i] = 0;
    float_col[i] = c_white;
}

// Damage flash
damage_flash = 0;

// Tower menu
show_tower_menu = false;
selected_tower_slot = -1;

// Colors
col_road = make_colour_rgb(50, 50, 65);
col_wall_l = make_colour_rgb(70, 65, 90);
col_wall_r = make_colour_rgb(55, 50, 75);
col_sky = make_colour_rgb(12, 8, 25);
col_ceil = make_colour_rgb(35, 30, 50);

// Load state
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        points = _state.data.points;
        gold = _state.data.gold;
        wave = _state.data.wave;
        total_kills = _state.data.total_kills;
        player_hp = _state.data.player_hp;
    }
    catch (_ex) {
        api_save_state(0, { points: points, gold: gold, wave: wave, total_kills: total_kills, player_hp: player_hp }, undefined);
    }
    game_state = 1;
    alarm[0] = 60;
});
